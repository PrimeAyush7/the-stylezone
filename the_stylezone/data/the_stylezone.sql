BEGIN TRANSACTION;
CREATE TABLE _fs_test (id INT PRIMARY KEY);
CREATE TABLE appointments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                booking_id TEXT UNIQUE NOT NULL,
                customer_id INTEGER NOT NULL,
                customer_name TEXT NOT NULL,
                customer_email TEXT NOT NULL,
                customer_phone TEXT,
                service_id INTEGER NOT NULL,
                service_name TEXT NOT NULL,
                service_price REAL NOT NULL,
                appointment_date TEXT NOT NULL,
                start_time TEXT NOT NULL,
                end_time TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'confirmed', 'completed', 'cancelled', 'no_show')),
                cancellation_reason TEXT,
                cancelled_by TEXT CHECK(cancelled_by IN ('customer', 'admin', NULL)),
                notes TEXT,
                payment_status TEXT NOT NULL DEFAULT 'unpaid' CHECK(payment_status IN ('unpaid', 'paid', 'cash_at_counter')),
                payment_method TEXT NOT NULL DEFAULT 'cash_at_counter',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT
            );
INSERT INTO "appointments" VALUES(2,'SZ-20260920-04AF',3,'Rahul Sharma','rahul.test@example.com','9876543210',1,'Haircut',100.0,'2026-09-20','09:00','09:30','cancelled','Schedule change','customer','Testing automated booking flow','unpaid','cash_at_counter','2026-09-18 17:57:33','2026-09-18 17:57:33');
INSERT INTO "appointments" VALUES(3,'SZ-20260920-A398',5,'Deepak Verma','customer.verify@example.com','9811223344',1,'Haircut',100.0,'2026-09-20','09:00','09:30','pending',NULL,NULL,'Regression verification appointment','unpaid','cash_at_counter','2026-09-18 21:20:55','2026-09-18 21:20:55');
INSERT INTO "appointments" VALUES(7,'SZ-20260921-91AD',18,'Test Customer 311','customer311@example.com','9876543210',1,'Haircut',100.0,'2026-09-21','09:30','10:00','pending',NULL,NULL,'Python 3.11 Render deployment verification','unpaid','cash_at_counter','2026-09-18 23:17:29','2026-09-18 23:17:29');
INSERT INTO "appointments" VALUES(11,'SZ-20260921-9E4A',40,'Ayush Verma','ayush.verma@example.com','9811223344',1,'Haircut',100.0,'2026-09-21','10:00','10:30','cancelled','Test cancel','customer','VIP haircut request','unpaid','cash_at_counter','2026-09-19 10:44:03','2026-09-19 10:44:03');
INSERT INTO "appointments" VALUES(12,'SZ-20260926-FA2B',43,'Schedule Admin','admin.hours.test@stylezone.local','9998887776',1,'Haircut',100.0,'2026-09-26','08:00','08:30','pending',NULL,NULL,'Saturday morning booking','unpaid','cash_at_counter','2026-09-19 10:44:07','2026-09-19 10:44:07');
CREATE TABLE blocked_slots (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL,
                start_time TEXT NOT NULL,
                end_time TEXT NOT NULL,
                reason TEXT,
                created_by INTEGER,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
            );
