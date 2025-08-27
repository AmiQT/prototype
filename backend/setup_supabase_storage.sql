-- Setup Supabase Storage for Showcase Media
-- Run this in your Supabase SQL Editor

-- 1. Create storage bucket for showcase media
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'showcase-media',
  'showcase-media',
  true,
  52428800, -- 50MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'video/mp4', 'video/quicktime']
);

-- 2. Create storage policies for the bucket
CREATE POLICY "Public Access" ON storage.objects
FOR SELECT USING (bucket_id = 'showcase-media');

CREATE POLICY "Authenticated users can upload" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'showcase-media' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can update their own files" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'showcase-media' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own files" ON storage.objects
FOR DELETE USING (
  bucket_id = 'showcase-media' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 3. Create RLS policy for showcase_posts to allow media uploads
CREATE POLICY "Users can insert showcase posts with media" ON showcase_posts
FOR INSERT WITH CHECK (
  auth.uid() = user_id
);

CREATE POLICY "Users can update their own showcase posts" ON showcase_posts
FOR UPDATE USING (
  auth.uid() = user_id
);

-- 4. Create function to handle media cleanup
CREATE OR REPLACE FUNCTION cleanup_showcase_media()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete associated media files when post is deleted
  IF OLD.media_urls IS NOT NULL THEN
    -- Extract filenames from URLs and delete from storage
    -- This will be handled by the Flutter app for now
    RETURN OLD;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger for media cleanup
CREATE TRIGGER cleanup_showcase_media_trigger
  BEFORE DELETE ON showcase_posts
  FOR EACH ROW
  EXECUTE FUNCTION cleanup_showcase_media();
