"""
Advanced Search API endpoints - Features Firebase cannot handle efficiently
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, and_, or_, text
from typing import List, Optional, Dict, Any
import logging
from datetime import datetime, timedelta

# Firebase auth removed - using Supabase auth
from app.database import get_db
from app.auth import verify_supabase_token
from app.models.user import User, UserRole
from app.models.profile import Profile
from app.models.achievement import Achievement
from app.models.event import Event, EventParticipation
from app.models.showcase import ShowcasePost

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/search", tags=["Advanced Search"])

@router.get("/students")
async def search_students(
    # Search parameters
    q: Optional[str] = Query(None, description="General search query"),
    name: Optional[str] = Query(None, description="Search by name"),
    email: Optional[str] = Query(None, description="Search by email"),
    student_id: Optional[str] = Query(None, description="Search by student ID"),
    
    # Filter parameters
    department: Optional[str] = Query(None, description="Filter by department"),
    faculty: Optional[str] = Query(None, description="Filter by faculty"),
    year_of_study: Optional[str] = Query(None, description="Filter by year of study"),
    skills: Optional[str] = Query(None, description="Filter by skills (comma-separated)"),
    interests: Optional[str] = Query(None, description="Filter by interests (comma-separated)"),
    
    # Achievement filters
    min_achievements: Optional[int] = Query(None, description="Minimum number of achievements"),
    achievement_category: Optional[str] = Query(None, description="Filter by achievement category"),
    
    # Event participation filters
    min_events: Optional[int] = Query(None, description="Minimum number of events attended"),
    event_category: Optional[str] = Query(None, description="Filter by event category"),
    
    # CGPA filter
    min_cgpa: Optional[float] = Query(None, description="Minimum CGPA"),
    max_cgpa: Optional[float] = Query(None, description="Maximum CGPA"),
    
    # Pagination
    limit: int = Query(20, le=100, description="Maximum results"),
    offset: int = Query(0, description="Pagination offset"),
    
    # Sorting
    sort_by: Optional[str] = Query("name", description="Sort by field"),
    sort_order: Optional[str] = Query("asc", description="Sort order (asc/desc)"),
    
    current_user: dict = Depends(verify_supabase_token),
    db: Session = Depends(get_db)
):
    """
    Advanced student search with multiple filters and sorting
    This demonstrates complex queries that Firebase cannot handle efficiently
    """
    try:
        # Base query with joins
        query = db.query(User).join(Profile, User.id == Profile.user_id, isouter=True)\
                  .filter(User.role == UserRole.student)
        
        # Apply search filters
        if q:
            search_term = f"%{q}%"
            query = query.filter(
                or_(
                    User.name.ilike(search_term),
                    User.email.ilike(search_term),
                    Profile.full_name.ilike(search_term),
                    Profile.student_id.ilike(search_term),
                    Profile.bio.ilike(search_term)
                )
            )
        
        if name:
            name_term = f"%{name}%"
            query = query.filter(
                or_(
                    User.name.ilike(name_term),
                    Profile.full_name.ilike(name_term)
                )
            )
        
        if email:
            query = query.filter(User.email.ilike(f"%{email}%"))
        
        if student_id:
            query = query.filter(
                or_(
                    User.student_id.ilike(f"%{student_id}%"),
                    Profile.student_id.ilike(f"%{student_id}%")
                )
            )
        
        # Apply department/faculty filters
        if department:
            query = query.filter(
                or_(
                    User.department.ilike(f"%{department}%"),
                    Profile.department.ilike(f"%{department}%")
                )
            )
        
        if faculty:
            query = query.filter(Profile.faculty.ilike(f"%{faculty}%"))
        
        if year_of_study:
            query = query.filter(Profile.year_of_study == year_of_study)
        
        # Apply CGPA filters (handle as string first)
        if min_cgpa is not None:
            query = query.filter(
                and_(
                    Profile.cgpa.isnot(None),
                    Profile.cgpa != '',
                    text("CAST(profiles.cgpa AS FLOAT) >= :min_cgpa")
                )
            ).params(min_cgpa=min_cgpa)
        
        if max_cgpa is not None:
            query = query.filter(
                and_(
                    Profile.cgpa.isnot(None),
                    Profile.cgpa != '',
                    text("CAST(profiles.cgpa AS FLOAT) <= :max_cgpa")
                )
            ).params(max_cgpa=max_cgpa)
        
        # Apply skills filter (PostgreSQL JSON array search)
        if skills:
            skill_list = [skill.strip() for skill in skills.split(',')]
            for skill in skill_list:
                query = query.filter(
                    func.cast(Profile.skills, text('TEXT')).like(f'%{skill}%')
                )
        
        # Apply interests filter (PostgreSQL JSON array search)
        if interests:
            interest_list = [interest.strip() for interest in interests.split(',')]
            for interest in interest_list:
                query = query.filter(
                    func.cast(Profile.interests, text('TEXT')).like(f'%{interest}%')
                )
        
        # Apply achievement filters (subquery)
        if min_achievements is not None or achievement_category:
            achievement_subquery = db.query(Achievement.user_id)
            
            if achievement_category:
                achievement_subquery = achievement_subquery.filter(
                    Achievement.category.ilike(f"%{achievement_category}%")
                )
            
            if min_achievements is not None:
                achievement_counts = achievement_subquery.group_by(Achievement.user_id)\
                                                       .having(func.count(Achievement.id) >= min_achievements)
                query = query.filter(User.id.in_(achievement_counts))
            else:
                query = query.filter(User.id.in_(achievement_subquery))
        
        # Apply event participation filters (subquery)
        if min_events is not None or event_category:
            event_subquery = db.query(EventParticipation.user_id)\
                              .join(Event, EventParticipation.event_id == Event.id)
            
            if event_category:
                event_subquery = event_subquery.filter(
                    Event.category.ilike(f"%{event_category}%")
                )
            
            if min_events is not None:
                event_counts = event_subquery.group_by(EventParticipation.user_id)\
                                           .having(func.count(EventParticipation.id) >= min_events)
                query = query.filter(User.id.in_(event_counts))
            else:
                query = query.filter(User.id.in_(event_subquery))
        
        # Apply sorting
        if sort_by == "name":
            sort_field = User.name
        elif sort_by == "email":
            sort_field = User.email
        elif sort_by == "department":
            sort_field = Profile.department
        elif sort_by == "cgpa":
            sort_field = Profile.cgpa
        elif sort_by == "created_at":
            sort_field = User.created_at
        else:
            sort_field = User.name
        
        if sort_order.lower() == "desc":
            sort_field = sort_field.desc()
        
        query = query.order_by(sort_field)
        
        # Get total count before pagination
        total_count = query.count()
        
        # Apply pagination
        students = query.offset(offset).limit(limit).all()
        
        # Format results
        results = []
        for user in students:
            profile = user.profile[0] if user.profile else None
            
            # Get achievement count
            achievement_count = db.query(Achievement).filter(Achievement.user_id == user.id).count()
            
            # Get event participation count
            event_count = db.query(EventParticipation).filter(EventParticipation.user_id == user.id).count()
            
            results.append({
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "student_id": user.student_id or (profile.student_id if profile else None),
                "department": user.department or (profile.department if profile else None),
                "faculty": profile.faculty if profile else None,
                "year_of_study": profile.year_of_study if profile else None,
                "cgpa": profile.cgpa if profile else None,
                "skills": profile.skills if profile else [],
                "interests": profile.interests if profile else [],
                "achievement_count": achievement_count,
                "event_participation_count": event_count,
                "profile_image_url": profile.profile_image_url if profile else None,
                "bio": profile.bio if profile else None,
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
            "filters_applied": {
                "search_query": q,
                "department": department,
                "faculty": faculty,
                "skills": skills,
                "interests": interests,
                "min_achievements": min_achievements,
                "min_events": min_events,
                "min_cgpa": min_cgpa,
                "max_cgpa": max_cgpa
            },
            "sorting": {
                "sort_by": sort_by,
                "sort_order": sort_order
            }
        }
        
    except Exception as e:
        logger.error(f"Error in advanced student search: {e}")
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")

@router.get("/similar-students/{student_id}")
async def find_similar_students(
    student_id: str,
    limit: int = Query(10, le=20, description="Maximum similar students to return"),
    current_user: dict = Depends(verify_supabase_token),
    db: Session = Depends(get_db)
):
    """
    Find students similar to the given student based on skills, interests, and department
    This uses advanced similarity algorithms that Firebase cannot perform
    """
    try:
        # Get the target student's profile
        target_user = db.query(User).filter(User.id == student_id).first()
        if not target_user:
            raise HTTPException(status_code=404, detail="Student not found")
        
        target_profile = db.query(Profile).filter(Profile.user_id == student_id).first()
        if not target_profile:
            return {
                "similar_students": [],
                "message": "No profile data available for similarity matching"
            }
        
        # Get all other students with profiles
        other_students = db.query(User).join(Profile, User.id == Profile.user_id)\
                          .filter(User.role == UserRole.student)\
                          .filter(User.id != student_id).all()
        
        # Calculate similarity scores
        similar_students = []
        
        for student in other_students:
            profile = student.profile[0] if student.profile else None
            if not profile:
                continue
            
            similarity_score = 0
            factors = []
            
            # Department similarity (high weight)
            if target_profile.department and profile.department:
                if target_profile.department.lower() == profile.department.lower():
                    similarity_score += 30
                    factors.append("Same department")
            
            # Faculty similarity (medium weight)
            if target_profile.faculty and profile.faculty:
                if target_profile.faculty.lower() == profile.faculty.lower():
                    similarity_score += 20
                    factors.append("Same faculty")
            
            # Year of study similarity (low weight)
            if target_profile.year_of_study and profile.year_of_study:
                if target_profile.year_of_study == profile.year_of_study:
                    similarity_score += 10
                    factors.append("Same year")
            
            # Skills similarity (high weight)
            if target_profile.skills and profile.skills:
                target_skills = set([skill.lower() for skill in target_profile.skills])
                student_skills = set([skill.lower() for skill in profile.skills])
                common_skills = target_skills.intersection(student_skills)
                if common_skills:
                    skill_score = len(common_skills) * 5
                    similarity_score += skill_score
                    factors.append(f"{len(common_skills)} common skills")
            
            # Interests similarity (medium weight)
            if target_profile.interests and profile.interests:
                target_interests = set([interest.lower() for interest in target_profile.interests])
                student_interests = set([interest.lower() for interest in profile.interests])
                common_interests = target_interests.intersection(student_interests)
                if common_interests:
                    interest_score = len(common_interests) * 3
                    similarity_score += interest_score
                    factors.append(f"{len(common_interests)} common interests")
            
            # CGPA similarity (low weight)
            if target_profile.cgpa and profile.cgpa:
                try:
                    target_cgpa = float(target_profile.cgpa)
                    student_cgpa = float(profile.cgpa)
                    cgpa_diff = abs(target_cgpa - student_cgpa)
                    if cgpa_diff <= 0.5:
                        similarity_score += 15
                        factors.append("Similar CGPA")
                    elif cgpa_diff <= 1.0:
                        similarity_score += 5
                        factors.append("Close CGPA")
                except ValueError:
                    pass
            
            if similarity_score > 0:
                similar_students.append({
                    "student": {
                        "id": student.id,
                        "name": student.name,
                        "email": student.email,
                        "department": profile.department,
                        "faculty": profile.faculty,
                        "year_of_study": profile.year_of_study,
                        "cgpa": profile.cgpa,
                        "skills": profile.skills,
                        "interests": profile.interests,
                        "profile_image_url": profile.profile_image_url
                    },
                    "similarity_score": similarity_score,
                    "similarity_factors": factors
                })
        
        # Sort by similarity score and limit results
        similar_students.sort(key=lambda x: x["similarity_score"], reverse=True)
        similar_students = similar_students[:limit]
        
        return {
            "target_student": {
                "id": target_user.id,
                "name": target_user.name,
                "department": target_profile.department,
                "skills": target_profile.skills,
                "interests": target_profile.interests
            },
            "similar_students": similar_students,
            "total_found": len(similar_students)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error finding similar students: {e}")
        raise HTTPException(status_code=500, detail=f"Similarity search failed: {str(e)}")