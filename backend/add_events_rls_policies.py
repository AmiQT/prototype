#!/usr/bin/env python3
"""
Add RLS policies for events table to allow service role full access
"""
import sys
import os
from sqlalchemy import text

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine

def add_events_rls_policies():
    """Add RLS policies for events table"""
    try:
        with engine.connect() as conn:
            # Enable RLS on events table if not already enabled
            print("Enabling RLS on events table...")
            conn.execute(text("""
                ALTER TABLE events ENABLE ROW LEVEL SECURITY;
            """))
            conn.commit()
            print("✅ RLS enabled on events table")
            
            # Drop existing policy if it exists
            print("Dropping existing policies if any...")
            conn.execute(text("""
                DROP POLICY IF EXISTS "Service role full access to events" ON events;
            """))
            conn.commit()
            
            # Create policy for service role to have full access
            print("Creating service role policy for events...")
            conn.execute(text("""
                CREATE POLICY "Service role full access to events" 
                ON public.events 
                FOR ALL 
                TO service_role 
                USING (true) 
                WITH CHECK (true);
            """))
            conn.commit()
            print("✅ Service role policy created for events")
            
            # Also create policy for authenticated users to read events
            print("Creating read policy for authenticated users...")
            conn.execute(text("""
                DROP POLICY IF EXISTS "Authenticated users can read events" ON events;
            """))
            conn.commit()
            
            conn.execute(text("""
                CREATE POLICY "Authenticated users can read events" 
                ON public.events 
                FOR SELECT 
                TO authenticated 
                USING (true);
            """))
            conn.commit()
            print("✅ Read policy created for authenticated users")
            
            print("\n✅ All RLS policies added successfully!")
        
    except Exception as e:
        print(f"❌ Error adding RLS policies: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    return True

if __name__ == "__main__":
    success = add_events_rls_policies()
    sys.exit(0 if success else 1)
