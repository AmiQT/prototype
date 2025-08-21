"""
Firebase to Backend Data Sync API endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Dict, Any
import logging
from datetime import datetime

# Firebase auth removed - using Supabase auth
from app.database import get_db
from app.models.user import User, UserRole
from app.models.profile import Profile
from app.models.achievement import Achievement
from app.models.event import Event
from app.models.showcase import ShowcasePost

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/sync", tags=["Data Sync"])

@router.get("/status")
async def get_sync_status(
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """
    Get current sync status and data counts
    """
    try:
        # Count records in PostgreSQL
        user_count = db.query(User).count()
        profile_count = db.query(Profile).count()
        achievement_count = db.query(Achievement).count()
        event_count = db.query(Event).count()
        showcase_count = db.query(ShowcasePost).count()
        
        return {
            "status": "ready",
            "database_counts": {
                "users": user_count,
                "profiles": profile_count,
                "achievements": achievement_count,
                "events": event_count,
                "showcases": showcase_count
            },
            "last_sync": None,  # Will implement tracking later
            "sync_available": True
        }
        
    except Exception as e:
        logger.error(f"Error getting sync status: {e}")
        raise HTTPException(status_code=500, detail="Failed to get sync status")

@router.post("/users")
async def sync_users_from_firebase(
    users_data: List[Dict[str, Any]],
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """
    Sync users from Firebase to PostgreSQL
    Expected format: [{"uid": "...", "email": "...", "name": "...", "role": "student"}]
    """
    try:
        synced_count = 0
        updated_count = 0
        errors = []
        
        for user_data in users_data:
            try:
                # Check if user already exists
                existing_user = db.query(User).filter(User.uid == user_data["uid"]).first()
                
                if existing_user:
                    # Update existing user
                    existing_user.email = user_data.get("email", existing_user.email)
                    existing_user.name = user_data.get("name", existing_user.name)
                    existing_user.role = UserRole(user_data.get("role", "student"))
                    existing_user.updated_at = datetime.utcnow()
                    updated_count += 1
                else:
                    # Create new user
                    new_user = User(
                        id=user_data["uid"],
                        uid=user_data["uid"],
                        email=user_data["email"],
                        name=user_data["name"],
                        role=UserRole(user_data.get("role", "student")),
                        student_id=user_data.get("studentId"),
                        department=user_data.get("department"),
                        is_active=True,
                        profile_completed=user_data.get("profileCompleted", False)
                    )
                    db.add(new_user)
                    synced_count += 1
                    
            except Exception as e:
                errors.append(f"Error syncing user {user_data.get('uid', 'unknown')}: {str(e)}")
                continue
        
        # Commit all changes
        db.commit()
        
        return {
            "status": "completed",
            "synced_count": synced_count,
            "updated_count": updated_count,
            "total_processed": len(users_data),
            "errors": errors
        }
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error syncing users: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to sync users: {str(e)}")

@router.post("/profiles")
async def sync_profiles_from_firebase(
    profiles_data: List[Dict[str, Any]],
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """
    Sync profiles from Firebase to PostgreSQL
    """
    try:
        synced_count = 0
        updated_count = 0
        errors = []
        
        for profile_data in profiles_data:
            try:
                user_id = profile_data.get("userId")
                if not user_id:
                    errors.append("Profile missing userId")
                    continue
                
                # Check if profile already exists
                existing_profile = db.query(Profile).filter(Profile.user_id == user_id).first()
                
                if existing_profile:
                    # Update existing profile
                    existing_profile.full_name = profile_data.get("fullName", existing_profile.full_name)
                    existing_profile.bio = profile_data.get("bio", existing_profile.bio)
                    existing_profile.phone = profile_data.get("phone", existing_profile.phone)
                    existing_profile.profile_image_url = profile_data.get("profileImageUrl", existing_profile.profile_image_url)
                    existing_profile.student_id = profile_data.get("studentId", existing_profile.student_id)
                    existing_profile.department = profile_data.get("department", existing_profile.department)
                    existing_profile.faculty = profile_data.get("faculty", existing_profile.faculty)
                    existing_profile.year_of_study = profile_data.get("yearOfStudy", existing_profile.year_of_study)
                    existing_profile.cgpa = profile_data.get("cgpa", existing_profile.cgpa)
                    existing_profile.skills = profile_data.get("skills", existing_profile.skills)
                    existing_profile.interests = profile_data.get("interests", existing_profile.interests)
                    existing_profile.languages = profile_data.get("languages", existing_profile.languages)
                    existing_profile.experiences = profile_data.get("experiences", existing_profile.experiences)
                    existing_profile.projects = profile_data.get("projects", existing_profile.projects)
                    existing_profile.linkedin_url = profile_data.get("linkedinUrl", existing_profile.linkedin_url)
                    existing_profile.github_url = profile_data.get("githubUrl", existing_profile.github_url)
                    existing_profile.portfolio_url = profile_data.get("portfolioUrl", existing_profile.portfolio_url)
                    existing_profile.updated_at = datetime.utcnow()
                    updated_count += 1
                else:
                    # Create new profile
                    new_profile = Profile(
                        id=profile_data.get("id", user_id),
                        user_id=user_id,
                        full_name=profile_data.get("fullName", ""),
                        bio=profile_data.get("bio"),
                        phone=profile_data.get("phone"),
                        profile_image_url=profile_data.get("profileImageUrl"),
                        student_id=profile_data.get("studentId"),
                        department=profile_data.get("department"),
                        faculty=profile_data.get("faculty"),
                        year_of_study=profile_data.get("yearOfStudy"),
                        cgpa=profile_data.get("cgpa"),
                        skills=profile_data.get("skills"),
                        interests=profile_data.get("interests"),
                        languages=profile_data.get("languages"),
                        experiences=profile_data.get("experiences"),
                        projects=profile_data.get("projects"),
                        linkedin_url=profile_data.get("linkedinUrl"),
                        github_url=profile_data.get("githubUrl"),
                        portfolio_url=profile_data.get("portfolioUrl")
                    )
                    db.add(new_profile)
                    synced_count += 1
                    
            except Exception as e:
                errors.append(f"Error syncing profile for user {profile_data.get('userId', 'unknown')}: {str(e)}")
                continue
        
        # Commit all changes
        db.commit()
        
        return {
            "status": "completed",
            "synced_count": synced_count,
            "updated_count": updated_count,
            "total_processed": len(profiles_data),
            "errors": errors
        }
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error syncing profiles: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to sync profiles: {str(e)}")

@router.post("/test-data")
async def create_test_data(
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """
    Create some test data for demonstration
    """
    try:
        # Create test users if they don't exist
        test_users = [
            {
                "uid": "test_student_1",
                "email": "student1@uthm.edu.my",
                "name": "Ahmad Rahman",
                "role": "student",
                "department": "FSKTM",
                "student_id": "AI200001"
            },
            {
                "uid": "test_student_2", 
                "email": "student2@uthm.edu.my",
                "name": "Siti Aminah",
                "role": "student",
                "department": "FSKTM",
                "student_id": "AI200002"
            },
            {
                "uid": "test_lecturer_1",
                "email": "lecturer1@uthm.edu.my", 
                "name": "Dr. Hassan Ali",
                "role": "lecturer",
                "department": "FSKTM"
            }
        ]
        
        created_count = 0
        for user_data in test_users:
            existing = db.query(User).filter(User.uid == user_data["uid"]).first()
            if not existing:
                new_user = User(
                    id=user_data["uid"],
                    uid=user_data["uid"],
                    email=user_data["email"],
                    name=user_data["name"],
                    role=UserRole(user_data["role"]),
                    department=user_data.get("department"),
                    student_id=user_data.get("student_id"),
                    is_active=True,
                    profile_completed=True
                )
                db.add(new_user)
                created_count += 1
        
        db.commit()
        
        return {
            "status": "completed",
            "message": f"Created {created_count} test users",
            "test_users": test_users
        }
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating test data: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create test data: {str(e)}")