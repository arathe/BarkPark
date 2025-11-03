-- Migration: Normalize password reset expiration timestamps to TIMESTAMPTZ
-- Rollback (manual):
--   ALTER TABLE users
--     ALTER COLUMN reset_token_expires TYPE TIMESTAMP
--     USING reset_token_expires AT TIME ZONE 'UTC';

ALTER TABLE users
  ALTER COLUMN reset_token_expires
  TYPE TIMESTAMPTZ
  USING CASE
    WHEN reset_token_expires IS NULL THEN NULL
    ELSE reset_token_expires AT TIME ZONE 'UTC'
  END;
