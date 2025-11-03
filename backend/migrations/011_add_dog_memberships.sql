BEGIN;

CREATE TABLE IF NOT EXISTS dog_memberships (
  id SERIAL PRIMARY KEY,
  dog_id INTEGER NOT NULL REFERENCES dogs(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('primary_owner', 'co_owner', 'viewer')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked')),
  invited_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (dog_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_dog_memberships_dog_id ON dog_memberships(dog_id);
CREATE INDEX IF NOT EXISTS idx_dog_memberships_user_id ON dog_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_dog_memberships_status ON dog_memberships(status);

CREATE TABLE IF NOT EXISTS dog_membership_invitations (
  id SERIAL PRIMARY KEY,
  dog_id INTEGER NOT NULL REFERENCES dogs(id) ON DELETE CASCADE,
  email TEXT,
  invited_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  invited_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('primary_owner', 'co_owner', 'viewer')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired', 'cancelled')),
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CHECK (email IS NOT NULL OR invited_user_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_dog_membership_invites_dog_id ON dog_membership_invitations(dog_id);
CREATE INDEX IF NOT EXISTS idx_dog_membership_invites_user_id ON dog_membership_invitations(invited_user_id);
CREATE INDEX IF NOT EXISTS idx_dog_membership_invites_status ON dog_membership_invitations(status);

INSERT INTO dog_memberships (dog_id, user_id, role, status, invited_by)
SELECT id, user_id, 'primary_owner', 'active', user_id
FROM dogs
ON CONFLICT (dog_id, user_id) DO UPDATE
SET role = EXCLUDED.role,
    status = EXCLUDED.status,
    updated_at = CURRENT_TIMESTAMP;

CREATE OR REPLACE FUNCTION set_updated_at_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_dog_memberships_updated_at ON dog_memberships;
CREATE TRIGGER trg_dog_memberships_updated_at
BEFORE UPDATE ON dog_memberships
FOR EACH ROW
EXECUTE FUNCTION set_updated_at_timestamp();

DROP TRIGGER IF EXISTS trg_dog_membership_invites_updated_at ON dog_membership_invitations;
CREATE TRIGGER trg_dog_membership_invites_updated_at
BEFORE UPDATE ON dog_membership_invitations
FOR EACH ROW
EXECUTE FUNCTION set_updated_at_timestamp();

COMMIT;
