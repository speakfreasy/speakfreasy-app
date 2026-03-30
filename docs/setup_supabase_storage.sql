-- ============================================
-- Setup Supabase Storage for Hall Images
-- ============================================

-- IMPORTANT: Storage buckets and policies are managed via Supabase Dashboard UI
-- This file documents the setup, but you'll configure it in the dashboard

-- ============================================
-- STEP 1: Create Buckets (Dashboard UI)
-- ============================================
-- Go to: Storage → Create new bucket

-- Bucket 1: hall-images
--   - Name: hall-images
--   - Public: YES (check the box)
--   - Allowed MIME types: image/*
--   - Max file size: 5 MB

-- Bucket 2: profile-images (optional, for future)
--   - Name: profile-images
--   - Public: YES
--   - Allowed MIME types: image/*
--   - Max file size: 5 MB

-- ============================================
-- STEP 2: Configure Policies (Dashboard UI)
-- ============================================
-- After creating the bucket, Supabase automatically creates basic policies
-- The default "Public" bucket setting allows:
--   ✓ Anyone can read/view images
--   ✓ Authenticated users can upload
--   ✓ Users can manage their own uploads

-- If you need custom policies:
-- 1. Go to: Storage → hall-images → Policies
-- 2. Click "New Policy"
-- 3. Configure as needed

-- ============================================
-- STEP 3: Test Upload (Dashboard UI)
-- ============================================
-- 1. Go to: Storage → hall-images
-- 2. Create folder: "avatars"
-- 3. Create folder: "banners"
-- 4. Upload a test image
-- 5. Click image → Copy URL
-- 6. Verify URL works in browser

-- ============================================
-- STEP 4: Update Database with Test Image
-- ============================================
-- After uploading a test image, update your hall record:

-- UPDATE halls
-- SET
--   avatar_url = 'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/hall-images/avatars/test.jpg',
--   banner_url = 'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/hall-images/banners/test-banner.jpg',
--   bio = 'Welcome to The Jazz Lounge - smooth jazz and soulful vibes.',
--   description = 'Premium jazz content and exclusive sessions'
-- WHERE slug = 'the-jazz-lounge';

-- Verify:
-- SELECT name, avatar_url, banner_url, bio FROM halls WHERE slug = 'the-jazz-lounge';
