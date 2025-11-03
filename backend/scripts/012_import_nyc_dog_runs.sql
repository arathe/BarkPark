-- NYC Dog Runs Import
-- Generated from dog_runs_enriched.csv

INSERT INTO dog_parks (
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Frank Decolvenaere Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Frank Decolvenaere Dog Run, New York, NY 11209',
    40.612313897294925,
    -74.03650678412465,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Frank S. Hackett Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Frank S. Hackett Park Dog Run, New York, NY 10471',
    40.90135705164516,
    -73.905665046473,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Kensington Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Kensington Dog Run, New York, NY 11226',
    40.64922961677055,
    -73.9714968265382,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Triborough Bridge Playground C Dog Run',
    'NYC Parks Department dog run in Queens',
    'Triborough Bridge Playground C Dog Run, New York, NY 11102',
    40.77402156354413,
    -73.92203493112895,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Bronx River Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Bronx River Park Dog Run, New York, NY 10462',
    40.85574079104197,
    -73.8707908532998,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Sirius Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Sirius Dog Run, New York, NY nan',
    40.711928554227256,
    -74.01681166888038,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'West Thames Street Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'West Thames Street Dog Run, New York, NY nan',
    40.70724611439286,
    -74.01634094360534,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Bellevue South Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Bellevue South Park Dog Run, New York, NY nan',
    40.740041095912524,
    -73.97832053294691,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Ida Court Dog Run',
    'NYC Parks Department dog run in Staten Island',
    'Ida Court Dog Run, New York, NY nan',
    40.53834544277189,
    -74.1874164080278,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Pier 84 Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Pier 84 Dog Run, New York, NY nan',
    40.76359559500704,
    -74.00052945033534,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Tribeca Dog Park',
    'NYC Parks Department dog run in Manhattan',
    'Tribeca Dog Park, New York, NY nan',
    40.72153555284229,
    -74.01244630958982,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Cooper Park Small Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Cooper Park Small Dog Run, New York, NY nan',
    40.71542350573422,
    -73.93633586930186,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Cooper Park Large Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Cooper Park Large Dog Run, New York, NY nan',
    40.715467926913306,
    -73.93616492948709,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Riverside Park South Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Riverside Park South Dog Run, New York, NY nan',
    40.781135449251956,
    -73.98772926764406,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Greenwood Playground Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Greenwood Playground Dog Run, New York, NY 11218',
    40.649409142603616,
    -73.97619088044168,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Fox Playground Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Fox Playground Dog Run, New York, NY 10455',
    40.8149567650444,
    -73.89822371990438,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Fort Independence Playground Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Fort Independence Playground Dog Run, New York, NY nan',
    40.88153523239843,
    -73.89464998638445,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Overlook Dog Park / The Barking Lot',
    'NYC Parks Department dog run in Queens',
    'Overlook Dog Park / The Barking Lot, New York, NY nan',
    40.71079844104306,
    -73.83631846029287,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'East River Esplanade Waterfront Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'East River Esplanade Waterfront Dog Run, New York, NY nan',
    40.70435656880518,
    -74.00589950932688,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'North End Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'North End Dog Run, New York, NY nan',
    40.71639499735246,
    -74.0149196018411,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Robin Kovary Run for Small Dogs',
    'NYC Parks Department dog run in Manhattan',
    'Robin Kovary Run for Small Dogs, New York, NY 10011',
    40.73022459322584,
    -73.99768480672438,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Stuyvesant Square Dog Park',
    'NYC Parks Department dog run in Manhattan',
    'Stuyvesant Square Dog Park, New York, NY 10003',
    40.73317315010797,
    -73.98391986317684,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Riverside Park Dog Run (W. 142nd St.)',
    'NYC Parks Department dog run in Manhattan',
    'Riverside Park Dog Run (W. 142nd St.), New York, NY nan',
    40.82518712812843,
    -73.95441012913086,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Soundview Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Soundview Park Dog Run, New York, NY 10473',
    40.81894288786234,
    -73.87748385052835,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'St. Mary''s Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'St. Mary''s Park Dog Run, New York, NY 10454',
    40.809805717959314,
    -73.91221621697598,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Washington Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Washington Park Dog Run, New York, NY 11215',
    40.67286528475229,
    -73.9858087835966,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Pier 6 Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Pier 6 Dog Run, New York, NY 11201',
    40.692831521200986,
    -74.00004416122805,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Hunters Point South Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Hunters Point South Park Dog Run, New York, NY 11101',
    40.743399910970105,
    -73.96011162581009,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Lou Lodati Dog Park',
    'NYC Parks Department dog run in Queens',
    'Lou Lodati Dog Park, New York, NY 11104',
    40.7472127045456,
    -73.9217962649402,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Homer''s Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Homer''s Dog Run, New York, NY 10034',
    40.87085776914007,
    -73.92179248756099,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Dog Bone Run',
    'NYC Parks Department dog run in Bronx',
    'Dog Bone Run, New York, NY Null',
    40.88378811994907,
    -73.88278270889644,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Woodlawn Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Woodlawn Dog Run, New York, NY Null',
    40.89946602067053,
    -73.87315817379164,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Canine Court Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Canine Court Dog Run, New York, NY 10471',
    40.899071536907506,
    -73.895125884814,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Tribeca Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Tribeca Dog Run, New York, NY 10007',
    40.71618119678133,
    -74.01227046002406,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'The Rocky Run',
    'NYC Parks Department dog run in Manhattan',
    'The Rocky Run, New York, NY 10032',
    40.84069788546422,
    -73.94554819444434,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'DeWitt Clinton Park Large Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'DeWitt Clinton Park Large Dog Run, New York, NY 10019',
    40.76750808547049,
    -73.99439430763938,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'DeWitt Clinton Park Small Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'DeWitt Clinton Park Small Dog Run, New York, NY 10019',
    40.76769957911417,
    -73.9944822157227,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Brooklyn Bridge Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Brooklyn Bridge Park Dog Run, New York, NY 11201',
    40.70441291794277,
    -73.98889097690027,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Williamsbridge Oval Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Williamsbridge Oval Dog Run, New York, NY 10467',
    40.877906181273964,
    -73.8761421785846,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Manhattan Beach Dog Run (Oriental Boulevard)',
    'NYC Parks Department dog run in Brooklyn',
    'Manhattan Beach Dog Run (Oriental Boulevard), New York, NY 11235',
    40.57789051234696,
    -73.94245483141644,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Dimattina Park Dog Run - South',
    'NYC Parks Department dog run in Brooklyn',
    'Dimattina Park Dog Run - South, New York, NY 11231',
    40.67992879266255,
    -74.00305120100299,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Maria Hernandez Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Maria Hernandez Park Dog Run, New York, NY 11237',
    40.70381096033493,
    -73.92320122229064,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Sternberg Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Sternberg Park Dog Run, New York, NY 11206',
    40.70619045019168,
    -73.94698310879613,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Wolfe''s Pond Park Dog Run',
    'NYC Parks Department dog run in Staten Island',
    'Wolfe''s Pond Park Dog Run, New York, NY 10312',
    40.52001769582299,
    -74.18503158566556,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Silver Lake Park Dog Run',
    'NYC Parks Department dog run in Staten Island',
    'Silver Lake Park Dog Run, New York, NY 10301',
    40.626702924414786,
    -74.0927651355187,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Conference House Park Dog Run',
    'NYC Parks Department dog run in Staten Island',
    'Conference House Park Dog Run, New York, NY 10307',
    40.50034706929861,
    -74.25017430828869,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Bloomingdale Park Dog Run',
    'NYC Parks Department dog run in Staten Island',
    'Bloomingdale Park Dog Run, New York, NY 10309',
    40.53357681031137,
    -74.21147028589863,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Windmuller Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Windmuller Park Dog Run, New York, NY 11377',
    40.74583303816196,
    -73.90852127096527,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Veteran''s Grove Dog Run',
    'NYC Parks Department dog run in Queens',
    'Veteran''s Grove Dog Run, New York, NY 11373',
    40.742484898185374,
    -73.87774000657929,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Underbridge Playground Dog Run',
    'NYC Parks Department dog run in Queens',
    'Underbridge Playground Dog Run, New York, NY 11375',
    40.733665928134094,
    -73.84490546275457,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Sherry Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Sherry Park Dog Run, New York, NY 11377',
    40.74144151575805,
    -73.89898429225877,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Rockaway Freeway Dog Park',
    'NYC Parks Department dog run in Queens',
    'Rockaway Freeway Dog Park, New York, NY 11693',
    40.59152764843032,
    -73.80842731417049,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Murray Playground Dog Run',
    'NYC Parks Department dog run in Queens',
    'Murray Playground Dog Run, New York, NY 11101',
    40.74689166833943,
    -73.9484798313606,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Little Bay Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Little Bay Park Dog Run, New York, NY 11360',
    40.78794400018938,
    -73.79284763590378,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Forest Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Forest Park Dog Run, New York, NY 11385',
    40.696914748320964,
    -73.86018266254078,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Cunningham Park Dog Run',
    'NYC Parks Department dog run in Queens',
    'Cunningham Park Dog Run, New York, NY 11423',
    40.726487145708646,
    -73.7755832097389,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Washington Square Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Washington Square Park Dog Run, New York, NY 10011',
    40.73079911300472,
    -73.99849263326139,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Union Square Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Union Square Park Dog Run, New York, NY 10003',
    40.73539246410828,
    -73.99095698122969,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Tompkins Square Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Tompkins Square Park Dog Run, New York, NY 10009',
    40.72645335278598,
    -73.98141327542261,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Theodore Roosevelt Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Theodore Roosevelt Park Dog Run, New York, NY 10024',
    40.7819726858672,
    -73.97356522953291,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'St. Nicholas Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'St. Nicholas Park Dog Run, New York, NY 10031',
    40.817794729838226,
    -73.94928819447615,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Robert Moses Playground Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Robert Moses Playground Dog Run, New York, NY 10017',
    40.7481418999281,
    -73.96882015296923,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Riverside Park Dog Run (72nd St)',
    'NYC Parks Department dog run in Manhattan',
    'Riverside Park Dog Run (72nd St), New York, NY 10024',
    40.7813529495921,
    -73.98658491354695,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Riverside Park Dog Run (87th St)',
    'NYC Parks Department dog run in Manhattan',
    'Riverside Park Dog Run (87th St), New York, NY 10024',
    40.78998674582576,
    -73.98093357866503,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Riverside Park Dog Run (105th St)',
    'NYC Parks Department dog run in Manhattan',
    'Riverside Park Dog Run (105th St), New York, NY 10024',
    40.80271155887992,
    -73.97144791980544,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Peter Detmold Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Peter Detmold Park Dog Run, New York, NY 10022',
    40.75363499230809,
    -73.96381290702455,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Morningside Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Morningside Park Dog Run, New York, NY 10026',
    40.8045142400111,
    -73.95902744007678,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Thomas Jefferson Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Thomas Jefferson Park Dog Run, New York, NY 10029',
    40.79201479100018,
    -73.93528895439637,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Marcus Garvey Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Marcus Garvey Park Dog Run, New York, NY 10027',
    40.80282551555144,
    -73.94342049558139,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Madison Square Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Madison Square Park Dog Run, New York, NY 10010',
    40.74210582626826,
    -73.98877885626241,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'J. Hood Wright Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'J. Hood Wright Park Dog Run, New York, NY 10033',
    40.846406995874254,
    -73.94218065781386,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Highbridge Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Highbridge Park Dog Run, New York, NY 10040',
    40.85591775325249,
    -73.92499381237899,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Fort Tryon Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Fort Tryon Park Dog Run, New York, NY 10040',
    40.86195015593058,
    -73.93196990995384,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Fishbridge Garden Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Fishbridge Garden Dog Run, New York, NY 10038',
    40.709326804724064,
    -74.00164591567291,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Andrew Haswell Green Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Andrew Haswell Green Dog Run, New York, NY 10065',
    40.76011094307365,
    -73.9570668056758,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Corlears Hook Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Corlears Hook Park Dog Run, New York, NY 10002',
    40.711855182717855,
    -73.97947522594802,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Coleman Oval Park Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Coleman Oval Park Dog Run, New York, NY 10002',
    40.71116987740717,
    -73.99349109050382,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Carl Schurz Park Small Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Carl Schurz Park Small Dog Run, New York, NY 10028',
    40.7738798386899,
    -73.9440195074753,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Carl Schurz Park Large Dog Run',
    'NYC Parks Department dog run in Manhattan',
    'Carl Schurz Park Large Dog Run, New York, NY 10028',
    40.774331486213796,
    -73.94404415590044,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Adam Yauch Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Adam Yauch Park Dog Run, New York, NY 11201',
    40.69228955053956,
    -73.99913350399208,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Owl''s Head Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Owl''s Head Park Dog Run, New York, NY 11220',
    40.639942598322136,
    -74.03516330324591,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'McGolrick Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'McGolrick Park Dog Run, New York, NY 11222',
    40.72323363586249,
    -73.94391776901901,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'McCarren Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'McCarren Park Dog Run, New York, NY 11211',
    40.71995679300122,
    -73.9531487158512,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Hillside Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Hillside Park Dog Run, New York, NY 11201',
    40.70102059449023,
    -73.99485938863606,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Herbert Von King Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Herbert Von King Park Dog Run, New York, NY 11216',
    40.68990543798157,
    -73.947974331475,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Dyker Beach Park Dog Run',
    'NYC Parks Department dog run in Brooklyn',
    'Dyker Beach Park Dog Run, New York, NY 11228',
    40.61745541495801,
    -74.02144864288913,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'DiMattina Park Dog Run - North',
    'NYC Parks Department dog run in Brooklyn',
    'DiMattina Park Dog Run - North, New York, NY 11231',
    40.68108973709557,
    -74.00242395798611,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Seton Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Seton Park Dog Run, New York, NY 10471',
    40.88655336213484,
    -73.9162091925375,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Pelham Bay Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Pelham Bay Park Dog Run, New York, NY 10465',
    40.850532214468906,
    -73.82126657937096,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Franz Sigel Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Franz Sigel Park Dog Run, New York, NY 10451',
    40.822998298398,
    -73.92601378337277,
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
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    'Ewen Park Dog Run',
    'NYC Parks Department dog run in Bronx',
    'Ewen Park Dog Run, New York, NY 10463',
    40.88216985427035,
    -73.91023102260864,
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
