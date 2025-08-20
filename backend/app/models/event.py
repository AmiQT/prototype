"""
Event model - matches Firebase events collection
"""
from sqlalchemy import Column, String, Text, DateTime, Boolean, Integer, JSON, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Event(Base):
    __tablename__ = "events"
    
    # Primary fields
    id = Column(String, primary_key=True)
    created_by = Column(String, ForeignKey("users.id"), nullable=False)
    
    # Event details
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String, nullable=True)  # "workshop", "seminar", "competition", etc.
    
    # Event scheduling
    start_date = Column(DateTime(timezone=True), nullable=False)
    end_date = Column(DateTime(timezone=True), nullable=True)
    location = Column(String, nullable=True)
    venue = Column(String, nullable=True)
    
    # Event metadata
    max_participants = Column(Integer, nullable=True)
    current_participants = Column(Integer, default=0)
    registration_deadline = Column(DateTime(timezone=True), nullable=True)
    
    # Requirements and details
    requirements = Column(JSON, nullable=True)  # Array of requirements
    skills_gained = Column(JSON, nullable=True)  # Array of skills participants will gain
    target_audience = Column(JSON, nullable=True)  # Array of target audience
    
    # Media
    image_url = Column(String, nullable=True)
    banner_url = Column(String, nullable=True)
    
    # Status
    is_active = Column(Boolean, default=True)
    is_featured = Column(Boolean, default=False)
    registration_open = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    creator = relationship("User", backref="created_events")
    
    def __repr__(self):
        return f"<Event(id={self.id}, title={self.title}, date={self.start_date})>"

class EventParticipation(Base):
    """
    Junction table for event participation
    """
    __tablename__ = "event_participations"
    
    id = Column(String, primary_key=True)
    event_id = Column(String, ForeignKey("events.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    
    # Participation details
    registration_date = Column(DateTime(timezone=True), server_default=func.now())
    attendance_status = Column(String, default="registered")  # "registered", "attended", "no_show"
    feedback_rating = Column(Integer, nullable=True)  # 1-5 rating
    feedback_comment = Column(Text, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    event = relationship("Event", backref="participations")
    user = relationship("User", backref="event_participations")
    
    def __repr__(self):
        return f"<EventParticipation(event_id={self.event_id}, user_id={self.user_id})>"