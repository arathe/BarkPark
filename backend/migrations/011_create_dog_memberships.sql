BEGIN;

CREATE TABLE IF NOT EXISTS dog_memberships (
  id SERIAL PRIMARY KEY,
  dog_id INTEGER NOT NULL REFERENCES dogs(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL DEFAULT 'owner',
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  invited_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (dog_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_dog_memberships_dog_id ON dog_memberships(dog_id);
CREATE INDEX IF NOT EXISTS idx_dog_memberships_user_id ON dog_memberships(user_id);

-- Backfill existing memberships from dogs table
DO $$
DECLARE
  owner_column TEXT;
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'dogs'
      AND column_name = 'user_id'
  ) THEN
    owner_column := 'user_id';
  ELSE
    owner_column := 'primary_owner_id';
  END IF;

  EXECUTE format(
    'INSERT INTO dog_memberships (dog_id, user_id, role, status, invited_by, created_at, updated_at)
     SELECT d.id, %1$I, ''owner'', ''active'', %1$I,
            COALESCE(d.created_at, NOW()), COALESCE(d.updated_at, NOW())
     FROM dogs d
     WHERE %1$I IS NOT NULL
     ON CONFLICT (dog_id, user_id) DO UPDATE
     SET role = EXCLUDED.role,
         status = ''active'',
         invited_by = EXCLUDED.invited_by,
         updated_at = CURRENT_TIMESTAMP',
    owner_column
  );
END $$;

-- Rename dogs.user_id to dogs.primary_owner_id to track the original creator
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'dogs'
      AND column_name = 'user_id'
  ) THEN
    ALTER TABLE dogs RENAME COLUMN user_id TO primary_owner_id;
  END IF;
END $$;

-- Rename the existing index if present
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'idx_dogs_user_id'
  ) THEN
    EXECUTE 'ALTER INDEX idx_dogs_user_id RENAME TO idx_dogs_primary_owner_id';
  END IF;
END $$;

-- Ensure the primary owner foreign key uses ON DELETE SET NULL semantics
ALTER TABLE dogs DROP CONSTRAINT IF EXISTS dogs_user_id_fkey;
ALTER TABLE dogs DROP CONSTRAINT IF EXISTS dogs_primary_owner_id_fkey;
ALTER TABLE dogs
  ADD CONSTRAINT dogs_primary_owner_id_fkey
  FOREIGN KEY (primary_owner_id)
  REFERENCES users(id)
  ON DELETE SET NULL;

COMMIT;
