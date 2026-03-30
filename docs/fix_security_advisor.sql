-- ============================================================
-- Fix Supabase Security Advisor Issues
-- Run in: Supabase Dashboard → SQL Editor
-- ============================================================
-- Errors fixed:
--   1. RLS Disabled in Public  → public.creators
--   2. RLS Disabled in Public  → public.user_access  (policy exists but was inactive)
-- Warnings fixed:
--   3. Function Search Path Mutable → public.user_owns_hall
--   4. Function Search Path Mutable → public.toggle_post_like
--   5. Function Search Path Mutable → public.handle_new_user
-- Manual step (no SQL):
--   6. Leaked Password Protection → Dashboard → Auth → Settings → Enable "Leaked Password Protection"
-- ============================================================


-- ============================================================
-- 1 & 2. Enable RLS on creators and user_access
-- ============================================================

ALTER TABLE public.creators   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_access ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- creators RLS policies
-- ============================================================
-- Rule: anyone authenticated can read approved creators (needed for hall joins),
--       creators can read their own record (even if unapproved),
--       admins can read all.
--       Only admins can insert/update/delete (approval workflow).

-- SELECT
DROP POLICY IF EXISTS "creators_select" ON public.creators;
CREATE POLICY "creators_select"
ON public.creators FOR SELECT
TO authenticated
USING (
  approved = true
  OR profile_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);

-- INSERT (admin only — creators are created via admin workflow)
DROP POLICY IF EXISTS "creators_insert_admin" ON public.creators;
CREATE POLICY "creators_insert_admin"
ON public.creators FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);

-- UPDATE (admin only — approval, hall assignment)
DROP POLICY IF EXISTS "creators_update_admin" ON public.creators;
CREATE POLICY "creators_update_admin"
ON public.creators FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);

-- DELETE (admin only)
DROP POLICY IF EXISTS "creators_delete_admin" ON public.creators;
CREATE POLICY "creators_delete_admin"
ON public.creators FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);


-- ============================================================
-- 3. Fix search_path on user_owns_hall
--    (re-create with SET search_path = public)
-- ============================================================
-- NOTE: Paste the original function body here if it differs.
-- This is the common form — check your dashboard for the exact body.
CREATE OR REPLACE FUNCTION public.user_owns_hall(hall_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM creators
    WHERE profile_id = auth.uid()
      AND id = (SELECT creator_id FROM halls WHERE id = hall_id)
      AND approved = true
  );
$$;


-- ============================================================
-- 4. Fix search_path on toggle_post_like
-- ============================================================
-- NOTE: Paste the original function body here if it differs.
CREATE OR REPLACE FUNCTION public.toggle_post_like(p_post_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_exists  boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM post_likes
    WHERE post_id = p_post_id AND user_id = v_user_id
  ) INTO v_exists;

  IF v_exists THEN
    DELETE FROM post_likes WHERE post_id = p_post_id AND user_id = v_user_id;
    UPDATE posts SET like_count = GREATEST(0, like_count - 1) WHERE id = p_post_id;
    RETURN false;
  ELSE
    INSERT INTO post_likes (post_id, user_id) VALUES (p_post_id, v_user_id);
    UPDATE posts SET like_count = like_count + 1 WHERE id = p_post_id;
    RETURN true;
  END IF;
END;
$$;


-- ============================================================
-- 5. Fix search_path on handle_new_user
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, role, display_name, created_at, updated_at)
  VALUES (
    NEW.id,
    'subscriber',
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$;


-- ============================================================
-- Verify RLS is now enabled
-- ============================================================
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('creators', 'user_access')
ORDER BY tablename;
