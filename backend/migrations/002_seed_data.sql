-- BarkPark Seed Data
-- This file contains initial park data for testing and production

-- Original Piermont area parks
INSERT INTO dog_parks (name, description, address, location, amenities, rules, hours_open, hours_close) VALUES
('Piermont Pier Dog Run', 'Waterfront dog park at the historic Piermont Pier with stunning Hudson River views and Manhattan skyline. Large fenced area perfect for safe off-leash play.', '490 Piermont Ave, Piermont, NY 10968', ST_SetSRID(ST_MakePoint(-73.9215, 41.0387), 4326),
 ARRAY['Off-leash area', 'Hudson River views', 'Fenced area', 'Water fountains', 'Waste bags', 'Benches', 'Historic pier'],
 'Dogs must be vaccinated and licensed. Clean up after your pet. No aggressive dogs. Leash required outside designated area.',
 '06:00:00', '20:00:00'),

('Tallman Mountain State Park Dog Area', 'Natural trails and open areas in beautiful Tallman Mountain State Park. Great for hiking with dogs and enjoying nature.', '1 Old Route 9W, Piermont, NY 10968', ST_SetSRID(ST_MakePoint(-73.9285, 41.0456), 4326),
 ARRAY['Hiking trails', 'Natural terrain', 'Mountain views', 'Large open areas', 'Parking available', 'Scenic overlooks'],
 'Dogs must be leashed on trails. Voice control required in designated off-leash areas. Stay on marked paths.',
 '06:00:00', '21:00:00'),

('Sparkill Creek Dog Park', 'Community dog park near Sparkill Creek with separate areas for large and small dogs. Shaded areas and water access.', '12 Main St, Sparkill, NY 10976', ST_SetSRID(ST_MakePoint(-73.9189, 41.0298), 4326),
 ARRAY['Separate small dog area', 'Creek access', 'Shade trees', 'Double-gated entry', 'Agility equipment', 'Water station'],
 'Current vaccination required. Clean up strictly enforced. No food allowed. Supervise children.',
 '07:00:00', '19:00:00'),

('Blauvelt State Park Dog Trail', 'Wooded state park with designated dog-friendly trails and natural swimming areas. Popular with local hiking groups.', '542 Western Hwy, Blauvelt, NY 10913', ST_SetSRID(ST_MakePoint(-73.9567, 41.0634), 4326),
 ARRAY['Wooded trails', 'Natural swimming holes', 'Wildlife viewing', 'Parking area', 'Trail maps', 'Seasonal restrooms'],
 'Dogs must be leashed except in designated areas. Swimming at own risk. Pack out all waste.',
 '05:00:00', '22:00:00'),

('Orangeburg Dog Run', 'Modern enclosed dog park in Orangeburg with all amenities. Well-maintained with regular community events and training sessions.', '45 Kings Hwy, Orangeburg, NY 10962', ST_SetSRID(ST_MakePoint(-73.9423, 41.0156), 4326),
 ARRAY['Fully enclosed', 'Separate small dog section', 'Agility course', 'Water fountains', 'Shade pavilion', 'Training area'],
 'Membership encouraged but not required. Dogs must be spayed/neutered for extended stays. Training classes available.',
 '06:30:00', '20:30:00'),

('Nyack Beach State Park Dog Area', 'Riverside park along the Hudson with beach access and wide open spaces. Great for water-loving dogs and fetch.', '61 N Broadway, Upper Nyack, NY 10960', ST_SetSRID(ST_MakePoint(-73.9178, 41.0789), 4326),
 ARRAY['Beach access', 'Hudson River frontage', 'Open fields', 'Picnic areas', 'River swimming', 'Historic lighthouse'],
 'Beach access seasonal. Strong swimmers only in river. Clean up required. Leash near picnic areas.',
 '06:00:00', '21:00:00'),

('Tappan Dog Park', 'Community-managed dog park in historic Tappan with volunteer-maintained facilities and regular social events for dogs and owners.', '20 Old Tappan Rd, Tappan, NY 10983', ST_SetSRID(ST_MakePoint(-73.9534, 41.0234), 4326),
 ARRAY['Community managed', 'Social events', 'Double gates', 'Waste stations', 'Volunteer maintained', 'Bulletin board'],
 'Community guidelines posted. Volunteer hours appreciated. No aggressive behavior tolerated.',
 '07:00:00', '19:00:00'),

('Clausland Mountain Dog Trail', 'Mountain hiking trails with spectacular views of the Hudson Valley. Challenging terrain for active dogs and experienced hikers.', 'Tweed Blvd, Upper Nyack, NY 10960', ST_SetSRID(ST_MakePoint(-73.9312, 41.0923), 4326),
 ARRAY['Mountain trails', 'Valley views', 'Challenging terrain', 'Rock formations', 'Seasonal waterfalls', 'Trail markers'],
 'Experienced hikers only. Dogs must be in excellent physical condition. Bring plenty of water.',
 '05:30:00', '21:30:00'),

('Hook Mountain Dog Area', 'State park with rugged trails and cliff-top views. Popular destination for serious hikers with well-trained dogs.', 'Route 9W, Nyack, NY 10960', ST_SetSRID(ST_MakePoint(-73.9145, 41.0876), 4326),
 ARRAY['Cliff-top views', 'Rugged trails', 'State park', 'Rock climbing areas', 'Scenic overlooks', 'Parking facilities'],
 'Leashed dogs only due to cliff areas. Stay on designated trails. Rock climbing areas off-limits to dogs.',
 '06:00:00', '20:00:00'),

('Central Nyack Riverside Dog Run', 'Small but well-equipped dog park in the heart of Nyack with river views and convenient downtown location.', '8 N Broadway, Nyack, NY 10960', ST_SetSRID(ST_MakePoint(-73.9189, 41.0901), 4326),
 ARRAY['Downtown location', 'River views', 'Small dog friendly', 'Walking distance to shops', 'Regular maintenance', 'Community bulletin'],
 'Urban park rules apply. Limited space - please share. Perfect for socialized dogs.',
 '07:00:00', '18:00:00'),

('Grandview-on-Hudson Dog Park', 'Hillside park with panoramic Hudson River views and multiple terraced play areas. Recently renovated with modern amenities.', '176 River Rd, Grandview, NY 10960', ST_SetSRID(ST_MakePoint(-73.9098, 41.0567), 4326),
 ARRAY['Panoramic river views', 'Terraced play areas', 'Recently renovated', 'Multiple levels', 'Scenic benches', 'Photo opportunities'],
 'Hillside terrain - supervise dogs carefully. Recent renovation - please help maintain. No digging.',
 '06:00:00', '20:00:00'),

('South Nyack Dog Beach', 'Unique beach access for dogs along the Hudson River with sandy areas and gentle water entry. Perfect for swimming and water play.', '282 S Broadway, South Nyack, NY 10960', ST_SetSRID(ST_MakePoint(-73.9234, 41.0678), 4326),
 ARRAY['Sandy beach', 'Gentle water entry', 'Swimming area', 'Rinse station', 'Beach toys welcome', 'Tidal pools'],
 'Swimming at own risk. Tides affect water levels. Rinse dogs after swimming. No glass on beach.',
 '06:00:00', '21:00:00');

-- Record this migration
INSERT INTO schema_migrations (version) VALUES ('002_seed_data');