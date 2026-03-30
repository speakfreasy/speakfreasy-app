-- ============================================
-- Fix: Infinite recursion in RLS policy for "halls"
-- ============================================
-- Error: PostgrestException(message: infinite recursion detected in policy for relation "halls", code: 42P17)
--
-- Cause: The UPDATE (or SELECT) policy on `halls` likely references `halls` again
-- (e.g. via a JOIN or subquery on halls), so Postgres re-evaluates the policy
-- and hits recursion. Fix by checking ownership only via `creators`, without
-- reading from `halls` in the policy.
--
-- Run in: Supabase Dashboard → SQL Editor

-- ---------------------------------------------------------------------------
-- Step 1: Optional – inspect existing policies (run to see what you have)
-- ---------------------------------------------------------------------------
-- SELECT polname, polcmd, pg_get_expr(polqual, polrelid) AS using_expr
-- FROM pg_policy
-- WHERE polrelid = 'public.halls'::regclass;

-- ---------------------------------------------------------------------------
-- Step 2: Drop existing UPDATE policy on halls (name may vary)
-- ---------------------------------------------------------------------------
-- This drops all UPDATE policies on halls so we can add a non-recursive one.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT polname FROM pg_policy
    WHERE polrelid = 'public.halls'::regclass
      AND polcmd = 'w'   -- 'w' = UPDATE
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.halls', r.polname);
  END LOOP;
END $$;

-- If the DO block fails or you prefer to drop by name, uncomment and use your policy name:
-- DROP POLICY IF EXISTS "Allow update for hall creator" ON public.halls;
-- DROP POLICY IF EXISTS "halls_update_policy" ON public.halls;

-- ---------------------------------------------------------------------------
-- Step 3: Helper that checks hall ownership without touching `halls` (no recursion)
-- ---------------------------------------------------------------------------
-- This app stores profile_id (auth.uid()) in halls.creator_id when creating halls.
-- So the policy must allow update when creator_id = current user's id:
CREATE OR REPLACE FUNCTION public.is_hall_creator_for(creator_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT creator_id = auth.uid();
$$;

-- If your schema stores creators.id in halls.creator_id instead, use this version:
-- CREATE OR REPLACE FUNCTION public.is_hall_creator_for(creator_id uuid)
-- RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public STABLE
-- AS $$ SELECT EXISTS (SELECT 1 FROM creators c WHERE c.id = creator_id AND c.profile_id = auth.uid()); $$;

-- ---------------------------------------------------------------------------
-- Step 4: New UPDATE policy using only creator_id (no SELECT from halls)
-- ---------------------------------------------------------------------------
-- Only the row’s creator (via creators.profile_id = auth.uid()) can update.
CREATE POLICY "halls_update_creator_only"
ON public.halls
FOR UPDATE
TO authenticated
USING (public.is_hall_creator_for(creator_id))
WITH CHECK (public.is_hall_creator_for(creator_id));

-- ---------------------------------------------------------------------------
-- Step 5: Ensure SELECT policy exists and is not recursive
-- ---------------------------------------------------------------------------
-- If your SELECT policy also recurses, replace it with a simple one, e.g.:
-- (Adjust if you need to restrict by approved status.)
-- DROP POLICY IF EXISTS "halls_select_*" ON public.halls;  -- use your actual name
-- CREATE POLICY "halls_select_public"
-- ON public.halls FOR SELECT TO authenticated
-- USING (true);
-- Or for public read: USING (true) with TO anon, authenticated as needed.

-- ---------------------------------------------------------------------------
-- Verify
-- ---------------------------------------------------------------------------
-- List policies on halls again; then try updating a hall / uploading avatar in the app.
-- SELECT polname, polcmd FROM pg_policy WHERE polrelid = 'public.halls'::regclass;
