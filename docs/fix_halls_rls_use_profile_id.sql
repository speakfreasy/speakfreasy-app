-- ============================================
-- Fix: Hall updates not persisting ("no rows updated")
-- ============================================
-- Run this entire file in Supabase Dashboard → SQL Editor.
-- It makes the creator check work whether halls.creator_id stores
-- profile_id (auth.uid()) OR creators.id, and ensures the UPDATE policy exists.
-- ============================================

-- 1) One function that works for both schemas: profile_id in creator_id OR creators.id in creator_id
CREATE OR REPLACE FUNCTION public.is_hall_creator_for(creator_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT auth.uid() IS NOT NULL AND (
    creator_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM creators c
      WHERE c.id = creator_id AND c.profile_id = auth.uid()
    )
  );
$$;

-- 2) Ensure UPDATE policy exists (drop and recreate so it uses the new function)
DROP POLICY IF EXISTS "halls_update_creator_only" ON public.halls;

CREATE POLICY "halls_update_creator_only"
ON public.halls
FOR UPDATE
TO authenticated
USING (public.is_hall_creator_for(creator_id))
WITH CHECK (public.is_hall_creator_for(creator_id));

-- 3) Optional: see why it might still fail (run separately if needed)
-- SELECT id, name, creator_id FROM halls LIMIT 5;
-- SELECT auth.uid() AS my_user_id;
--
-- Note: In the SQL Editor, auth.uid() is always NULL (no app user session).
-- That's expected. For RLS, what matters is the JWT sent when the app calls
-- the API. If updates still fail, in the app try: sign out and sign back in,
-- or use Settings → "Refresh session", then try uploading again.
