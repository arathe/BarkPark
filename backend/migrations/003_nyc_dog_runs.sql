-- NYC Dog Runs - Sample data
-- This adds key NYC dog runs with proper address format

INSERT INTO dog_parks (name, description, address, location, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough) VALUES
('Frank Decolvenaere Dog Run', 'NYC Parks Department dog run in Brooklyn', 'Frank Decolvenaere Dog Run, Brooklyn NY 11209', ST_SetSRID(ST_MakePoint(-74.03650678412465, 40.61231389729492), 4326), 'https://www.nycgovparks.org/parks/shore-park-and-parkway/facilities/dogareas', '(212) 639-9675', 4.8, 9, 'Synthetic', true, '11209', 'Brooklyn'),
('Central Park Dog Run', 'NYC Parks Department dog run in Manhattan', 'Central Park Dog Run, Manhattan NY 10024', ST_SetSRID(ST_MakePoint(-73.9654, 40.7829), 4326), 'https://www.nycgovparks.org/parks/central-park', '(212) 310-6600', 4.5, 250, 'Natural', true, '10024', 'Manhattan'),
('Prospect Park Dog Beach', 'NYC Parks Department dog run in Brooklyn', 'Prospect Park Dog Beach, Brooklyn NY 11215', ST_SetSRID(ST_MakePoint(-73.9626, 40.6602), 4326), 'https://www.nycgovparks.org/parks/prospect-park', '(718) 965-8951', 4.6, 180, 'Sand', false, '11215', 'Brooklyn'),
('Riverside Park Dog Run', 'NYC Parks Department dog run in Manhattan', 'Riverside Park Dog Run, Manhattan NY 10025', ST_SetSRID(ST_MakePoint(-73.9776, 40.7903), 4326), 'https://www.nycgovparks.org/parks/riverside-park', '(212) 408-0226', 4.4, 120, 'Natural', true, '10025', 'Manhattan'),
('Washington Square Park Dog Run', 'NYC Parks Department dog run in Manhattan', 'Washington Square Park Dog Run, Manhattan NY 10012', ST_SetSRID(ST_MakePoint(-73.9976, 40.7308), 4326), 'https://www.nycgovparks.org/parks/washington-square-park', '(212) 639-9675', 4.2, 95, 'Concrete', true, '10012', 'Manhattan');

-- Record this migration
INSERT INTO schema_migrations (version) VALUES ('003_nyc_dog_runs');