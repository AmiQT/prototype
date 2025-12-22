"""
Student Balance Analysis Router

API endpoints for analyzing student academic-kokurikulum balance
and generating personalized action plans.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
import logging

from app.database import get_db
from app.auth import verify_supabase_token
from app.models.profile import Profile
from app.ml_analytics import BalanceAnalyzer, AIActionPlanGenerator

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/analytics/balance",
    tags=["Student Balance Analysis"]
)


# Request/Response Models
class StudentBalanceResponse(BaseModel):
    """Response for single student balance analysis."""
    student_id: str
    student_name: str
    metrics: Dict[str, Any]
    issues: List[Dict[str, Any]]
    action_plan: List[Dict[str, Any]]
    summary: str
    ai_action_plan: Optional[Dict[str, Any]] = None
    ai_enhanced: bool = False


class BatchBalanceResponse(BaseModel):
    """Response for batch balance analysis."""
    total_students: int
    statistics: Dict[str, Any]
    priority_groups: Dict[str, Any]
    individual_results: Optional[List[Dict[str, Any]]] = None
    ai_summary: Optional[str] = None


class BalanceMetricsResponse(BaseModel):
    """Simple metrics response."""
    academic_score: float
    kokurikulum_score: float
    balance_score: float
    status: str
    gap: float


# Initialize analyzers
balance_analyzer = BalanceAnalyzer()
ai_plan_generator = AIActionPlanGenerator()


# =====================================================
# DEV ENDPOINTS (No Auth - for testing only)
# =====================================================

@router.get("/dev/test")
async def dev_test():
    """Simple test endpoint."""
    return {"status": "ok", "message": "Balance API is working"}


@router.get("/dev/batch")
async def dev_batch_analysis(
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """DEV: Batch analysis without auth."""
    profiles = db.query(Profile).limit(limit).all()
    
    if not profiles:
        return {"total": 0, "results": []}
    
    results = []
    for profile in profiles:
        student_data = _profile_to_dict(profile)
        analysis = balance_analyzer.analyze_student(student_data)
        results.append({
            "uuid": str(profile.id),
            "student_id": profile.student_id or str(profile.id)[:8],
            "name": profile.full_name,
            "status": analysis["metrics"]["status"],
            "balance_score": analysis["metrics"]["balance_score"],
            "academic_score": analysis["metrics"]["academic_score"],
            "kokurikulum_score": analysis["metrics"]["kokurikulum_score"],
        })
    
    return {
        "total": len(results),
        "results": results
    }


def _find_profile(db: Session, identifier: str):
    """Find profile by student_id (AI220001) or UUID."""
    # First try student_id (shorter, user-friendly)
    profile = db.query(Profile).filter(Profile.student_id == identifier).first()
    if profile:
        return profile
    
    # Then try UUID
    profile = db.query(Profile).filter(Profile.id == identifier).first()
    return profile


@router.get("/dev/student/{identifier}")
async def dev_student_analysis(
    identifier: str,
    db: Session = Depends(get_db)
):
    """DEV: Single student analysis. Accepts student_id (AI220001) or UUID."""
    profile = _find_profile(db, identifier)
    
    if not profile:
        raise HTTPException(status_code=404, detail=f"Student not found: {identifier}")
    
    student_data = _profile_to_dict(profile)
    analysis = balance_analyzer.analyze_student(student_data)
    
    return {
        "uuid": str(profile.id),
        "student_id": profile.student_id,
        "name": profile.full_name,
        **analysis
    }


@router.post("/dev/student/{identifier}/action-plan")
async def dev_action_plan(
    identifier: str,
    db: Session = Depends(get_db)
):
    """DEV: Generate AI action plan. Accepts student_id (AI220001) or UUID."""
    profile = _find_profile(db, identifier)
    
    if not profile:
        raise HTTPException(status_code=404, detail=f"Student not found: {identifier}")
    
    student_data = _profile_to_dict(profile)
    plan = await ai_plan_generator.generate_action_plan(student_data, include_ai_insights=True)
    
    return {
        "uuid": str(profile.id),
        "student_id": profile.student_id,
        "name": profile.full_name,
        **plan
    }


# =====================================================
# PRODUCTION ENDPOINTS (With Auth)
# =====================================================


def _profile_to_dict(profile: Profile) -> Dict[str, Any]:
    """Convert Profile model to dictionary for analysis."""
    return {
        "id": profile.id,
        "full_name": profile.full_name,
        "department": profile.department,
        "faculty": profile.faculty,
        "cgpa": profile.cgpa,
        "academic_info": profile.academic_info,
        "kokurikulum_score": profile.kokurikulum_score,
        "kokurikulum_credits": profile.kokurikulum_credits,
        "kokurikulum_activities": profile.kokurikulum_activities or [],
        "skills": profile.skills or [],
        "interests": profile.interests or [],
    }


@router.get("/student/{student_id}", response_model=StudentBalanceResponse)
async def analyze_student_balance(
    student_id: str,
    include_ai: bool = Query(True, description="Include AI-generated action plan"),
    db: Session = Depends(get_db),
    current_user: dict = Depends(verify_supabase_token)
):
    """
    Analyze academic-kokurikulum balance for a specific student.
    
    Returns:
    - Balance metrics (academic score, koku score, balance score)
    - Identified issues with severity
    - Action plan with specific recommendations
    - AI-generated insights (if enabled)
    """
    try:
        # Get student profile
        profile = db.query(Profile).filter(Profile.id == student_id).first()
        
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Student with ID {student_id} not found"
            )
        
        # Convert to dict for analysis
        student_data = _profile_to_dict(profile)
        
        # Generate analysis
        if include_ai:
            analysis = await ai_plan_generator.generate_action_plan(
                student_data, 
                include_ai_insights=True
            )
        else:
            analysis = balance_analyzer.analyze_student(student_data)
            analysis["ai_enhanced"] = False
        
        logger.info(f"Balance analysis completed for student {student_id}")
        
        return StudentBalanceResponse(**analysis)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing student balance: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze student balance: {str(e)}"
        )


@router.get("/student/{student_id}/metrics", response_model=BalanceMetricsResponse)
async def get_student_metrics(
    student_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(verify_supabase_token)
):
    """
    Get quick balance metrics for a student (no action plan).
    
    Useful for dashboard widgets and quick status checks.
    """
    try:
        profile = db.query(Profile).filter(Profile.id == student_id).first()
        
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Student with ID {student_id} not found"
            )
        
        student_data = _profile_to_dict(profile)
        analysis = balance_analyzer.analyze_student(student_data)
        
        return BalanceMetricsResponse(**analysis["metrics"])
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting student metrics: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/batch", response_model=BatchBalanceResponse)
async def analyze_batch_balance(
    department: Optional[str] = Query(None, description="Filter by department"),
    limit: int = Query(50, ge=1, le=200, description="Maximum students to analyze"),
    include_individual: bool = Query(False, description="Include individual results"),
    include_ai: bool = Query(False, description="Include AI summary"),
    db: Session = Depends(get_db),
    current_user: dict = Depends(verify_supabase_token)
):
    """
    Analyze balance for multiple students.
    
    Provides aggregate statistics and priority groupings.
    Useful for admin/faculty overview.
    """
    try:
        # Build query
        query = db.query(Profile)
        
        if department:
            query = query.filter(Profile.department.ilike(f"%{department}%"))
        
        profiles = query.limit(limit).all()
        
        if not profiles:
            return BatchBalanceResponse(
                total_students=0,
                statistics={
                    "average_academic_score": 0,
                    "average_kokurikulum_score": 0,
                    "students_needing_attention": 0,
                    "status_distribution": {}
                },
                priority_groups={
                    "high": {"count": 0, "students": [], "action_required": ""},
                    "medium": {"count": 0, "students": [], "action_required": ""},
                    "low": {"count": 0, "students": [], "action_required": ""}
                }
            )
        
        # Convert profiles to dicts
        students_data = [_profile_to_dict(p) for p in profiles]
        
        # Run batch analysis
        batch_result = await ai_plan_generator.generate_batch_report(
            students_data,
            include_ai=include_ai
        )
        
        # Optionally exclude individual results
        if not include_individual:
            batch_result.pop("individual_results", None)
        
        logger.info(f"Batch balance analysis completed for {len(profiles)} students")
        
        return BatchBalanceResponse(**batch_result)
        
    except Exception as e:
        logger.error(f"Error in batch balance analysis: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/my-balance", response_model=StudentBalanceResponse)
async def get_my_balance(
    include_ai: bool = Query(True, description="Include AI-generated action plan"),
    db: Session = Depends(get_db),
    current_user: dict = Depends(verify_supabase_token)
):
    """
    Get balance analysis for the currently logged-in student.
    
    Useful for student self-assessment.
    """
    try:
        user_id = current_user.get("uid")
        
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not authenticated"
            )
        
        # Find profile by user_id
        profile = db.query(Profile).filter(Profile.user_id == user_id).first()
        
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found for current user"
            )
        
        student_data = _profile_to_dict(profile)
        
        if include_ai:
            analysis = await ai_plan_generator.generate_action_plan(
                student_data,
                include_ai_insights=True
            )
        else:
            analysis = balance_analyzer.analyze_student(student_data)
            analysis["ai_enhanced"] = False
        
        return StudentBalanceResponse(**analysis)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user balance: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/summary/department")
async def get_department_summary(
    db: Session = Depends(get_db),
    current_user: dict = Depends(verify_supabase_token)
):
    """
    Get balance summary grouped by department.
    
    Returns average scores and student counts per department.
    """
    try:
        # Get all profiles with department
        profiles = db.query(Profile).filter(
            Profile.department.isnot(None),
            Profile.department != ''
        ).all()
        
        # Group by department
        dept_data = {}
        
        for profile in profiles:
            dept = profile.department
            if dept not in dept_data:
                dept_data[dept] = {
                    "department": dept,
                    "students": [],
                    "total_academic": 0,
                    "total_koku": 0,
                    "count": 0
                }
            
            student_data = _profile_to_dict(profile)
            analysis = balance_analyzer.analyze_student(student_data)
            metrics = analysis["metrics"]
            
            dept_data[dept]["students"].append({
                "name": profile.full_name,
                "status": metrics["status"]
            })
            dept_data[dept]["total_academic"] += metrics["academic_score"]
            dept_data[dept]["total_koku"] += metrics["kokurikulum_score"]
            dept_data[dept]["count"] += 1
        
        # Calculate averages
        summary = []
        for dept, data in dept_data.items():
            count = data["count"]
            summary.append({
                "department": dept,
                "student_count": count,
                "average_academic_score": round(data["total_academic"] / count, 2) if count else 0,
                "average_kokurikulum_score": round(data["total_koku"] / count, 2) if count else 0,
                "status_distribution": {
                    s["status"]: sum(1 for st in data["students"] if st["status"] == s["status"])
                    for s in data["students"]
                }
            })
        
        return {
            "departments": sorted(summary, key=lambda x: x["student_count"], reverse=True),
            "total_departments": len(summary),
            "total_students": len(profiles)
        }
        
    except Exception as e:
        logger.error(f"Error getting department summary: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
