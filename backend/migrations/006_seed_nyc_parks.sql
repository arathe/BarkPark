-- NYC Dog Runs Import
-- Generated from dog_runs_enriched.csv

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Frank Decolvenaere Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Frank Decolvenaere Dog Run, New York, NY 11209', ST_MakePoint(-74.03650678412465, 40.612313897294925)::geography,
    '{"Synthetic surface","Seating available","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '21:00:00',
    'https://www.nycgovparks.org/parks/shore-park-and-parkway/facilities/dogareas',
    '(212) 639-9675',
    4.8,
    9,
    'Synthetic',
    True,
    '11209',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Frank S. Hackett Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Frank S. Hackett Park Dog Run, New York, NY 10471', ST_MakePoint(-73.905665046473, 40.90135705164516)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/hackett-park/',
    NULL,
    4.0,
    40,
    NULL,
    NULL,
    '10471',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Kensington Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Kensington Dog Run, New York, NY 11226', ST_MakePoint(-73.9714968265382, 40.64922961677055)::geography,
    '{"Natural surface","Seating available","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '22:00:00',
    'http://www.prospectpark.org/dogs',
    NULL,
    4.6,
    222,
    'Natural',
    True,
    '11226',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Triborough Bridge Playground C Dog Run',
    'NYC Parks Department dog run in Queens',
    'Triborough Bridge Playground C Dog Run, New York, NY 11102', ST_MakePoint(-73.92203493112895, 40.77402156354413)::geography,
    '{"Asphalt surface","Seating available","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '21:00:00',
    'https://www.nycgovparks.org/parks/triborough-bridge-playground-c/facilities/dogareas',
    '(212) 639-9675',
    4.5,
    164,
    'Asphalt',
    True,
    '11102',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Bronx River Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Bronx River Park Dog Run, New York, NY 10462', ST_MakePoint(-73.8707908532998, 40.85574079104197)::geography,
    '{"Seating available","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/bronx-park/facilities/dogareas',
    '(212) 639-9675',
    4.5,
    122,
    NULL,
    True,
    '10462',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Sirius Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Sirius Dog Run, New York, NY nan', ST_MakePoint(-74.01681166888038, 40.711928554227256)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    NULL,
    NULL,
    4.7,
    17,
    NULL,
    NULL,
    NULL,
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'West Thames Street Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'West Thames Street Dog Run, New York, NY nan', ST_MakePoint(-74.01634094360534, 40.70724611439286)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://bpca.ny.gov/place/the-west-thames-street-dog-run/',
    NULL,
    4.4,
    32,
    NULL,
    NULL,
    NULL,
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Bellevue South Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Bellevue South Park Dog Run, New York, NY nan', ST_MakePoint(-73.97832053294691, 40.740041095912524)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '09:00:00',
    '18:00:00',
    'https://www.nycgovparks.org/parks/bellevue-south-park/facilities/dogareas',
    NULL,
    3.8,
    24,
    NULL,
    NULL,
    NULL,
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Ida Court Dog Run',
    'NYC Parks Department dog run in Staten Island',
    'Ida Court Dog Run, New York, NY nan', ST_MakePoint(-74.1874164080278, 40.53834544277189)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '21:00:00',
    'https://www.nycgovparks.org/parks/ida-court/',
    NULL,
    4.4,
    92,
    NULL,
    NULL,
    NULL,
    'Staten Island',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Pier 84 Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Pier 84 Dog Run, New York, NY nan', ST_MakePoint(-74.00052945033534, 40.76359559500704)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    NULL,
    NULL,
    4.3,
    68,
    NULL,
    NULL,
    NULL,
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Tribeca Dog Park',
    'NYC Parks Department dog run in Manhattan',
    'Tribeca Dog Park, New York, NY nan', ST_MakePoint(-74.01244630958982, 40.72153555284229)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'http://hudsonriverpark.org/',
    '(212) 627-2020',
    4.0,
    40,
    NULL,
    NULL,
    NULL,
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Cooper Park Small Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Cooper Park Small Dog Run, New York, NY nan', ST_MakePoint(-73.93633586930186, 40.71542350573422)::geography,
    '{"Sand surface","Seating available"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/cooper-park/facilities/dogareas',
    NULL,
    4.1,
    50,
    'Sand',
    True,
    NULL,
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Cooper Park Large Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Cooper Park Large Dog Run, New York, NY nan', ST_MakePoint(-73.93616492948709, 40.715467926913306)::geography,
    '{"Sand surface","Seating available"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/cooper-park/facilities/dogareas',
    NULL,
    4.1,
    50,
    'Sand',
    True,
    NULL,
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Riverside Park South Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Riverside Park South Dog Run, New York, NY nan', ST_MakePoint(-73.98772926764406, 40.781135449251956)::geography,
    '{"Natural surface","Seating available","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/riverside-park-south/facilities/dogareas',
    '(212) 639-9675',
    4.7,
    51,
    'Natural',
    True,
    NULL,
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Greenwood Playground Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Greenwood Playground Dog Run, New York, NY 11218', ST_MakePoint(-73.97619088044168, 40.649409142603616)::geography,
    '{"Natural surface"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    NULL,
    NULL,
    3.9,
    26,
    'Natural',
    NULL,
    '11218',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Fox Playground Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Fox Playground Dog Run, New York, NY 10455', ST_MakePoint(-73.89822371990438, 40.8149567650444)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '07:00:00',
    '18:00:00',
    'https://www.nycgovparks.org/parks/fox-playground_bronx/',
    '(212) 639-9675',
    3.6,
    103,
    NULL,
    NULL,
    '10455',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Fort Independence Playground Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Fort Independence Playground Dog Run, New York, NY nan', ST_MakePoint(-73.89464998638445, 40.88153523239843)::geography,
    '{"Seating available","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '07:00:00',
    '18:00:00',
    'https://www.nycgovparks.org/parks/fort-independence-playground/',
    '(212) 639-9675',
    4.5,
    261,
    NULL,
    True,
    NULL,
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Overlook Dog Park / The Barking Lot',
    'NYC Parks Department dog run in Queens',
    'Overlook Dog Park / The Barking Lot, New York, NY nan', ST_MakePoint(-73.83631846029287, 40.71079844104306)::geography,
    '{"Natural surface","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '21:00:00',
    'http://www.forestparkbarkinglot.org/',
    NULL,
    4.6,
    575,
    'Natural',
    NULL,
    NULL,
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'East River Esplanade Waterfront Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'East River Esplanade Waterfront Dog Run, New York, NY nan', ST_MakePoint(-74.00589950932688, 40.70435656880518)::geography,
    '{"Concrete surface","Seating available","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'https://www.nycgovparks.org/parks/andrew-haswell-green-park/facilities/dogareas',
    '(212) 639-9675',
    4.5,
    73,
    'Concrete',
    True,
    NULL,
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'North End Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'North End Dog Run, New York, NY nan', ST_MakePoint(-74.0149196018411, 40.71639499735246)::geography,
    '{"Seating available","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    NULL,
    NULL,
    4.5,
    29,
    NULL,
    True,
    NULL,
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Robin Kovary Run for Small Dogs',
    'NYC Parks Department dog run in Manhattan',
    'Robin Kovary Run for Small Dogs, New York, NY 10011', ST_MakePoint(-73.99768480672438, 40.73022459322584)::geography,
    '{"Natural surface","Seating available","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'http://wspdogrun.org/',
    '(212) 639-9675',
    4.6,
    18,
    'Natural',
    True,
    '10011',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Stuyvesant Square Dog Park',
    'NYC Parks Department dog run in Manhattan',
    'Stuyvesant Square Dog Park, New York, NY 10003', ST_MakePoint(-73.98391986317684, 40.73317315010797)::geography,
    '{"Concrete surface","Seating available","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '07:00:00',
    '23:00:00',
    'https://www.nycgovparks.org/parks/stuyvesant-square/facilities/dogareas',
    '(212) 639-9675',
    4.5,
    107,
    'Concrete',
    True,
    '10003',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Riverside Park Dog Run (W. 142nd St.)',
    'NYC Parks Department dog run in Manhattan',
    'Riverside Park Dog Run (W. 142nd St.), New York, NY nan', ST_MakePoint(-73.95441012913086, 40.82518712812843)::geography,
    '{"Natural surface","Seating available"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://riversideparknyc.org/groups/142nd-street-dog-run/',
    '(212) 870-3070',
    4.4,
    188,
    'Natural',
    True,
    NULL,
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Soundview Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Soundview Park Dog Run, New York, NY 10473', ST_MakePoint(-73.87748385052835, 40.81894288786234)::geography,
    '{"Sand surface","Seating available"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/soundview-park/facilities/dogareas',
    '(212) 639-9675',
    4.2,
    137,
    'Sand',
    True,
    '10473',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'St. Mary''s Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'St. Mary''s Park Dog Run, New York, NY 10454', ST_MakePoint(-73.91221621697598, 40.809805717959314)::geography,
    '{"Natural surface"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '22:00:00',
    'https://www.nycgovparks.org/parks/st-marys-park/facilities/dogareas',
    '(718) 402-5155',
    4.2,
    330,
    'Natural',
    False,
    '10454',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Washington Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Washington Park Dog Run, New York, NY 11215', ST_MakePoint(-73.9858087835966, 40.67286528475229)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'https://www.nycgovparks.org/parks/washington-skate-park/facilities/dogareas',
    '(212) 639-9675',
    4.0,
    132,
    NULL,
    NULL,
    '11215',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Pier 6 Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Pier 6 Dog Run, New York, NY 11201', ST_MakePoint(-74.00004416122805, 40.692831521200986)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:30:00',
    '22:00:00',
    'http://www.brooklynbridgepark.org/places/dog-runs-1',
    '(617) 337-0054',
    4.0,
    83,
    NULL,
    NULL,
    '11201',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Hunters Point South Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Hunters Point South Park Dog Run, New York, NY 11101', ST_MakePoint(-73.96011162581009, 40.743399910970105)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:30:00',
    '22:00:00',
    'https://www.nycgovparks.org/parks/hunters-point-south-park/facilities/dogareas',
    '(212) 639-9675',
    4.7,
    187,
    NULL,
    NULL,
    '11101',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Lou Lodati Dog Park',
    'NYC Parks Department dog run in Queens',
    'Lou Lodati Dog Park, New York, NY 11104', ST_MakePoint(-73.9217962649402, 40.7472127045456)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/torsney-playground/facilities/dogareas',
    '(212) 639-9675',
    4.5,
    172,
    NULL,
    NULL,
    '11104',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Homer''s Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Homer''s Dog Run, New York, NY 10034', ST_MakePoint(-73.92179248756099, 40.87085776914007)::geography,
    '{"Natural surface","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'http://www.inwoof.com/',
    NULL,
    4.5,
    41,
    'Natural',
    NULL,
    '10034',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Dog Bone Run',
    'NYC Parks Department dog run in Bronx',
    'Dog Bone Run, New York, NY Null', ST_MakePoint(-73.88278270889644, 40.88378811994907)::geography,
    '{"Concrete surface"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://vancortlandt.org/visit/things-to-see-and-do/',
    '(718) 430-1890',
    3.5,
    24,
    'Concrete',
    NULL,
    'Null',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Woodlawn Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Woodlawn Dog Run, New York, NY Null', ST_MakePoint(-73.87315817379164, 40.89946602067053)::geography,
    '{"Natural surface","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://vancortlandt.org/visit/things-to-see-and-do/',
    '(718) 430-1890',
    4.5,
    84,
    'Natural',
    NULL,
    'Null',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Canine Court Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Canine Court Dog Run, New York, NY 10471', ST_MakePoint(-73.895125884814, 40.899071536907506)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '22:00:00',
    'https://vancortlandt.org/visit/things-to-see-and-do/',
    '(718) 430-1890',
    4.1,
    88,
    NULL,
    NULL,
    '10471',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Tribeca Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Tribeca Dog Run, New York, NY 10007', ST_MakePoint(-74.01227046002406, 40.71618119678133)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'http://hudsonriverpark.org/',
    '(212) 627-2020',
    4.0,
    40,
    NULL,
    NULL,
    '10007',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'The Rocky Run',
    'NYC Parks Department dog run in Manhattan',
    'The Rocky Run, New York, NY 10032', ST_MakePoint(-73.94554819444434, 40.84069788546422)::geography,
    '{"Natural surface","Seating available"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'https://www.nycgovparks.org/parks/fort-washington-park/facilities/dogareas',
    '(212) 639-9675',
    4.2,
    60,
    'Natural',
    True,
    '10032',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'DeWitt Clinton Park Large Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'DeWitt Clinton Park Large Dog Run, New York, NY 10019', ST_MakePoint(-73.99439430763938, 40.76750808547049)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/de-witt-clinton-park/facilities/dogareas',
    '(212) 639-9675',
    4.5,
    30,
    NULL,
    NULL,
    '10019',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'DeWitt Clinton Park Small Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'DeWitt Clinton Park Small Dog Run, New York, NY 10019', ST_MakePoint(-73.9944822157227, 40.76769957911417)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/de-witt-clinton-park/facilities/dogareas',
    '(212) 639-9675',
    4.5,
    30,
    NULL,
    NULL,
    '10019',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Brooklyn Bridge Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Brooklyn Bridge Park Dog Run, New York, NY 11201', ST_MakePoint(-73.98889097690027, 40.70441291794277)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'http://www.nycgovparks.org/parks/brooklyn-bridge-park/facilities/dogareas',
    '(212) 639-9675',
    4.0,
    72,
    NULL,
    NULL,
    '11201',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Williamsbridge Oval Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Williamsbridge Oval Dog Run, New York, NY 10467', ST_MakePoint(-73.8761421785846, 40.877906181273964)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/williamsbridge-oval/facilities/runningtracks',
    '(212) 639-9675',
    4.5,
    125,
    NULL,
    NULL,
    '10467',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Manhattan Beach Dog Run (Oriental Boulevard)',
    'NYC Parks Department dog run in Brooklyn',
    'Manhattan Beach Dog Run (Oriental Boulevard), New York, NY 11235', ST_MakePoint(-73.94245483141644, 40.57789051234696)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '21:00:00',
    'https://www.nycgovparks.org/parks/manhattan-beach-park/facilities/dogareas',
    '(212) 639-9675',
    4.7,
    361,
    NULL,
    NULL,
    '11235',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Dimattina Park Dog Run - South',
    'NYC Parks Department dog run in Brooklyn',
    'Dimattina Park Dog Run - South, New York, NY 11231', ST_MakePoint(-74.00305120100299, 40.67992879266255)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/dimattina-playground/facilities/dogareas',
    NULL,
    4.4,
    48,
    NULL,
    NULL,
    '11231',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Maria Hernandez Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Maria Hernandez Park Dog Run, New York, NY 11237', ST_MakePoint(-73.92320122229064, 40.70381096033493)::geography,
    '{"Seating available"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'http://mhdogrunpack.com/',
    NULL,
    4.3,
    70,
    NULL,
    True,
    '11237',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Sternberg Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Sternberg Park Dog Run, New York, NY 11206', ST_MakePoint(-73.94698310879613, 40.70619045019168)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    NULL,
    NULL,
    2.5,
    22,
    NULL,
    NULL,
    '11206',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Wolfe''s Pond Park Dog Run',
    'NYC Parks Department dog run in Staten Island',
    'Wolfe''s Pond Park Dog Run, New York, NY 10312', ST_MakePoint(-74.18503158566556, 40.52001769582299)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/wolfes-pond-park/facilities/dogareas',
    '(212) 639-9675',
    5.0,
    9,
    NULL,
    NULL,
    '10312',
    'Staten Island',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Silver Lake Park Dog Run',
    'NYC Parks Department dog run in Staten Island',
    'Silver Lake Park Dog Run, New York, NY 10301', ST_MakePoint(-74.0927651355187, 40.626702924414786)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'https://www.nycgovparks.org/parks/silver-lake-park/facilities/dogareas',
    '(212) 639-9675',
    4.5,
    337,
    NULL,
    NULL,
    '10301',
    'Staten Island',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Conference House Park Dog Run',
    'NYC Parks Department dog run in Staten Island',
    'Conference House Park Dog Run, New York, NY 10307', ST_MakePoint(-74.25017430828869, 40.50034706929861)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/conference-house-park/facilities/dogareas',
    '(212) 639-9675',
    4.3,
    26,
    NULL,
    NULL,
    '10307',
    'Staten Island',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Bloomingdale Park Dog Run',
    'NYC Parks Department dog run in Staten Island',
    'Bloomingdale Park Dog Run, New York, NY 10309', ST_MakePoint(-74.21147028589863, 40.53357681031137)::geography,
    '{"Natural surface","Seating available"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/bloomingdale-park/facilities/dogareas',
    '(212) 639-9675',
    4.1,
    21,
    'Natural',
    True,
    '10309',
    'Staten Island',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Windmuller Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Windmuller Park Dog Run, New York, NY 11377', ST_MakePoint(-73.90852127096527, 40.74583303816196)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    NULL,
    NULL,
    1.3,
    3,
    NULL,
    NULL,
    '11377',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Veteran''s Grove Dog Run',
    'NYC Parks Department dog run in Queens',
    'Veteran''s Grove Dog Run, New York, NY 11373', ST_MakePoint(-73.87774000657929, 40.742484898185374)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '21:00:00',
    'https://www.nycgovparks.org/parks/veterans-grove/',
    '(212) 639-9675',
    4.3,
    410,
    NULL,
    NULL,
    '11373',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Underbridge Playground Dog Run',
    'NYC Parks Department dog run in Queens',
    'Underbridge Playground Dog Run, New York, NY 11375', ST_MakePoint(-73.84490546275457, 40.733665928134094)::geography,
    '{"Seating available"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '21:00:00',
    'https://www.nycgovparks.org/parks/underbridge-dog-run',
    NULL,
    4.1,
    283,
    NULL,
    True,
    '11375',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Sherry Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Sherry Park Dog Run, New York, NY 11377', ST_MakePoint(-73.89898429225877, 40.74144151575805)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '21:00:00',
    'https://www.nycgovparks.org/parks/sherry-dog-run',
    '(212) 639-9675',
    4.4,
    164,
    NULL,
    NULL,
    '11377',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Rockaway Freeway Dog Park',
    'NYC Parks Department dog run in Queens',
    'Rockaway Freeway Dog Park, New York, NY 11693', ST_MakePoint(-73.80842731417049, 40.59152764843032)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '21:00:00',
    'https://www.nycgovparks.org/parks/rockaway-freeway/facilities/dogareas',
    '(212) 639-9675',
    4.4,
    287,
    NULL,
    NULL,
    '11693',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Murray Playground Dog Run',
    'NYC Parks Department dog run in Queens',
    'Murray Playground Dog Run, New York, NY 11101', ST_MakePoint(-73.9484798313606, 40.74689166833943)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/planning-and-building/capital-project-tracker/project/10436',
    '(212) 639-9675',
    4.0,
    51,
    NULL,
    NULL,
    '11101',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Little Bay Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Little Bay Park Dog Run, New York, NY 11360', ST_MakePoint(-73.79284763590378, 40.78794400018938)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '22:00:00',
    'https://www.nycgovparks.org/parks/little-bay-park/facilities/dogareas',
    NULL,
    4.4,
    376,
    NULL,
    NULL,
    '11360',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Forest Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Forest Park Dog Run, New York, NY 11385', ST_MakePoint(-73.86018266254078, 40.696914748320964)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '09:00:00',
    '21:00:00',
    'https://www.nycgovparks.org/parks/forest-park/facilities/dogareas',
    '(718) 235-4151',
    4.2,
    266,
    NULL,
    NULL,
    '11385',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Cunningham Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Cunningham Park Dog Run, New York, NY 11423', ST_MakePoint(-73.7755832097389, 40.726487145708646)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '20:00:00',
    'https://www.nycgovparks.org/parks/cunningham-park/facilities/dogareas',
    '(212) 639-9675',
    4.4,
    450,
    NULL,
    NULL,
    '11423',
    'Queens',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Washington Square Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Washington Square Park Dog Run, New York, NY 10011', ST_MakePoint(-73.99849263326139, 40.73079911300472)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'http://wspdogrun.org/',
    NULL,
    4.2,
    25,
    NULL,
    NULL,
    '10011',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Union Square Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Union Square Park Dog Run, New York, NY 10003', ST_MakePoint(-73.99095698122969, 40.73539246410828)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/union-square-park/facilities/dogareas',
    '(212) 639-9675',
    4.3,
    70,
    NULL,
    NULL,
    '10003',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Tompkins Square Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Tompkins Square Park Dog Run, New York, NY 10009', ST_MakePoint(-73.98141327542261, 40.72645335278598)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '23:00:00',
    'http://www.tompkinssquaredogrun.com/',
    NULL,
    4.6,
    105,
    NULL,
    NULL,
    '10009',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Theodore Roosevelt Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Theodore Roosevelt Park Dog Run, New York, NY 10024', ST_MakePoint(-73.97356522953291, 40.7819726858672)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '22:00:00',
    NULL,
    NULL,
    4.5,
    77,
    NULL,
    NULL,
    '10024',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'St. Nicholas Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'St. Nicholas Park Dog Run, New York, NY 10031', ST_MakePoint(-73.94928819447615, 40.817794729838226)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '22:00:00',
    'https://www.nycgovparks.org/parks/st-nicholas-park/facilities/dogareas',
    '(212) 639-9675',
    4.5,
    140,
    NULL,
    NULL,
    '10031',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Robert Moses Playground Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Robert Moses Playground Dog Run, New York, NY 10017', ST_MakePoint(-73.96882015296923, 40.7481418999281)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/robert-moses-playground/facilities/dogareas',
    '(212) 639-9675',
    3.6,
    21,
    NULL,
    NULL,
    '10017',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Riverside Park Dog Run (72nd St)',
    'NYC Parks Department dog run in Manhattan',
    'Riverside Park Dog Run (72nd St), New York, NY 10024', ST_MakePoint(-73.98658491354695, 40.7813529495921)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/riverside-park-south/facilities/dogareas',
    '(212) 639-9675',
    4.7,
    51,
    NULL,
    NULL,
    '10024',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Riverside Park Dog Run (87th St)',
    'NYC Parks Department dog run in Manhattan',
    'Riverside Park Dog Run (87th St), New York, NY 10024', ST_MakePoint(-73.98093357866503, 40.78998674582576)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/riverside-park-south/facilities/dogareas',
    '(212) 639-9675',
    4.7,
    51,
    NULL,
    NULL,
    '10024',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Riverside Park Dog Run (105th St)',
    'NYC Parks Department dog run in Manhattan',
    'Riverside Park Dog Run (105th St), New York, NY 10024', ST_MakePoint(-73.97144791980544, 40.80271155887992)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://riversideparknyc.org/place_categories/dog-runs/',
    '(212) 870-3070',
    4.4,
    168,
    NULL,
    NULL,
    '10024',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Peter Detmold Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Peter Detmold Park Dog Run, New York, NY 10022', ST_MakePoint(-73.96381290702455, 40.75363499230809)::geography,
    '{"Seating available","Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    NULL,
    NULL,
    4.6,
    31,
    NULL,
    True,
    '10022',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Morningside Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Morningside Park Dog Run, New York, NY 10026', ST_MakePoint(-73.95902744007678, 40.8045142400111)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'https://www.nycgovparks.org/parks/morningside-park/facilities/dogareas',
    '(212) 639-9675',
    4.5,
    164,
    NULL,
    NULL,
    '10026',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Thomas Jefferson Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Thomas Jefferson Park Dog Run, New York, NY 10029', ST_MakePoint(-73.93528895439637, 40.79201479100018)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'http://tomsdogrun.com/',
    '(212) 639-9675',
    4.3,
    81,
    NULL,
    NULL,
    '10029',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Marcus Garvey Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Marcus Garvey Park Dog Run, New York, NY 10027', ST_MakePoint(-73.94342049558139, 40.80282551555144)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '22:00:00',
    'http://marcusgarveydogs.org/',
    NULL,
    4.4,
    101,
    NULL,
    NULL,
    '10027',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Madison Square Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Madison Square Park Dog Run, New York, NY 10010', ST_MakePoint(-73.98877885626241, 40.74210582626826)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '23:00:00',
    'http://www.tompkinssquaredogrun.com/',
    NULL,
    4.6,
    105,
    NULL,
    NULL,
    '10010',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'J. Hood Wright Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'J. Hood Wright Park Dog Run, New York, NY 10033', ST_MakePoint(-73.94218065781386, 40.846406995874254)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '23:00:00',
    'https://www.nycgovparks.org/parks/j-hood-wright-park/facilities/dogareas',
    NULL,
    4.5,
    234,
    NULL,
    NULL,
    '10033',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Highbridge Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Highbridge Park Dog Run, New York, NY 10040', ST_MakePoint(-73.92499381237899, 40.85591775325249)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/highbridge-park/facilities/dogareas',
    NULL,
    3.9,
    9,
    NULL,
    NULL,
    '10040',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Fort Tryon Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Fort Tryon Park Dog Run, New York, NY 10040', ST_MakePoint(-73.93196990995384, 40.86195015593058)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'https://www.forttryonparktrust.org/',
    '(212) 795-1388',
    4.7,
    8128,
    NULL,
    NULL,
    '10040',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Fishbridge Garden Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Fishbridge Garden Dog Run, New York, NY 10038', ST_MakePoint(-74.00164591567291, 40.709326804724064)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/facilities/dogareas',
    NULL,
    4.5,
    35,
    NULL,
    NULL,
    '10038',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Andrew Haswell Green Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Andrew Haswell Green Dog Run, New York, NY 10065', ST_MakePoint(-73.9570668056758, 40.76011094307365)::geography,
    '{"Seating available"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    NULL,
    NULL,
    4.3,
    84,
    NULL,
    True,
    '10065',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Corlears Hook Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Corlears Hook Park Dog Run, New York, NY 10002', ST_MakePoint(-73.97947522594802, 40.711855182717855)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'https://www.nycgovparks.org/parks/corlears-hook-park/',
    '(212) 639-9675',
    4.3,
    483,
    NULL,
    NULL,
    '10002',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Coleman Oval Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Coleman Oval Park Dog Run, New York, NY 10002', ST_MakePoint(-73.99349109050382, 40.71116987740717)::geography,
    '{"Seating available"}',
    'Please follow NYC Parks Department rules and regulations',
    '07:00:00',
    '18:00:00',
    'https://www.nycgovparks.org/parks/coleman-playground/facilities/dogareas',
    '(212) 639-9675',
    2.5,
    4,
    NULL,
    True,
    '10002',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Carl Schurz Park Small Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Carl Schurz Park Small Dog Run, New York, NY 10028', ST_MakePoint(-73.9440195074753, 40.7738798386899)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '00:00:00',
    'https://www.nycgovparks.org/parks/M081/facilities/dogareas',
    '(212) 639-9675',
    4.7,
    275,
    NULL,
    NULL,
    '10028',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Carl Schurz Park Large Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Carl Schurz Park Large Dog Run, New York, NY 10028', ST_MakePoint(-73.94404415590044, 40.774331486213796)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '00:00:00',
    'https://www.nycgovparks.org/parks/M081/facilities/dogareas',
    '(212) 639-9675',
    4.7,
    275,
    NULL,
    NULL,
    '10028',
    'Manhattan',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Adam Yauch Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Adam Yauch Park Dog Run, New York, NY 11201', ST_MakePoint(-73.99913350399208, 40.69228955053956)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/adam-yauch-park/',
    '(212) 639-9675',
    4.6,
    195,
    NULL,
    NULL,
    '11201',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Owl''s Head Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Owl''s Head Park Dog Run, New York, NY 11220', ST_MakePoint(-74.03516330324591, 40.639942598322136)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '21:00:00',
    'https://www.nycgovparks.org/parks/owls-head-park/facilities/dogareas',
    '(212) 639-9675',
    4.4,
    250,
    NULL,
    NULL,
    '11220',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'McGolrick Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'McGolrick Park Dog Run, New York, NY 11222', ST_MakePoint(-73.94391776901901, 40.72323363586249)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    NULL,
    NULL,
    4.5,
    79,
    NULL,
    NULL,
    '11222',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'McCarren Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'McCarren Park Dog Run, New York, NY 11211', ST_MakePoint(-73.9531487158512, 40.71995679300122)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/mccarren-park/facilities/dogareas',
    NULL,
    4.2,
    196,
    NULL,
    NULL,
    '11211',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Hillside Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Hillside Park Dog Run, New York, NY 11201', ST_MakePoint(-73.99485938863606, 40.70102059449023)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'http://www.nycgovparks.org/parks/hillside-park',
    '(212) 639-9675',
    4.6,
    374,
    NULL,
    NULL,
    '11201',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Herbert Von King Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Herbert Von King Park Dog Run, New York, NY 11216', ST_MakePoint(-73.947974331475, 40.68990543798157)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'https://www.nycgovparks.org/parks/herbert-von-king-park/facilities/dogareas',
    '(212) 639-9675',
    4.4,
    654,
    NULL,
    NULL,
    '11216',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Dyker Beach Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Dyker Beach Park Dog Run, New York, NY 11228', ST_MakePoint(-74.02144864288913, 40.61745541495801)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '01:00:00',
    'https://www.nycgovparks.org/parks/dyker-beach-park/facilities/dogareas',
    '(212) 639-9675',
    4.4,
    474,
    NULL,
    NULL,
    '11228',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'DiMattina Park Dog Run - North',
    'NYC Parks Department dog run in Brooklyn',
    'DiMattina Park Dog Run - North, New York, NY 11231', ST_MakePoint(-74.00242395798611, 40.68108973709557)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    NULL,
    NULL,
    'https://www.nycgovparks.org/parks/dimattina-playground/facilities/dogareas',
    NULL,
    4.4,
    48,
    NULL,
    NULL,
    '11231',
    'Brooklyn',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Seton Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Seton Park Dog Run, New York, NY 10471', ST_MakePoint(-73.9162091925375, 40.88655336213484)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '22:00:00',
    'https://www.nycgovparks.org/parks/seton-park/',
    '(212) 639-9675',
    4.4,
    415,
    NULL,
    NULL,
    '10471',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Pelham Bay Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Pelham Bay Park Dog Run, New York, NY 10465', ST_MakePoint(-73.82126657937096, 40.850532214468906)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '22:00:00',
    'https://www.nycgovparks.org/parks/pelham-bay-park/facilities/dogareas',
    '(212) 639-9675',
    4.7,
    150,
    NULL,
    NULL,
    '10465',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Franz Sigel Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Franz Sigel Park Dog Run, New York, NY 10451', ST_MakePoint(-73.92601378337277, 40.822998298398)::geography,
    NULL,
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '22:00:00',
    'https://www.nycgovparks.org/parks/franz-sigel-park/facilities/dogareas',
    '(212) 639-9675',
    4.2,
    52,
    NULL,
    NULL,
    '10451',
    'Bronx',
    NOW(),
    NOW()
);

INSERT INTO dog_parks (
    name, description, address, location, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Ewen Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Ewen Park Dog Run, New York, NY 10463', ST_MakePoint(-73.91023102260864, 40.88216985427035)::geography,
    '{"Highly rated"}',
    'Please follow NYC Parks Department rules and regulations',
    '06:00:00',
    '22:00:00',
    'https://www.nycgovparks.org/parks/ewen-park/facilities/dogareas',
    NULL,
    5.0,
    6,
    NULL,
    NULL,
    '10463',
    'Bronx',
    NOW(),
    NOW()
);
