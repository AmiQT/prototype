# 🗄️ Database Migration Guide - Event Registration

**File:** `add_event_registration_fields.sql`  
**Status:** Ready to Deploy  
**Estimated Time:** 2-3 minutes

---

## 📋 Quick Start

### Option 1: Supabase Dashboard (RECOMMENDED)

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your project

2. **Navigate to SQL Editor**
   - Left sidebar → SQL Editor
   - Click "+ New Query"

3. **Copy Migration SQL**
   - Open: `backend/migrations/versions/add_event_registration_fields.sql`
   - Copy ALL content (Ctrl+A, Ctrl+C)

4. **Paste and Run**
   - Paste in SQL Editor (Ctrl+V)
   - Click "Run" button
   - Wait for "Success" message

5. **Verify**
   ```sql
   -- Run this to check:
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'events' 
   AND column_name IN (
     'event_date', 'venue', 'max_participants', 
     'current_participants', 'registration_deadline'
   );
   ```

---

### Option 2: Supabase CLI

```bash
# Navigate to backend directory
cd backend

# Push migration
supabase db push

# Or run specific migration
psql $DATABASE_URL -f migrations/versions/add_event_registration_fields.sql
```

---

### Option 3: Direct psql

```bash
# Get connection string from Supabase Dashboard
# Settings → Database → Connection String

psql "postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres" \
  -f backend/migrations/versions/add_event_registration_fields.sql
```

---

## ✅ What Gets Created

### 1. Events Table Updates
**9 New Columns:**
```sql
event_date              TIMESTAMP WITH TIME ZONE
venue                   TEXT
max_participants        INTEGER
current_participants    INTEGER DEFAULT 0
registration_deadline   TIMESTAMP WITH TIME ZONE
registration_open       BOOLEAN DEFAULT true
requirements            TEXT[]
skills_gained           TEXT[]
target_audience         TEXT[]
```

**3 New Indexes:**
- `idx_events_event_date` - Fast date queries
- `idx_events_registration_open` - Filter open events
- `idx_events_registration_deadline` - Deadline checks

**3 Constraints:**
- Participants must be positive
- Max participants must be valid
- Current can't exceed max

### 2. Event Participations Updates
**1 New Column:**
```sql
participant_data JSONB  -- Stores auto-filled profile data
```

**4 New Indexes:**
- `idx_event_participations_participant_data` (GIN)
- `idx_event_participations_event_user`
- `idx_event_participations_user_id`
- `idx_event_participations_attendance_status`

### 3. Database Functions (3)
```sql
get_event_participant_count(event_id UUID) → INTEGER
is_event_full(event_id UUID) → BOOLEAN
is_registration_open(event_id UUID) → BOOLEAN
```

### 4. Auto-Triggers (3)
```sql
trg_update_participants_insert    -- Auto +1 on registration
trg_update_participants_delete    -- Auto -1 on cancellation
trg_update_participants_status    -- Handle status changes
```

---

## 🔍 Verification Steps

### Step 1: Check Events Table
```sql
-- Should return 9 new columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'events'
AND column_name IN (
  'event_date', 'venue', 'max_participants', 
  'current_participants', 'registration_deadline',
  'registration_open', 'requirements', 
  'skills_gained', 'target_audience'
);
```

**Expected Result:** 9 rows

### Step 2: Check Event Participations Table
```sql
-- Should return participant_data column
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'event_participations'
AND column_name = 'participant_data';
```

**Expected Result:** 1 row with type JSONB

### Step 3: Check Functions
```sql
-- Should return 3 functions
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%event%'
AND routine_name IN (
  'get_event_participant_count',
  'is_event_full',
  'is_registration_open'
);
```

**Expected Result:** 3 rows

### Step 4: Check Triggers
```sql
-- Should return 3 triggers
SELECT trigger_name, event_manipulation
FROM information_schema.triggers
WHERE event_object_table = 'event_participations'
AND trigger_name LIKE '%participants%';
```

**Expected Result:** 3 rows

### Step 5: Check Indexes
```sql
-- Should return new indexes
SELECT indexname 
FROM pg_indexes 
WHERE tablename IN ('events', 'event_participations')
AND indexname LIKE '%event%';
```

**Expected Result:** 7+ indexes

---

## 🧪 Test Functions

### Test 1: Get Participant Count
```sql
-- Test the function
SELECT get_event_participant_count('[YOUR_EVENT_ID]'::UUID);

-- Should return: 0 (if no registrations yet)
```

### Test 2: Check if Event Full
```sql
-- Test the function
SELECT is_event_full('[YOUR_EVENT_ID]'::UUID);

-- Should return: false (if not full)
```

### Test 3: Check Registration Open
```sql
-- Test the function
SELECT is_registration_open('[YOUR_EVENT_ID]'::UUID);

-- Should return: true (if open and not full)
```

---

## 🔄 Test Triggers

