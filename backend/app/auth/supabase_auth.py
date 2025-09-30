"""
Supabase Authentication Middleware
"""
import os
import jwt
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)

# Supabase JWT settings - MUST be set via environment variables
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET")
SUPABASE_URL = os.getenv("SUPABASE_URL")

if not SUPABASE_JWT_SECRET:
    logger.warning("⚠️ SUPABASE_JWT_SECRET not set! Authentication will fail.")
if not SUPABASE_URL:
    logger.warning("⚠️ SUPABASE_URL not set! Please configure environment variables.")

security = HTTPBearer()

async def verify_supabase_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """
    Verify Supabase JWT token and return user info
    """
    try:
        token = credentials.credentials
        
        # Verify JWT signature using Supabase JWT secret
        try:
            # Decode with proper signature verification
            payload = jwt.decode(
                token,
                SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                audience=None,
                options={"verify_aud": False},
            )
            
            # Extract user info from token
            user_info = {
                "uid": payload.get("sub"),
                "email": payload.get("email"),
                "name": payload.get("user_metadata", {}).get("name", payload.get("email", "").split("@")[0]),
                "role": payload.get("user_metadata", {}).get("role", "student"),
                "email_verified": payload.get("email_confirmed_at") is not None
            }
            
            logger.info(f"Supabase token verified for user: {user_info['email']}")
            return user_info
            
        except jwt.InvalidTokenError as e:
            logger.error(f"Invalid JWT token: {e}")
            raise HTTPException(status_code=401, detail="Invalid authentication token")
            
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        raise HTTPException(status_code=401, detail="Authentication failed")

async def verify_admin_user(current_user: Dict[str, Any] = Depends(verify_supabase_token)) -> Dict[str, Any]:
    """
    Verify that the current user is an admin
    """
    user_role = current_user.get("role", "student").lower()
    
    # Check if user is admin
    if user_role not in ["admin", "administrator"]:
        logger.warning(f"Non-admin user {current_user.get('email')} attempted admin access")
        raise HTTPException(status_code=403, detail="Admin access required")
    
    logger.info(f"Admin access granted to: {current_user.get('email')}")
    return current_user

# Backward compatibility aliases
verify_firebase_token = verify_supabase_token