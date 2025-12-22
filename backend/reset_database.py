#!/usr/bin/env python3
"""
Complete Database Reset Script
Drops all tables, recreates them, and inserts comprehensive sample data
"""
import sys
import os
import uuid
from datetime import datetime, timedelta
import random
import logging

# Configure logging for CLI script
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s',  # Simple format for CLI output
)
logger = logging.getLogger(__name__)

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine, SessionLocal, Base
from app.models.user import User, UserRole
from app.models.profile import Profile
from app.models.achievement import Achievement, UserAchievement
from app.models.event import Event, EventParticipation
from app.models.showcase import ShowcasePost, ShowcaseComment, ShowcaseLike

def reset_database():
    """Complete database reset"""
    try:
        logger.info("🗑️  Starting complete database reset...")
        
        # Drop all tables
        logger.info("📉 Dropping all existing tables...")
        Base.metadata.drop_all(engine)
        logger.info("✅ All tables dropped successfully")
        
        # Create all tables
        logger.info("📈 Creating fresh tables...")
        Base.metadata.create_all(engine)
        logger.info("✅ All tables created successfully")
        
        # Insert sample data
        logger.info("📝 Inserting sample data...")
        insert_sample_data()
        logger.info("✅ Sample data inserted successfully")
        
        logger.info("🎉 Database reset completed successfully!")
        return True
        
    except Exception as e:
        logger.error(f"❌ Database reset failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def insert_sample_data():
    """Insert comprehensive sample data"""
    db = SessionLocal()
    
    try:
        # Create sample users
        users = create_sample_users()
        db.add_all(users)
        db.commit()
        logger.info(f"✅ Created {len(users)} sample users")
        
        # Create sample profiles
        profiles = create_sample_profiles(users)
        db.add_all(profiles)
        db.commit()
        logger.info(f"✅ Created {len(profiles)} sample profiles")
        
        # Create sample achievements
        achievements = create_sample_achievements(users)
        db.add_all(achievements)
        db.commit()
        logger.info(f"✅ Created {len(achievements)} sample achievements")
        
        # Create sample events
        events = create_sample_events(users)
        db.add_all(events)
        db.commit()
        logger.info(f"✅ Created {len(events)} sample events")
        
        # Create sample showcase posts
        posts = create_sample_showcase_posts(users)
        db.add_all(posts)
        db.commit()
        logger.info(f"✅ Created {len(posts)} sample showcase posts")
        
        # Create sample comments and likes
        comments = create_sample_comments(posts, users)
        likes = create_sample_likes(posts, users)
        db.add_all(comments)
        db.add_all(likes)
        db.commit()
        logger.info(f"✅ Created {len(comments)} comments and {len(likes)} likes")
        
        # Create event participations
        participations = create_sample_event_participations(events, users)
        db.add_all(participations)
        db.commit()
        logger.info(f"✅ Created {len(participations)} event participations")
        
    except Exception as e:
        db.rollback()
        raise e
    finally:
        db.close()

def create_sample_users():
    """Create sample users with different roles"""
    users = []
    
    # Admin user
    admin_user = User(
        id="admin_001",
        uid="admin_001",
        email="admin@uthm.edu.my",
        name="Admin UTHM",
        role=UserRole.admin,
        department="FSKTM",
        staff_id="ADM001",
        is_active=True,
        profile_completed=True,
        created_at=datetime.now() - timedelta(days=30)
    )
    users.append(admin_user)
    
    # Lecturer users
    lecturer_emails = [
        "dr.ahmad@uthm.edu.my",
        "dr.sarah@uthm.edu.my", 
        "dr.mohd@uthm.edu.my"
    ]
    
    for i, email in enumerate(lecturer_emails):
        lecturer = User(
            id=f"lecturer_{i+1:03d}",
            uid=f"lecturer_{i+1:03d}",
            email=email,
            name=f"Dr. {'Ahmad' if i == 0 else 'Sarah' if i == 1 else 'Mohd'}",
            role=UserRole.lecturer,
            department="FSKTM",
            staff_id=f"LEC{i+1:03d}",
            is_active=True,
            profile_completed=True,
            created_at=datetime.now() - timedelta(days=25 + i)
        )
        users.append(lecturer)
    
    # Student users
    student_emails = [
        "ali.ahmad@student.uthm.edu.my",
        "siti.rahim@student.uthm.edu.my",
        "ahmad.khalil@student.uthm.edu.my",
        "nurul.aini@student.uthm.edu.my",
        "mohd.faiz@student.uthm.edu.my"
    ]
    
    for i, email in enumerate(student_emails):
        student = User(
            id=f"student_{i+1:03d}",
            uid=f"student_{i+1:03d}",
            email=email,
            name=f"{'Ali Ahmad' if i == 0 else 'Siti Rahim' if i == 1 else 'Ahmad Khalil' if i == 2 else 'Nurul Aini' if i == 3 else 'Mohd Faiz'}",
            role=UserRole.student,
            department="FSKTM",
            student_id=f"STU{i+1:03d}",
            is_active=True,
            profile_completed=random.choice([True, False]),
            created_at=datetime.now() - timedelta(days=20 + i)
        )
        users.append(student)
    
    return users

def create_sample_profiles(users):
    """Create sample profiles for users"""
    profiles = []
    
    departments = ["Computer Science", "Software Engineering", "Information Technology", "Data Science"]
    faculties = ["FSKTM", "FKEE", "FKAAS"]
    skills = [
        ["Python", "JavaScript", "React", "Node.js", "SQL"],
        ["Java", "Spring Boot", "Android", "Kotlin", "MySQL"],
        ["C++", "Python", "Machine Learning", "TensorFlow", "PostgreSQL"],
        ["JavaScript", "Vue.js", "PHP", "Laravel", "MongoDB"],
        ["Python", "Django", "React", "Docker", "Redis"]
    ]
    
    interests = [
        ["Web Development", "Mobile Apps", "AI/ML", "Cloud Computing"],
        ["Software Engineering", "System Design", "DevOps", "Microservices"],
        ["Data Science", "Machine Learning", "Big Data", "Analytics"],
        ["Frontend Development", "UI/UX", "Progressive Web Apps", "Performance"],
        ["Backend Development", "API Design", "Database Design", "Security"]
    ]
    
    for i, user in enumerate(users):
        if user.role == UserRole.student:
            profile = Profile(
                id=str(uuid.uuid4()),
                userId=user.id,
                fullName=user.name,
                bio=f"Passionate {user.department} student at UTHM",
                phone=f"01{random.randint(10000000, 99999999)}",
                profileImageUrl="https://via.placeholder.com/150/4A90E2/FFFFFF?text=Profile",
                studentId=user.student_id,
                department=random.choice(departments),
                faculty=random.choice(faculties),
                yearOfStudy=random.choice(["Year 1", "Year 2", "Year 3", "Year 4"]),
                cgpa=f"{random.uniform(2.5, 4.0):.2f}",
                skills=skills[i % len(skills)] if i < len(skills) else skills[0],
                interests=interests[i % len(interests)] if i < len(interests) else interests[0],
                languages=[{"name": "English", "level": "Advanced"}, {"name": "Bahasa Malaysia", "level": "Native"}],
                experiences=[
                    {
                        "title": "Software Developer Intern",
                        "company": "Tech Company",
                        "duration": "3 months",
                        "description": "Developed web applications using modern technologies"
                    }
                ],
                projects=[
                    {
                        "title": "Student Management System",
                        "description": "A comprehensive system for managing student records",
                        "technologies": ["React", "Node.js", "MongoDB"],
                        "github": "https://github.com/username/project"
                    }
                ],
                linkedinUrl="https://linkedin.com/in/username",
                githubUrl="https://github.com/username",
                portfolioUrl="https://portfolio.com"
            )
            profiles.append(profile)
        elif user.role == UserRole.lecturer:
            profile = Profile(
                id=str(uuid.uuid4()),
                userId=user.id,
                fullName=user.name,
                bio=f"Senior Lecturer in {user.department} at UTHM",
                phone=f"01{random.randint(10000000, 99999999)}",
                profileImageUrl="https://via.placeholder.com/150/9B59B6/FFFFFF?text=Lecturer",
                staffId=user.staff_id,
                department=random.choice(departments),
                faculty=user.department,
                skills=skills[i % len(skills)] if i < len(skills) else skills[0],
                interests=interests[i % len(interests)] if i < len(interests) else interests[0],
                languages=[{"name": "English", "level": "Native"}, {"name": "Bahasa Malaysia", "level": "Advanced"}],
                experiences=[
                    {
                        "title": "Senior Lecturer",
                        "company": "UTHM",
                        "duration": "5+ years",
                        "description": "Teaching and research in computer science"
                    }
                ],
                projects=[
                    {
                        "title": "Research on Machine Learning Applications",
                        "description": "Published research on ML in education",
                        "technologies": ["Python", "TensorFlow", "Scikit-learn"],
                        "publication": "International Journal of Computer Science"
                    }
                ]
            )
            profiles.append(profile)
    
    return profiles

def create_sample_achievements(users):
    """Create sample achievements"""
    achievements = []
    
    achievement_templates = [
        {
            "title": "Dean's List Award",
            "description": "Achieved outstanding academic performance",
            "category": "academic",
            "achievement_type": "award",
            "issuing_organization": "UTHM Faculty",
            "skills_demonstrated": ["Academic Excellence", "Time Management", "Discipline"]
        },
        {
            "title": "Programming Competition Winner",
            "description": "First place in university programming contest",
            "category": "technical",
            "achievement_type": "competition",
            "issuing_organization": "UTHM Computer Science Department",
            "skills_demonstrated": ["Problem Solving", "Programming", "Algorithm Design"]
        },
        {
            "title": "Best Final Year Project",
            "description": "Outstanding final year project presentation",
            "category": "academic",
            "achievement_type": "project",
            "issuing_organization": "UTHM",
            "skills_demonstrated": ["Project Management", "Research", "Presentation"]
        },
        {
            "title": "Microsoft Azure Certification",
            "description": "Certified in cloud computing fundamentals",
            "category": "technical",
            "achievement_type": "certificate",
            "issuing_organization": "Microsoft",
            "skills_demonstrated": ["Cloud Computing", "Azure", "DevOps"]
        }
    ]
    
    for user in users:
        if user.role == UserRole.student:
            # Give each student 2-4 achievements
            num_achievements = random.randint(2, 4)
            selected_achievements = random.sample(achievement_templates, num_achievements)
            
            for template in selected_achievements:
                achievement = Achievement(
                    id=str(uuid.uuid4()),
                    user_id=user.id,
                    title=template["title"],
                    description=template["description"],
                    category=template["category"],
                    achievement_type=template["achievement_type"],
                    issuing_organization=template["issuing_organization"],
                    date_achieved=datetime.now() - timedelta(days=random.randint(30, 365)),
                    image_urls=["https://via.placeholder.com/300/4A90E2/FFFFFF?text=Achievement"],
                    is_verified=random.choice([True, False]),
                    verified_by=random.choice([u.id for u in users if u.role == UserRole.admin or u.role == UserRole.lecturer]) if random.choice([True, False]) else None,
                    verified_at=datetime.now() - timedelta(days=random.randint(1, 30)) if random.choice([True, False]) else None,
                    skills_demonstrated=template["skills_demonstrated"],
                    tags=[template["category"], template["achievement_type"]]
                )
                achievements.append(achievement)
    
    return achievements

def create_sample_events(users):
    """Create sample events"""
    events = []
    
    event_templates = [
        {
            "title": "Web Development Workshop",
            "description": "Learn modern web development with React and Node.js",
            "category": "workshop",
            "location": "FSKTM Lab 1",
            "venue": "UTHM Campus",
            "max_participants": 30,
            "skills_gained": ["React", "Node.js", "JavaScript", "Web Development"],
            "target_audience": ["Computer Science Students", "Software Engineering Students"]
        },
        {
            "title": "Machine Learning Seminar",
            "description": "Introduction to machine learning and AI applications",
            "category": "seminar",
            "location": "Main Auditorium",
            "venue": "UTHM Campus",
            "max_participants": 100,
            "skills_gained": ["Machine Learning", "Python", "Data Analysis", "AI"],
            "target_audience": ["All Students", "Lecturers", "Researchers"]
        },
        {
            "title": "Programming Competition",
            "description": "Annual programming contest for UTHM students",
            "category": "competition",
            "location": "Computer Lab",
            "venue": "FSKTM Building",
            "max_participants": 50,
            "skills_gained": ["Problem Solving", "Programming", "Algorithm Design", "Teamwork"],
            "target_audience": ["Computer Science Students", "Software Engineering Students"]
        },
        {
            "title": "Career Fair 2024",
            "description": "Connect with industry professionals and explore career opportunities",
            "category": "career",
            "location": "Main Hall",
            "venue": "UTHM Campus",
            "max_participants": 200,
            "skills_gained": ["Networking", "Career Planning", "Professional Development"],
            "target_audience": ["Final Year Students", "Graduates", "All Students"]
        }
    ]
    
    for i, template in enumerate(event_templates):
        # Random lecturer as creator
        creator = random.choice([u for u in users if u.role == UserRole.lecturer])
        
        event = Event(
            id=str(uuid.uuid4()),
            created_by=creator.id,
            title=template["title"],
            description=template["description"],
            category=template["category"],
            start_date=datetime.now() + timedelta(days=random.randint(7, 60)),
            end_date=datetime.now() + timedelta(days=random.randint(7, 60) + 1),
            location=template["location"],
            venue=template["venue"],
            max_participants=template["max_participants"],
            current_participants=0,
            registration_deadline=datetime.now() + timedelta(days=random.randint(1, 30)),
            requirements=["Basic programming knowledge", "Laptop required"],
            skills_gained=template["skills_gained"],
            target_audience=template["target_audience"],
            image_url=f"https://via.placeholder.com/400/3498DB/FFFFFF?text={template['title'].replace(' ', '+')}",
            is_active=True,
            is_featured=random.choice([True, False]),
            registration_open=True
        )
        events.append(event)
    
    return events

def create_sample_showcase_posts(users):
    """Create sample showcase posts"""
    posts = []
    
    post_templates = [
        {
            "title": "My First Web App",
            "content": "Just completed my first full-stack web application using React and Node.js! Learned so much about modern web development.",
            "category": "project",
            "tags": ["web-development", "react", "nodejs", "first-project"],
            "skills_used": ["React", "Node.js", "JavaScript", "HTML", "CSS"]
        },
        {
            "title": "Machine Learning Project",
            "content": "Working on a machine learning project to predict student performance. Using Python with scikit-learn and pandas.",
            "category": "research",
            "tags": ["machine-learning", "python", "data-science", "education"],
            "skills_used": ["Python", "Scikit-learn", "Pandas", "NumPy", "Data Analysis"]
        },
        {
            "title": "Mobile App Development",
            "content": "Developing a mobile app for campus navigation. Using Flutter for cross-platform development.",
            "category": "project",
            "tags": ["mobile-development", "flutter", "dart", "campus-app"],
            "skills_used": ["Flutter", "Dart", "Mobile Development", "UI/UX"]
        },
        {
            "title": "Database Design Project",
            "content": "Designed and implemented a comprehensive database for library management system. Learned about normalization and relationships.",
            "category": "project",
            "tags": ["database", "sql", "design", "library-system"],
            "skills_used": ["SQL", "Database Design", "ERD", "Normalization"]
        }
    ]
    
    for user in users:
        if user.role == UserRole.student:
            # Each student gets 1-3 posts
            num_posts = random.randint(1, 3)
            selected_posts = random.sample(post_templates, num_posts)
            
            for template in selected_posts:
                post = ShowcasePost(
                    id=str(uuid.uuid4()),
                    user_id=user.id,
                    title=template["title"],
                    description=template["content"][:100] + "...",
                    content=template["content"],
                    category=template["category"],
                    tags=template["tags"],
                    skills_used=template["skills_used"],
                    media_urls=["https://via.placeholder.com/600/4A90E2/FFFFFF?text=Project+Image"],
                    media_types=["image"],
                    user_name=user.name,
                    user_profile_image="https://via.placeholder.com/50/4A90E2/FFFFFF?text=U",
                    user_role=user.role.value,
                    user_department=user.department,
                    user_headline=f"{user.department} Student",
                    likes_count=random.randint(0, 15),
                    comments_count=random.randint(0, 8),
                    shares_count=random.randint(0, 5),
                    views_count=random.randint(10, 100),
                    is_public=True,
                    is_featured=random.choice([True, False]),
                    allow_comments=True,
                    is_approved=True
                )
                posts.append(post)
    
    return posts

def create_sample_comments(posts, users):
    """Create sample comments on posts"""
    comments = []
    
    comment_templates = [
        "Great work! This looks really impressive.",
        "I love the design! How long did it take you to build this?",
        "This is exactly what I needed for my project. Thanks for sharing!",
        "Amazing project! Can you share the source code?",
        "Very well done! The UI looks clean and professional.",
        "I'm working on something similar. Would love to collaborate!",
        "This is inspiring! Makes me want to start my own project.",
        "Great use of modern technologies! Keep up the good work."
    ]
    
    for post in posts:
        # Each post gets 2-6 comments
        num_comments = random.randint(2, 6)
        commenters = random.sample([u for u in users if u.role == UserRole.student], min(num_comments, len([u for u in users if u.role == UserRole.student])))
        
        for i, commenter in enumerate(commenters):
            comment = ShowcaseComment(
                id=str(uuid.uuid4()),
                post_id=post.id,
                user_id=commenter.id,
                parent_comment_id=None,  # No replies for now
                content=random.choice(comment_templates),
                user_name=commenter.name,
                user_profile_image="https://via.placeholder.com/30/4A90E2/FFFFFF?text=U",
                likes_count=random.randint(0, 5),
                mentions=[],
                is_approved=True,
                is_edited=False
            )
            comments.append(comment)
    
    return comments

def create_sample_likes(posts, users):
    """Create sample likes on posts"""
    likes = []
    
    for post in posts:
        # Each post gets 5-20 likes
        num_likes = random.randint(5, 20)
        likers = random.sample([u for u in users if u.role == UserRole.student], min(num_likes, len([u for u in users if u.role == UserRole.student])))
        
        for liker in likers:
            like = ShowcaseLike(
                post_id=post.id,
                user_id=liker.id
            )
            likes.append(like)
    
    return likes

def create_sample_event_participations(events, users):
    """Create sample event participations"""
    participations = []
    
    for event in events:
        # Each event gets 10-25 participants
        num_participants = random.randint(10, min(25, event.max_participants))
        participants = random.sample([u for u in users if u.role == UserRole.student], min(num_participants, len([u for u in users if u.role == UserRole.student])))
        
        for participant in participants:
            participation = EventParticipation(
                id=str(uuid.uuid4()),
                event_id=event.id,
                user_id=participant.id,
                registration_date=datetime.now() - timedelta(days=random.randint(1, 30)),
                attendance_status=random.choice(["registered", "attended", "no_show"]),
                feedback_rating=random.randint(1, 5) if random.choice([True, False]) else None,
                feedback_comment="Great event! Learned a lot." if random.choice([True, False]) else None
            )
            participations.append(participation)
            
            # Update event participant count
            event.current_participants = len(participants)
    
    return participations

if __name__ == "__main__":
    success = reset_database()
    sys.exit(0 if success else 1)
