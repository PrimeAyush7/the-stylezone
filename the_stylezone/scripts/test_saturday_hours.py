import sys
import unittest
from datetime import date, timedelta
from pathlib import Path
from starlette.testclient import TestClient

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

import app
import main
from app.database import query_one, query_all, execute_query, set_setting
from scripts.create_admin import create_admin
from scripts.seed_demo import seed_database

client = TestClient(main.app)

class TestSaturdayBusinessHours(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        seed_database()
        cls.admin_email = "admin.hours.test@stylezone.local"
        cls.admin_pw = "AdminSecretPass2026!"
        create_admin("Schedule Admin", cls.admin_email, cls.admin_pw)

    def setUp(self):
        # Obtain CSRF token and admin session
        r_home = client.get("/")
        self.csrf = client.cookies.get("stylezone_csrf") or r_home.cookies.get("stylezone_csrf")

        r_log = client.post("/admin/login", data={
            "email": self.admin_email,
            "password": self.admin_pw,
            "csrf_token": self.csrf
        }, follow_redirects=False)
        self.admin_session = r_log.cookies.get("stylezone_session")
        self.assertIsNotNone(self.admin_session)

    def test_saturday_open_08_to_22_flow(self):
        """
        Configure Monday-Sunday open, 08:00-22:00, with Saturday Weekly Off unchecked.
        Verify:
        - DB saves Saturday as is_open=1, open_time='08:00', close_time='22:00'
        - Customer availability endpoint for Saturday returns available=True, is_open=True
        - Slots begin at 08:00 and end at 22:00
        - Customer can successfully book a Saturday slot
        """
        # Form payload: Monday-Sunday open 08:00 to 22:00
        # Saturday (dow=5) Weekly Off unchecked (not passed in form)
        form_data = {
            "csrf_token": self.csrf,
            "booking_enabled": "on",
            "slot_duration_minutes": "30",
        }
        for dow in range(7):
            form_data[f"open_time_{dow}"] = "08:00"
            form_data[f"close_time_{dow}"] = "22:00"
            # If Sunday (dow=6), simulate Weekly Off checked:
            if dow == 6:
                form_data[f"weekly_off_{dow}"] = "on"
            # For dow=5 (Saturday), weekly_off_5 is UNCHECKED (omitted from form)
            # For dow=0..4, weekly_off is also omitted (open)

        r_save = client.post(
            "/admin/hours",
            data=form_data,
            cookies={"stylezone_session": self.admin_session, "stylezone_csrf": self.csrf},
            follow_redirects=False
        )
        self.assertEqual(r_save.status_code, 303)

        # 1. Verify Database Business Hours for Saturday
        sat_row = query_one("SELECT * FROM business_hours WHERE day_of_week = 5")
        self.assertEqual(sat_row["day_name"], "Saturday")
        self.assertEqual(sat_row["is_open"], 1, "Saturday must be saved as is_open=1 when Weekly Off is unchecked")
        self.assertEqual(sat_row["open_time"], "08:00", "Saturday opening time must be 08:00")
        self.assertEqual(sat_row["close_time"], "22:00", "Saturday closing time must be 22:00")

        # 2. Find upcoming Saturday date
        today = date.today()
        days_to_sat = (5 - today.weekday()) % 7
        if days_to_sat == 0:
            days_to_sat = 7
        target_saturday = (today + timedelta(days=days_to_sat)).strftime("%Y-%m-%d")

        # 3. Customer Availability Endpoint Check for Saturday
        r_avail = client.get(f"/api/public/availability?date={target_saturday}&service_id=1")
        self.assertEqual(r_avail.status_code, 200)
        avail_json = r_avail.json()

        self.assertTrue(avail_json.get("available"), "Saturday must be available for booking")
        self.assertNotIn("closed on Saturdays", avail_json.get("message", ""))
        self.assertEqual(avail_json.get("open_time"), "08:00")
        self.assertEqual(avail_json.get("close_time"), "22:00")

        slots = avail_json.get("slots", [])
        self.assertGreater(len(slots), 0, "Saturday must return active slots")
        self.assertEqual(slots[0]["time"], "08:00", "First slot must start at 08:00")
        self.assertEqual(slots[-1]["end_time"], "22:00", "Last slot must end at 22:00")

        # 4. Verify Sunday is closed (Weekly Off was checked)
        target_sunday = (today + timedelta(days=days_to_sat + 1)).strftime("%Y-%m-%d")
        r_sun_avail = client.get(f"/api/public/availability?date={target_sunday}&service_id=1")
        self.assertEqual(r_sun_avail.status_code, 200)
        sun_json = r_sun_avail.json()
        self.assertFalse(sun_json.get("available"))
        self.assertFalse(sun_json.get("is_open"))
        self.assertIn("The Stylezone is closed on Sundays (Weekly Off).", sun_json.get("message", ""))

        # 5. Customer Booking on Saturday
        r_book = client.post("/api/bookings/create", json={
            "service_id": 1,
            "appointment_date": target_saturday,
            "start_time": "08:00",
            "name": "Aman Saturday Client",
            "email": "aman.sat@example.com",
            "phone": "9998887776",
            "notes": "Saturday morning booking",
            "csrf_token": self.csrf
        }, headers={"X-CSRF-Token": self.csrf})

        self.assertEqual(r_book.status_code, 200)
        booking_data = r_book.json()
        self.assertTrue(booking_data.get("success"))
        self.assertEqual(booking_data["booking"]["start_time"], "08:00")
        self.assertEqual(booking_data["booking"]["appointment_date"], target_saturday)

    def test_break_checkbox_enabled_vs_disabled(self):
        """
        Verify break is respected only when has_break checkbox is enabled.
        """
        today = date.today()
        days_to_mon = (0 - today.weekday()) % 7
        if days_to_mon == 0:
            days_to_mon = 7
        target_monday = (today + timedelta(days=days_to_mon)).strftime("%Y-%m-%d")

        # Case A: Break ENABLED on Monday (13:00 - 14:00)
        form_data = {
            "csrf_token": self.csrf,
            "booking_enabled": "on",
            "open_time_0": "08:00",
            "close_time_0": "22:00",
            "has_break_0": "on",
            "break_start_0": "13:00",
            "break_end_0": "14:00",
        }
        for d in range(1, 7):
            form_data[f"open_time_{d}"] = "08:00"
            form_data[f"close_time_{d}"] = "22:00"

        client.post("/admin/hours", data=form_data, cookies={"stylezone_session": self.admin_session}, follow_redirects=False)

        r_avail = client.get(f"/api/public/availability?date={target_monday}&service_id=1").json()
        slot_1300 = next(s for s in r_avail["slots"] if s["time"] == "13:00")
        self.assertFalse(slot_1300["available"])
        self.assertEqual(slot_1300["reason"], "Shop Break")

        # Case B: Break DISABLED on Monday (has_break unchecked)
        form_data_no_break = {
            "csrf_token": self.csrf,
            "booking_enabled": "on",
            "open_time_0": "08:00",
            "close_time_0": "22:00",
            # has_break_0 omitted / unchecked
            "break_start_0": "13:00",
            "break_end_0": "14:00",
        }
        for d in range(1, 7):
            form_data_no_break[f"open_time_{d}"] = "08:00"
            form_data_no_break[f"close_time_{d}"] = "22:00"

        client.post("/admin/hours", data=form_data_no_break, cookies={"stylezone_session": self.admin_session}, follow_redirects=False)

        r_avail_no_break = client.get(f"/api/public/availability?date={target_monday}&service_id=1").json()
        slot_1300_open = next(s for s in r_avail_no_break["slots"] if s["time"] == "13:00")
        self.assertTrue(slot_1300_open["available"], "When break checkbox is disabled, 13:00 slot must be available")

if __name__ == "__main__":
    unittest.main()
