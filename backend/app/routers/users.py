"""
User management API endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from pydantic import BaseModel, EmailStr
from datetime import datetime
# Supabase auth integration
from app.auth import verify_supabase_token, verify_admin_user
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
    current_user: dict = Depends(verify_supabase_token),
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
    current_user: dict = Depends(verify_supabase_token),
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

@router.put("/{user_id}")
async def update_user(
    user_id: str,
    user_data: UserUpdate,
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """Update an existing user in Supabase database"""
    try:
        from supabase import create_client
        import os
        from uuid import UUID
        
        # Initialize Supabase client
        supabase_url = os.getenv("SUPABASE_URL")
        supabase_service_key = os.getenv("SUPABASE_SERVICE_KEY")
        
        if not supabase_url or not supabase_service_key:
            raise HTTPException(status_code=500, detail="Supabase configuration missing")
        
        supabase = create_client(supabase_url, supabase_service_key)
        
        # Convert user_id to UUID
        try:
            user_uuid = UUID(user_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid user ID format")
        
        # Prepare update data (only include fields that were set)
        update_data = user_data.dict(exclude_unset=True)
        
        # Convert role enum to string if present
        if 'role' in update_data and update_data['role']:
            update_data['role'] = update_data['role'].value if hasattr(update_data['role'], 'value') else update_data['role']
        
        # Update in Supabase database
        result = supabase.table('users').update(update_data).eq('id', user_id).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")
        
        logger.info(f"✅ User updated: {user_id}")
        
        return {
            "status": "success",
            "message": "User updated successfully",
            "user": result.data[0] if result.data else None
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error updating user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to update user: {str(e)}")

@router.delete("/{user_id}")
async def delete_user(
    user_id: str,
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """Delete a user from both Supabase Auth and database"""
    try:
        from supabase import create_client
        import os
        from uuid import UUID
        
        # Initialize Supabase client with service role key
        supabase_url = os.getenv("SUPABASE_URL")
        supabase_service_key = os.getenv("SUPABASE_SERVICE_KEY")
        
        if not supabase_url or not supabase_service_key:
            raise HTTPException(status_code=500, detail="Supabase configuration missing")
        
        supabase = create_client(supabase_url, supabase_service_key)
        
        # Convert user_id to UUID for database query
        try:
            user_uuid = UUID(user_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid user ID format")
        
        # Delete from Supabase Auth first
        try:
            supabase.auth.admin.delete_user(user_id)
            logger.info(f"✅ Deleted user from Supabase Auth: {user_id}")
        except Exception as auth_error:
            logger.warning(f"⚠️ Failed to delete from Supabase Auth (user may not exist): {auth_error}")
        
        # Delete from database
        result = supabase.table('users').delete().eq('id', user_id).execute()
        logger.info(f"✅ Deleted user from database: {user_id}")
        
        return {
            "status": "success",
            "message": "User deleted successfully",
            "id": user_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error deleting user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to delete user: {str(e)}")

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

# Admin endpoint to create user with auth
class AdminUserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str
    role: UserRole
    department: Optional[str] = None
    student_id: Optional[str] = None
    is_active: bool = True


@router.post("/admin/create")
async def admin_create_user(
    user_data: AdminUserCreate,
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """
    Admin endpoint to create a new user with Supabase authentication
    This endpoint has service role privileges
    """
    try:
        from supabase import create_client
        import os
        
        # Initialize Supabase client with service role key
        supabase_url = os.getenv("SUPABASE_URL")
        supabase_service_key = os.getenv("SUPABASE_SERVICE_KEY")
        
        if not supabase_url or not supabase_service_key:
            raise HTTPException(
                status_code=500,
                detail="Supabase configuration missing. Please set SUPABASE_URL and SUPABASE_SERVICE_KEY"
            )
        
        supabase = create_client(supabase_url, supabase_service_key)
        
        # Check if user already exists in database
        existing_user = db.query(User).filter(User.email == user_data.email).first()
        if existing_user:
            raise HTTPException(
                status_code=400,
                detail=f"User with email {user_data.email} already exists in database"
            )
        
        # Create auth user in Supabase
        try:
            auth_response = supabase.auth.admin.create_user({
                "email": user_data.email,
                "password": user_data.password,
                "email_confirm": True
            })
        except Exception as auth_error:
            # Log the full error for debugging
            logger.error(f"Supabase auth error: {type(auth_error).__name__}: {str(auth_error)}")
            
            # Check if it's a duplicate user error
            error_str = str(auth_error).lower()
            if 'already been registered' in error_str or 'already exists' in error_str or '422' in error_str:
                raise HTTPException(
                    status_code=400,
                    detail=f"User with email {user_data.email} already exists. Please use a different email or delete the existing user from Supabase Auth."
                )
            # Re-raise other auth errors as 400 Bad Request with details
            raise HTTPException(
                status_code=400,
                detail=f"Failed to create user in Supabase Auth: {str(auth_error)}"
            )
        
        if not auth_response.user:
            raise HTTPException(status_code=400, detail="Failed to create auth user")
        
        user_id = auth_response.user.id
        
        # Insert user data into Supabase users table
        # Note: Backend DB and Supabase DB are the SAME database (via DATABASE_URL)
        # So we only need to insert ONCE via Supabase client
        user_insert = supabase.table('users').insert({
            "id": user_id,
            "email": user_data.email,
            "name": user_data.name,
            "role": user_data.role.value,
            "department": user_data.department,
            "student_id": user_data.student_id,
            "is_active": user_data.is_active,
            "profile_completed": False
        }).execute()
        
        if not user_insert.data:
            raise HTTPException(status_code=500, detail="Failed to insert user data into database")
        
        logger.info(f"✅ User data inserted into database for: {user_data.email}")
        
        logger.info(f"✅ Admin created user: {user_data.email} with ID: {user_id}")
        
        return {
            "status": "success",
            "message": "User created successfully",
            "user": {
                "id": user_id,
                "email": user_data.email,
                "name": user_data.name,
                "role": user_data.role.value,
                "is_active": user_data.is_active
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error creating user: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create user: {str(e)}")


# Reset password request model
class ResetPasswordRequest(BaseModel):
    new_password: str


@router.post("/{user_id}/reset-password")
async def reset_user_password(
    user_id: str,
    password_data: ResetPasswordRequest,
    current_user: dict = Depends(verify_admin_user),
    db: Session = Depends(get_db)
):
    """
    Admin endpoint to reset a user's password
    """
    try:
        from supabase import create_client
        import os
        
        # Validate password length
        if len(password_data.new_password) < 6:
            raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
        
        # Initialize Supabase client with service role key
        supabase_url = os.getenv("SUPABASE_URL")
        supabase_service_key = os.getenv("SUPABASE_SERVICE_KEY")
        
        if not supabase_url or not supabase_service_key:
            raise HTTPException(status_code=500, detail="Supabase configuration missing")
        
        supabase = create_client(supabase_url, supabase_service_key)
        
        # Update user password via Supabase Admin API
        supabase.auth.admin.update_user_by_id(
            user_id,
            {"password": password_data.new_password}
        )
        
        logger.info(f"✅ Password reset for user: {user_id}")
        
        return {
            "status": "success",
            "message": "Password reset successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error resetting password for {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to reset password: {str(e)}")
