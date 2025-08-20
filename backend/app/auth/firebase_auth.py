from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth
from sqlalchemy.orm import Session
from typing import Optional
import logging

from app.database import get_db
from app.models.user import User, UserRole

logger = logging.getLogger(__name__)
security = HTTPBearer()

async def verify_firebase_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """
    Verify Firebase ID token and return Firebase user information
    """
    try:
        # Verify the ID token
        decoded_token = auth.verify_id_token(credentials.credentials)
        
        # Extract user information
        user_info = {
            "uid": decoded_token["uid"],
            "email": decoded_token.get("email"),
            "name": decoded_token.get("name"),
            "email_verified": decoded_token.get("email_verified", False),
            "firebase_claims": decoded_token
        }
        
        logger.info(f"Firebase token verified for: {user_info['uid']}")
        return user_info
        
    except auth.InvalidIdTokenError:
        logger.warning("Invalid Firebase ID token")
        raise HTTPException(
            status_code=401,
            detail="Invalid authentication token"
        )
    except auth.ExpiredIdTokenError:
        logger.warning("Expired Firebase ID token")
        raise HTTPException(
            status_code=401,
            detail="Authentication token has expired"
        )
    except Exception as e:
        logger.error(f"Token verification failed: {str(e)}")
        raise HTTPException(
            status_code=401,
            detail="Authentication failed"
        )

async def get_current_user(
    firebase_user: dict = Depends(verify_firebase_token),
    db: Session = Depends(get_db)
):
    """
    Get current authenticated user with database information
    Enhanced for Future Architecture: Firebase Auth + Database Roles
    """
    try:
        # Look up user in our database
        db_user = db.query(User).filter(User.uid == firebase_user['uid']).first()
        
        if not db_user:
            # User exists in Firebase but not in our database
            # Auto-create user record for seamless experience
            logger.info(f"Auto-creating user record for: {firebase_user['email']}")
            
            # Set admin role for admin email
            user_role = UserRole.admin if firebase_user['email'] == 'admin@uthm.edu.my' else UserRole.student
            
            db_user = User(
                id=firebase_user['uid'],
                uid=firebase_user['uid'],
                email=firebase_user['email'],
                name=firebase_user.get('name', 'User'),
                role=user_role,
                department="FSKTM" if user_role == UserRole.admin else None,
                is_active=True,
                profile_completed=True if user_role == UserRole.admin else False
            )
            db.add(db_user)
            db.commit()
            db.refresh(db_user)
            logger.info(f"Created user with role: {user_role.value}")
        
        # Combine Firebase and database information
        enhanced_user = {
            'uid': firebase_user['uid'],
            'email': firebase_user['email'],
            'name': db_user.name,
            'role': db_user.role.value,
            'department': db_user.department,
            'student_id': getattr(db_user, 'student_id', None),
            'staff_id': getattr(db_user, 'staff_id', None),
            'is_active': db_user.is_active,
            'profile_completed': db_user.profile_completed,
            'firebase_claims': firebase_user['firebase_claims'],
            'db_user': db_user
        }
        
        logger.info(f"User loaded: {enhanced_user['email']} (Role: {enhanced_user['role']})")
        return enhanced_user
        
    except Exception as e:
        logger.error(f"Error getting user information: {e}")
        logger.error(f"Error type: {type(e).__name__}")
        logger.error(f"Firebase user info: {firebase_user}")
        import traceback
        logger.error(f"Full traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Failed to get user information: {str(e)}")

# Enhanced role-based verification functions for Future Architecture
async def verify_admin_user(current_user: dict = Depends(get_current_user)):
    """
    Verify that the current user has admin privileges (Database-based)
    """
    if current_user.get("role") != "admin":
        logger.warning(f"Non-admin user attempted admin action: {current_user['email']}")
        raise HTTPException(
            status_code=403,
            detail="Admin access required"
        )
    return current_user

async def verify_lecturer_or_admin(current_user: dict = Depends(get_current_user)):
    """
    Verify that the current user is a lecturer or admin (Database-based)
    """
    allowed_roles = ["lecturer", "admin"]
    if current_user.get("role") not in allowed_roles:
        logger.warning(f"Non-lecturer user attempted lecturer action: {current_user['email']}")
        raise HTTPException(
            status_code=403,
            detail="Lecturer or admin access required"
        )
    return current_user

async def verify_student_or_above(current_user: dict = Depends(get_current_user)):
    """
    Verify that the current user is a student or above (Database-based)
    """
    allowed_roles = ["student", "lecturer", "admin"]
    if current_user.get("role") not in allowed_roles:
        logger.warning(f"Unauthorized user attempted student action: {current_user['email']}")
        raise HTTPException(
            status_code=403,
            detail="Student access required"
        )
    return current_user

def get_user_id(current_user: dict = Depends(get_current_user)) -> str:
    """
    Extract user ID from authenticated user
    """
    return current_user["uid"]

# Optional authentication for public endpoints
async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False)),
    db: Session = Depends(get_db)
) -> Optional[dict]:
    """
    Get user information if token is provided, otherwise return None
    Useful for endpoints that work for both authenticated and anonymous users
    """
    if not credentials:
        return None
    
    try:
        # Verify the token
        decoded_token = auth.verify_id_token(credentials.credentials)
        
        # Look up user in database
        db_user = db.query(User).filter(User.uid == decoded_token['uid']).first()
        
        if db_user:
            return {
                'uid': decoded_token['uid'],
                'email': decoded_token.get('email'),
                'name': db_user.name,
                'role': db_user.role.value,
                'department': db_user.department,
                'is_active': db_user.is_active,
                'db_user': db_user
            }
    except Exception as e:
        logger.warning(f"Optional auth failed: {e}")
    
    return None
