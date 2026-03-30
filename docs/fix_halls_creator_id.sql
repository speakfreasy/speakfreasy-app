-- ============================================================
-- Fix halls.creator_id — replace profileId with creators.id
-- Run in: Supabase Dashboard → SQL Editor
-- ============================================================
-- Background: halls.creator_id must store creators.id (not profiles.id).
-- user_owns_hall() and the halls_update_own RLS policy both depend on this.
-- Any hall created via the admin panel before this fix has the wrong value.
-- ============================================================

-- Preview: see which halls are affected before changing anything
SELECT
  h.id        AS hall_id,
  h.name,
  h.creator_id AS stored_value,
  c.id        AS correct_creator_id,
  c.profile_id
FROM halls h
JOIN creators c ON c.profile_id = h.creator_id  -- currently storing profile_id
WHERE h.creator_id NOT IN (SELECT id FROM creators); -- not a valid creators.id

-- Fix: update all affected halls in one statement
UPDATE halls h
SET creator_id = c.id
FROM creators c
WHERE c.profile_id = h.creator_id          -- currently stores profile_id
  AND h.creator_id NOT IN (SELECT id FROM creators); -- not already a valid creators.id

-- Verify: should return 0 rows after the fix
SELECT h.id, h.name, h.creator_id
FROM halls h
WHERE h.creator_id NOT IN (SELECT id FROM creators);
