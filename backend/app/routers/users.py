"""
User management API endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from pydantic import BaseModel, EmailStr
from datetime import datetime
# Firebase auth removed - using Supabase auth
from app.models.user import User, UserRole
from app.models.profile import Profile
from app.database import get_db
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/users", tags=["Users"])

# Pydantic models for CRUD operations
class UserCreate(BaseModel):
    uid: str
    email: EmailStr
    name: str
    role: UserRole
    department: Optional[str] = None
    student_id: Optional[str] = None
    staff_id: Optional[str] = None
    is_active: bool = True
    profile_completed: bool = False

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    name: Optional[str] = None
    role: Optional[UserRole] = None
    department: Optional[str] = None
    student_id: Optional[str] = None
    staff_id: Optional[str] = None
    is_active: Optional[bool] = None
    profile_completed: Optional[bool] = None

class UserSyncRequest(BaseModel):
    action: str  # 'create', 'update', 'delete'
    user_data: dict

@router.get("/search")
async def search_users(
    q: Optional[str] = Query(None, description="Search query"),
    role: Optional[UserRole] = Query(None, description="Filter by role"),
    department: Optional[str] = Query(None, description="Filter by department"),
    limit: int = Query(50, le=100, description="Maximum results"),
    offset: int = Query(0, description="Pagination offset"),
    current_user: dict = Depends(verify_firebase_token),
    db: Session = Depends(get_db)
):
    """
    Advanced user search with filters
    This demonstrates the kind of complex query Firebase can't handle efficiently
    """
    try:
        query = db.query(User).join(Profile, User.id == Profile.user_id, isouter=True)
        
        # Apply search filter
        if q:
            search_filter = f"%{q}%"
            query = query.filter(
                (User.name.ilike(search_filter)) |
                (User.email.ilike(search_filter)) |
                (Profile.full_name.ilike(search_filter)) |
                (Profile.student_id.ilike(search_filter))
            )
        
        # Apply role filter
        if role:
            query = query.filter(User.role == role)
        
        # Apply department filter
        if department:
            query = query.filter(
                (User.department.ilike(f"%{department}%")) |
                (Profile.department.ilike(f"%{department}%"))
            )
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        users = query.offset(offset).limit(limit).all()
        
        return {
            "users": [
                {
                    "id": user.id,
                    "name": user.name,
                    "email": user.email,
                    "role": user.role.value,
                    "department": user.department,
                    "is_active": user.is_active,
                    "profile_completed": user.profile_completed,
                    "created_at": user.created_at.isoformat() if user.created_at else None
                }
                for user in users
            ],
            "pagination": {
                "total": total,
                "limit": limit,
                "offset": offset,
                "has_more": offset + limit < total
            }
        }
        
    except Exception as e:
        logger.error(f"Error searching users: {e}")
        raise HTTPException(status_code=500, detail="Search failed")

@router.get("/stats")
async def get_user_stats(
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """
    Get user statistics - another example of complex analytics
    """
    try:
        # Get user counts by role
        role_stats = db.query(
            User.role,
            func.count(User.id).label('count')
        ).group_by(User.role).all()
        
        # Get department distribution
        dept_stats = db.query(
            User.department,
            func.count(User.id).label('count')
        ).filter(User.department.isnot(None)).group_by(User.department).all()
        
        # Get profile completion stats
        profile_stats = db.query(
            User.profile_completed,
            func.count(User.id).label('count')
        ).group_by(User.profile_completed).all()
        
        return {
            "total_users": db.query(User).count(),
            "active_users": db.query(User).filter(User.is_active == True).count(),
            "role_distribution": {
                role.value: count for role, count in role_stats
            },
            "department_distribution": {
                dept: count for dept, count in dept_stats
            },
            "profile_completion": {
                "completed" if completed else "incomplete": count 
                for completed, count in profile_stats
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting user stats: {e}")
        raise HTTPException(status_code=500, detail="Failed to get statistics")

@router.get("/{user_id}")
async def get_user(
    user_id: str,
    current_user: dict = Depends(verify_firebase_token),
    db: Session = Depends(get_db)
):
    """
    Get specific user details
    """
    try:
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Check if current user can view this profile
        if current_user["uid"] != user_id and current_user.get("role") not in ["admin", "lecturer"]:
            raise HTTPException(status_code=403, detail="Access denied")
        
        return {
            "user": {
                "id": user.id,
                "uid": user.uid,
                "name": user.name,
                "email": user.email,
                "role": user.role.value,
                "department": user.department,
                "student_id": user.student_id,
                "is_active": user.is_active,
                "profile_completed": user.profile_completed,
                "created_at": user.created_at.isoformat() if user.created_at else None,
                "last_login_at": user.last_login_at.isoformat() if user.last_login_at else None
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to get user")

# CRUD Operations for Dashboard Integration

@router.post("/")
async def create_user(
    user_data: UserCreate,
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """Create a new user in the backend database"""
    try:
        # Check if user already exists
        existing_user = db.query(User).filter(User.uid == user_data.uid).first()
        if existing_user:
            raise HTTPException(status_code=409, detail="User already exists")
        
        # Create new user
        db_user = User(
            id=user_data.uid,
            uid=user_data.uid,
            email=user_data.email,
            name=user_data.name,
            role=user_data.role,
            department=user_data.department,
            student_id=user_data.student_id,
            staff_id=user_data.staff_id,
            is_active=user_data.is_active,
            profile_completed=user_data.profile_completed
        )
        
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        logger.info(f"User created: {user_data.email}")
        return {
            "status": "success",
            "message": "User created successfully",
            "user": {
                "id": db_user.id,
                "uid": db_user.uid,
                "email": db_user.email,
                "name": db_user.name,
                "role": db_user.role.value
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to create user")

@router.put("/{user_uid}")
async def update_user(
    user_uid: str,
    user_data: UserUpdate,
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """Update an existing user in the backend database"""
    try:
        # Find user
        db_user = db.query(User).filter(User.uid == user_uid).first()
        if not db_user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Update fields
        update_data = user_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_user, field, value)
        
        db_user.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_user)
        
        logger.info(f"User updated: {user_uid}")
        return {
            "status": "success",
            "message": "User updated successfully",
            "user": {
                "id": db_user.id,
                "uid": db_user.uid,
                "email": db_user.email,
                "name": db_user.name,
                "role": db_user.role.value
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating user {user_uid}: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to update user")

@router.delete("/{user_uid}")
async def delete_user(
    user_uid: str,
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """Soft delete a user (mark as inactive)"""
    try:
        # Find user
        db_user = db.query(User).filter(User.uid == user_uid).first()
        if not db_user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Soft delete
        db_user.is_active = False
        db_user.updated_at = datetime.utcnow()
        db.commit()
        
        logger.info(f"User deleted: {user_uid}")
        return {
            "status": "success",
            "message": "User deleted successfully",
            "uid": user_uid
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting user {user_uid}: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to delete user")

@router.post("/sync")
async def sync_user_operation(
    sync_request: UserSyncRequest,
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """Sync user operations from Firebase to backend"""
    try:
        action = sync_request.action
        user_data = sync_request.user_data
        
        logger.info(f"Syncing user operation: {action} for {user_data.get('email', 'unknown')}")
        
        if action == "create":
            # Create user in backend
            user_create = UserCreate(**user_data)
            result = await create_user(user_create, current_user, db)
            return {"status": "success", "action": "create", "result": result}
            
        elif action == "update":
            # Update user in backend
            uid = user_data.get("uid")
            if not uid:
                raise HTTPException(status_code=400, detail="UID required for update")
            
            user_update = UserUpdate(**{k: v for k, v in user_data.items() if k != "uid"})
            result = await update_user(uid, user_update, current_user, db)
            return {"status": "success", "action": "update", "result": result}
            
        elif action == "delete":
            # Delete user in backend
            uid = user_data.get("uid")
            if not uid:
                raise HTTPException(status_code=400, detail="UID required for delete")
            
            result = await delete_user(uid, current_user, db)
            return {"status": "success", "action": "delete", "result": result}
            
        else:
            raise HTTPException(status_code=400, detail=f"Unknown action: {action}")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Sync operation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Sync operation failed: {str(e)}")