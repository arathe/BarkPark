-- Migration: Rename friendships indexes to match user_id/friend_id naming
-- Rollback (manual):
--   ALTER INDEX idx_friendships_user_friend RENAME TO idx_friendships_users;
--   ALTER TABLE friendships
--     RENAME CONSTRAINT friendships_user_id_friend_id_key
--     TO friendships_requester_id_addressee_id_key;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'friendships'
      AND indexname = 'idx_friendships_users'
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'friendships'
      AND indexname = 'idx_friendships_user_friend'
  ) THEN
    ALTER INDEX idx_friendships_users RENAME TO idx_friendships_user_friend;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'friendships'::regclass
      AND conname = 'friendships_requester_id_addressee_id_key'
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'friendships'::regclass
      AND conname = 'friendships_user_id_friend_id_key'
  ) THEN
    ALTER TABLE friendships
      RENAME CONSTRAINT friendships_requester_id_addressee_id_key
      TO friendships_user_id_friend_id_key;
  END IF;
END $$;
