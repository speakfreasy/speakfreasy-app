-- ============================================
-- Auto-create profile with 'subscriber' role on signup
-- Run in Supabase Dashboard → SQL Editor
-- ============================================

-- This trigger automatically creates a profile row with role='subscriber'
-- when a new user signs up via Supabase Auth.

-- Step 1: Create the function that inserts into profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role, display_name, created_at, updated_at)
  VALUES (
    NEW.id,
    'subscriber',  -- Default role
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),  -- Use email prefix as default display name
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Create the trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 3: Grant necessary permissions (if needed)
-- Ensure the trigger function can insert into profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Test: Sign up a new user and verify they get 'subscriber' role automatically
-- SELECT p.id, u.email, p.role, p.display_name
-- FROM profiles p
-- JOIN auth.users u ON u.id = p.id
-- ORDER BY p.created_at DESC
-- LIMIT 5;
