"""
Profile management API endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
# Firebase auth removed - using Supabase auth
from app.models.profile import Profile
from app.models.user import User
from app.database import get_db
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/profiles", tags=["Profiles"])

@router.get("/")
async def get_all_profiles(
    limit: int = Query(50, le=100),
    offset: int = Query(0),
    current_user: dict = Depends(verify_supabase_token),
    db: Session = Depends(get_db)
):
    """Get all profiles"""
    try:
        profiles = db.query(Profile).offset(offset).limit(limit).all()
        
        result = []
        for profile in profiles:
            profile_dict = {
                "id": profile.id,
                "user_id": profile.userId,
                "full_name": profile.fullName,
                "bio": profile.bio,
                "phone": profile.phone,
                "profile_image_url": profile.profileImageUrl,
                "student_id": profile.studentId,
                "department": profile.department,
                "faculty": profile.faculty,
                "year_of_study": profile.yearOfStudy,
                "cgpa": profile.cgpa,
                "skills": profile.skills or [],
                "interests": profile.interests or [],
                "languages": profile.languages or [],
                "experiences": profile.experiences or [],
                "projects": profile.projects or [],
                "linkedin_url": profile.linkedinUrl,
                "github_url": profile.githubUrl,
                "portfolio_url": profile.portfolioUrl,
                "created_at": profile.createdAt.isoformat() if profile.createdAt else None,
                "updated_at": profile.updatedAt.isoformat() if profile.updatedAt else None,
            }
            result.append(profile_dict)
        
        return result
        
    except Exception as e:
        logger.error(f"Error getting profiles: {e}")
        raise HTTPException(status_code=500, detail="Failed to get profiles")

@router.get("/{user_id}")
async def get_profile_by_user_id(
    user_id: str,
    current_user: dict = Depends(verify_supabase_token),
    db: Session = Depends(get_db)
):
    """Get profile by user ID"""
    try:
        profile = db.query(Profile).filter(Profile.userId == user_id).first()
        
        if not profile:
            raise HTTPException(status_code=404, detail="Profile not found")
        
        return {
            "id": profile.id,
            "user_id": profile.userId,
            "full_name": profile.fullName,
            "bio": profile.bio,
            "phone": profile.phone,
            "profile_image_url": profile.profileImageUrl,
            "student_id": profile.studentId,
            "department": profile.department,
            "faculty": profile.faculty,
            "year_of_study": profile.yearOfStudy,
            "cgpa": profile.cgpa,
            "skills": profile.skills or [],
            "interests": profile.interests or [],
            "languages": profile.languages or [],
            "experiences": profile.experiences or [],
            "projects": profile.projects or [],
            "linkedin_url": profile.linkedinUrl,
            "github_url": profile.githubUrl,
            "portfolio_url": profile.portfolioUrl,
            "created_at": profile.createdAt.isoformat() if profile.createdAt else None,
            "updated_at": profile.updatedAt.isoformat() if profile.updatedAt else None,
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting profile: {e}")
        raise HTTPException(status_code=500, detail="Failed to get profile")

@router.get("/search")
async def search_profiles(
    q: Optional[str] = Query(None, description="Search query"),
    department: Optional[str] = Query(None),
    limit: int = Query(20, le=100),
    current_user: dict = Depends(verify_supabase_token),
    db: Session = Depends(get_db)
):
    """Search profiles"""
    try:
        query = db.query(Profile)
        
        if q:
            query = query.filter(
                Profile.fullName.ilike(f"%{q}%") |
                Profile.bio.ilike(f"%{q}%") |
                Profile.department.ilike(f"%{q}%")
            )
        
        if department:
            query = query.filter(Profile.department.ilike(f"%{department}%"))
        
        profiles = query.limit(limit).all()
        
        result = []
        for profile in profiles:
            profile_dict = {
                "id": profile.id,
                "user_id": profile.userId,
                "full_name": profile.fullName,
                "bio": profile.bio,
                "department": profile.department,
                "faculty": profile.faculty,
                "profile_image_url": profile.profileImageUrl,
                "skills": profile.skills or [],
                "interests": profile.interests or [],
            }
            result.append(profile_dict)
        
        return result
        
    except Exception as e:
        logger.error(f"Error searching profiles: {e}")
        raise HTTPException(status_code=500, detail="Search failed")