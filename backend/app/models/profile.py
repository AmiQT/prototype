"""
Profile model - matches Supabase profiles table schema exactly
"""
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, JSON, Boolean, ARRAY
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Profile(Base):
    __tablename__ = "profiles"
    
    # Primary fields (match database exactly)
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    
    # Personal information (match database column names exactly)
    full_name = Column(String, nullable=True)  # snake_case
    bio = Column(Text, nullable=True)
    phone_number = Column(String, nullable=True)  # snake_case
    address = Column(Text, nullable=True)
    headline = Column(String, nullable=True)
    profile_image_url = Column(Text, nullable=True)  # snake_case
    
    # Academic & experience info (stored as JSONB)
    academic_info = Column(JSON, nullable=True)  # Contains student info, department, etc
    skills = Column(ARRAY(String), nullable=True)  # Array of skills
    interests = Column(ARRAY(String), nullable=True)  # Array of interests
    experiences = Column(JSON, nullable=True)  # JSONB
    projects = Column(JSON, nullable=True)  # JSONB
    
    # Profile completion status
    is_profile_complete = Column(Boolean, nullable=True, default=False)
    
    # Timestamps (snake_case)
    created_at = Column(DateTime(timezone=True), nullable=True, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=True, onupdate=func.now())
    
    # Relationships
    user = relationship("User", backref="profile")
    
    def __repr__(self):
        return f"<Profile(id={self.id}, user_id={self.user_id}, name={self.full_name})>"