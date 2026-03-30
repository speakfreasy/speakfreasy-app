-- ============================================================
-- Add cached count columns + triggers
-- Run in: Supabase Dashboard → SQL Editor
-- ============================================================
-- Covers:
--   1. halls.subscriber_count  — maintained by subscriptions trigger
--   2. videos.view_count       — column only (Bunny.net webhook will populate)
--   3. posts.comment_count     — maintained by comments trigger
--   5. creators.updated_at     — missing trigger (reuses existing update_updated_at fn)
-- ============================================================


-- ============================================================
-- 1. halls.subscriber_count
-- ============================================================

ALTER TABLE public.halls
  ADD COLUMN IF NOT EXISTS subscriber_count integer NOT NULL DEFAULT 0;

-- Backfill from existing active subscriptions
UPDATE public.halls h
SET subscriber_count = (
  SELECT COUNT(*)
  FROM public.subscriptions s
  WHERE s.hall_id = h.id AND s.status = 'active'
);

-- SECURITY DEFINER so the trigger bypasses RLS when updating halls
-- (a subscriber inserting a sub row must not be blocked by halls_update_own)
CREATE OR REPLACE FUNCTION public.update_hall_subscriber_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'active' THEN
      UPDATE halls SET subscriber_count = subscriber_count + 1 WHERE id = NEW.hall_id;
    END IF;

  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.status != 'active' AND NEW.status = 'active' THEN
      UPDATE halls SET subscriber_count = subscriber_count + 1 WHERE id = NEW.hall_id;
    ELSIF OLD.status = 'active' AND NEW.status != 'active' THEN
      UPDATE halls SET subscriber_count = GREATEST(subscriber_count - 1, 0) WHERE id = NEW.hall_id;
    END IF;

  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.status = 'active' THEN
      UPDATE halls SET subscriber_count = GREATEST(subscriber_count - 1, 0) WHERE id = OLD.hall_id;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS subscriptions_update_hall_sub_count ON public.subscriptions;
CREATE TRIGGER subscriptions_update_hall_sub_count
  AFTER INSERT OR UPDATE OF status OR DELETE
  ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_hall_subscriber_count();


-- ============================================================
-- 2. videos.view_count
-- ============================================================

ALTER TABLE public.videos
  ADD COLUMN IF NOT EXISTS view_count integer NOT NULL DEFAULT 0;

-- No backfill — no view tracking in DB yet.
-- Increment this from the Bunny.net webhook handler when a view event fires.


-- ============================================================
-- 3. posts.comment_count
-- ============================================================

ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS comment_count integer NOT NULL DEFAULT 0;

-- Backfill from existing comments
UPDATE public.posts p
SET comment_count = (
  SELECT COUNT(*)
  FROM public.comments c
  WHERE c.post_id = p.id
);

-- SECURITY DEFINER so a commenter (not post author) can trigger the update on posts
CREATE OR REPLACE FUNCTION public.update_post_comment_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.post_id IS NOT NULL THEN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;

  ELSIF TG_OP = 'DELETE' AND OLD.post_id IS NOT NULL THEN
    UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = OLD.post_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS comments_update_post_comment_count ON public.comments;
CREATE TRIGGER comments_update_post_comment_count
  AFTER INSERT OR DELETE
  ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.update_post_comment_count();


-- ============================================================
-- 5. creators.updated_at trigger (was missing)
-- ============================================================

DROP TRIGGER IF EXISTS creators_updated_at ON public.creators;
CREATE TRIGGER creators_updated_at
  BEFORE UPDATE ON public.creators
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


-- ============================================================
-- Verify
-- ============================================================
SELECT table_name, column_name, data_type, column_default
FROM information_schema.columns
WHERE (table_name = 'halls'  AND column_name = 'subscriber_count')
   OR (table_name = 'videos' AND column_name = 'view_count')
   OR (table_name = 'posts'  AND column_name = 'comment_count')
ORDER BY table_name, column_name;
