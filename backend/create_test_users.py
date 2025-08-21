#!/usr/bin/env python3
"""
Create Testing User Accounts Script
Creates test users for development and testing purposes
"""
import sys
import os
import uuid
from datetime import datetime, timedelta

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine, SessionLocal, Base
from app.models.user import User, UserRole
from app.models.profile import Profile

def create_test_users():
    """Create test users for development"""
    try:
        print("🔧 Creating test users for development...")
        
        # Ensure tables exist
        Base.metadata.create_all(engine)
        
        db = SessionLocal()
        
        # Test Admin User
        admin_user = User(
            id="test_admin_001",
            uid="test_admin_001",
            email="admin@test.com",
            name="Test Admin",
            role=UserRole.admin,
            department="FSKTM",
            staff_id="TEST_ADM001",
            is_active=True,
            profile_completed=True,
            created_at=datetime.now()
        )
        db.add(admin_user)
        
        # Test Lecturer User
        lecturer_user = User(
            id="test_lecturer_001",
            uid="test_lecturer_001",
            email="lecturer@test.com",
            name="Test Lecturer",
            role=UserRole.lecturer,
            department="FSKTM",
            staff_id="TEST_LEC001",
            is_active=True,
            profile_completed=True,
            created_at=datetime.now()
        )
        db.add(lecturer_user)
        
        # Test Student Users
        student_users = [
            {
                "id": "test_student_001",
                "uid": "test_student_001",
                "email": "student1@test.com",
                "name": "Test Student 1",
                "student_id": "TEST_STU001"
            },
            {
                "id": "test_student_002",
                "uid": "test_student_002",
                "email": "student2@test.com",
                "name": "Test Student 2",
                "student_id": "TEST_STU002"
            },
            {
                "id": "test_student_003",
                "uid": "test_student_003",
                "email": "student3@test.com",
                "name": "Test Student 3",
                "student_id": "TEST_STU003"
            }
        ]
        
        for student_data in student_users:
            student = User(
                id=student_data["id"],
                uid=student_data["uid"],
                email=student_data["email"],
                name=student_data["name"],
                role=UserRole.student,
                department="FSKTM",
                student_id=student_data["student_id"],
                is_active=True,
                profile_completed=False,
                created_at=datetime.now()
            )
            db.add(student)
        
        # Commit users
        db.commit()
        print("✅ Test users created successfully!")
        
        # Create basic profiles for students
        print("📝 Creating basic profiles for students...")
        for student_data in student_users:
            profile = Profile(
                id=str(uuid.uuid4()),
                userId=student_data["id"],
                fullName=student_data["name"],
                bio=f"Test student profile for {student_data['name']}",
                phone="0123456789",
                profileImageUrl="https://via.placeholder.com/150/4A90E2/FFFFFF?text=Test",
                studentId=student_data["student_id"],
                department="Computer Science",
                faculty="FSKTM",
                yearOfStudy="Year 2",
                cgpa="3.50",
                skills=["Python", "JavaScript", "Basic Programming"],
                interests=["Web Development", "Mobile Apps", "Learning"],
                languages=[{"name": "English", "level": "Intermediate"}],
                experiences=[],
                projects=[]
            )
            db.add(profile)
        
        # Commit profiles
        db.commit()
        print("✅ Student profiles created successfully!")
        
        # Print test account information
        print("\n" + "="*50)
        print("🧪 TEST ACCOUNT INFORMATION")
        print("="*50)
        print("Admin Account:")
        print("  Email: admin@test.com")
        print("  Role: Admin")
        print("  UID: test_admin_001")
        print()
        print("Lecturer Account:")
        print("  Email: lecturer@test.com")
        print("  Role: Lecturer")
        print("  UID: test_lecturer_001")
        print()
        print("Student Accounts:")
        for i, student in enumerate(student_users, 1):
            print(f"  Student {i}:")
            print(f"    Email: {student['email']}")
            print(f"    Role: Student")
            print(f"    UID: {student['uid']}")
            print()
        print("="*50)
        print("💡 Use these accounts for testing your application!")
        print("   Note: These are test accounts - don't use in production!")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to create test users: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        if 'db' in locals():
            db.close()

if __name__ == "__main__":
    success = create_test_users()
    sys.exit(0 if success else 1)
