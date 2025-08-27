"""
Events API endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
# Firebase auth removed - using Supabase auth
from app.database import get_db
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/events", tags=["Events"])

# Sample events data for testing
SAMPLE_EVENTS = [
    {
        "id": "1",
        "title": "Tech Talk: AI in Education",
        "description": "Learn about the latest AI applications in educational technology",
        "date": "2024-02-15T10:00:00Z",
        "location": "UTHM Auditorium",
        "organizer": "Computer Science Department",
        "category": "academic",
        "image_url": "https://via.placeholder.com/300x200",
        "is_featured": True,
        "max_participants": 100,
        "current_participants": 45
    },
    {
        "id": "2", 
        "title": "Career Fair 2024",
        "description": "Meet with top employers and explore career opportunities",
        "date": "2024-02-20T09:00:00Z",
        "location": "UTHM Main Hall",
        "organizer": "Career Services",
        "category": "career",
        "image_url": "https://via.placeholder.com/300x200",
        "is_featured": True,
        "max_participants": 500,
        "current_participants": 234
    },
    {
        "id": "3",
        "title": "Programming Workshop: Flutter Development",
        "description": "Hands-on workshop for mobile app development with Flutter",
        "date": "2024-02-25T14:00:00Z",
        "location": "Computer Lab 1",
        "organizer": "Mobile Development Club",
        "category": "workshop",
        "image_url": "https://via.placeholder.com/300x200",
        "is_featured": False,
        "max_participants": 30,
        "current_participants": 18
    },
    {
        "id": "4",
        "title": "Research Symposium",
        "description": "Present and discuss latest research findings",
        "date": "2024-03-01T08:00:00Z",
        "location": "Research Center",
        "organizer": "Research Office",
        "category": "research",
        "image_url": "https://via.placeholder.com/300x200",
        "is_featured": False,
        "max_participants": 200,
        "current_participants": 89
    },
    {
        "id": "5",
        "title": "Hackathon 2024",
        "description": "48-hour coding competition with amazing prizes",
        "date": "2024-03-10T18:00:00Z",
        "location": "Innovation Hub",
        "organizer": "Tech Society",
        "category": "competition",
        "image_url": "https://via.placeholder.com/300x200",
        "is_featured": True,
        "max_participants": 80,
        "current_participants": 67
    }
]

@router.get("/")
async def get_all_events(
    limit: int = Query(50, le=100),
    category: Optional[str] = Query(None),
    featured: Optional[bool] = Query(None),
    current_user: dict = Depends(verify_supabase_token),
):
    """Get all events"""
    try:
        events = SAMPLE_EVENTS.copy()
        
        # Filter by category
        if category:
            events = [e for e in events if e["category"] == category]
        
        # Filter by featured
        if featured is not None:
            events = [e for e in events if e["is_featured"] == featured]
        
        # Apply limit
        events = events[:limit]
        
        return {
            "events": events,
            "total": len(events),
            "message": "Events retrieved successfully"
        }
        
    except Exception as e:
        logger.error(f"Error getting events: {e}")
        raise HTTPException(status_code=500, detail="Failed to get events")

@router.get("/{event_id}")
async def get_event_by_id(
    event_id: str,
    current_user: dict = Depends(verify_supabase_token),
):
    """Get event by ID"""
    try:
        event = next((e for e in SAMPLE_EVENTS if e["id"] == event_id), None)
        
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")
        
        return event
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting event: {e}")
        raise HTTPException(status_code=500, detail="Failed to get event")