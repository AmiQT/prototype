"""
Profile model - matches Firebase profiles collection
"""
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Profile(Base):
    __tablename__ = "profiles"
    
    # Primary fields
    id = Column(String, primary_key=True)
    userId = Column(String, ForeignKey("users.id"), nullable=False)
    
    # Personal information
    fullName = Column(String, nullable=False)
    bio = Column(Text, nullable=True)
    phone = Column(String, nullable=True)
    profileImageUrl = Column(String, nullable=True)
    
    # Academic information
    studentId = Column(String, nullable=True)
    department = Column(String, nullable=True)
    faculty = Column(String, nullable=True)
    yearOfStudy = Column(String, nullable=True)
    cgpa = Column(String, nullable=True)
    
    # Skills and interests (stored as JSON arrays)
    skills = Column(JSON, nullable=True)  # ["Python", "JavaScript", "React"]
    interests = Column(JSON, nullable=True)  # ["Web Development", "AI", "Mobile Apps"]
    languages = Column(JSON, nullable=True)  # [{"name": "English", "level": "Native"}]
    
    # Experience and projects (stored as JSON)
    experiences = Column(JSON, nullable=True)
    projects = Column(JSON, nullable=True)
    
    # Social links
    linkedinUrl = Column(String, nullable=True)
    githubUrl = Column(String, nullable=True)
    portfolioUrl = Column(String, nullable=True)
    
    # Timestamps
    createdAt = Column(DateTime(timezone=True), server_default=func.now())
    updatedAt = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", backref="profile")
    
    def __repr__(self):
        return f"<Profile(id={self.id}, user_id={self.user_id}, name={self.full_name})>"