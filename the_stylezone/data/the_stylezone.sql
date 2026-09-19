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
INSERT INTO "appointments" VALUES(6,'SZ-20260921-2EEF',15,'Ayush Verma','ayush.verma@example.com','9811223344',1,'Haircut',100.0,'2026-09-21','09:30','10:00','cancelled','Test cancel','customer','VIP haircut request','unpaid','cash_at_counter','2026-09-18 21:58:46','2026-09-18 21:58:47');
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
INSERT INTO "blocked_slots" VALUES(1,'2026-09-21','15:00','16:00','Studio Power Maintenance',7,'2026-09-18 21:58:47');
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
INSERT INTO "business_hours" VALUES(0,'Monday',1,'09:30','20:30',1,'13:00','14:00','2026-09-18 21:58:46');
INSERT INTO "business_hours" VALUES(1,'Tuesday',1,'09:30','20:30',0,NULL,NULL,'2026-09-18 21:58:46');
INSERT INTO "business_hours" VALUES(2,'Wednesday',1,'09:30','20:30',0,NULL,NULL,'2026-09-18 21:58:46');
INSERT INTO "business_hours" VALUES(3,'Thursday',1,'09:30','20:30',0,NULL,NULL,'2026-09-18 21:58:46');
INSERT INTO "business_hours" VALUES(4,'Friday',1,'09:30','20:30',0,NULL,NULL,'2026-09-18 21:58:46');
INSERT INTO "business_hours" VALUES(5,'Saturday',1,'09:30','20:30',0,NULL,NULL,'2026-09-18 21:58:46');
INSERT INTO "business_hours" VALUES(6,'Sunday',0,NULL,NULL,0,NULL,NULL,'2026-09-18 21:58:46');
CREATE TABLE business_settings (
                key TEXT PRIMARY KEY,
                value TEXT,
                description TEXT,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
INSERT INTO "business_settings" VALUES('business_name','The Stylezone','Official business name','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('address','Street no 32, Vipin Garden Extension, Dwarka Mor, Delhi','Official shop address','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('phone_number','','Contact phone number (Configure in Admin)','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('whatsapp_number','','WhatsApp booking number (Configure in Admin)','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('instagram_url','','Instagram profile link (Configure in Admin)','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('google_maps_url','','Google Maps embed or link (Configure in Admin)','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('hero_headline','Refined Grooming For The Modern Gentleman','Main headline on public hero section','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('hero_description','Experience precision haircuts, master beard sculpting, and revitalizing skin treatments in Dwarka Mor, Delhi.','Hero subheading','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('about_text','The Stylezone brings refined grooming and sharp craftsmanship to Dwarka Mor, Delhi. Dedicated to delivering consistent quality for every client.','About section text','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('why_choose_us_text','Focused styling expertise, comfortable ambiance, and dedicated attention tailored to your personal aesthetic.','Why Choose Us text','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('footer_text','© 2026 The Stylezone. All rights reserved.','Footer text','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('cancellation_window_hours','2','Minimum hours before appointment required for customer self-cancellation','2026-09-18 21:58:44');
INSERT INTO "business_settings" VALUES('booking_enabled','1','Master toggle for online booking (1 = enabled, 0 = disabled)','2026-09-18 21:58:46');
INSERT INTO "business_settings" VALUES('slot_duration_minutes','30','Default booking slot interval in minutes','2026-09-18 21:58:46');
INSERT INTO "business_settings" VALUES('hours_configured','1','Whether operating hours have been set by the admin (0=unconfigured, 1=configured)','2026-09-18 21:58:46');
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
INSERT INTO "password_reset_tokens" VALUES(7,15,'63e1c66dcda01b68fd97ad22cd653a52fa6b077f117c069fb76ebe78b213cde9','2026-09-18 22:28:45',0,'2026-09-18 21:58:45');
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
CREATE TABLE sessions (
                session_id TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                role TEXT NOT NULL DEFAULT 'customer',
                expires_at DATETIME NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
INSERT INTO "sessions" VALUES('yf8YKohxLaedwSvcKB-hq5et8vPp_sPCig8_qO240fE',1,'admin','2026-09-25 17:56:02','2026-09-18 17:56:02');
INSERT INTO "sessions" VALUES('LBUTpjiToAuXGN242LKbdHitKt3HlAMrkjNlVgp_10k',3,'customer','2026-09-25 17:57:32','2026-09-18 17:57:32');
INSERT INTO "sessions" VALUES('rYhUImNGcX7xeDp4XdsexC7f-3j5JpU85SPgUHPMr_g',3,'customer','2026-09-25 17:57:33','2026-09-18 17:57:33');
INSERT INTO "sessions" VALUES('xwPDnv58iJmBV2DBpiK91IcxE_lzYdAiQzaon3TEqZY',1,'admin','2026-09-25 17:57:34','2026-09-18 17:57:34');
INSERT INTO "sessions" VALUES('5LFl1ehEF5ufXFy-lGuySDn-O-Eo6FCgaKul9dalxrg',5,'customer','2026-09-25 21:20:54','2026-09-18 21:20:54');
INSERT INTO "sessions" VALUES('x6363lBkH77OeorZHILTOMO8nN6xEsJN4uISsKP45LQ',5,'customer','2026-09-25 21:20:55','2026-09-18 21:20:55');
INSERT INTO "sessions" VALUES('woN8d8vbZCr9jlr0iIHs4XEltNeEsVdkkVLtnxoQGLk',4,'admin','2026-09-25 21:20:55','2026-09-18 21:20:55');
INSERT INTO "sessions" VALUES('fsGtw8gp4RJoxNbaSEyi22keExj3ZSd7_61E_MeBoQE',7,'admin','2026-09-25 21:52:20','2026-09-18 21:52:20');
INSERT INTO "sessions" VALUES('GeN-G_NFbwr_tFxjuGWLoQymGn-LCNHQsHxYP6_arVM',7,'admin','2026-09-25 21:53:26','2026-09-18 21:53:26');
INSERT INTO "sessions" VALUES('eqJ4WP0VAl7vMu3OZuBgtjIBRqTL1GN1wyI3ZNKb0s4',7,'admin','2026-09-25 21:54:07','2026-09-18 21:54:07');
INSERT INTO "sessions" VALUES('_YJDQkM9CySQEygPeGVvH9JBzIpNWIJTpbGR8FlDO8c',7,'admin','2026-09-25 21:54:30','2026-09-18 21:54:30');
INSERT INTO "sessions" VALUES('s1Dy2AJhGjXUFfIpGAya96okYQl6Eyky8vC7PTOPQ0E',7,'admin','2026-09-25 21:56:21','2026-09-18 21:56:21');
INSERT INTO "sessions" VALUES('kXrHVmZGGATxj0zsmqk1_D4Guhvh_bFb4EvX5GIPIJQ',7,'admin','2026-09-25 21:56:44','2026-09-18 21:56:44');
INSERT INTO "sessions" VALUES('5uMttA7imPDPdVghBACLKNwofBCg8NiJpQGiGi86SQA',15,'customer','2026-09-25 21:58:45','2026-09-18 21:58:45');
INSERT INTO "sessions" VALUES('KHsJpOzWsWIk_kZH-ZqVECGWvHhAfvE9maBzkF0sra4',7,'admin','2026-09-25 21:58:46','2026-09-18 21:58:46');
INSERT INTO "sessions" VALUES('A4iip0a1My0CyO99O-zxaj6qhPyOzwVNO-IvaW1_eg0',15,'customer','2026-09-25 21:58:46','2026-09-18 21:58:46');
INSERT INTO "sessions" VALUES('o8TFycwTyyWYDf9BYmo8DrDuh6sVuqyZSfSMQ-csOrA',16,'customer','2026-09-25 21:58:47','2026-09-18 21:58:47');
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
INSERT INTO "users" VALUES(1,'Owner - The Stylezone','admin@stylezone.com','','pbkdf2:sha256:260000$0d22072ba071db1e96aaedd73ad6e886$6d8b3c5559f5a556b2764f2fbc07384ec12802343fcce1827c6efc87dedd20d2','admin',NULL,NULL,'2026-09-18 17:48:27','2026-09-18 17:48:27');
INSERT INTO "users" VALUES(3,'Rahul Sharma','rahul.test@example.com','9876543210','pbkdf2:sha256:260000$f61d6e8b005accdfd82b030c64af45cc$bd88aa33dabe095129038a07cc3c19c44fb1b45e9eb302387e2edd63b5900d07','customer',NULL,NULL,'2026-09-18 17:57:32','2026-09-18 17:57:32');
INSERT INTO "users" VALUES(4,'Test Administrator','test.admin@stylezone.local','','pbkdf2:sha256:260000$6afb9bdbbd259e9c6efaefa545b7d84a$748d06b71c9bc026c9bb4092f1c4938be9c3f9400fe0e115dcd50f799afbd7b2','admin',NULL,NULL,'2026-09-18 21:20:53','2026-09-18 21:20:53');
INSERT INTO "users" VALUES(5,'Deepak Verma','customer.verify@example.com','9811223344','pbkdf2:sha256:260000$81261056dd78e19a132fdc4413f9994d$ab1eae4b334f72b83b4863993ccd7f2e920cda376f0183a843548952f5a46d56','customer',NULL,NULL,'2026-09-18 21:20:54','2026-09-18 21:20:54');
INSERT INTO "users" VALUES(7,'Studio Owner','admin.owner@stylezone.local','','pbkdf2:sha256:260000$4e3884d0f5387b05803c3db9e130b147$97198b5ca6cf89df9b5546dd67c5ce0a241ddc65cd695035e22bf824cd8b6883','admin',NULL,NULL,'2026-09-18 21:52:19','2026-09-18 21:58:45');
INSERT INTO "users" VALUES(15,'Ayush Verma','ayush.verma@example.com','9811223344','pbkdf2:sha256:260000$f5e87a3eee00ea6f2b882f3aa4365d6a$c1aa83665b1b177d8bf817d381048dea2d70eb1fafdd1fde978c936282bbbb80','customer',NULL,NULL,'2026-09-18 21:58:44','2026-09-18 21:58:44');
INSERT INTO "users" VALUES(16,'Stranger User','stranger@example.com','','pbkdf2:sha256:260000$ba054c214a5a2ceb54e2a6fc0badc581$ce3e22ab67ddafe39e5621b9ddd1d1edd33e3369a8b951f6470ff278bbed0ff3','customer',NULL,NULL,'2026-09-18 21:58:47','2026-09-18 21:58:47');
CREATE UNIQUE INDEX idx_unique_active_slot 
            ON appointments(appointment_date, start_time) 
            WHERE status != 'cancelled';
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_customer ON appointments(customer_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_blocked_slots_date ON blocked_slots(date);
DELETE FROM "sqlite_sequence";
INSERT INTO "sqlite_sequence" VALUES('services',56);
INSERT INTO "sqlite_sequence" VALUES('gallery',80);
INSERT INTO "sqlite_sequence" VALUES('reviews',30);
INSERT INTO "sqlite_sequence" VALUES('users',16);
INSERT INTO "sqlite_sequence" VALUES('appointments',6);
INSERT INTO "sqlite_sequence" VALUES('password_reset_tokens',7);
INSERT INTO "sqlite_sequence" VALUES('blocked_slots',1);
INSERT INTO "sqlite_sequence" VALUES('holidays',1);
COMMIT;
