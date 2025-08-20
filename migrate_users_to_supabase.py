#!/usr/bin/env python3
"""
Firebase to Supabase User Migration Script
Migrates 10 testing users from Firebase to Supabase
"""

import json
import requests
import sys
from datetime import datetime

# Supabase configuration
SUPABASE_URL = "https://xibffemtpboiecpeynon.supabase.co"
SUPABASE_SERVICE_KEY = "YOUR_SUPABASE_SERVICE_ROLE_KEY"  # You need to get this from Supabase dashboard

def load_firebase_users():
    """Load exported Firebase users"""
    try:
        with open('firebase_users.json', 'r') as f:
            data = json.load(f)
            return data.get('users', [])
    except FileNotFoundError:
        print("❌ firebase_users.json not found. Please export Firebase users first.")
        return None
    except json.JSONDecodeError:
        print("❌ Invalid JSON in firebase_users.json")
        return None

def create_supabase_user(user_data):
    """Create user in Supabase"""
    
    # Prepare user data for Supabase
    supabase_user = {
        "email": user_data.get("email"),
        "password": "TempPassword123!",  # Users will need to reset password
        "email_confirm": True,  # Skip email confirmation for migration
        "user_metadata": {
            "name": user_data.get("displayName", user_data.get("email", "").split("@")[0]),
            "firebase_uid": user_data.get("localId"),
            "migrated_from_firebase": True,
            "migration_date": datetime.now().isoformat()
        }
    }
    
    # Add custom claims if they exist
    if "customClaims" in user_data:
        supabase_user["user_metadata"].update(user_data["customClaims"])
    
    return supabase_user

def migrate_users():
    """Main migration function"""
    print("🔄 Starting Firebase to Supabase user migration...")
    
    # Load Firebase users
    firebase_users = load_firebase_users()
    if not firebase_users:
        return False
    
    print(f"📊 Found {len(firebase_users)} users to migrate")
    
    # Check Supabase service key
    if SUPABASE_SERVICE_KEY == "YOUR_SUPABASE_SERVICE_ROLE_KEY":
        print("❌ Please update SUPABASE_SERVICE_KEY in the script")
        print("🔑 Get your service role key from: Supabase Dashboard → Settings → API")
        return False
    
    migrated_count = 0
    failed_count = 0
    
    for i, user in enumerate(firebase_users, 1):
        try:
            print(f"👤 Migrating user {i}/{len(firebase_users)}: {user.get('email', 'No email')}")
            
            # Create Supabase user data
            supabase_user = create_supabase_user(user)
            
            # Create user in Supabase Auth
            response = requests.post(
                f"{SUPABASE_URL}/auth/v1/admin/users",
                headers={
                    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
                    "Content-Type": "application/json",
                    "apikey": SUPABASE_SERVICE_KEY
                },
                json=supabase_user
            )
            
            if response.status_code in [200, 201]:
                migrated_count += 1
                print(f"   ✅ Success")
                
                # Optionally create user profile in your users table
                supabase_response = response.json()
                user_id = supabase_response.get("id")
                
                # Create user record in your users table
                user_record = {
                    "id": user_id,
                    "email": user.get("email"),
                    "name": user.get("displayName", user.get("email", "").split("@")[0]),
                    "role": "student",  # Default role
                    "is_active": True,
                    "profile_completed": False
                }
                
                # Insert into users table (if you have one set up)
                # This part depends on your Supabase table structure
                
            else:
                failed_count += 1
                print(f"   ❌ Failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            failed_count += 1
            print(f"   ❌ Error: {str(e)}")
    
    print(f"\n📊 Migration Summary:")
    print(f"   ✅ Successfully migrated: {migrated_count}")
    print(f"   ❌ Failed: {failed_count}")
    print(f"   📧 Users will need to reset passwords using: TempPassword123!")
    
    return migrated_count > 0

def main():
    """Main function"""
    print("🚀 Firebase to Supabase User Migration Tool")
    print("=" * 50)
    
    # Check if firebase_users.json exists
    try:
        with open('firebase_users.json', 'r') as f:
            pass
    except FileNotFoundError:
        print("❌ firebase_users.json not found")
        print("📋 Please run the Firebase export script first:")
        print("   ./export_firebase_users.sh")
        return
    
    # Confirm migration
    response = input("🤔 Are you sure you want to migrate users to Supabase? (y/N): ")
    if response.lower() != 'y':
        print("Migration cancelled.")
        return
    
    # Run migration
    success = migrate_users()
    
    if success:
        print("\n🎉 Migration completed!")
        print("📋 Next steps:")
        print("1. Test user login with migrated accounts")
        print("2. Users should reset their passwords")
        print("3. Update your app to use Supabase authentication")
    else:
        print("\n❌ Migration failed. Please check the errors above.")

if __name__ == "__main__":
    main()