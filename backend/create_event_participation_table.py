#!/usr/bin/env python3
"""
Script to create the event_participations table in the database
"""
import sys
import os

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from app.models.event import EventParticipation

def create_event_participation_table():
    """Create the event_participations table"""
    try:
        print("Creating event_participations table...")
        
        EventParticipation.__table__.create(bind=engine, checkfirst=True)
        
        print("event_participations table created successfully!")
        
    except Exception as e:
        print(f"Error creating table: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = create_event_participation_table()
    sys.exit(0 if success else 1)
