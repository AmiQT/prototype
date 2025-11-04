#!/usr/bin/env python3
"""
Fix admin user role in database
"""

from app.database import SessionLocal
from app.models.user import User, UserRole

def fix_admin_role():
    """Update admin@uthm.edu.my to have admin role"""
    try:
        db = SessionLocal()
        
        # Find admin user
        admin = db.query(User).filter(User.email == 'admin@uthm.edu.my').first()
        
        if not admin:
            print("❌ Admin user not found!")
            return
        
        print(f"Current admin role: {admin.role}")
        
        # Update role to admin
        admin.role = 'admin'  # Store as string since database is String type
        db.commit()
        
        print(f"✅ Admin role updated to: {admin.role}")
        
        # Verify
        updated_admin = db.query(User).filter(User.email == 'admin@uthm.edu.my').first()
        print(f"✅ Verified: {updated_admin.email} = {updated_admin.role}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == '__main__':
    fix_admin_role()
