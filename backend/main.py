from fastapi import FastAPI, HTTPException, Depends, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from sqlalchemy.orm import Session
import os
from dotenv import load_dotenv
import cloudinary
import logging
import threading
import requests
import time


# Load environment variables FIRST before any imports that need them
load_dotenv()

# Import database dependency AFTER loading env vars
from app.database import get_db

# Configure logging first with detailed format
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),  # Console output
    ]
)
logger = logging.getLogger(__name__)



# Initialize FastAPI app
app = FastAPI(
    title="Student Talent Analytics API",
    description="Hybrid backend for student talent profiling system",
    version="1.0.0"
)

# Add middleware to handle OPTIONS requests before authentication
class OptionsMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.method == "OPTIONS":
            return Response(
                status_code=200,
                headers={
                    "Access-Control-Allow-Origin": request.headers.get("origin", "*"),
                    "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
                    "Access-Control-Allow-Headers": "*",
                    "Access-Control-Allow-Credentials": "true",
                    "Access-Control-Max-Age": "3600",
                }
            )
        return await call_next(request)

app.add_middleware(OptionsMiddleware)

# CORS middleware - Cloud-friendly configuration
raw_origins = os.getenv("ALLOWED_ORIGINS", "").split(",")
allowed_origins = [origin.strip() for origin in raw_origins if origin.strip()]

# Always ensure essential local development ports are included
essential_origins = [
    "http://127.0.0.1:3000",
    "http://localhost:3000",
    "http://127.0.0.1:8080",
    "http://localhost:8080",
    "https://127.0.0.1:8080",
    "https://localhost:8080",
    "http://localhost:4321",
    "http://127.0.0.1:4321",
]

# Add wildcard for development (matches http://127.0.0.1:* and http://localhost:*)
# Using regex_patterns for FastAPI CORS middleware
allow_origin_regex_patterns = [
    r"^http:\/\/(127\.0\.0\.1|localhost)(:[0-9]{1,5})?$",  # Allow localhost:any-port
]

# Add Vercel production URLs
vercel_origins = [
    "https://student-talent-profiling-2cw1eyzuc-noor-azamis-projects.vercel.app",
    "https://student-talent-profiling-app.vercel.app",  # Web dashboard
    "https://talent-app-black.vercel.app",  # PWA mobile app
]

# Merge with environment origins and remove duplicates
if not allowed_origins or allowed_origins == ["*"]:
    allowed_origins = essential_origins + vercel_origins
else:
    allowed_origins = list(set(allowed_origins + essential_origins + vercel_origins))

logger.info(f"🌐 CORS enabled for origins: {allowed_origins}")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_origin_regex=allow_origin_regex_patterns[0] if allow_origin_regex_patterns else None,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=3600,  # Cache preflight for 1 hour
)

# Initialize Cloudinary
try:
    cloud_name = os.getenv("CLOUDINARY_CLOUD_NAME")
    api_key = os.getenv("CLOUDINARY_API_KEY")
    api_secret = os.getenv("CLOUDINARY_API_SECRET")
    
    if cloud_name and api_key and api_secret:
        cloudinary.config(
            cloud_name=cloud_name,
            api_key=api_key,
            api_secret=api_secret,
            secure=True
        )
        logger.info("Cloudinary initialized successfully")
    else:
        logger.warning("⚠️ Cloudinary credentials not set. Media upload will be disabled.")
except Exception as e:
    logger.warning(f"Cloudinary initialization failed: {e}")

# Health check endpoint
@app.get("/")
async def root():
    return {
        "message": "Student Talent Analytics API",
        "version": "1.0.0",
        "status": "healthy"
    }

@app.get("/health")
async def health_check(db: Session = Depends(get_db)):
    """Health check endpoint for monitoring"""
    try:
        # Test database connection
        from sqlalchemy import text
        result = db.execute(text("SELECT 1")).scalar()
        db_status = "connected" if result == 1 else "error"
        
        return {
            "status": "healthy" if db_status == "connected" else "degraded",
            "services": {
                "api": "running",
                "database": db_status,
                "cloudinary": "configured" if os.getenv("CLOUDINARY_CLOUD_NAME", "demo") != "demo" else "demo_mode"
            }
        }
    except Exception as e:
        return {
            "status": "error",
            "services": {
                "api": "running",
                "database": f"error: {str(e)[:50]}",
                "cloudinary": "configured" if os.getenv("CLOUDINARY_CLOUD_NAME", "demo") != "demo" else "demo_mode"
            },
            "error": str(e)
        }

# Simple media router for testing
from fastapi import UploadFile, File

@app.post("/api/media/test-upload")
async def test_upload(file: UploadFile = File(...)):
    """Test endpoint for media upload"""
    try:
        # Basic file validation
        if not file.content_type or not file.content_type.startswith("image/"):
            raise HTTPException(400, "File must be an image")

        # For now, just return file info without actually uploading
        return {
            "success": True,
            "message": "File received successfully",
            "file_info": {
                "filename": file.filename,
                "content_type": file.content_type,
                "size": file.size if hasattr(file, 'size') else "unknown"
            },
            "note": "This is a test endpoint. Configure Cloudinary credentials to enable actual uploads."
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Upload test failed: {str(e)}")

# Include API routers
from app.routers import (
    ai_assistant,
    ai_langchain,
    auth,
    events,
    media,
    ml_analytics,
    payment,
    profiles_supabase,
    search,
    showcase,
    student_analytics,
    student_balance,
    talents,
    users,
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(profiles_supabase.router)  # Profile management with Supabase structure
app.include_router(events.router)  # Events management

app.include_router(search.router)  # Advanced search capabilities
app.include_router(student_analytics.router)  # Student-focused analytics
app.include_router(media.router, prefix="/api/media")  # Media upload and management
app.include_router(showcase.router)  # Showcase posts management
app.include_router(ai_assistant.router)  # Legacy AI assistant (Gemini direct)
app.include_router(ai_langchain.router)  # NEW: LangChain Agentic AI v2
app.include_router(ml_analytics.router)  # ML analytics with student risk prediction
app.include_router(student_balance.router)  # Student balance analysis with AI action plans
app.include_router(talents.router)  # Talent system - soft skills, hobbies, quiz
app.include_router(payment.router)  # ToyyibPay payment proxy

# Additional routers will be added as we build them
# from app.routers import media, analytics, sync
# app.include_router(media.router)
# app.include_router(analytics.router)


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    logger.info(f"🚀 Starting server on http://0.0.0.0:{port}")
    logger.info(f"📱 Android emulator can access via: http://10.0.2.2:{port}")
    logger.info(f"🌐 Browser can access via: http://localhost:{port}")
    uvicorn.run(app, host="0.0.0.0", port=port)
