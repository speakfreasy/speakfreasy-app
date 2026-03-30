-- ============================================
-- Check and fix dev@speakfreasy.ca role
-- Run in Supabase Dashboard → SQL Editor
-- ============================================
-- Note: Email lives in auth.users; profiles has id (same as auth.users.id), role, etc.

-- 1. CHECK: See profiles with email from auth.users (join on id)
SELECT p.id, u.email, p.role, p.display_name
FROM profiles p
LEFT JOIN auth.users u ON u.id = p.id
ORDER BY u.email;

-- 2. CHECK: Does a profile row exist for dev@? (If this returns no row, the app will show role as null/subscriber)
SELECT p.id, p.role FROM profiles p
WHERE p.id = (SELECT id FROM auth.users WHERE email = 'dev@speakfreasy.ca' LIMIT 1);

-- 3. FIX: Set role to admin for dev@ (only updates if a profile row already exists)
UPDATE profiles
SET role = 'admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'dev@speakfreasy.ca' LIMIT 1);

-- 3b. If step 2 returned no row: profile is missing. Create it (adjust columns to match your profiles table).
--     First check: SELECT column_name FROM information_schema.columns WHERE table_name = 'profiles';
-- INSERT INTO profiles (id, role, display_name)
-- SELECT id, 'admin', 'Dev Admin' FROM auth.users WHERE email = 'dev@speakfreasy.ca' LIMIT 1;

-- 4. Verify: run step 1 again; dev@speakfreasy.ca should show role = 'admin'.
-- Then in the app: Logout and log back in so the session picks up the new role.