### Test Auto-Increment Trigger
```sql
-- 1. Create test event
INSERT INTO events (
  id, title, description, image_url, category,
  max_participants, current_participants, registration_open
) VALUES (
  gen_random_uuid(), 
  'Test Event', 
  'Test Description', 
  'https://example.com/image.jpg',
  'Workshop',
  10,
  0,
  true
) RETURNING id;

-- Note the event ID

-- 2. Create test registration
INSERT INTO event_participations (
  event_id, user_id, registration_date, 
  attendance_status, participant_data
) VALUES (
  '[EVENT_ID]',
  '[YOUR_USER_ID]',
  NOW(),
  'pending',
  '{"fullName": "Test User", "studentId": "123456"}'::JSONB
);

-- 3. Check current_participants auto-incremented
SELECT current_participants 
FROM events 
WHERE id = '[EVENT_ID]';

-- Should return: 1 (auto-incremented!)

-- 4. Clean up test data
DELETE FROM event_participations 
WHERE event_id = '[EVENT_ID]';

DELETE FROM events 
WHERE id = '[EVENT_ID]';
```

---

## ⚠️ Troubleshooting

### Error: "relation already exists"
**Solution:** Some columns/indexes already exist. Safe to ignore or:
```sql
-- Add IF NOT EXISTS clauses (already in migration)
ALTER TABLE events 
ADD COLUMN IF NOT EXISTS event_date TIMESTAMP;
```

### Error: "permission denied"
**Solution:** Use superuser or:
```sql
-- Grant permissions
GRANT ALL ON events TO authenticated;
GRANT ALL ON event_participations TO authenticated;
```

### Error: "function already exists"
**Solution:** Drop and recreate:
```sql
DROP FUNCTION IF EXISTS get_event_participant_count(UUID);
-- Then re-run the CREATE FUNCTION statement
```

### Error: "trigger already exists"
**Solution:** Drop and recreate:
```sql
DROP TRIGGER IF EXISTS trg_update_participants_insert 
ON event_participations;
-- Then re-run the CREATE TRIGGER statement
```

---

## 🗑️ Rollback (If Needed)

### Remove All Changes
```sql
-- Drop triggers
DROP TRIGGER IF EXISTS trg_update_participants_insert ON event_participations;
DROP TRIGGER IF EXISTS trg_update_participants_delete ON event_participations;
DROP TRIGGER IF EXISTS trg_update_participants_status ON event_participations;

-- Drop functions
DROP FUNCTION IF EXISTS get_event_participant_count(UUID);
DROP FUNCTION IF EXISTS is_event_full(UUID);
DROP FUNCTION IF EXISTS is_registration_open(UUID);

-- Drop indexes
DROP INDEX IF EXISTS idx_events_event_date;
DROP INDEX IF EXISTS idx_events_registration_open;
DROP INDEX IF EXISTS idx_events_registration_deadline;
DROP INDEX IF EXISTS idx_event_participations_participant_data;
DROP INDEX IF EXISTS idx_event_participations_event_user;
DROP INDEX IF EXISTS idx_event_participations_user_id;
DROP INDEX IF EXISTS idx_event_participations_attendance_status;

-- Remove columns (CAREFUL - This deletes data!)
ALTER TABLE events DROP COLUMN IF EXISTS event_date;
ALTER TABLE events DROP COLUMN IF EXISTS venue;
ALTER TABLE events DROP COLUMN IF EXISTS max_participants;
ALTER TABLE events DROP COLUMN IF EXISTS current_participants;
ALTER TABLE events DROP COLUMN IF EXISTS registration_deadline;
ALTER TABLE events DROP COLUMN IF EXISTS registration_open;
ALTER TABLE events DROP COLUMN IF EXISTS requirements;
ALTER TABLE events DROP COLUMN IF EXISTS skills_gained;
ALTER TABLE events DROP COLUMN IF EXISTS target_audience;

ALTER TABLE event_participations DROP COLUMN IF EXISTS participant_data;
```

---

## ✅ Post-Migration Checklist

- [ ] All 9 columns added to events table
- [ ] participant_data column added to event_participations
- [ ] 7 indexes created
- [ ] 3 functions working
- [ ] 3 triggers active
- [ ] Constraints enforced
- [ ] Permissions granted
- [ ] Test queries successful
- [ ] Trigger test passed
- [ ] No errors in logs

---

## 📊 Performance Impact

**Expected:**
- Query time: < 10ms (with indexes)
- Insert time: < 50ms (with triggers)
- Space usage: ~5-10% increase
- No performance degradation

**Monitoring:**
```sql
-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE tablename IN ('events', 'event_participations')
ORDER BY idx_scan DESC;

-- Check table size
SELECT 
  pg_size_pretty(pg_total_relation_size('events')) as events_size,
  pg_size_pretty(pg_total_relation_size('event_participations')) as participations_size;
```

---

## 🎉 Success!

**Migration Complete!**

Your database now supports:
- ✅ Event registration fields
- ✅ Participant tracking
- ✅ Automatic counting
- ✅ Smart validation
- ✅ Fast queries

**Next:** Test the mobile app registration flow!

---

*Migration Time: 2-3 minutes*  
*Zero Downtime: Yes*  
*Backwards Compatible: Yes*
