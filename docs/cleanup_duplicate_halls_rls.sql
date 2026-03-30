-- ============================================================
-- Cleanup: Remove duplicate/redundant SELECT policies on halls
-- Run in: Supabase Dashboard → SQL Editor
-- ============================================================
--
-- Current state has 5 SELECT policies on halls, 3 of which overlap:
--
--   "Anyone can view approved halls"    → approved = true  (DUPLICATE of halls_select)
--   "anyone_can_view_approved_halls"    → approved = true  (DUPLICATE of halls_select)
--   "Creators can view their halls"     → user_owns_hall() (DUPLICATE of creators_can_view_own_hall)
--   "creators_can_view_own_hall"        → creator_id IN (creators where profile_id = uid)
--   "halls_select"                      → approved OR creator_id = uid OR admin  ← KEEP THIS
--
-- "halls_select" covers all three cases in one policy. Drop the redundant ones.
-- ============================================================

-- Verify before dropping (optional — inspect current policies)
-- SELECT polname, pg_get_expr(polqual, polrelid) AS using_expr
-- FROM pg_policy
-- WHERE polrelid = 'public.halls'::regclass AND polcmd = 'r'
-- ORDER BY polname;

-- Drop redundant duplicate SELECT policies
DROP POLICY IF EXISTS "Anyone can view approved halls" ON public.halls;
DROP POLICY IF EXISTS "anyone_can_view_approved_halls" ON public.halls;
DROP POLICY IF EXISTS "Creators can view their halls" ON public.halls;
DROP POLICY IF EXISTS "creators_can_view_own_hall" ON public.halls;

-- Verify: only these SELECT policies should remain after cleanup:
--   halls_select  → (approved = true) OR (creator_id = auth.uid()) OR (admin)
SELECT polname, polcmd
FROM pg_policy
WHERE polrelid = 'public.halls'::regclass
ORDER BY polcmd, polname;
