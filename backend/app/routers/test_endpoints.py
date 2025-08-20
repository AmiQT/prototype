"""
Test endpoints without authentication for debugging
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
# Using raw SQL queries instead of models
from app.database import get_db
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/test", tags=["Test"])

@router.get("/profiles")
async def test_get_profiles(db: Session = Depends(get_db)):
    """Test endpoint to get profiles without authentication"""
    try:
        # Use raw SQL to get profiles with only confirmed existing columns
        result = db.execute(text("""
            SELECT 
                id,
                COALESCE("fullName", '') as full_name,
                COALESCE(bio, '') as bio,
                COALESCE(address, '') as address,
                COALESCE("academicInfo/department", '') as department,
                COALESCE("academicInfo/faculty", '') as faculty,
                COALESCE("academicInfo/program", '') as program,
                COALESCE("academicInfo/studentId", '') as student_id
            FROM profiles 
            LIMIT 10
        """)).fetchall()
        
        profiles = []
        for row in result:
            profile_dict = {
                "id": row[0],
                "full_name": row[1],
                "bio": row[2],
                "address": row[3],
                "department": row[4],
                "faculty": row[5],
                "program": row[6],
                "student_id": row[7],
            }
            profiles.append(profile_dict)
        
        return {
            "status": "success",
            "count": len(profiles),
            "profiles": profiles
        }
        
    except Exception as e:
        logger.error(f"Error getting test profiles: {e}")
        return {
            "status": "error",
            "message": str(e),
            "profiles": []
        }

@router.get("/events")
async def test_get_events():
    """Test endpoint to get events without authentication"""
    sample_events = [
        {
            "id": "1",
            "title": "Tech Talk: AI in Education",
            "description": "Learn about the latest AI applications",
            "date": "2024-02-15T10:00:00Z",
            "location": "UTHM Auditorium"
        },
        {
            "id": "2", 
            "title": "Career Fair 2024",
            "description": "Meet with top employers",
            "date": "2024-02-20T09:00:00Z",
            "location": "UTHM Main Hall"
        }
    ]
    
    return {
        "status": "success",
        "count": len(sample_events),
        "events": sample_events
    }

@router.get("/database-connection")
async def test_database_connection(db: Session = Depends(get_db)):
    """Test database connection"""
    try:
        # Try to execute a simple query
        result = db.execute(text("SELECT 1 as test")).fetchone()
        
        # Check if profiles table exists
        table_check = db.execute(text("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'profiles'
        """)).fetchone()
        
        # Get actual column names in profiles table
        columns_result = db.execute(text("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'profiles'
            ORDER BY ordinal_position
        """)).fetchall()
        
        columns = [{"name": row[0], "type": row[1]} for row in columns_result]
        
        return {
            "status": "success",
            "database_connected": True,
            "profiles_table_exists": table_check is not None,
            "actual_columns": columns,
            "test_query": result[0] if result else None
        }
        
    except Exception as e:
        return {
            "status": "error",
            "database_connected": False,
            "error": str(e)
        }

@router.get("/raw-profiles")
async def get_raw_profiles(db: Session = Depends(get_db)):
    """Get raw profiles data to see actual structure"""
    try:
        # Get first few profiles with raw SQL to see actual column names
        result = db.execute(text("SELECT * FROM profiles LIMIT 3")).fetchall()
        
        # Get column names
        columns_result = db.execute(text("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'profiles'
            ORDER BY ordinal_position
        """)).fetchall()
        
        column_names = [row[0] for row in columns_result]
        
        # Convert results to dictionaries
        profiles = []
        for row in result:
            profile_dict = dict(zip(column_names, row))
            profiles.append(profile_dict)
        
        return {
            "status": "success",
            "column_names": column_names,
            "sample_profiles": profiles
        }
        
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }