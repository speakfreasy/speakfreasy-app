-- ============================================
-- Add avatar_url field to halls table
-- Run in Supabase Dashboard → SQL Editor
-- ============================================

-- Add avatar_url column to halls table (nullable, halls can use creator's avatar as fallback)
ALTER TABLE halls
ADD COLUMN IF NOT EXISTS avatar_url text;

-- Optional: Add some sample data for testing
-- UPDATE halls
-- SET avatar_url = 'https://example.com/hall-avatar.jpg'
-- WHERE slug = 'the-jazz-lounge';

-- Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'halls'
ORDER BY ordinal_position;
