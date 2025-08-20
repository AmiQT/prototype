from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv
import cloudinary
import logging
import firebase_admin
from firebase_admin import credentials

# Load environment variables
load_dotenv()

# Configure logging first
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK
try:
    if not firebase_admin._apps:
        cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "./firebase-credentials.json")
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info("✅ Firebase Admin SDK initialized with service account")
        else:
            logger.warning(f"⚠️ Firebase credentials file not found at: {cred_path}")
            logger.info("🔧 Trying default Firebase initialization...")
            # Try default initialization (works in some environments)
            firebase_admin.initialize_app()
            logger.info("✅ Firebase Admin SDK initialized with default credentials")
except Exception as e:
    logger.error(f"❌ Failed to initialize Firebase: {e}")
    logger.info("💡 To fix: Download firebase-credentials.json from Firebase Console")

# Initialize FastAPI app
app = FastAPI(
    title="Student Talent Analytics API",
    description="Hybrid backend for student talent profiling system",
    version="1.0.0"
)

# CORS middleware - Cloud-friendly configuration
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")
if allowed_origins == ["*"]:
    allowed_origins = ["*"]  # Keep wildcard for development

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Cloudinary
try:
    cloudinary.config(
        cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME", "demo"),
        api_key=os.getenv("CLOUDINARY_API_KEY", "demo"),
        api_secret=os.getenv("CLOUDINARY_API_SECRET", "demo"),
        secure=True
    )
    logger.info("Cloudinary initialized successfully")
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
async def health_check():
    """Health check endpoint for monitoring"""
    try:
        return {
            "status": "healthy",
            "services": {
                "api": "running",
                "cloudinary": "configured" if os.getenv("CLOUDINARY_CLOUD_NAME", "demo") != "demo" else "demo_mode"
            }
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unhealthy: {str(e)}")

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
from app.routers import auth, users, sync, search, search_simple, student_analytics, media, profiles_supabase, events, test_endpoints, showcase

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(profiles_supabase.router)  # Profile management with Supabase structure
app.include_router(events.router)  # Events management
app.include_router(test_endpoints.router)  # Test endpoints without auth
app.include_router(sync.router)
app.include_router(search.router)  # Advanced search capabilities
app.include_router(search_simple.router)  # Simplified search for testing
app.include_router(student_analytics.router)  # Student-focused analytics
app.include_router(media.router, prefix="/api/media")  # Media upload and management
app.include_router(showcase.router)  # Showcase posts management

# Additional routers will be added as we build them
# from app.routers import media, analytics, sync
# app.include_router(media.router)
# app.include_router(analytics.router)
# app.include_router(sync.router)

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    print(f"🚀 Starting server on http://0.0.0.0:{port}")
    print(f"📱 Android emulator can access via: http://10.0.2.2:{port}")
    print(f"🌐 Browser can access via: http://localhost:{port}")
    uvicorn.run(app, host="0.0.0.0", port=port)
