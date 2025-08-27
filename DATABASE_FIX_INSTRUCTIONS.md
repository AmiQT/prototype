# Database Fix Instructions

## Issues Identified

Your Flutter app is experiencing several database-related issues:

1. **Column Name Mismatch**: The app expects `full_name` but the database has `fullName`
2. **Data Type Mismatch**: `cgpa` is stored as string but expected as double
3. **Missing Supabase Edge Functions**: Backend functions not found

## Solutions

### 1. Fix Database Schema (Recommended)

Run the SQL script to fix column naming inconsistencies:

```bash
# Connect to your Supabase database and run:
psql -h your-supabase-host -U postgres -d postgres -f backend/fix_database_schema.sql
```

Or run it directly in your Supabase SQL editor.

### 2. Alternative: Update Flutter Code

If you prefer to keep the current database schema, update the Flutter code to match:

#### Update ShowcaseService
The `ShowcaseService` has been updated to use the correct column names:
- `full_name` → `fullName`
- `profile_image_url` → `profileImageUrl`

#### Update AcademicInfoModel
The `AcademicInfoModel` now safely handles `cgpa` values as strings and converts them to doubles.

### 3. Database Compatibility Check

Use the new `DatabaseFixService` to check your database compatibility:

```dart
final dbFixService = DatabaseFixService();
final compatibility = await dbFixService.checkDatabaseCompatibility();
dbFixService.logDatabaseIssues(compatibility);
```

## Database Schema Requirements

### Profiles Table
```sql
CREATE TABLE profiles (
    id VARCHAR PRIMARY KEY,
    user_id VARCHAR NOT NULL REFERENCES users(id),
    full_name VARCHAR NOT NULL,
    profile_image_url TEXT,
    student_id VARCHAR,
    cgpa VARCHAR(10),
    -- other fields...
);
```

### Showcase Posts Table
```sql
CREATE TABLE showcase_posts (
    id VARCHAR PRIMARY KEY,
    user_id VARCHAR NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    category VARCHAR DEFAULT 'general',
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    -- other fields...
);
```

### Users Table
```sql
CREATE TABLE users (
    id VARCHAR PRIMARY KEY,
    email VARCHAR UNIQUE NOT NULL,
    name VARCHAR NOT NULL,
    role VARCHAR NOT NULL,
    is_active BOOLEAN DEFAULT true,
    profile_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    -- other fields...
);
```

## Testing the Fix

1. **Run the database migration script**
2. **Restart your Flutter app**
3. **Check the logs for database compatibility**
4. **Test the showcase feed functionality**

## Common Error Messages and Solutions

### "column users_1.full_name does not exist"
- **Solution**: Run the database migration script or update column names in Flutter code

### "Class 'String' has no instance method 'toDouble'"
- **Solution**: The `AcademicInfoModel` now handles this safely

### "Requested function was not found"
- **Solution**: This indicates missing Supabase Edge Functions. The app will fall back to direct database queries.

## Fallback Mode

If database issues persist, the app includes fallback mechanisms:
- Basic user data without profile information
- Simplified showcase posts
- Error logging for debugging

## Support

If you continue to experience issues:
1. Check the database compatibility report
2. Verify your Supabase connection settings
3. Ensure all required tables exist
4. Check RLS (Row Level Security) policies

## Next Steps

1. **Immediate**: Run the database migration script
2. **Short-term**: Test the showcase functionality
3. **Long-term**: Consider implementing proper Supabase Edge Functions for backend operations
