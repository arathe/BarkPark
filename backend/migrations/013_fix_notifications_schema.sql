-- Migration: Align notifications schema with JSON payload while preserving compatibility
-- Rollback (manual):
--   1. ALTER TABLE notifications DROP COLUMN IF EXISTS data;
--   2. ALTER TABLE notifications RENAME COLUMN read TO is_read;
--   3. (Optional) Re-add defaults if needed: ALTER TABLE notifications ALTER COLUMN is_read SET DEFAULT false;

-- Ensure JSONB payload column exists with sane defaults
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS data JSONB DEFAULT '{}'::jsonb NOT NULL;

-- Backfill payload for rows that relied on scalar columns
UPDATE notifications
SET data = jsonb_strip_nulls(
      jsonb_build_object(
        'actorId', actor_id,
        'postId', post_id,
        'commentId', comment_id
      )
    )
WHERE (data IS NULL OR data = '{}'::jsonb)
  AND (
    actor_id IS NOT NULL
    OR post_id IS NOT NULL
    OR comment_id IS NOT NULL
  );

-- Rename is_read column to read if still present to match application expectations
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'notifications'
      AND column_name = 'is_read'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'notifications'
      AND column_name = 'read'
  ) THEN
    ALTER TABLE notifications RENAME COLUMN is_read TO read;
  END IF;
END $$;

-- Ensure read column retains expected default
ALTER TABLE notifications
  ALTER COLUMN read SET DEFAULT false;
