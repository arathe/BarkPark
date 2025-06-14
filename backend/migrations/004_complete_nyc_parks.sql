-- Migration: Complete NYC Dog Runs Import
-- Description: Import all 91 NYC dog runs with complete metadata
-- Date: 2025-06-14

BEGIN;

-- Remove existing NYC parks (if any exist from previous migrations)
DELETE FROM dog_parks WHERE borough IS NOT NULL;

-- Insert all 91 NYC dog runs
INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Frank Decolvenaere Dog Run',
  'Frank Decolvenaere Dog Run, Brooklyn NY 11209',
  ST_SetSRID(ST_MakePoint(-74.03650678412465, 40.61231389729492), 4326),
  '{Seating,Synthetic Surface}',
  'https://www.nycgovparks.org/parks/shore-park-and-parkway/facilities/dogareas',
  '(212) 639-9675',
  4.8,
  9,
  'Synthetic',
  true,
  11209,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Frank S. Hackett Park Dog Run',
  'Frank S. Hackett Park Dog Run, Bronx NY 10471',
  ST_SetSRID(ST_MakePoint(-73.905665046473, 40.90135705164516), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/hackett-park/',
  NULL,
  4.0,
  40,
  NULL,
  false,
  10471,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Kensington Dog Run',
  'Kensington Dog Run, Brooklyn NY 11226',
  ST_SetSRID(ST_MakePoint(-73.9714968265382, 40.64922961677055), 4326),
  '{Seating,Natural Surface}',
  'http://www.prospectpark.org/dogs',
  NULL,
  4.6,
  222,
  'Natural',
  true,
  11226,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Triborough Bridge Playground C Dog Run',
  'Triborough Bridge Playground C Dog Run, Queens NY 11102',
  ST_SetSRID(ST_MakePoint(-73.92203493112896, 40.77402156354413), 4326),
  '{Seating,Asphalt Surface}',
  'https://www.nycgovparks.org/parks/triborough-bridge-playground-c/facilities/dogareas',
  '(212) 639-9675',
  4.5,
  164,
  'Asphalt',
  true,
  11102,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Bronx River Park Dog Run',
  'Bronx River Park Dog Run, Bronx NY 10462',
  ST_SetSRID(ST_MakePoint(-73.8707908532998, 40.855740791041974), 4326),
  '{Seating}',
  'https://www.nycgovparks.org/parks/bronx-park/facilities/dogareas',
  '(212) 639-9675',
  4.5,
  122,
  NULL,
  true,
  10462,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Sirius Dog Run',
  'Sirius Dog Run, Manhattan NY',
  ST_SetSRID(ST_MakePoint(-74.01681166888038, 40.711928554227256), 4326),
  '{}',
  NULL,
  NULL,
  4.7,
  17,
  NULL,
  false,
  NULL,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'West Thames Street Dog Run',
  'West Thames Street Dog Run, Manhattan NY',
  ST_SetSRID(ST_MakePoint(-74.01634094360534, 40.70724611439286), 4326),
  '{}',
  'https://bpca.ny.gov/place/the-west-thames-street-dog-run/',
  NULL,
  4.4,
  32,
  NULL,
  false,
  NULL,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Bellevue South Park Dog Run',
  'Bellevue South Park Dog Run, Manhattan NY',
  ST_SetSRID(ST_MakePoint(-73.97832053294691, 40.74004109591252), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/bellevue-south-park/facilities/dogareas',
  NULL,
  3.8,
  24,
  NULL,
  false,
  NULL,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Ida Court Dog Run',
  'Ida Court Dog Run, Staten Island NY',
  ST_SetSRID(ST_MakePoint(-74.18741640802779, 40.53834544277189), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/ida-court/',
  NULL,
  4.4,
  92,
  NULL,
  false,
  NULL,
  'Staten Island',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Pier 84 Dog Run',
  'Pier 84 Dog Run, Manhattan NY',
  ST_SetSRID(ST_MakePoint(-74.00052945033535, 40.76359559500704), 4326),
  '{}',
  NULL,
  NULL,
  4.3,
  68,
  NULL,
  false,
  NULL,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Tribeca Dog Park',
  'Tribeca Dog Park, Manhattan NY',
  ST_SetSRID(ST_MakePoint(-74.01244630958983, 40.72153555284229), 4326),
  '{}',
  'http://hudsonriverpark.org/',
  '(212) 627-2020',
  4.0,
  40,
  NULL,
  false,
  NULL,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Cooper Park Small Dog Run',
  'Cooper Park Small Dog Run, Brooklyn NY',
  ST_SetSRID(ST_MakePoint(-73.93633586930186, 40.71542350573422), 4326),
  '{Seating,Sand Surface}',
  'https://www.nycgovparks.org/parks/cooper-park/facilities/dogareas',
  NULL,
  4.1,
  50,
  'Sand',
  true,
  NULL,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Cooper Park Large Dog Run',
  'Cooper Park Large Dog Run, Brooklyn NY',
  ST_SetSRID(ST_MakePoint(-73.9361649294871, 40.715467926913306), 4326),
  '{Seating,Sand Surface}',
  'https://www.nycgovparks.org/parks/cooper-park/facilities/dogareas',
  NULL,
  4.1,
  50,
  'Sand',
  true,
  NULL,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Riverside Park South Dog Run',
  'Riverside Park South Dog Run, Manhattan NY',
  ST_SetSRID(ST_MakePoint(-73.98772926764407, 40.78113544925195), 4326),
  '{Seating,Natural Surface}',
  'https://www.nycgovparks.org/parks/riverside-park-south/facilities/dogareas',
  '(212) 639-9675',
  4.7,
  51,
  'Natural',
  true,
  NULL,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Greenwood Playground Dog Run',
  'Greenwood Playground Dog Run, Brooklyn NY 11218',
  ST_SetSRID(ST_MakePoint(-73.97619088044168, 40.649409142603616), 4326),
  '{Natural Surface}',
  NULL,
  NULL,
  3.9,
  26,
  'Natural',
  false,
  11218,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Fox Playground Dog Run',
  'Fox Playground Dog Run, Bronx NY 10455',
  ST_SetSRID(ST_MakePoint(-73.89822371990437, 40.8149567650444), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/fox-playground_bronx/',
  '(212) 639-9675',
  3.6,
  103,
  NULL,
  false,
  10455,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Fort Independence Playground Dog Run',
  'Fort Independence Playground Dog Run, Bronx NY',
  ST_SetSRID(ST_MakePoint(-73.89464998638445, 40.88153523239843), 4326),
  '{Seating}',
  'https://www.nycgovparks.org/parks/fort-independence-playground/',
  '(212) 639-9675',
  4.5,
  261,
  NULL,
  true,
  NULL,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Overlook Dog Park / The Barking Lot',
  'Overlook Dog Park / The Barking Lot, Queens NY',
  ST_SetSRID(ST_MakePoint(-73.83631846029287, 40.71079844104306), 4326),
  '{Natural Surface}',
  'http://www.forestparkbarkinglot.org/',
  NULL,
  4.6,
  575,
  'Natural',
  false,
  NULL,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'East River Esplanade Waterfront Dog Run',
  'East River Esplanade Waterfront Dog Run, Manhattan NY',
  ST_SetSRID(ST_MakePoint(-74.00589950932687, 40.70435656880518), 4326),
  '{Seating,Concrete Surface}',
  'https://www.nycgovparks.org/parks/andrew-haswell-green-park/facilities/dogareas',
  '(212) 639-9675',
  4.5,
  73,
  'Concrete',
  true,
  NULL,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'North End Dog Run',
  'North End Dog Run, Manhattan NY',
  ST_SetSRID(ST_MakePoint(-74.01491960184111, 40.71639499735246), 4326),
  '{Seating}',
  NULL,
  NULL,
  4.5,
  29,
  NULL,
  true,
  NULL,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Robin Kovary Run for Small Dogs',
  'Robin Kovary Run for Small Dogs, Manhattan NY 10011',
  ST_SetSRID(ST_MakePoint(-73.99768480672438, 40.73022459322584), 4326),
  '{Seating,Natural Surface}',
  'http://wspdogrun.org/',
  '(212) 639-9675',
  4.6,
  18,
  'Natural',
  true,
  10011,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Stuyvesant Square Dog Park',
  'Stuyvesant Square Dog Park, Manhattan NY 10003',
  ST_SetSRID(ST_MakePoint(-73.98391986317685, 40.73317315010798), 4326),
  '{Seating,Concrete Surface}',
  'https://www.nycgovparks.org/parks/stuyvesant-square/facilities/dogareas',
  '(212) 639-9675',
  4.5,
  107,
  'Concrete',
  true,
  10003,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Riverside Park Dog Run (W. 142nd St.)',
  'Riverside Park Dog Run (W. 142nd St.), Manhattan NY',
  ST_SetSRID(ST_MakePoint(-73.95441012913086, 40.82518712812843), 4326),
  '{Seating,Natural Surface}',
  'https://riversideparknyc.org/groups/142nd-street-dog-run/',
  '(212) 870-3070',
  4.4,
  188,
  'Natural',
  true,
  NULL,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Soundview Park Dog Run',
  'Soundview Park Dog Run, Bronx NY 10473',
  ST_SetSRID(ST_MakePoint(-73.87748385052834, 40.81894288786234), 4326),
  '{Seating,Sand Surface}',
  'https://www.nycgovparks.org/parks/soundview-park/facilities/dogareas',
  '(212) 639-9675',
  4.2,
  137,
  'Sand',
  true,
  10473,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'St. Mary''s Park Dog Run',
  'St. Mary''''s Park Dog Run, Bronx NY 10454',
  ST_SetSRID(ST_MakePoint(-73.91221621697598, 40.809805717959314), 4326),
  '{Natural Surface}',
  'https://www.nycgovparks.org/parks/st-marys-park/facilities/dogareas',
  '(718) 402-5155',
  4.2,
  330,
  'Natural',
  false,
  10454,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Washington Park Dog Run',
  'Washington Park Dog Run, Brooklyn NY 11215',
  ST_SetSRID(ST_MakePoint(-73.9858087835966, 40.672865284752284), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/washington-skate-park/facilities/dogareas',
  '(212) 639-9675',
  4.0,
  132,
  NULL,
  false,
  11215,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Pier 6 Dog Run',
  'Pier 6 Dog Run, Brooklyn NY 11201',
  ST_SetSRID(ST_MakePoint(-74.00004416122805, 40.692831521200986), 4326),
  '{}',
  'http://www.brooklynbridgepark.org/places/dog-runs-1',
  '(617) 337-0054',
  4.0,
  83,
  NULL,
  false,
  11201,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Hunters Point South Park Dog Run',
  'Hunters Point South Park Dog Run, Queens NY 11101',
  ST_SetSRID(ST_MakePoint(-73.9601116258101, 40.7433999109701), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/hunters-point-south-park/facilities/dogareas',
  '(212) 639-9675',
  4.7,
  187,
  NULL,
  false,
  11101,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Lou Lodati Dog Park',
  'Lou Lodati Dog Park, Queens NY 11104',
  ST_SetSRID(ST_MakePoint(-73.92179626494021, 40.7472127045456), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/torsney-playground/facilities/dogareas',
  '(212) 639-9675',
  4.5,
  172,
  NULL,
  false,
  11104,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Homer''s Dog Run',
  'Homer''''s Dog Run, Manhattan NY 10034',
  ST_SetSRID(ST_MakePoint(-73.92179248756099, 40.87085776914007), 4326),
  '{Natural Surface}',
  'http://www.inwoof.com/',
  NULL,
  4.5,
  41,
  'Natural',
  false,
  10034,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Dog Bone Run',
  'Dog Bone Run, Bronx NY Null',
  ST_SetSRID(ST_MakePoint(-73.88278270889644, 40.88378811994906), 4326),
  '{Concrete Surface}',
  'https://vancortlandt.org/visit/things-to-see-and-do/',
  '(718) 430-1890',
  3.5,
  24,
  'Concrete',
  false,
  Null,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Woodlawn Dog Run',
  'Woodlawn Dog Run, Bronx NY Null',
  ST_SetSRID(ST_MakePoint(-73.87315817379164, 40.89946602067053), 4326),
  '{Natural Surface}',
  'https://vancortlandt.org/visit/things-to-see-and-do/',
  '(718) 430-1890',
  4.5,
  84,
  'Natural',
  false,
  Null,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Canine Court Dog Run',
  'Canine Court Dog Run, Bronx NY 10471',
  ST_SetSRID(ST_MakePoint(-73.895125884814, 40.899071536907506), 4326),
  '{}',
  'https://vancortlandt.org/visit/things-to-see-and-do/',
  '(718) 430-1890',
  4.1,
  88,
  NULL,
  false,
  10471,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Tribeca Dog Run',
  'Tribeca Dog Run, Manhattan NY 10007',
  ST_SetSRID(ST_MakePoint(-74.01227046002407, 40.71618119678133), 4326),
  '{}',
  'http://hudsonriverpark.org/',
  '(212) 627-2020',
  4.0,
  40,
  NULL,
  false,
  10007,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'The Rocky Run',
  'The Rocky Run, Manhattan NY 10032',
  ST_SetSRID(ST_MakePoint(-73.94554819444434, 40.840697885464216), 4326),
  '{Seating,Natural Surface}',
  'https://www.nycgovparks.org/parks/fort-washington-park/facilities/dogareas',
  '(212) 639-9675',
  4.2,
  60,
  'Natural',
  true,
  10032,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'DeWitt Clinton Park Large Dog Run',
  'DeWitt Clinton Park Large Dog Run, Manhattan NY 10019',
  ST_SetSRID(ST_MakePoint(-73.99439430763937, 40.76750808547049), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/de-witt-clinton-park/facilities/dogareas',
  '(212) 639-9675',
  4.5,
  30,
  NULL,
  false,
  10019,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'DeWitt Clinton Park Small Dog Run',
  'DeWitt Clinton Park Small Dog Run, Manhattan NY 10019',
  ST_SetSRID(ST_MakePoint(-73.99448221572271, 40.76769957911417), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/de-witt-clinton-park/facilities/dogareas',
  '(212) 639-9675',
  4.5,
  30,
  NULL,
  false,
  10019,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Brooklyn Bridge Park Dog Run',
  'Brooklyn Bridge Park Dog Run, Brooklyn NY 11201',
  ST_SetSRID(ST_MakePoint(-73.98889097690027, 40.70441291794277), 4326),
  '{}',
  'http://www.nycgovparks.org/parks/brooklyn-bridge-park/facilities/dogareas',
  '(212) 639-9675',
  4.0,
  72,
  NULL,
  false,
  11201,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Williamsbridge Oval Dog Run',
  'Williamsbridge Oval Dog Run, Bronx NY 10467',
  ST_SetSRID(ST_MakePoint(-73.87614217858459, 40.87790618127396), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/williamsbridge-oval/facilities/runningtracks',
  '(212) 639-9675',
  4.5,
  125,
  NULL,
  false,
  10467,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Manhattan Beach Dog Run (Oriental Boulevard)',
  'Manhattan Beach Dog Run (Oriental Boulevard), Brooklyn NY 11235',
  ST_SetSRID(ST_MakePoint(-73.94245483141643, 40.577890512346954), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/manhattan-beach-park/facilities/dogareas',
  '(212) 639-9675',
  4.7,
  361,
  NULL,
  false,
  11235,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Dimattina Park Dog Run - South',
  'Dimattina Park Dog Run - South, Brooklyn NY 11231',
  ST_SetSRID(ST_MakePoint(-74.00305120100298, 40.679928792662544), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/dimattina-playground/facilities/dogareas',
  NULL,
  4.4,
  48,
  NULL,
  false,
  11231,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Maria Hernandez Park Dog Run',
  'Maria Hernandez Park Dog Run, Brooklyn NY 11237',
  ST_SetSRID(ST_MakePoint(-73.92320122229064, 40.703810960334934), 4326),
  '{Seating}',
  'http://mhdogrunpack.com/',
  NULL,
  4.3,
  70,
  NULL,
  true,
  11237,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Sternberg Park Dog Run',
  'Sternberg Park Dog Run, Brooklyn NY 11206',
  ST_SetSRID(ST_MakePoint(-73.94698310879613, 40.70619045019168), 4326),
  '{}',
  NULL,
  NULL,
  2.5,
  22,
  NULL,
  false,
  11206,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Wolfe''s Pond Park Dog Run',
  'Wolfe''''s Pond Park Dog Run, Staten Island NY 10312',
  ST_SetSRID(ST_MakePoint(-74.18503158566556, 40.52001769582299), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/wolfes-pond-park/facilities/dogareas',
  '(212) 639-9675',
  5.0,
  9,
  NULL,
  false,
  10312,
  'Staten Island',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Silver Lake Park Dog Run',
  'Silver Lake Park Dog Run, Staten Island NY 10301',
  ST_SetSRID(ST_MakePoint(-74.0927651355187, 40.626702924414786), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/silver-lake-park/facilities/dogareas',
  '(212) 639-9675',
  4.5,
  337,
  NULL,
  false,
  10301,
  'Staten Island',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Conference House Park Dog Run',
  'Conference House Park Dog Run, Staten Island NY 10307',
  ST_SetSRID(ST_MakePoint(-74.25017430828869, 40.50034706929862), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/conference-house-park/facilities/dogareas',
  '(212) 639-9675',
  4.3,
  26,
  NULL,
  false,
  10307,
  'Staten Island',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Bloomingdale Park Dog Run',
  'Bloomingdale Park Dog Run, Staten Island NY 10309',
  ST_SetSRID(ST_MakePoint(-74.21147028589863, 40.53357681031137), 4326),
  '{Seating,Natural Surface}',
  'https://www.nycgovparks.org/parks/bloomingdale-park/facilities/dogareas',
  '(212) 639-9675',
  4.1,
  21,
  'Natural',
  true,
  10309,
  'Staten Island',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Windmuller Park Dog Run',
  'Windmuller Park Dog Run, Queens NY 11377',
  ST_SetSRID(ST_MakePoint(-73.90852127096527, 40.745833038161955), 4326),
  '{}',
  NULL,
  NULL,
  1.3,
  3,
  NULL,
  false,
  11377,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Veteran''s Grove Dog Run',
  'Veteran''''s Grove Dog Run, Queens NY 11373',
  ST_SetSRID(ST_MakePoint(-73.8777400065793, 40.742484898185374), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/veterans-grove/',
  '(212) 639-9675',
  4.3,
  410,
  NULL,
  false,
  11373,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Underbridge Playground Dog Run',
  'Underbridge Playground Dog Run, Queens NY 11375',
  ST_SetSRID(ST_MakePoint(-73.84490546275457, 40.733665928134094), 4326),
  '{Seating}',
  'https://www.nycgovparks.org/parks/underbridge-dog-run',
  NULL,
  4.1,
  283,
  NULL,
  true,
  11375,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Sherry Park Dog Run',
  'Sherry Park Dog Run, Queens NY 11377',
  ST_SetSRID(ST_MakePoint(-73.89898429225877, 40.74144151575805), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/sherry-dog-run',
  '(212) 639-9675',
  4.4,
  164,
  NULL,
  false,
  11377,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Rockaway Freeway Dog Park',
  'Rockaway Freeway Dog Park, Queens NY 11693',
  ST_SetSRID(ST_MakePoint(-73.80842731417049, 40.59152764843032), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/rockaway-freeway/facilities/dogareas',
  '(212) 639-9675',
  4.4,
  287,
  NULL,
  false,
  11693,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Murray Playground Dog Run',
  'Murray Playground Dog Run, Queens NY 11101',
  ST_SetSRID(ST_MakePoint(-73.94847983136059, 40.74689166833943), 4326),
  '{}',
  'https://www.nycgovparks.org/planning-and-building/capital-project-tracker/project/10436',
  '(212) 639-9675',
  4.0,
  51,
  NULL,
  false,
  11101,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Little Bay Park Dog Run',
  'Little Bay Park Dog Run, Queens NY 11360',
  ST_SetSRID(ST_MakePoint(-73.79284763590378, 40.787944000189384), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/little-bay-park/facilities/dogareas',
  NULL,
  4.4,
  376,
  NULL,
  false,
  11360,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Forest Park Dog Run',
  'Forest Park Dog Run, Queens NY 11385',
  ST_SetSRID(ST_MakePoint(-73.86018266254078, 40.696914748320964), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/forest-park/facilities/dogareas',
  '(718) 235-4151',
  4.2,
  266,
  NULL,
  false,
  11385,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Cunningham Park Dog Run',
  'Cunningham Park Dog Run, Queens NY 11423',
  ST_SetSRID(ST_MakePoint(-73.7755832097389, 40.72648714570865), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/cunningham-park/facilities/dogareas',
  '(212) 639-9675',
  4.4,
  450,
  NULL,
  false,
  11423,
  'Queens',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Washington Square Park Dog Run',
  'Washington Square Park Dog Run, Manhattan NY 10011',
  ST_SetSRID(ST_MakePoint(-73.99849263326139, 40.73079911300472), 4326),
  '{}',
  'http://wspdogrun.org/',
  NULL,
  4.2,
  25,
  NULL,
  false,
  10011,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Union Square Park Dog Run',
  'Union Square Park Dog Run, Manhattan NY 10003',
  ST_SetSRID(ST_MakePoint(-73.99095698122969, 40.73539246410828), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/union-square-park/facilities/dogareas',
  '(212) 639-9675',
  4.3,
  70,
  NULL,
  false,
  10003,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Tompkins Square Park Dog Run',
  'Tompkins Square Park Dog Run, Manhattan NY 10009',
  ST_SetSRID(ST_MakePoint(-73.98141327542261, 40.72645335278598), 4326),
  '{}',
  'http://www.tompkinssquaredogrun.com/',
  NULL,
  4.6,
  105,
  NULL,
  false,
  10009,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Theodore Roosevelt Park Dog Run',
  'Theodore Roosevelt Park Dog Run, Manhattan NY 10024',
  ST_SetSRID(ST_MakePoint(-73.97356522953291, 40.7819726858672), 4326),
  '{}',
  NULL,
  NULL,
  4.5,
  77,
  NULL,
  false,
  10024,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'St. Nicholas Park Dog Run',
  'St. Nicholas Park Dog Run, Manhattan NY 10031',
  ST_SetSRID(ST_MakePoint(-73.94928819447615, 40.817794729838226), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/st-nicholas-park/facilities/dogareas',
  '(212) 639-9675',
  4.5,
  140,
  NULL,
  false,
  10031,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Robert Moses Playground Dog Run',
  'Robert Moses Playground Dog Run, Manhattan NY 10017',
  ST_SetSRID(ST_MakePoint(-73.96882015296923, 40.7481418999281), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/robert-moses-playground/facilities/dogareas',
  '(212) 639-9675',
  3.6,
  21,
  NULL,
  false,
  10017,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Riverside Park Dog Run (72nd St)',
  'Riverside Park Dog Run (72nd St), Manhattan NY 10024',
  ST_SetSRID(ST_MakePoint(-73.98658491354696, 40.781352949592105), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/riverside-park-south/facilities/dogareas',
  '(212) 639-9675',
  4.7,
  51,
  NULL,
  false,
  10024,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Riverside Park Dog Run (87th St)',
  'Riverside Park Dog Run (87th St), Manhattan NY 10024',
  ST_SetSRID(ST_MakePoint(-73.98093357866503, 40.78998674582576), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/riverside-park-south/facilities/dogareas',
  '(212) 639-9675',
  4.7,
  51,
  NULL,
  false,
  10024,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Riverside Park Dog Run (105th St)',
  'Riverside Park Dog Run (105th St), Manhattan NY 10024',
  ST_SetSRID(ST_MakePoint(-73.97144791980544, 40.80271155887992), 4326),
  '{}',
  'https://riversideparknyc.org/place_categories/dog-runs/',
  '(212) 870-3070',
  4.4,
  168,
  NULL,
  false,
  10024,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Peter Detmold Park Dog Run',
  'Peter Detmold Park Dog Run, Manhattan NY 10022',
  ST_SetSRID(ST_MakePoint(-73.96381290702455, 40.753634992308086), 4326),
  '{Seating}',
  NULL,
  NULL,
  4.6,
  31,
  NULL,
  true,
  10022,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Morningside Park Dog Run',
  'Morningside Park Dog Run, Manhattan NY 10026',
  ST_SetSRID(ST_MakePoint(-73.95902744007678, 40.8045142400111), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/morningside-park/facilities/dogareas',
  '(212) 639-9675',
  4.5,
  164,
  NULL,
  false,
  10026,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Thomas Jefferson Park Dog Run',
  'Thomas Jefferson Park Dog Run, Manhattan NY 10029',
  ST_SetSRID(ST_MakePoint(-73.93528895439638, 40.79201479100018), 4326),
  '{}',
  'http://tomsdogrun.com/',
  '(212) 639-9675',
  4.3,
  81,
  NULL,
  false,
  10029,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Marcus Garvey Park Dog Run',
  'Marcus Garvey Park Dog Run, Manhattan NY 10027',
  ST_SetSRID(ST_MakePoint(-73.94342049558139, 40.80282551555144), 4326),
  '{}',
  'http://marcusgarveydogs.org/',
  NULL,
  4.4,
  101,
  NULL,
  false,
  10027,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Madison Square Park Dog Run',
  'Madison Square Park Dog Run, Manhattan NY 10010',
  ST_SetSRID(ST_MakePoint(-73.98877885626241, 40.74210582626826), 4326),
  '{}',
  'http://www.tompkinssquaredogrun.com/',
  NULL,
  4.6,
  105,
  NULL,
  false,
  10010,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'J. Hood Wright Park Dog Run',
  'J. Hood Wright Park Dog Run, Manhattan NY 10033',
  ST_SetSRID(ST_MakePoint(-73.94218065781386, 40.846406995874254), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/j-hood-wright-park/facilities/dogareas',
  NULL,
  4.5,
  234,
  NULL,
  false,
  10033,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Highbridge Park Dog Run',
  'Highbridge Park Dog Run, Manhattan NY 10040',
  ST_SetSRID(ST_MakePoint(-73.92499381237899, 40.85591775325249), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/highbridge-park/facilities/dogareas',
  NULL,
  3.9,
  9,
  NULL,
  false,
  10040,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Fort Tryon Park Dog Run',
  'Fort Tryon Park Dog Run, Manhattan NY 10040',
  ST_SetSRID(ST_MakePoint(-73.93196990995385, 40.86195015593058), 4326),
  '{}',
  'https://www.forttryonparktrust.org/',
  '(212) 795-1388',
  4.7,
  8128,
  NULL,
  false,
  10040,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Fishbridge Garden Dog Run',
  'Fishbridge Garden Dog Run, Manhattan NY 10038',
  ST_SetSRID(ST_MakePoint(-74.0016459156729, 40.70932680472406), 4326),
  '{}',
  'https://www.nycgovparks.org/facilities/dogareas',
  NULL,
  4.5,
  35,
  NULL,
  false,
  10038,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Andrew Haswell Green Dog Run',
  'Andrew Haswell Green Dog Run, Manhattan NY 10065',
  ST_SetSRID(ST_MakePoint(-73.9570668056758, 40.76011094307365), 4326),
  '{Seating}',
  NULL,
  NULL,
  4.3,
  84,
  NULL,
  true,
  10065,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Corlears Hook Park Dog Run',
  'Corlears Hook Park Dog Run, Manhattan NY 10002',
  ST_SetSRID(ST_MakePoint(-73.97947522594801, 40.711855182717855), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/corlears-hook-park/',
  '(212) 639-9675',
  4.3,
  483,
  NULL,
  false,
  10002,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Coleman Oval Park Dog Run',
  'Coleman Oval Park Dog Run, Manhattan NY 10002',
  ST_SetSRID(ST_MakePoint(-73.99349109050381, 40.711169877407166), 4326),
  '{Seating}',
  'https://www.nycgovparks.org/parks/coleman-playground/facilities/dogareas',
  '(212) 639-9675',
  2.5,
  4,
  NULL,
  true,
  10002,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Carl Schurz Park Small Dog Run',
  'Carl Schurz Park Small Dog Run, Manhattan NY 10028',
  ST_SetSRID(ST_MakePoint(-73.94401950747532, 40.7738798386899), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/M081/facilities/dogareas',
  '(212) 639-9675',
  4.7,
  275,
  NULL,
  false,
  10028,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Carl Schurz Park Large Dog Run',
  'Carl Schurz Park Large Dog Run, Manhattan NY 10028',
  ST_SetSRID(ST_MakePoint(-73.94404415590046, 40.774331486213796), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/M081/facilities/dogareas',
  '(212) 639-9675',
  4.7,
  275,
  NULL,
  false,
  10028,
  'Manhattan',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Adam Yauch Park Dog Run',
  'Adam Yauch Park Dog Run, Brooklyn NY 11201',
  ST_SetSRID(ST_MakePoint(-73.99913350399208, 40.692289550539556), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/adam-yauch-park/',
  '(212) 639-9675',
  4.6,
  195,
  NULL,
  false,
  11201,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Owl''s Head Park Dog Run',
  'Owl''''s Head Park Dog Run, Brooklyn NY 11220',
  ST_SetSRID(ST_MakePoint(-74.0351633032459, 40.63994259832214), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/owls-head-park/facilities/dogareas',
  '(212) 639-9675',
  4.4,
  250,
  NULL,
  false,
  11220,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'McGolrick Park Dog Run',
  'McGolrick Park Dog Run, Brooklyn NY 11222',
  ST_SetSRID(ST_MakePoint(-73.94391776901901, 40.723233635862485), 4326),
  '{}',
  NULL,
  NULL,
  4.5,
  79,
  NULL,
  false,
  11222,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'McCarren Park Dog Run',
  'McCarren Park Dog Run, Brooklyn NY 11211',
  ST_SetSRID(ST_MakePoint(-73.95314871585121, 40.71995679300121), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/mccarren-park/facilities/dogareas',
  NULL,
  4.2,
  196,
  NULL,
  false,
  11211,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Hillside Park Dog Run',
  'Hillside Park Dog Run, Brooklyn NY 11201',
  ST_SetSRID(ST_MakePoint(-73.99485938863606, 40.701020594490224), 4326),
  '{}',
  'http://www.nycgovparks.org/parks/hillside-park',
  '(212) 639-9675',
  4.6,
  374,
  NULL,
  false,
  11201,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Herbert Von King Park Dog Run',
  'Herbert Von King Park Dog Run, Brooklyn NY 11216',
  ST_SetSRID(ST_MakePoint(-73.947974331475, 40.689905437981565), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/herbert-von-king-park/facilities/dogareas',
  '(212) 639-9675',
  4.4,
  654,
  NULL,
  false,
  11216,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Dyker Beach Park Dog Run',
  'Dyker Beach Park Dog Run, Brooklyn NY 11228',
  ST_SetSRID(ST_MakePoint(-74.02144864288913, 40.61745541495801), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/dyker-beach-park/facilities/dogareas',
  '(212) 639-9675',
  4.4,
  474,
  NULL,
  false,
  11228,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'DiMattina Park Dog Run - North',
  'DiMattina Park Dog Run - North, Brooklyn NY 11231',
  ST_SetSRID(ST_MakePoint(-74.00242395798611, 40.68108973709557), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/dimattina-playground/facilities/dogareas',
  NULL,
  4.4,
  48,
  NULL,
  false,
  11231,
  'Brooklyn',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Seton Park Dog Run',
  'Seton Park Dog Run, Bronx NY 10471',
  ST_SetSRID(ST_MakePoint(-73.91620919253748, 40.88655336213484), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/seton-park/',
  '(212) 639-9675',
  4.4,
  415,
  NULL,
  false,
  10471,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Pelham Bay Park Dog Run',
  'Pelham Bay Park Dog Run, Bronx NY 10465',
  ST_SetSRID(ST_MakePoint(-73.82126657937096, 40.850532214468906), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/pelham-bay-park/facilities/dogareas',
  '(212) 639-9675',
  4.7,
  150,
  NULL,
  false,
  10465,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Franz Sigel Park Dog Run',
  'Franz Sigel Park Dog Run, Bronx NY 10451',
  ST_SetSRID(ST_MakePoint(-73.92601378337277, 40.822998298398), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/franz-sigel-park/facilities/dogareas',
  '(212) 639-9675',
  4.2,
  52,
  NULL,
  false,
  10451,
  'Bronx',
  NOW(),
  NOW()
);

INSERT INTO dog_parks (name, address, location, amenities, website, phone, rating, review_count, surface_type, has_seating, zipcode, borough, created_at, updated_at) VALUES (
  'Ewen Park Dog Run',
  'Ewen Park Dog Run, Bronx NY 10463',
  ST_SetSRID(ST_MakePoint(-73.91023102260864, 40.88216985427035), 4326),
  '{}',
  'https://www.nycgovparks.org/parks/ewen-park/facilities/dogareas',
  NULL,
  5.0,
  6,
  NULL,
  false,
  10463,
  'Bronx',
  NOW(),
  NOW()
);

COMMIT;

-- Add migration tracking
INSERT INTO schema_migrations (version, applied_at) VALUES ('004_complete_nyc_parks', NOW()) ON CONFLICT (version) DO NOTHING;