#!/usr/bin/env python3
"""
Test admin user creation endpoint
"""

import asyncio
import os
import jwt
from datetime import datetime, timedelta
import httpx

# Test configuration
BACKEND_URL = "http://127.0.0.1:8000"
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET")

async def test_create_user():
    """Test the user creation endpoint"""
    
    if not SUPABASE_JWT_SECRET:
        print("❌ SUPABASE_JWT_SECRET not set!")
        return
    
    # Create a mock JWT token for admin@uthm.edu.my
    admin_id = "880698eb-2793-435f-ae67-734cc7d3d756"
    
    payload = {
        "sub": admin_id,
        "email": "admin@uthm.edu.my",
        "email_confirmed_at": datetime.utcnow().isoformat(),
        "aud": "authenticated",
        "iat": datetime.utcnow().timestamp(),
        "exp": (datetime.utcnow() + timedelta(hours=1)).timestamp()
    }
    
    token = jwt.encode(payload, SUPABASE_JWT_SECRET, algorithm="HS256")
    
    print(f"✅ Created JWT token")
    print(f"   Token: {token[:50]}...")
    
    # Test with backend
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    user_data = {
        "email": "test@uthm.edu.my",
        "password": "Test@123",
        "name": "Test User",
        "role": "student",
        "department": "Computer Science",
        "is_active": True
    }
    
    async with httpx.AsyncClient() as client:
        print(f"\n📤 POST {BACKEND_URL}/api/users/admin/create")
        print(f"   Headers: Authorization: Bearer {token[:30]}...")
        print(f"   Body: {user_data}")
        
        response = await client.post(
            f"{BACKEND_URL}/api/users/admin/create",
            json=user_data,
            headers=headers,
            timeout=10
        )
        
        print(f"\n📥 Response Status: {response.status_code}")
        print(f"   Headers: {dict(response.headers)}")
        print(f"   Body: {response.text}")
        
        if response.status_code == 200:
            print("\n✅ SUCCESS! User creation endpoint works!")
        else:
            print("\n❌ FAILED! Check the response above.")

if __name__ == '__main__':
    asyncio.run(test_create_user())
