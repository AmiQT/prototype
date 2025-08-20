# FREE Media Storage Setup Guide
## Complete Configuration for 100% Free Media Handling

**Total Cost:** $0/month  
**Storage Capacity:** 25GB bandwidth + 5GB backup  
**Features:** Auto-optimization, CDN, transformations, video processing

---

## 🎯 Storage Strategy Overview

```
Primary: Cloudinary (25GB/month FREE)
├── Auto image optimization (WebP, AVIF)
├── Real-time transformations
├── Global CDN delivery
├── AI-powered cropping
└── Video processing (1GB storage)

Backup: Firebase Storage (5GB FREE)
├── Critical file backup
├── System files storage
└── Disaster recovery

Cache: PostgreSQL + Redis
├── Metadata storage
├── URL caching
└── Usage tracking
```

---

## 🚀 Step 1: Cloudinary Setup (PRIMARY)

### Sign Up (FREE Account)
1. Go to [cloudinary.com/users/register/free](https://cloudinary.com/users/register/free)
2. Create account (no credit card required)
3. Get credentials from Dashboard:
   - Cloud Name: `your-cloud-name`
   - API Key: `123456789012345`
   - API Secret: `your-api-secret`

### Free Tier Limits
```yaml
Monthly Bandwidth: 25GB
Transformations: 25,000/month
Storage: 25GB
Video Storage: 1GB
CDN: Global delivery
Auto-optimization: Included
AI Features: Basic cropping
```

### FastAPI Integration
```python
# requirements.txt
cloudinary==1.36.0
python-multipart==0.0.6

# app/config.py
import cloudinary
import os

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)

# app/services/media_service.py
import cloudinary.uploader
from fastapi import UploadFile
import uuid

class CloudinaryService:
    @staticmethod
    async def upload_image(file: UploadFile, user_id: str) -> dict:
        """Upload and optimize image"""
        file_id = str(uuid.uuid4())
        
        result = cloudinary.uploader.upload(
            file.file,
            public_id=f"showcase/{user_id}/{file_id}",
            transformation=[
                {"quality": "auto", "fetch_format": "auto"},
                {"width": 1920, "height": 1080, "crop": "limit"}
            ],
            eager=[
                {"width": 400, "height": 300, "crop": "fill"},  # Thumbnail
                {"width": 800, "height": 600, "crop": "fill"},  # Medium
            ]
        )
        
        return {
            "id": file_id,
            "url": result["secure_url"],
            "thumbnail": result["eager"][0]["secure_url"],
            "medium": result["eager"][1]["secure_url"],
            "public_id": result["public_id"],
            "format": result["format"],
            "bytes": result["bytes"],
            "width": result["width"],
            "height": result["height"]
        }
    
    @staticmethod
    async def upload_video(file: UploadFile, user_id: str) -> dict:
        """Upload and process video"""
        file_id = str(uuid.uuid4())
        
        result = cloudinary.uploader.upload(
            file.file,
            public_id=f"videos/{user_id}/{file_id}",
            resource_type="video",
            transformation=[
                {"quality": "auto", "format": "mp4"},
                {"width": 1280, "height": 720, "crop": "limit"}
            ],
            eager=[
                {"width": 640, "height": 360, "format": "mp4"},  # Compressed
                {"resource_type": "image", "format": "jpg"}      # Thumbnail
            ]
        )
        
        return {
            "id": file_id,
            "url": result["secure_url"],
            "thumbnail": result["eager"][1]["secure_url"],
            "compressed": result["eager"][0]["secure_url"],
            "public_id": result["public_id"],
            "duration": result.get("duration", 0),
            "format": result["format"],
            "bytes": result["bytes"]
        }
```

---

## 🔧 Step 2: FastAPI Endpoints

```python
# app/routers/media.py
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from app.services.media_service import CloudinaryService
from app.auth import verify_firebase_token

router = APIRouter()

@router.post("/upload/image")
async def upload_image(
    file: UploadFile = File(...),
    current_user: dict = Depends(verify_firebase_token)
):
    # Validate file
    if not file.content_type.startswith("image/"):
        raise HTTPException(400, "File must be an image")
    
    if file.size > 10 * 1024 * 1024:  # 10MB limit
        raise HTTPException(400, "File too large (max 10MB)")
    
    try:
        result = await CloudinaryService.upload_image(file, current_user["uid"])
        
        # Save to database
        await save_media_record(result, current_user["uid"], "image")
        
        return {"success": True, "media": result}
    
    except Exception as e:
        raise HTTPException(500, f"Upload failed: {str(e)}")

@router.post("/upload/video")
async def upload_video(
    file: UploadFile = File(...),
    current_user: dict = Depends(verify_firebase_token)
):
    # Validate file
    if not file.content_type.startswith("video/"):
        raise HTTPException(400, "File must be a video")
    
    if file.size > 100 * 1024 * 1024:  # 100MB limit
        raise HTTPException(400, "File too large (max 100MB)")
    
    try:
        result = await CloudinaryService.upload_video(file, current_user["uid"])
        
        # Save to database
        await save_media_record(result, current_user["uid"], "video")
        
        return {"success": True, "media": result}
    
    except Exception as e:
        raise HTTPException(500, f"Upload failed: {str(e)}")

async def save_media_record(media_data: dict, user_id: str, media_type: str):
    """Save media metadata to PostgreSQL"""
    query = """
        INSERT INTO media_files (
            id, user_id, cloudinary_public_id, cloudinary_url, 
            thumbnail_url, file_type, file_format, file_size_bytes,
            width, height, duration_seconds
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
    """
    
    await database.execute(query, 
        media_data["id"], user_id, media_data["public_id"],
        media_data["url"], media_data.get("thumbnail"),
        media_type, media_data["format"], media_data["bytes"],
        media_data.get("width"), media_data.get("height"),
        media_data.get("duration", 0)
    )
```

---

## 📱 Step 3: Flutter Integration

```dart
// lib/services/media_upload_service.dart
class MediaUploadService {
  static const String baseUrl = 'https://your-backend.railway.app';
  
  Future<MediaUploadResult> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/media/upload/image'),
      );
      
      // Add auth headers
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path)
      );
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        
        return MediaUploadResult.fromJson(data['media']);
      }
      
      throw Exception('Upload failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }
  
  Future<MediaUploadResult> uploadVideo(File videoFile) async {
    // Similar implementation for video upload
    // ... (same pattern as uploadImage)
  }
}

// lib/models/media_upload_result.dart
class MediaUploadResult {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String? mediumUrl;
  final String format;
  final int bytes;
  final int? width;
  final int? height;
  final int? duration;
  
  MediaUploadResult({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.mediumUrl,
    required this.format,
    required this.bytes,
    this.width,
    this.height,
    this.duration,
  });
  
  factory MediaUploadResult.fromJson(Map<String, dynamic> json) {
    return MediaUploadResult(
      id: json['id'],
      url: json['url'],
      thumbnailUrl: json['thumbnail'],
      mediumUrl: json['medium'],
      format: json['format'],
      bytes: json['bytes'],
      width: json['width'],
      height: json['height'],
      duration: json['duration'],
    );
  }
}
```

---

## 🔄 Step 4: Usage in Post Creation

```dart
// Update your existing post creation to use new service
class PostCreationScreen extends StatefulWidget {
  // ... existing code
  
  Future<void> _uploadMedia() async {
    setState(() => _isUploading = true);
    
    try {
      final List<MediaUploadResult> uploadedMedia = [];
      
      for (final file in _selectedMedia) {
        MediaUploadResult result;
        
        if (_isImage(file)) {
          result = await MediaUploadService().uploadImage(file);
        } else {
          result = await MediaUploadService().uploadVideo(file);
        }
        
        uploadedMedia.add(result);
      }
      
      // Create post with media URLs
      await _createPostWithMedia(uploadedMedia);
      
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }
  
  bool _isImage(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }
}
```

---

## 📊 Step 5: Usage Monitoring

```python
# app/services/usage_monitor.py
class UsageMonitor:
    @staticmethod
    async def get_current_usage() -> dict:
        """Monitor Cloudinary usage to stay within free tier"""
        result = await database.fetch_one("""
            SELECT 
                COUNT(*) as total_uploads,
                SUM(file_size_bytes) as total_bytes,
                COUNT(CASE WHEN file_type = 'image' THEN 1 END) as images,
                COUNT(CASE WHEN file_type = 'video' THEN 1 END) as videos
            FROM media_files 
            WHERE created_at >= date_trunc('month', CURRENT_DATE)
        """)
        
        bandwidth_gb = result["total_bytes"] / (1024**3)
        usage_percent = (bandwidth_gb / 25) * 100  # 25GB free limit
        
        return {
            "uploads_this_month": result["total_uploads"],
            "bandwidth_used_gb": round(bandwidth_gb, 2),
            "bandwidth_limit_gb": 25,
            "usage_percentage": round(usage_percent, 1),
            "images": result["images"],
            "videos": result["videos"],
            "warning": usage_percent > 80,
            "critical": usage_percent > 95
        }

# Add endpoint to check usage
@router.get("/usage")
async def get_usage_stats(current_user: dict = Depends(verify_firebase_token)):
    if current_user.get("role") != "admin":
        raise HTTPException(403, "Admin access required")
    
    usage = await UsageMonitor.get_current_usage()
    return usage
```

---

## ✅ Verification Checklist

- [ ] Cloudinary account created (FREE)
- [ ] API credentials configured
- [ ] FastAPI endpoints deployed
- [ ] PostgreSQL media tables created
- [ ] Flutter upload service integrated
- [ ] Usage monitoring active
- [ ] Firebase Storage backup configured

**Result:** Complete media storage system with 25GB monthly bandwidth, auto-optimization, and global CDN delivery - completely FREE!
