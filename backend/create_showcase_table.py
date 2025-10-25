#!/usr/bin/env python3
"""
Script to create the showcase_posts table in the database
"""
import sys
import os

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine, Base
from app.models.showcase import ShowcasePost, ShowcaseComment, ShowcaseLike
from sqlalchemy import text

def create_showcase_tables():
    """Create all showcase-related tables"""
    try:
        print("Creating showcase tables...")
        
        # Create only the showcase tables, not all tables
        ShowcasePost.__table__.create(bind=engine, checkfirst=True)
        ShowcaseComment.__table__.create(bind=engine, checkfirst=True)
        ShowcaseLike.__table__.create(bind=engine, checkfirst=True)
        
        print("Showcase tables created successfully!")
        print("Tables created:")
        print("  - showcase_posts")
        print("  - showcase_comments") 
        print("  - showcase_likes")
        
    except Exception as e:
        print(f"Error creating tables: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = create_showcase_tables()
    sys.exit(0 if success else 1)