INSERT INTO "blocked_slots" VALUES(1,'2026-09-21','15:00','16:00','Studio Power Maintenance',NULL,'2026-09-18 21:58:47');
INSERT INTO "blocked_slots" VALUES(2,'2026-09-21','15:00','16:00','Studio Power Maintenance',NULL,'2026-09-19 08:38:36');
INSERT INTO "blocked_slots" VALUES(3,'2026-09-21','15:00','16:00','Studio Power Maintenance',NULL,'2026-09-19 09:37:07');
INSERT INTO "blocked_slots" VALUES(4,'2026-09-21','15:00','16:00','Studio Power Maintenance',41,'2026-09-19 10:44:03');
CREATE TABLE business_hours (
        day_of_week INTEGER PRIMARY KEY CHECK(day_of_week BETWEEN 0 AND 6),
        day_name TEXT NOT NULL,
        is_open INTEGER NOT NULL DEFAULT 0 CHECK(is_open IN (0, 1)),
        open_time TEXT,
        close_time TEXT,
        has_break INTEGER NOT NULL DEFAULT 0 CHECK(has_break IN (0, 1)),
        break_start TEXT,
        break_end TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
INSERT INTO "business_hours" VALUES(0,'Monday',1,'08:00','22:00',0,NULL,NULL,'2026-09-19 10:44:07');
INSERT INTO "business_hours" VALUES(1,'Tuesday',1,'08:00','22:00',0,NULL,NULL,'2026-09-19 10:44:07');
INSERT INTO "business_hours" VALUES(2,'Wednesday',1,'08:00','22:00',0,NULL,NULL,'2026-09-19 10:44:07');
INSERT INTO "business_hours" VALUES(3,'Thursday',1,'08:00','22:00',0,NULL,NULL,'2026-09-19 10:44:07');
INSERT INTO "business_hours" VALUES(4,'Friday',1,'08:00','22:00',0,NULL,NULL,'2026-09-19 10:44:07');
INSERT INTO "business_hours" VALUES(5,'Saturday',1,'08:00','22:00',0,NULL,NULL,'2026-09-19 10:44:07');
INSERT INTO "business_hours" VALUES(6,'Sunday',0,'08:00','22:00',0,NULL,NULL,'2026-09-19 10:44:07');
CREATE TABLE business_settings (
                key TEXT PRIMARY KEY,
                value TEXT,
                description TEXT,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
INSERT INTO "business_settings" VALUES('business_name','The Stylezone','Official business name','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('address','Street no 32, Vipin Garden Extension, Dwarka Mor, Delhi','Official shop address','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('phone_number','','Contact phone number (Configure in Admin)','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('whatsapp_number','','WhatsApp booking number (Configure in Admin)','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('instagram_url','','Instagram profile link (Configure in Admin)','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('google_maps_url','','Google Maps embed or link (Configure in Admin)','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('hero_headline','Refined Grooming For The Modern Gentleman','Main headline on public hero section','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('hero_description','Experience precision haircuts, master beard sculpting, and revitalizing skin treatments in Dwarka Mor, Delhi.','Hero subheading','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('about_text','The Stylezone brings refined grooming and sharp craftsmanship to Dwarka Mor, Delhi. Dedicated to delivering consistent quality for every client.','About section text','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('why_choose_us_text','Focused styling expertise, comfortable ambiance, and dedicated attention tailored to your personal aesthetic.','Why Choose Us text','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('footer_text','© 2026 The Stylezone. All rights reserved.','Footer text','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('cancellation_window_hours','2','Minimum hours before appointment required for customer self-cancellation','2026-09-19 10:44:05');
INSERT INTO "business_settings" VALUES('booking_enabled','1','Master toggle for online booking (1 = enabled, 0 = disabled)','2026-09-19 10:44:07');
INSERT INTO "business_settings" VALUES('slot_duration_minutes','30','Default booking slot interval in minutes','2026-09-19 10:44:07');
INSERT INTO "business_settings" VALUES('hours_configured','1','Whether operating hours have been set by the admin (0=unconfigured, 1=configured)','2026-09-19 10:44:07');
CREATE TABLE gallery (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                category TEXT NOT NULL,
                image_url TEXT NOT NULL,
                description TEXT,
                is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
                display_order INTEGER NOT NULL DEFAULT 0,
                is_placeholder INTEGER NOT NULL DEFAULT 1 CHECK(is_placeholder IN (0, 1)),
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
INSERT INTO "gallery" VALUES(1,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 17:48:27');
INSERT INTO "gallery" VALUES(2,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 17:48:27');
INSERT INTO "gallery" VALUES(3,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 17:48:27');
INSERT INTO "gallery" VALUES(4,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 17:48:27');
INSERT INTO "gallery" VALUES(5,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 17:48:27');
INSERT INTO "gallery" VALUES(6,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 17:48:27');
INSERT INTO "gallery" VALUES(7,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 17:48:27');
INSERT INTO "gallery" VALUES(8,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 17:48:27');
INSERT INTO "gallery" VALUES(9,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 21:50:31');
INSERT INTO "gallery" VALUES(10,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 21:50:31');
INSERT INTO "gallery" VALUES(11,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 21:50:31');
INSERT INTO "gallery" VALUES(12,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 21:50:31');
INSERT INTO "gallery" VALUES(13,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 21:50:31');
INSERT INTO "gallery" VALUES(14,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 21:50:31');
INSERT INTO "gallery" VALUES(15,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 21:50:31');
INSERT INTO "gallery" VALUES(16,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 21:50:31');
INSERT INTO "gallery" VALUES(17,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 21:51:57');
INSERT INTO "gallery" VALUES(18,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 21:51:57');
INSERT INTO "gallery" VALUES(19,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 21:51:57');
INSERT INTO "gallery" VALUES(20,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 21:51:57');
INSERT INTO "gallery" VALUES(21,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 21:51:57');
INSERT INTO "gallery" VALUES(22,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 21:51:57');
INSERT INTO "gallery" VALUES(23,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 21:51:57');
INSERT INTO "gallery" VALUES(24,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 21:51:57');
INSERT INTO "gallery" VALUES(25,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 21:52:18');
INSERT INTO "gallery" VALUES(26,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 21:52:18');
INSERT INTO "gallery" VALUES(27,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 21:52:18');
INSERT INTO "gallery" VALUES(28,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 21:52:18');
INSERT INTO "gallery" VALUES(29,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 21:52:18');
INSERT INTO "gallery" VALUES(30,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 21:52:18');
INSERT INTO "gallery" VALUES(31,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 21:52:18');
INSERT INTO "gallery" VALUES(32,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 21:52:18');
INSERT INTO "gallery" VALUES(33,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 21:53:24');
INSERT INTO "gallery" VALUES(34,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 21:53:24');
INSERT INTO "gallery" VALUES(35,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 21:53:24');
INSERT INTO "gallery" VALUES(36,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 21:53:24');
INSERT INTO "gallery" VALUES(37,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 21:53:24');
INSERT INTO "gallery" VALUES(38,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 21:53:24');
INSERT INTO "gallery" VALUES(39,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 21:53:24');
INSERT INTO "gallery" VALUES(40,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 21:53:24');
INSERT INTO "gallery" VALUES(41,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 21:54:06');
INSERT INTO "gallery" VALUES(42,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 21:54:06');
INSERT INTO "gallery" VALUES(43,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 21:54:06');
INSERT INTO "gallery" VALUES(44,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 21:54:06');
INSERT INTO "gallery" VALUES(45,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 21:54:06');
INSERT INTO "gallery" VALUES(46,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 21:54:06');
INSERT INTO "gallery" VALUES(47,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 21:54:06');
INSERT INTO "gallery" VALUES(48,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 21:54:06');
INSERT INTO "gallery" VALUES(49,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 21:54:29');
INSERT INTO "gallery" VALUES(50,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 21:54:29');
INSERT INTO "gallery" VALUES(51,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 21:54:29');
INSERT INTO "gallery" VALUES(52,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 21:54:29');
INSERT INTO "gallery" VALUES(53,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 21:54:29');
INSERT INTO "gallery" VALUES(54,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 21:54:29');
INSERT INTO "gallery" VALUES(55,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 21:54:29');
INSERT INTO "gallery" VALUES(56,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 21:54:29');
INSERT INTO "gallery" VALUES(57,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 21:56:19');
INSERT INTO "gallery" VALUES(58,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 21:56:19');
INSERT INTO "gallery" VALUES(59,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 21:56:19');
INSERT INTO "gallery" VALUES(60,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 21:56:19');
INSERT INTO "gallery" VALUES(61,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 21:56:19');
INSERT INTO "gallery" VALUES(62,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 21:56:19');
INSERT INTO "gallery" VALUES(63,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 21:56:19');
INSERT INTO "gallery" VALUES(64,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 21:56:19');
INSERT INTO "gallery" VALUES(65,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 21:56:43');
INSERT INTO "gallery" VALUES(66,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 21:56:43');
INSERT INTO "gallery" VALUES(67,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 21:56:43');
INSERT INTO "gallery" VALUES(68,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 21:56:43');
INSERT INTO "gallery" VALUES(69,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 21:56:43');
INSERT INTO "gallery" VALUES(70,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 21:56:43');
INSERT INTO "gallery" VALUES(71,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 21:56:43');
INSERT INTO "gallery" VALUES(72,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 21:56:43');
INSERT INTO "gallery" VALUES(73,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 21:58:44');
INSERT INTO "gallery" VALUES(74,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 21:58:44');
INSERT INTO "gallery" VALUES(75,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 21:58:44');
INSERT INTO "gallery" VALUES(76,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 21:58:44');
INSERT INTO "gallery" VALUES(77,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 21:58:44');
INSERT INTO "gallery" VALUES(78,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 21:58:44');
INSERT INTO "gallery" VALUES(79,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 21:58:44');
INSERT INTO "gallery" VALUES(80,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 21:58:44');
INSERT INTO "gallery" VALUES(81,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 23:16:04');
INSERT INTO "gallery" VALUES(82,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 23:16:04');
INSERT INTO "gallery" VALUES(83,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 23:16:04');
INSERT INTO "gallery" VALUES(84,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 23:16:04');
INSERT INTO "gallery" VALUES(85,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 23:16:04');
INSERT INTO "gallery" VALUES(86,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 23:16:04');
INSERT INTO "gallery" VALUES(87,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 23:16:04');
INSERT INTO "gallery" VALUES(88,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 23:16:04');
INSERT INTO "gallery" VALUES(89,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-18 23:17:28');
INSERT INTO "gallery" VALUES(90,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-18 23:17:28');
INSERT INTO "gallery" VALUES(91,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-18 23:17:28');
INSERT INTO "gallery" VALUES(92,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-18 23:17:28');
INSERT INTO "gallery" VALUES(93,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-18 23:17:28');
INSERT INTO "gallery" VALUES(94,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-18 23:17:28');
INSERT INTO "gallery" VALUES(95,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-18 23:17:28');
INSERT INTO "gallery" VALUES(96,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-18 23:17:28');
INSERT INTO "gallery" VALUES(97,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-19 08:37:01');
INSERT INTO "gallery" VALUES(98,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-19 08:37:01');
INSERT INTO "gallery" VALUES(99,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-19 08:37:01');
INSERT INTO "gallery" VALUES(100,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-19 08:37:01');
INSERT INTO "gallery" VALUES(101,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-19 08:37:01');
INSERT INTO "gallery" VALUES(102,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-19 08:37:01');
INSERT INTO "gallery" VALUES(103,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-19 08:37:01');
INSERT INTO "gallery" VALUES(104,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-19 08:37:01');
INSERT INTO "gallery" VALUES(105,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-19 08:37:46');
INSERT INTO "gallery" VALUES(106,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-19 08:37:46');
INSERT INTO "gallery" VALUES(107,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-19 08:37:46');
INSERT INTO "gallery" VALUES(108,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-19 08:37:46');
INSERT INTO "gallery" VALUES(109,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-19 08:37:46');
INSERT INTO "gallery" VALUES(110,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-19 08:37:46');
INSERT INTO "gallery" VALUES(111,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-19 08:37:46');
INSERT INTO "gallery" VALUES(112,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-19 08:37:46');
INSERT INTO "gallery" VALUES(113,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-19 08:38:33');
INSERT INTO "gallery" VALUES(114,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-19 08:38:33');
INSERT INTO "gallery" VALUES(115,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-19 08:38:33');
INSERT INTO "gallery" VALUES(116,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-19 08:38:33');
INSERT INTO "gallery" VALUES(117,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-19 08:38:33');
INSERT INTO "gallery" VALUES(118,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-19 08:38:33');
INSERT INTO "gallery" VALUES(119,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-19 08:38:33');
INSERT INTO "gallery" VALUES(120,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-19 08:38:33');
INSERT INTO "gallery" VALUES(121,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-19 09:36:20');
INSERT INTO "gallery" VALUES(122,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-19 09:36:20');
INSERT INTO "gallery" VALUES(123,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-19 09:36:20');
INSERT INTO "gallery" VALUES(124,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-19 09:36:20');
INSERT INTO "gallery" VALUES(125,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-19 09:36:20');
INSERT INTO "gallery" VALUES(126,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-19 09:36:20');
INSERT INTO "gallery" VALUES(127,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-19 09:36:20');
INSERT INTO "gallery" VALUES(128,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-19 09:36:20');
INSERT INTO "gallery" VALUES(129,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-19 09:37:04');
INSERT INTO "gallery" VALUES(130,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-19 09:37:04');
INSERT INTO "gallery" VALUES(131,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-19 09:37:04');
INSERT INTO "gallery" VALUES(132,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-19 09:37:04');
INSERT INTO "gallery" VALUES(133,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-19 09:37:04');
INSERT INTO "gallery" VALUES(134,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-19 09:37:04');
INSERT INTO "gallery" VALUES(135,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-19 09:37:04');
INSERT INTO "gallery" VALUES(136,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-19 09:37:04');
INSERT INTO "gallery" VALUES(137,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-19 10:42:38');
INSERT INTO "gallery" VALUES(138,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-19 10:42:38');
INSERT INTO "gallery" VALUES(139,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-19 10:42:38');
INSERT INTO "gallery" VALUES(140,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-19 10:42:38');
INSERT INTO "gallery" VALUES(141,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-19 10:42:38');
INSERT INTO "gallery" VALUES(142,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-19 10:42:38');
INSERT INTO "gallery" VALUES(143,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-19 10:42:38');
INSERT INTO "gallery" VALUES(144,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-19 10:42:38');
INSERT INTO "gallery" VALUES(145,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-19 10:43:12');
INSERT INTO "gallery" VALUES(146,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-19 10:43:12');
INSERT INTO "gallery" VALUES(147,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-19 10:43:12');
INSERT INTO "gallery" VALUES(148,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-19 10:43:12');
INSERT INTO "gallery" VALUES(149,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-19 10:43:12');
INSERT INTO "gallery" VALUES(150,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-19 10:43:12');
INSERT INTO "gallery" VALUES(151,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-19 10:43:12');
INSERT INTO "gallery" VALUES(152,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-19 10:43:12');
INSERT INTO "gallery" VALUES(153,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-19 10:44:00');
INSERT INTO "gallery" VALUES(154,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-19 10:44:00');
INSERT INTO "gallery" VALUES(155,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-19 10:44:00');
INSERT INTO "gallery" VALUES(156,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-19 10:44:00');
INSERT INTO "gallery" VALUES(157,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-19 10:44:00');
INSERT INTO "gallery" VALUES(158,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-19 10:44:00');
INSERT INTO "gallery" VALUES(159,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-19 10:44:00');
INSERT INTO "gallery" VALUES(160,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-19 10:44:00');
INSERT INTO "gallery" VALUES(161,'Classic Pompadour Fade','Haircut','https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80','High skin fade paired with a classic styled pompadour top.',1,1,1,'2026-09-19 10:44:05');
INSERT INTO "gallery" VALUES(162,'Textured Crop & Low Fade','Haircut','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80','Modern blunt crop with natural textured layering and clean edges.',1,2,1,'2026-09-19 10:44:05');
INSERT INTO "gallery" VALUES(163,'Executive Side Part','Haircut','https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80','Sophisticated gentleman''s taper with sharp parting and glossy finish.',1,3,1,'2026-09-19 10:44:05');
INSERT INTO "gallery" VALUES(164,'Sculpted Beard & Razor Fade','Beard','https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80','Crisp cheek line definition with graduated chin thickness.',1,4,1,'2026-09-19 10:44:05');
INSERT INTO "gallery" VALUES(165,'Signature Haircut & Full Beard','Hair + Beard','https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80','Harmonious blend of mid-fade haircut and full contoured beard.',1,5,1,'2026-09-19 10:44:05');
INSERT INTO "gallery" VALUES(166,'Modern Quiff with Clean Taper','Styling','https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80','Voluminous lifted quiff with clean natural temple taper.',1,6,1,'2026-09-19 10:44:05');
INSERT INTO "gallery" VALUES(167,'Precision Buzz Cut & Shape Up','Haircut','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80','Clean military buzz cut with razor-sharp hairline perimeter.',1,7,1,'2026-09-19 10:44:05');
INSERT INTO "gallery" VALUES(168,'Rejuvenating Grooming & Skin Care','Grooming','https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80','Fresh, revitalized appearance post-facial & D-Tan care.',1,8,1,'2026-09-19 10:44:05');
CREATE TABLE holidays (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT UNIQUE NOT NULL,
                reason TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
INSERT INTO "holidays" VALUES(1,'2026-10-02','National Holiday','2026-09-18 21:58:47');
CREATE TABLE password_reset_tokens (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                token TEXT UNIQUE NOT NULL,
                expires_at DATETIME NOT NULL,
                used INTEGER NOT NULL DEFAULT 0 CHECK(used IN (0, 1)),
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
INSERT INTO "password_reset_tokens" VALUES(13,40,'4c23625f5ca354a058856ec2f2750cdb51fc59f4f8c28858fc9b07db44de2575','2026-09-19 11:14:01',0,'2026-09-19 10:44:01');
CREATE TABLE reviews (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                author_name TEXT NOT NULL,
                rating INTEGER NOT NULL DEFAULT 5 CHECK(rating BETWEEN 1 AND 5),
                content TEXT NOT NULL,
                service_mentioned TEXT,
                is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
                is_demo INTEGER NOT NULL DEFAULT 1 CHECK(is_demo IN (0, 1)),
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
INSERT INTO "reviews" VALUES(1,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 17:48:27');
INSERT INTO "reviews" VALUES(2,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 17:48:27');
INSERT INTO "reviews" VALUES(3,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 17:48:27');
INSERT INTO "reviews" VALUES(4,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 21:50:31');
INSERT INTO "reviews" VALUES(5,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 21:50:31');
INSERT INTO "reviews" VALUES(6,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 21:50:31');
INSERT INTO "reviews" VALUES(7,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 21:51:57');
INSERT INTO "reviews" VALUES(8,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 21:51:57');
INSERT INTO "reviews" VALUES(9,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 21:51:57');
INSERT INTO "reviews" VALUES(10,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 21:52:18');
INSERT INTO "reviews" VALUES(11,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 21:52:18');
INSERT INTO "reviews" VALUES(12,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 21:52:18');
INSERT INTO "reviews" VALUES(13,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 21:53:24');
INSERT INTO "reviews" VALUES(14,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 21:53:24');
INSERT INTO "reviews" VALUES(15,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 21:53:24');
INSERT INTO "reviews" VALUES(16,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 21:54:06');
INSERT INTO "reviews" VALUES(17,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 21:54:06');
INSERT INTO "reviews" VALUES(18,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 21:54:06');
INSERT INTO "reviews" VALUES(19,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 21:54:29');
INSERT INTO "reviews" VALUES(20,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 21:54:29');
INSERT INTO "reviews" VALUES(21,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 21:54:29');
INSERT INTO "reviews" VALUES(22,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 21:56:19');
INSERT INTO "reviews" VALUES(23,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 21:56:19');
INSERT INTO "reviews" VALUES(24,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 21:56:19');
INSERT INTO "reviews" VALUES(25,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 21:56:43');
INSERT INTO "reviews" VALUES(26,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 21:56:43');
INSERT INTO "reviews" VALUES(27,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 21:56:43');
INSERT INTO "reviews" VALUES(28,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 21:58:44');
INSERT INTO "reviews" VALUES(29,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 21:58:44');
INSERT INTO "reviews" VALUES(30,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 21:58:44');
INSERT INTO "reviews" VALUES(31,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 23:16:04');
INSERT INTO "reviews" VALUES(32,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 23:16:04');
INSERT INTO "reviews" VALUES(33,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 23:16:04');
INSERT INTO "reviews" VALUES(34,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-18 23:17:28');
INSERT INTO "reviews" VALUES(35,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-18 23:17:28');
INSERT INTO "reviews" VALUES(36,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-18 23:17:28');
INSERT INTO "reviews" VALUES(37,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-19 08:37:01');
INSERT INTO "reviews" VALUES(38,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-19 08:37:01');
INSERT INTO "reviews" VALUES(39,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-19 08:37:01');
INSERT INTO "reviews" VALUES(40,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-19 08:37:46');
INSERT INTO "reviews" VALUES(41,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-19 08:37:46');
INSERT INTO "reviews" VALUES(42,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-19 08:37:46');
INSERT INTO "reviews" VALUES(43,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-19 08:38:33');
INSERT INTO "reviews" VALUES(44,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-19 08:38:33');
INSERT INTO "reviews" VALUES(45,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-19 08:38:33');
INSERT INTO "reviews" VALUES(46,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-19 09:36:20');
INSERT INTO "reviews" VALUES(47,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-19 09:36:20');
INSERT INTO "reviews" VALUES(48,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-19 09:36:20');
INSERT INTO "reviews" VALUES(49,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-19 09:37:04');
INSERT INTO "reviews" VALUES(50,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-19 09:37:04');
INSERT INTO "reviews" VALUES(51,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-19 09:37:04');
INSERT INTO "reviews" VALUES(52,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-19 10:42:38');
INSERT INTO "reviews" VALUES(53,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-19 10:42:38');
INSERT INTO "reviews" VALUES(54,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-19 10:42:38');
INSERT INTO "reviews" VALUES(55,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-19 10:43:12');
INSERT INTO "reviews" VALUES(56,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-19 10:43:12');
INSERT INTO "reviews" VALUES(57,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-19 10:43:12');
INSERT INTO "reviews" VALUES(58,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-19 10:44:00');
INSERT INTO "reviews" VALUES(59,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-19 10:44:00');
INSERT INTO "reviews" VALUES(60,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-19 10:44:00');
INSERT INTO "reviews" VALUES(61,'Vikram S. (Demo)',5,'Clean haircut and exact fade. The place has a great ambiance and friendly vibe.','Haircut + Beard',1,1,'2026-09-19 10:44:05');
INSERT INTO "reviews" VALUES(62,'Rohit M. (Demo)',5,'Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.','Facial',1,1,'2026-09-19 10:44:05');
INSERT INTO "reviews" VALUES(63,'Aman K. (Demo)',5,'Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.','Beard',1,1,'2026-09-19 10:44:05');
CREATE TABLE services (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                price REAL NOT NULL CHECK(price >= 0),
                duration_minutes INTEGER NOT NULL DEFAULT 30 CHECK(duration_minutes > 0),
                description TEXT,
                is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
                display_order INTEGER NOT NULL DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
INSERT INTO "services" VALUES(1,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 17:48:27','2026-09-18 17:48:27');
INSERT INTO "services" VALUES(2,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 17:48:27','2026-09-18 17:48:27');
INSERT INTO "services" VALUES(3,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 17:48:27','2026-09-18 17:48:27');
INSERT INTO "services" VALUES(4,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 17:48:27','2026-09-18 17:48:27');
INSERT INTO "services" VALUES(5,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 17:48:27','2026-09-18 17:48:27');
INSERT INTO "services" VALUES(6,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 21:49:50','2026-09-18 21:49:50');
INSERT INTO "services" VALUES(7,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 21:49:50','2026-09-18 21:49:50');
INSERT INTO "services" VALUES(8,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 21:49:50','2026-09-18 21:49:50');
INSERT INTO "services" VALUES(9,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 21:49:50','2026-09-18 21:49:50');
INSERT INTO "services" VALUES(10,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 21:49:50','2026-09-18 21:49:50');
INSERT INTO "services" VALUES(11,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 21:50:31','2026-09-18 21:50:31');
INSERT INTO "services" VALUES(12,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 21:50:31','2026-09-18 21:50:31');
INSERT INTO "services" VALUES(13,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 21:50:31','2026-09-18 21:50:31');
INSERT INTO "services" VALUES(14,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 21:50:31','2026-09-18 21:50:31');
INSERT INTO "services" VALUES(15,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 21:50:31','2026-09-18 21:50:31');
INSERT INTO "services" VALUES(16,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 21:51:57','2026-09-18 21:51:57');
INSERT INTO "services" VALUES(17,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 21:51:57','2026-09-18 21:51:57');
INSERT INTO "services" VALUES(18,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 21:51:57','2026-09-18 21:51:57');
INSERT INTO "services" VALUES(19,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 21:51:57','2026-09-18 21:51:57');
INSERT INTO "services" VALUES(20,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 21:51:57','2026-09-18 21:51:57');
INSERT INTO "services" VALUES(21,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 21:52:18','2026-09-18 21:52:18');
INSERT INTO "services" VALUES(22,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 21:52:18','2026-09-18 21:52:18');
INSERT INTO "services" VALUES(23,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 21:52:18','2026-09-18 21:52:18');
INSERT INTO "services" VALUES(24,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 21:52:18','2026-09-18 21:52:18');
INSERT INTO "services" VALUES(25,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 21:52:18','2026-09-18 21:52:18');
INSERT INTO "services" VALUES(26,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 21:53:24','2026-09-18 21:53:24');
INSERT INTO "services" VALUES(27,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 21:53:24','2026-09-18 21:53:24');
INSERT INTO "services" VALUES(28,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 21:53:24','2026-09-18 21:53:24');
INSERT INTO "services" VALUES(29,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 21:53:24','2026-09-18 21:53:24');
INSERT INTO "services" VALUES(30,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 21:53:24','2026-09-18 21:53:24');
INSERT INTO "services" VALUES(31,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 21:54:06','2026-09-18 21:54:06');
INSERT INTO "services" VALUES(32,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 21:54:06','2026-09-18 21:54:06');
INSERT INTO "services" VALUES(33,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 21:54:06','2026-09-18 21:54:06');
INSERT INTO "services" VALUES(34,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 21:54:06','2026-09-18 21:54:06');
INSERT INTO "services" VALUES(35,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 21:54:06','2026-09-18 21:54:06');
INSERT INTO "services" VALUES(36,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 21:54:29','2026-09-18 21:54:29');
INSERT INTO "services" VALUES(37,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 21:54:29','2026-09-18 21:54:29');
INSERT INTO "services" VALUES(38,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 21:54:29','2026-09-18 21:54:29');
INSERT INTO "services" VALUES(39,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 21:54:29','2026-09-18 21:54:29');
INSERT INTO "services" VALUES(40,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 21:54:29','2026-09-18 21:54:29');
INSERT INTO "services" VALUES(41,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 21:56:19','2026-09-18 21:56:19');
INSERT INTO "services" VALUES(42,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 21:56:19','2026-09-18 21:56:19');
INSERT INTO "services" VALUES(43,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 21:56:19','2026-09-18 21:56:19');
INSERT INTO "services" VALUES(44,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 21:56:19','2026-09-18 21:56:19');
INSERT INTO "services" VALUES(45,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 21:56:19','2026-09-18 21:56:19');
INSERT INTO "services" VALUES(46,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 21:56:43','2026-09-18 21:56:43');
INSERT INTO "services" VALUES(47,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 21:56:43','2026-09-18 21:56:43');
INSERT INTO "services" VALUES(48,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 21:56:43','2026-09-18 21:56:43');
INSERT INTO "services" VALUES(49,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 21:56:43','2026-09-18 21:56:43');
INSERT INTO "services" VALUES(50,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 21:56:43','2026-09-18 21:56:43');
INSERT INTO "services" VALUES(51,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 21:58:44','2026-09-18 21:58:44');
INSERT INTO "services" VALUES(52,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 21:58:44','2026-09-18 21:58:44');
INSERT INTO "services" VALUES(53,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 21:58:44','2026-09-18 21:58:44');
INSERT INTO "services" VALUES(54,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 21:58:44','2026-09-18 21:58:44');
INSERT INTO "services" VALUES(55,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 21:58:44','2026-09-18 21:58:44');
INSERT INTO "services" VALUES(56,'Head Massage',120.0,20,'Relaxing scalp massage',1,6,'2026-09-18 21:58:47','2026-09-18 21:58:47');
INSERT INTO "services" VALUES(57,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 23:16:04','2026-09-18 23:16:04');
INSERT INTO "services" VALUES(58,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 23:16:04','2026-09-18 23:16:04');
INSERT INTO "services" VALUES(59,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 23:16:04','2026-09-18 23:16:04');
INSERT INTO "services" VALUES(60,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 23:16:04','2026-09-18 23:16:04');
INSERT INTO "services" VALUES(61,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 23:16:04','2026-09-18 23:16:04');
INSERT INTO "services" VALUES(62,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-18 23:17:28','2026-09-18 23:17:28');
INSERT INTO "services" VALUES(63,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-18 23:17:28','2026-09-18 23:17:28');
INSERT INTO "services" VALUES(64,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-18 23:17:28','2026-09-18 23:17:28');
INSERT INTO "services" VALUES(65,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-18 23:17:28','2026-09-18 23:17:28');
INSERT INTO "services" VALUES(66,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-18 23:17:28','2026-09-18 23:17:28');
INSERT INTO "services" VALUES(67,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-19 08:37:01','2026-09-19 08:37:01');
INSERT INTO "services" VALUES(68,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-19 08:37:01','2026-09-19 08:37:01');
INSERT INTO "services" VALUES(69,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-19 08:37:01','2026-09-19 08:37:01');
INSERT INTO "services" VALUES(70,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-19 08:37:01','2026-09-19 08:37:01');
INSERT INTO "services" VALUES(71,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-19 08:37:01','2026-09-19 08:37:01');
INSERT INTO "services" VALUES(72,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-19 08:37:46','2026-09-19 08:37:46');
INSERT INTO "services" VALUES(73,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-19 08:37:46','2026-09-19 08:37:46');
INSERT INTO "services" VALUES(74,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-19 08:37:46','2026-09-19 08:37:46');
INSERT INTO "services" VALUES(75,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-19 08:37:46','2026-09-19 08:37:46');
INSERT INTO "services" VALUES(76,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-19 08:37:46','2026-09-19 08:37:46');
INSERT INTO "services" VALUES(77,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-19 08:38:33','2026-09-19 08:38:33');
INSERT INTO "services" VALUES(78,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-19 08:38:33','2026-09-19 08:38:33');
INSERT INTO "services" VALUES(79,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-19 08:38:33','2026-09-19 08:38:33');
INSERT INTO "services" VALUES(80,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-19 08:38:33','2026-09-19 08:38:33');
INSERT INTO "services" VALUES(81,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-19 08:38:33','2026-09-19 08:38:33');
INSERT INTO "services" VALUES(82,'Head Massage',120.0,20,'Relaxing scalp massage',1,7,'2026-09-19 08:38:36','2026-09-19 08:38:36');
INSERT INTO "services" VALUES(83,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-19 09:36:20','2026-09-19 09:36:20');
INSERT INTO "services" VALUES(84,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-19 09:36:20','2026-09-19 09:36:20');
INSERT INTO "services" VALUES(85,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-19 09:36:20','2026-09-19 09:36:20');
INSERT INTO "services" VALUES(86,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-19 09:36:20','2026-09-19 09:36:20');
INSERT INTO "services" VALUES(87,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-19 09:36:20','2026-09-19 09:36:20');
INSERT INTO "services" VALUES(88,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-19 09:37:04','2026-09-19 09:37:04');
INSERT INTO "services" VALUES(89,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-19 09:37:04','2026-09-19 09:37:04');
INSERT INTO "services" VALUES(90,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-19 09:37:04','2026-09-19 09:37:04');
INSERT INTO "services" VALUES(91,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-19 09:37:04','2026-09-19 09:37:04');
INSERT INTO "services" VALUES(92,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-19 09:37:04','2026-09-19 09:37:04');
INSERT INTO "services" VALUES(93,'Head Massage',120.0,20,'Relaxing scalp massage',1,8,'2026-09-19 09:37:07','2026-09-19 09:37:07');
INSERT INTO "services" VALUES(94,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-19 10:42:38','2026-09-19 10:42:38');
INSERT INTO "services" VALUES(95,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-19 10:42:38','2026-09-19 10:42:38');
INSERT INTO "services" VALUES(96,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-19 10:42:38','2026-09-19 10:42:38');
INSERT INTO "services" VALUES(97,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-19 10:42:38','2026-09-19 10:42:38');
INSERT INTO "services" VALUES(98,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-19 10:42:38','2026-09-19 10:42:38');
INSERT INTO "services" VALUES(99,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-19 10:43:12','2026-09-19 10:43:12');
INSERT INTO "services" VALUES(100,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-19 10:43:12','2026-09-19 10:43:12');
INSERT INTO "services" VALUES(101,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-19 10:43:12','2026-09-19 10:43:12');
INSERT INTO "services" VALUES(102,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-19 10:43:12','2026-09-19 10:43:12');
INSERT INTO "services" VALUES(103,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-19 10:43:12','2026-09-19 10:43:12');
INSERT INTO "services" VALUES(104,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-19 10:44:00','2026-09-19 10:44:00');
INSERT INTO "services" VALUES(105,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-19 10:44:00','2026-09-19 10:44:00');
INSERT INTO "services" VALUES(106,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-19 10:44:00','2026-09-19 10:44:00');
INSERT INTO "services" VALUES(107,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-19 10:44:00','2026-09-19 10:44:00');
INSERT INTO "services" VALUES(108,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-19 10:44:00','2026-09-19 10:44:00');
INSERT INTO "services" VALUES(109,'Head Massage',120.0,20,'Relaxing scalp massage',1,9,'2026-09-19 10:44:03','2026-09-19 10:44:03');
INSERT INTO "services" VALUES(110,'Haircut',100.0,30,'Tailored haircut with scissor & clipper precision, finished with clean styling.',1,1,'2026-09-19 10:44:05','2026-09-19 10:44:05');
INSERT INTO "services" VALUES(111,'Beard',70.0,20,'Beard shaping, line-up, and trimming tailored to your face shape.',1,2,'2026-09-19 10:44:05','2026-09-19 10:44:05');
INSERT INTO "services" VALUES(112,'Haircut + Beard',150.0,45,'Complete signature grooming combo: precision haircut paired with beard sculpting.',1,3,'2026-09-19 10:44:05','2026-09-19 10:44:05');
INSERT INTO "services" VALUES(113,'Facial',300.0,45,'Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.',1,4,'2026-09-19 10:44:05','2026-09-19 10:44:05');
INSERT INTO "services" VALUES(114,'D-Tan',300.0,45,'Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.',1,5,'2026-09-19 10:44:05','2026-09-19 10:44:05');
CREATE TABLE sessions (
                session_id TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                role TEXT NOT NULL DEFAULT 'customer',
                expires_at DATETIME NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
INSERT INTO "sessions" VALUES('LBUTpjiToAuXGN242LKbdHitKt3HlAMrkjNlVgp_10k',3,'customer','2026-09-25 17:57:32','2026-09-18 17:57:32');
INSERT INTO "sessions" VALUES('rYhUImNGcX7xeDp4XdsexC7f-3j5JpU85SPgUHPMr_g',3,'customer','2026-09-25 17:57:33','2026-09-18 17:57:33');
INSERT INTO "sessions" VALUES('5LFl1ehEF5ufXFy-lGuySDn-O-Eo6FCgaKul9dalxrg',5,'customer','2026-09-25 21:20:54','2026-09-18 21:20:54');
INSERT INTO "sessions" VALUES('x6363lBkH77OeorZHILTOMO8nN6xEsJN4uISsKP45LQ',5,'customer','2026-09-25 21:20:55','2026-09-18 21:20:55');
INSERT INTO "sessions" VALUES('i5U83yH6Dc6oYRnQlGLvzH5e80ZuWlxWh73tVZ9yBsM',18,'customer','2026-09-25 23:17:29','2026-09-18 23:17:29');
INSERT INTO "sessions" VALUES('B_X_OEAr9OL3v4nHxA6tNBPfhksydVU5iXCdmMmaW6I',40,'customer','2026-09-26 10:44:01','2026-09-19 10:44:01');
INSERT INTO "sessions" VALUES('xVAg9dkXDWSCLwvNvHIclQsXGaE2SrcHxRjy025cDrQ',41,'admin','2026-09-26 10:44:02','2026-09-19 10:44:02');
INSERT INTO "sessions" VALUES('WFxUUjEDUPJIYAX7ibNJR8YWQnKtWdT-KopmhHtExDE',40,'customer','2026-09-26 10:44:03','2026-09-19 10:44:03');
INSERT INTO "sessions" VALUES('DwnhkISbUuy633_ACfaH-HBv9Q9KE-DhBsL5YBuMyb8',42,'customer','2026-09-26 10:44:03','2026-09-19 10:44:03');
INSERT INTO "sessions" VALUES('jkBZ_NwfpG12GF9UezjYb8q-Vs_kwqACHZCGtlOCZ1E',43,'admin','2026-09-26 10:44:06','2026-09-19 10:44:06');
INSERT INTO "sessions" VALUES('nITAp2R6hO9CKoRsFSb1PRiJB2XNNmJsaiBT0eD5swE',43,'admin','2026-09-26 10:44:06','2026-09-19 10:44:06');
CREATE TABLE users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                full_name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL COLLATE NOCASE,
                phone TEXT,
                password_hash TEXT NOT NULL,
                role TEXT NOT NULL DEFAULT 'customer' CHECK(role IN ('customer', 'admin')),
                oauth_provider TEXT CHECK(oauth_provider IN ('google', 'facebook', NULL)),
                oauth_id TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
INSERT INTO "users" VALUES(3,'Rahul Sharma','rahul.test@example.com','9876543210','pbkdf2:sha256:260000$f61d6e8b005accdfd82b030c64af45cc$bd88aa33dabe095129038a07cc3c19c44fb1b45e9eb302387e2edd63b5900d07','customer',NULL,NULL,'2026-09-18 17:57:32','2026-09-18 17:57:32');
INSERT INTO "users" VALUES(5,'Deepak Verma','customer.verify@example.com','9811223344','pbkdf2:sha256:260000$81261056dd78e19a132fdc4413f9994d$ab1eae4b334f72b83b4863993ccd7f2e920cda376f0183a843548952f5a46d56','customer',NULL,NULL,'2026-09-18 21:20:54','2026-09-18 21:20:54');
INSERT INTO "users" VALUES(18,'Test Customer 311','customer311@example.com','9876543210','pbkdf2:sha256:260000$7ef2e13721f107a9569dbf2d19918466$478cc981d4a0d658a8e1aa8a757c665b62d506516b74939e89466c6a4379c86e','customer',NULL,NULL,'2026-09-18 23:17:29','2026-09-18 23:17:29');
INSERT INTO "users" VALUES(37,'Studio Head','render.owner@stylezone.local',NULL,'pbkdf2:sha256:260000$0265f98e84895262ff361277b6a9d1ab$c6f2db0e9394d5523c45b060f60bc758512ac6343e54eaeb9b52556ddc1cff2e','admin',NULL,NULL,'2026-09-19 10:43:55','2026-09-19 10:43:55');
INSERT INTO "users" VALUES(40,'Ayush Verma','ayush.verma@example.com','9811223344','pbkdf2:sha256:260000$22debcc8c0b3477466d1896b6dd22946$aa9b550469473133dd3b37579e45f616c18003f212a6c42f1b5e67619b4a30a3','customer',NULL,NULL,'2026-09-19 10:44:01','2026-09-19 10:44:01');
INSERT INTO "users" VALUES(41,'Studio Owner','admin.owner@stylezone.local','','pbkdf2:sha256:260000$6e4d08748a17da107bc24b5e8941f170$b8323a04719d433635de9a960198418e9052edc48cbf57d970c05b2d8419f1d9','admin',NULL,NULL,'2026-09-19 10:44:02','2026-09-19 10:44:02');
INSERT INTO "users" VALUES(42,'Stranger User','stranger@example.com','','pbkdf2:sha256:260000$cedc5478510c8f1d60949fa461f282a9$096fa258b92f220c193afd412c21cf37d2cb87b1cc7744d2b756110941c01ec7','customer',NULL,NULL,'2026-09-19 10:44:03','2026-09-19 10:44:03');
INSERT INTO "users" VALUES(43,'Schedule Admin','admin.hours.test@stylezone.local','','pbkdf2:sha256:260000$2c9cb264318e26d59ea25449e8433eee$5aeadc50d34bff82f5e9251eea142945ce582f565776263ce38cf23684ccc0d1','admin',NULL,NULL,'2026-09-19 10:44:05','2026-09-19 10:44:05');
CREATE UNIQUE INDEX idx_unique_active_slot 
            ON appointments(appointment_date, start_time) 
            WHERE status != 'cancelled';
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_customer ON appointments(customer_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_blocked_slots_date ON blocked_slots(date);
DELETE FROM "sqlite_sequence";
INSERT INTO "sqlite_sequence" VALUES('services',114);
INSERT INTO "sqlite_sequence" VALUES('gallery',168);
INSERT INTO "sqlite_sequence" VALUES('reviews',63);
INSERT INTO "sqlite_sequence" VALUES('users',43);
INSERT INTO "sqlite_sequence" VALUES('appointments',12);
INSERT INTO "sqlite_sequence" VALUES('password_reset_tokens',13);
INSERT INTO "sqlite_sequence" VALUES('blocked_slots',4);
INSERT INTO "sqlite_sequence" VALUES('holidays',1);
COMMIT;
