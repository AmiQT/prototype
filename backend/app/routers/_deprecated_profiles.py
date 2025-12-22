"""
Profile management API endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
# Firebase auth removed - using Supabase auth
from app.auth import verify_supabase_token
from app.models.profile import Profile
from app.models.user import User
from app.database import get_db
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/profiles", tags=["Profiles"])

# =============================================================================
# ACCESS CONTROL HELPERS
# =============================================================================

def is_user_pak_of_student(pak_user: User, student_profile: Profile) -> bool:
    """
    Check if the given user (PAK) is the personal advisor of the student.
    """
    if not pak_user or not student_profile:
        return False
    
    pak_name = pak_user.name.lower() if pak_user.name else ""
    pak_email = pak_user.email.lower() if pak_user.email else ""
    
    # Check direct personal_advisor field
    if student_profile.personal_advisor:
        if pak_name in student_profile.personal_advisor.lower():
            return True
    
    # Check personal_advisor_email field
    if student_profile.personal_advisor_email:
        if pak_email == student_profile.personal_advisor_email.lower():
            return True
    
    # Check in academic_info JSON
    if student_profile.academic_info and isinstance(student_profile.academic_info, dict):
        academic_pak = student_profile.academic_info.get('personalAdvisor') or \
                       student_profile.academic_info.get('personal_advisor') or ''
        if academic_pak and pak_name in academic_pak.lower():
            return True
    
    return False

def build_profile_response(profile: Profile, can_view_sensitive: bool = False) -> dict:
    """
    Build profile response dict with access control.
    - PAK/Admin/Self: can see all data including CGPA, phone, etc.
    - Others: only basic public info
    """
    # Basic public info - everyone can see
    response = {
        "id": profile.id,
        "user_id": profile.user_id,
        "full_name": profile.full_name,
        "bio": profile.bio,
        "profile_image_url": profile.profile_image_url,
        "department": profile.department,
        "faculty": profile.faculty,
        "year_of_study": profile.year_of_study,
        "skills": profile.skills or [],
        "interests": profile.interests or [],
        "created_at": profile.created_at.isoformat() if profile.created_at else None,
        "updated_at": profile.updated_at.isoformat() if profile.updated_at else None,
        "_access_level": "full" if can_view_sensitive else "limited",
    }
    
    # Sensitive info - only PAK/Admin/Self can see
    if can_view_sensitive:
        response.update({
            "phone": profile.phone_number,
            "phone_number": profile.phone_number,
            "address": profile.address,
            "headline": profile.headline,
            "student_id": profile.student_id,
            "cgpa": profile.cgpa,
            "academic_info": profile.academic_info,
            "experiences": profile.experiences or [],
            "projects": profile.projects or [],
            "languages": profile.languages if hasattr(profile, 'languages') else [],
            "linkedin_url": profile.linkedin_url if hasattr(profile, 'linkedin_url') else None,
            "github_url": profile.github_url if hasattr(profile, 'github_url') else None,
            "portfolio_url": profile.portfolio_url if hasattr(profile, 'portfolio_url') else None,
            "personal_advisor": profile.personal_advisor,
            "personal_advisor_email": profile.personal_advisor_email,
            "kokurikulum_score": profile.kokurikulum_score,
            "kokurikulum_credits": profile.kokurikulum_credits,
            "kokurikulum_activities": profile.kokurikulum_activities or [],
            "balance_metrics": profile.get_balance_metrics() if hasattr(profile, 'get_balance_metrics') else None,
        })
    
    return response

@router.get("/")
async def get_all_profiles(
    limit: int = Query(50, le=100),
    offset: int = Query(0),
    current_user: dict = Depends(verify_supabase_token),
    db: Session = Depends(get_db)
):
    """Get all profiles - sensitive data filtered based on access level"""
    try:
        # Get current user's info for access control
        user_id = current_user.get("sub") or current_user.get("user_id")
        requester = db.query(User).filter(User.id == user_id).first()
        is_admin = requester and requester.role == "admin"
        is_lecturer = requester and requester.role == "lecturer"
        
        profiles = db.query(Profile).offset(offset).limit(limit).all()
        
        result = []
        for profile in profiles:
            # Determine access level for each profile
            can_view_sensitive = False
            if is_admin:
                can_view_sensitive = True
            elif requester and str(requester.id) == str(profile.user_id):
                # User viewing their own profile
                can_view_sensitive = True
            elif is_lecturer:
                # PAK can view their students' sensitive info
                can_view_sensitive = is_user_pak_of_student(requester, profile)
            
            profile_dict = build_profile_response(profile, can_view_sensitive)
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
    """
    Get profile by user ID - sensitive data filtered based on access level.
    
    Access Control:
    - Admin: Full access to all profiles
    - PAK (Lecturer): Full access only to their assigned students
    - Student: Full access to own profile, limited access to others
    """
    try:
        profile = db.query(Profile).filter(Profile.user_id == user_id).first()
        
        if not profile:
            raise HTTPException(status_code=404, detail="Profile not found")
        
        # Get current user's info for access control
        requester_id = current_user.get("sub") or current_user.get("user_id")
        requester = db.query(User).filter(User.id == requester_id).first()
        
        # Determine access level
        can_view_sensitive = False
        
        if not requester:
            # No valid requester - limited access
            can_view_sensitive = False
        elif requester.role == "admin":
            # Admin has full access
            can_view_sensitive = True
        elif str(requester.id) == str(user_id):
            # User viewing their own profile
            can_view_sensitive = True
        elif requester.role == "lecturer":
            # PAK can view their students' sensitive info
            can_view_sensitive = is_user_pak_of_student(requester, profile)
        else:
            # Student viewing another student - limited access
            can_view_sensitive = False
        
        response = build_profile_response(profile, can_view_sensitive)
        
        # Add access info to help frontend
        if not can_view_sensitive:
            response["_message"] = "Maklumat terhad. Hanya PAK anda boleh melihat maklumat penuh."
        
        return response
        
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