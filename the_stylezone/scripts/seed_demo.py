import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

from app.database import get_db, init_db, save_db_snapshot, set_setting, query_one

def seed_database():
    print("Seeding The Stylezone database...")
    init_db()

    with get_db() as conn:
        cursor = conn.cursor()

        # 1. Business Settings
        set_setting("business_name", "The Stylezone", "Official business name")
        set_setting("address", "Street no 32, Vipin Garden Extension, Dwarka Mor, Delhi", "Official shop address")
        # Empty contact info - DO NOT INVENT! Admin will configure these.
        set_setting("phone_number", "", "Contact phone number (Configure in Admin)")
        set_setting("whatsapp_number", "", "WhatsApp booking number (Configure in Admin)")
        set_setting("instagram_url", "", "Instagram profile link (Configure in Admin)")
        set_setting("google_maps_url", "", "Google Maps embed or link (Configure in Admin)")
        set_setting("hero_headline", "Refined Grooming For The Modern Gentleman", "Main headline on public hero section")
        set_setting("hero_description", "Experience precision haircuts, master beard sculpting, and revitalizing skin treatments in Dwarka Mor, Delhi.", "Hero subheading")
        set_setting("about_text", "The Stylezone brings refined grooming and sharp craftsmanship to Dwarka Mor, Delhi. Dedicated to delivering consistent quality for every client.", "About section text")
        set_setting("why_choose_us_text", "Focused styling expertise, comfortable ambiance, and dedicated attention tailored to your personal aesthetic.", "Why Choose Us text")
        set_setting("footer_text", "© 2026 The Stylezone. All rights reserved.", "Footer text")
        set_setting("cancellation_window_hours", "2", "Minimum hours before appointment required for customer self-cancellation")
        set_setting("booking_enabled", "1", "Master toggle for online booking")
        set_setting("slot_duration_minutes", "30", "Default booking slot interval in minutes")
        
        # IMPORTANT: Do not assume or invent business hours! Hours start unconfigured.
        set_setting("hours_configured", "0", "Whether operating hours have been set by the admin (0=unconfigured, 1=configured)")

        # 2. Confirmed Services (Strictly matching business specs)
        services_data = [
            ("Haircut", 100.0, 30, "Tailored haircut with scissor & clipper precision, finished with clean styling.", 1),
            ("Beard", 70.0, 20, "Beard shaping, line-up, and trimming tailored to your face shape.", 2),
            ("Haircut + Beard", 150.0, 45, "Complete signature grooming combo: precision haircut paired with beard sculpting.", 3),
            ("Facial", 300.0, 45, "Deep cleansing facial treatment that cleanses pores and rejuvenates your skin.", 4),
            ("D-Tan", 300.0, 45, "Specialized skin de-tanning treatment to restore natural tone and clear sun exposure.", 5)
        ]

        for name, price, duration, desc, order in services_data:
            cursor.execute("""
            INSERT INTO services (name, price, duration_minutes, description, is_active, display_order, created_at, updated_at)
            VALUES (?, ?, ?, ?, 1, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT DO NOTHING;
            """, (name, price, duration, desc, order))

        # 3. Business Hours table: Days initialized, but marked unconfigured / closed until admin sets them!
        days = [
            (0, "Monday"),
            (1, "Tuesday"),
            (2, "Wednesday"),
            (3, "Thursday"),
            (4, "Friday"),
            (5, "Saturday"),
            (6, "Sunday"),
        ]

        for dow, day_name in days:
            cursor.execute("""
            INSERT INTO business_hours (day_of_week, day_name, is_open, open_time, close_time, has_break, break_start, break_end, updated_at)
            VALUES (?, ?, 0, NULL, NULL, 0, NULL, NULL, CURRENT_TIMESTAMP)
            ON CONFLICT(day_of_week) DO NOTHING;
            """, (dow, day_name))

        # 4. Lookbook / Gallery (Model photography clearly marked as demonstration placeholders)
        gallery_items = [
            ("Classic Pompadour Fade", "Haircut", "https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800&auto=format&fit=crop&q=80", "High skin fade paired with a classic styled pompadour top.", 1),
            ("Textured Crop & Low Fade", "Haircut", "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&auto=format&fit=crop&q=80", "Modern blunt crop with natural textured layering and clean edges.", 2),
            ("Executive Side Part", "Haircut", "https://images.unsplash.com/photo-1517832606589-715753d4f323?w=800&auto=format&fit=crop&q=80", "Sophisticated gentleman's taper with sharp parting and glossy finish.", 3),
            ("Sculpted Beard & Razor Fade", "Beard", "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80", "Crisp cheek line definition with graduated chin thickness.", 4),
            ("Signature Haircut & Full Beard", "Hair + Beard", "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80", "Harmonious blend of mid-fade haircut and full contoured beard.", 5),
            ("Modern Quiff with Clean Taper", "Styling", "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80", "Voluminous lifted quiff with clean natural temple taper.", 6),
            ("Precision Buzz Cut & Shape Up", "Haircut", "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80", "Clean military buzz cut with razor-sharp hairline perimeter.", 7),
            ("Rejuvenating Grooming & Skin Care", "Grooming", "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80", "Fresh, revitalized appearance post-facial & D-Tan care.", 8)
        ]

        for title, cat, img_url, desc, order in gallery_items:
            cursor.execute("""
            INSERT INTO gallery (title, category, image_url, description, is_active, display_order, is_placeholder, created_at)
            VALUES (?, ?, ?, ?, 1, ?, 1, CURRENT_TIMESTAMP)
            ON CONFLICT DO NOTHING;
            """, (title, cat, img_url, desc, order))

        # 5. Reviews - Clearly marked as DEMO (removable with 1 click in admin)
        demo_reviews = [
            ("Vikram S. (Demo)", 5, "Clean haircut and exact fade. The place has a great ambiance and friendly vibe.", "Haircut + Beard"),
            ("Rohit M. (Demo)", 5, "Tried the Facial and D-Tan treatment. Immediate freshness and very relaxed experience.", "Facial"),
            ("Aman K. (Demo)", 5, "Best beard line-up in Dwarka Mor. Sharp razor work and great symmetry.", "Beard")
        ]

        for author, rating, content, service in demo_reviews:
            cursor.execute("""
            INSERT INTO reviews (author_name, rating, content, service_mentioned, is_active, is_demo, created_at)
            VALUES (?, ?, ?, ?, 1, 1, CURRENT_TIMESTAMP)
            ON CONFLICT DO NOTHING;
            """, (author, rating, content, service))

        conn.commit()

    save_db_snapshot()
    print("Database seeded! Notice: Business hours remain unconfigured until admin sets them in /admin/hours.")

if __name__ == "__main__":
    seed_database()
