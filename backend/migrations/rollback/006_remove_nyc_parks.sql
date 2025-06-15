-- Rollback script for 006_seed_nyc_parks.sql

-- Remove all NYC dog runs (those not in the initial 12)
DELETE FROM dog_parks WHERE id NOT IN (
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a01',
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a02',
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a03',
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a04',
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a05',
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a06',
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a07',
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a08',
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a09',
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a10',
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a11',
  'd550e8e6-16e8-4f67-8b89-7f1b8c9e8a12'
);