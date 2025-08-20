"""
User model - matches Firebase users collection
"""
from sqlalchemy import Column, String, Boolean, DateTime, Enum
from sqlalchemy.sql import func
from app.database import Base
import enum

class UserRole(enum.Enum):
    student = "student"
    lecturer = "lecturer"
    admin = "admin"

class User(Base):
    __tablename__ = "users"
    
    # Primary fields
    id = Column(String, primary_key=True)  # Firebase UID
    uid = Column(String, unique=True, nullable=False)  # Firebase UID (duplicate for compatibility)
    email = Column(String, unique=True, nullable=False)
    name = Column(String, nullable=False)
    role = Column(Enum(UserRole, name='user_role', create_type=True), nullable=False, default=UserRole.student)
    
    # Optional fields
    student_id = Column(String, nullable=True)  # For students
    staff_id = Column(String, nullable=True)    # For lecturers/staff
    department = Column(String, nullable=True)
    
    # Status fields
    is_active = Column(Boolean, default=True)
    profile_completed = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_login_at = Column(DateTime(timezone=True), nullable=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, role={self.role})>"