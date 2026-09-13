-- Seed the 27 Egyptian Governorates and their primary cities
INSERT INTO governorate (governorate_id, name) VALUES
  (1, 'Cairo'),
  (2, 'Giza'),
  (3, 'Alexandria'),
  (4, 'Dakahlia'),
  (5, 'Red Sea'),
  (6, 'Beheira'),
  (7, 'Faiyum'),
  (8, 'Gharbia'),
  (9, 'Ismailia'),
  (10, 'Monufia'),
  (11, 'Minya'),
  (12, 'Qalyubia'),
  (13, 'New Valley'),
  (14, 'Suez'),
  (15, 'Aswan'),
  (16, 'Asyut'),
  (17, 'Beni Suef'),
  (18, 'Port Said'),
  (19, 'Damietta'),
  (20, 'Sharkia'),
  (21, 'South Sinai'),
  (22, 'Kafr El Sheikh'),
  (23, 'Matrouh'),
  (24, 'Luxor'),
  (25, 'Qena'),
  (26, 'North Sinai'),
  (27, 'Sohag')
ON CONFLICT (name) DO NOTHING;

SELECT setval('governorate_governorate_id_seq', (SELECT MAX(governorate_id) FROM governorate));

-- Insert cities for Cairo (1)
INSERT INTO city (city_id, governorate_id, name) VALUES
  (1, 1, 'Nasr City'),
  (2, 1, 'New Cairo'),
  (3, 1, 'Maadi'),
  (4, 1, 'Heliopolis'),
  (5, 1, 'Helwan'),
  (6, 1, 'Shubra'),
  (7, 1, 'Ain Shams'),
  (8, 1, 'El Tagamoa El Khames'),
  (9, 1, 'Downtown'),
  (10, 1, 'Zamalek')
ON CONFLICT (governorate_id, name) DO NOTHING;

-- Reset sequence so auto-increment doesn't collide
SELECT setval('city_city_id_seq', (SELECT GREATEST(MAX(city_id), 10) FROM city));

-- Insert cities for Giza (2)
INSERT INTO city (governorate_id, name) VALUES
  (2, 'Dokki'),
  (2, 'Mohandessin'),
  (2, 'Haram'),
  (2, 'Faisal'),
  (2, '6th of October'),
  (2, 'Sheikh Zayed'),
  (2, 'Imbaba')
ON CONFLICT (governorate_id, name) DO NOTHING;

-- Insert cities for Alexandria (3)
INSERT INTO city (governorate_id, name) VALUES
  (3, 'Montaza'),
  (3, 'Sidi Gaber'),
  (3, 'Moharam Bek'),
  (3, 'Agami'),
  (3, 'Borg El Arab')
ON CONFLICT (governorate_id, name) DO NOTHING;

-- Ensure all other governorates have at least one city
INSERT INTO city (governorate_id, name) VALUES
  (4, 'Mansoura'),
  (5, 'Hurghada'),
  (6, 'Damanhur'),
  (7, 'Fayoum City'),
  (8, 'Tanta'),
  (9, 'Ismailia City'),
  (10, 'Shibin El Kom'),
  (11, 'Minya City'),
  (12, 'Banha'),
  (13, 'Kharga'),
  (14, 'Suez City'),
  (15, 'Aswan City'),
  (16, 'Asyut City'),
  (17, 'Beni Suef City'),
  (18, 'Port Said City'),
  (19, 'Damietta City'),
  (20, 'Zagazig'),
  (21, 'Sharm El Sheikh'),
  (22, 'Kafr El Sheikh City'),
  (23, 'Marsa Matrouh'),
  (24, 'Luxor City'),
  (25, 'Qena City'),
  (26, 'Arish'),
  (27, 'Sohag City')
ON CONFLICT (governorate_id, name) DO NOTHING;

SELECT setval('city_city_id_seq', (SELECT MAX(city_id) FROM city));

-- 4. Default Seed Users (Admin and Community Volunteer)
-- Password for both is: password123 (bcrypt hash: $2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYTa)
INSERT INTO "User" (user_id, name, phone, password_hash, city_id, role) VALUES
  (100, 'Admin Reunite', '+201000000000', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYTa', 1, true),
  (101, 'Ahmed Volunteer', '+201000000001', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYTa', 1, false)
ON CONFLICT (phone) DO UPDATE SET role = EXCLUDED.role, password_hash = EXCLUDED.password_hash;

SELECT setval('"User_user_id_seq"', (SELECT GREATEST(MAX(user_id), 101) FROM "User"));

-- 5. Seed Initial Sample Cases for Immediate Testing and Map Display
INSERT INTO report (report_id, user_id, kind, name, age, gender, status, occurrence_date, latitude, longitude, description) VALUES
  (100, 100, 'MISSING', 'Karim Mahmoud', 9, 'MALE', 'OPEN', CURRENT_DATE - INTERVAL '2 days', 30.0561, 31.3301, 'Wearing yellow hoodie and blue jeans in Nasr City, Cairo. Speaks Arabic.'),
  (101, 101, 'FOUND', 'Laila Sameh', 6, 'FEMALE', 'OPEN', CURRENT_DATE - INTERVAL '1 day', 30.0298, 31.4087, 'Found accompanied by security near Cairo Festival City, New Cairo. Safe and waiting for family identification.')
ON CONFLICT (report_id) DO NOTHING;

SELECT setval('report_report_id_seq', (SELECT GREATEST(MAX(report_id), 101) FROM report));
