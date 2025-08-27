-- Fix database schema inconsistencies
-- This script should be run to align the database with the expected column names

-- 1. Fix profiles table column names to match the expected schema
ALTER TABLE profiles 
RENAME COLUMN "fullName" TO "full_name";

ALTER TABLE profiles 
RENAME COLUMN "profileImageUrl" TO "profile_image_url";

ALTER TABLE profiles 
RENAME COLUMN "studentId" TO "student_id";

ALTER TABLE profiles 
RENAME COLUMN "yearOfStudy" TO "year_of_study";

ALTER TABLE profiles 
RENAME COLUMN "linkedinUrl" TO "linkedin_url";

ALTER TABLE profiles 
RENAME COLUMN "githubUrl" TO "github_url";

ALTER TABLE profiles 
RENAME COLUMN "portfolioUrl" TO "portfolio_url";

ALTER TABLE profiles 
RENAME COLUMN "createdAt" TO "created_at";

ALTER TABLE profiles 
RENAME COLUMN "updatedAt" TO "updated_at";

-- 2. Fix showcase_posts table column names
ALTER TABLE showcase_posts 
RENAME COLUMN "user_name" TO "user_name";

ALTER TABLE showcase_posts 
RENAME COLUMN "user_profile_image" TO "user_profile_image";

ALTER TABLE showcase_posts 
RENAME COLUMN "user_role" TO "user_role";

ALTER TABLE showcase_posts 
RENAME COLUMN "user_department" TO "user_department";

ALTER TABLE showcase_posts 
RENAME COLUMN "user_headline" TO "user_headline";

-- 3. Add missing columns if they don't exist
DO $$ 
BEGIN
    -- Add full_name column to profiles if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'full_name') THEN
        ALTER TABLE profiles ADD COLUMN "full_name" VARCHAR(255);
    END IF;
    
    -- Add profile_image_url column to profiles if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'profile_image_url') THEN
        ALTER TABLE profiles ADD COLUMN "profile_image_url" TEXT;
    END IF;
    
    -- Add student_id column to profiles if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'student_id') THEN
        ALTER TABLE profiles ADD COLUMN "student_id" VARCHAR(100);
    END IF;
    
    -- Add cgpa column to profiles if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'cgpa') THEN
        ALTER TABLE profiles ADD COLUMN "cgpa" VARCHAR(10);
    END IF;
END $$;

-- 4. Update existing data to use the correct column names
UPDATE profiles 
SET 
    "full_name" = COALESCE("fullName", "full_name", ''),
    "profile_image_url" = COALESCE("profileImageUrl", "profile_image_url", ''),
    "student_id" = COALESCE("studentId", "student_id", ''),
    "cgpa" = COALESCE("cgpa", '0.00')
WHERE "full_name" IS NULL OR "profile_image_url" IS NULL OR "student_id" IS NULL;

-- 5. Drop old columns after migration
ALTER TABLE profiles DROP COLUMN IF EXISTS "fullName";
ALTER TABLE profiles DROP COLUMN IF EXISTS "profileImageUrl";
ALTER TABLE profiles DROP COLUMN IF EXISTS "studentId";
ALTER TABLE profiles DROP COLUMN IF EXISTS "yearOfStudy";
ALTER TABLE profiles DROP COLUMN IF EXISTS "linkedinUrl";
ALTER TABLE profiles DROP COLUMN IF EXISTS "githubUrl";
ALTER TABLE profiles DROP COLUMN IF EXISTS "portfolioUrl";
ALTER TABLE profiles DROP COLUMN IF EXISTS "createdAt";
ALTER TABLE profiles DROP COLUMN IF EXISTS "updatedAt";

-- 6. Verify the changes
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;
