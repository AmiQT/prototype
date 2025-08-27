"""
Simplified Search API endpoints for testing - avoiding complex PostgreSQL queries
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import List, Optional, Dict, Any
import logging

# Firebase auth removed - using Supabase auth
from app.database import get_db
from app.auth import verify_supabase_token
from app.models.user import User, UserRole
from app.models.profile import Profile
from app.models.achievement import Achievement
from app.models.event import Event, EventParticipation

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/search-simple", tags=["Simple Search"])

@router.get("/students")
async def search_students_simple(
    # Basic search parameters
    q: Optional[str] = Query(None, description="General search query"),
    department: Optional[str] = Query(None, description="Filter by department"),
    
    # Pagination
    limit: int = Query(20, le=50, description="Maximum results"),
    offset: int = Query(0, description="Pagination offset"),
    
    current_user: dict = Depends(verify_supabase_token),
    db: Session = Depends(get_db)
):
    """
    Simplified student search that works reliably with PostgreSQL
    """
    try:
        # Base query with simple join
        query = db.query(User).join(Profile, User.id == Profile.user_id, isouter=True)\
                  .filter(User.role == UserRole.student)
        
        # Apply basic search filter
        if q:
            search_term = f"%{q}%"
            query = query.filter(
                or_(
                    User.name.ilike(search_term),
                    User.email.ilike(search_term),
                    Profile.full_name.ilike(search_term)
                )
            )
        
        # Apply department filter
        if department:
            dept_term = f"%{department}%"
            query = query.filter(
                or_(
                    User.department.ilike(dept_term),
                    Profile.department.ilike(dept_term)
                )
            )
        
        # Simple sorting by name
        query = query.order_by(User.name)
        
        # Get total count
        total_count = query.count()
        
        # Apply pagination
        students = query.offset(offset).limit(limit).all()
        
        # Format results with basic info
        results = []
        for user in students:
            profile = user.profile[0] if user.profile else None
            
            # Get basic counts
            achievement_count = db.query(Achievement).filter(Achievement.user_id == user.id).count()
            
            results.append({
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "department": user.department or (profile.department if profile else None),
                "student_id": user.student_id or (profile.student_id if profile else None),
                "full_name": profile.full_name if profile else user.name,
                "bio": profile.bio if profile else None,
                "achievement_count": achievement_count,
                "profile_image_url": profile.profile_image_url if profile else None,
                "created_at": user.created_at.isoformat() if user.created_at else None
            })
        
        return {
            "students": results,
            "pagination": {
                "total": total_count,
                "limit": limit,
                "offset": offset,
                "has_more": offset + limit < total_count
            },
            "search_info": {
                "query": q,
                "department": department,
                "note": "Simplified search for testing - full features available in production"
            }
        }
        
    except Exception as e:
        logger.error(f"Error in simple student search: {e}")
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")

@router.get("/departments")
async def get_departments(
    current_user: dict = Depends(verify_supabase_token),
    db: Session = Depends(get_db)
):
    """
    Get list of available departments
    """
    try:
        # Get departments from users table
        user_depts = db.query(User.department).filter(
            User.department.isnot(None),
            User.department != ''
        ).distinct().all()
        
        # Get departments from profiles table
        profile_depts = db.query(Profile.department).filter(
            Profile.department.isnot(None),
            Profile.department != ''
        ).distinct().all()
        
        # Combine and clean up
        all_depts = set()
        for dept in user_depts:
            if dept[0]:
                all_depts.add(dept[0])
        for dept in profile_depts:
            if dept[0]:
                all_depts.add(dept[0])
        
        return {
            "departments": sorted(list(all_depts)),
            "count": len(all_depts)
        }
        
    except Exception as e:
        logger.error(f"Error getting departments: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get departments: {str(e)}")

@router.get("/stats")
async def get_search_stats(
    current_user: dict = Depends(verify_supabase_token),
    db: Session = Depends(get_db)
):
    """
    Get basic statistics for search functionality
    """
    try:
        # Basic counts
        total_students = db.query(User).filter(User.role == UserRole.student).count()
        students_with_profiles = db.query(User).join(Profile, User.id == Profile.user_id)\
                                  .filter(User.role == UserRole.student).count()
        total_achievements = db.query(Achievement).count()
        total_events = db.query(Event).count()
        
        # Department distribution
        dept_stats = db.query(
            User.department,
            func.count(User.id).label('count')
        ).filter(
            User.role == UserRole.student,
            User.department.isnot(None),
            User.department != ''
        ).group_by(User.department).all()
        
        return {
            "overview": {
                "total_students": total_students,
                "students_with_profiles": students_with_profiles,
                "total_achievements": total_achievements,
                "total_events": total_events,
                "profile_completion_rate": round((students_with_profiles / total_students * 100) if total_students > 0 else 0, 1)
            },
            "departments": {
                dept: count for dept, count in dept_stats if dept
            },
            "search_capabilities": [
                "Basic name and email search",
                "Department filtering",
                "Achievement counting",
                "Profile information display",
                "Pagination support"
            ]
        }
        
    except Exception as e:
        logger.error(f"Error getting search stats: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get stats: {str(e)}")

@router.get("/test-data-check")
async def check_test_data(
    current_user: dict = Depends(verify_supabase_token),
    db: Session = Depends(get_db)
):
    """
    Check if test data exists and suggest creating it
    """
    try:
        student_count = db.query(User).filter(User.role == UserRole.student).count()
        profile_count = db.query(Profile).count()
        
        has_test_data = student_count > 0
        
        return {
            "has_data": has_test_data,
            "student_count": student_count,
            "profile_count": profile_count,
            "recommendation": "Create test data first" if not has_test_data else "Ready for search testing",
            "next_steps": [
                "Go to Data Sync screen",
                "Click 'Create Test Data'",
                "Return here to test search"
            ] if not has_test_data else [
                "Try searching for 'Ahmad' or 'FSKTM'",
                "Test department filtering",
                "Check search statistics"
            ]
        }
        
    except Exception as e:
        logger.error(f"Error checking test data: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to check data: {str(e)}")