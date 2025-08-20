# Fix for showcase API - replace the create_showcase_post function
# Copy this entire function and replace the one in backend/app/routers/showcase.py

@router.post("/")
async def create_showcase_post(
    post_data: CreateShowcasePostRequest,
    current_user: dict = Depends(verify_firebase_token),
    db: Session = Depends(get_db)
):
    """Create a new showcase post"""
    try:
        user_id = current_user["uid"]
        user_email = current_user.get("email", "")
        user_name = current_user.get("name", "")
        
        # Generate unique ID for the post
        import uuid
        import json
        post_id = str(uuid.uuid4())
        
        # Get user information from Firebase token instead of database to avoid transaction issues
        user_role = "student"  # Default role
        user_department = None
        user_profile_image = None
        user_headline = None
        
        # Try to get user data from database, but don't fail if it doesn't work
        try:
            from app.models.user import User
            user = db.query(User).filter(User.id == user_id).first()
            if user:
                user_name = user.name or user_name
                user_role = str(user.role.value) if user.role else "student"
                user_department = getattr(user, 'department', None)
                user_profile_image = None  # Add if available in user model
                user_headline = None  # Add if available in user model
        except Exception as e:
            logger.warning(f"Could not fetch user data, using defaults: {e}")
            # Rollback any failed transaction
            db.rollback()
        
        # Prepare media data for storage
        media_data = []
        if post_data.media_urls:
            for i, url in enumerate(post_data.media_urls):
                media_type = post_data.media_types[i] if i < len(post_data.media_types) else 'image'
                media_data.append({
                    'id': f'media_{i}',
                    'url': url,
                    'type': media_type,
                    'thumbnailUrl': None,
                    'duration': None,
                    'aspectRatio': None,
                    'fileSize': None,
                    'uploadedAt': datetime.utcnow().isoformat()
                })
        
        # Create new showcase post with updated field names
        new_post = ShowcasePost(
            id=post_id,
            user_id=user_id,  # Updated field name
            title=post_data.title or "",
            description=post_data.description or "",
            content=post_data.content,
            category=post_data.category,
            privacy='public' if post_data.is_public else 'private',
            media_urls=post_data.media_urls,
            media_types=post_data.media_types,
            media=media_data if media_data else None,
            tags=post_data.tags,
            skills_used=post_data.skills_used,
            mentions=[],  # Empty for now
            user_name=user_name,
            user_profile_image=user_profile_image,
            user_role=user_role,
            user_department=user_department,
            user_headline=user_headline,
            is_public=post_data.is_public,
            allow_comments=post_data.allow_comments,
            # Other fields will use defaults
        )
        
        # Start a fresh transaction
        db.rollback()  # Clear any previous failed transaction
        db.add(new_post)
        db.commit()
        db.refresh(new_post)
        
        logger.info(f"Showcase post created successfully: {new_post.id} for user {user_id}")
        
        return {
            "success": True,
            "message": "Showcase post created successfully",
            "post_id": new_post.id
        }
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating showcase post: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create post: {str(e)}")