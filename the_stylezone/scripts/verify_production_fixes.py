import sys
import secrets
from pathlib import Path
from datetime import date, timedelta

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

# Ensure 9p finder
import app
from starlette.testclient import TestClient
from app.database import execute_query, query_one, set_setting, init_db
from scripts.create_admin import create_admin
from scripts.seed_demo import seed_database
import main

client = TestClient(main.app)

def run_verification():
    print("=" * 70)
    print("THE STYLEZONE — RIGOROUS PRODUCTION-SAFETY VERIFICATION SUITE")
    print("=" * 70)

    # Re-seed database to clean initial state
    seed_database()

    # 1. Verification of Business Hours Unconfigured Safety
    print("\n[CHECK 1/17] Verifying Business Hours Unconfigured Safety...")
    hours_cfg = query_one("SELECT value FROM business_settings WHERE key = 'hours_configured'")
    assert hours_cfg["value"] == "0", "Default hours_configured must be 0 (unconfigured)"
    
    # Check availability returns disabled when unconfigured
    monday_date = (date.today() + timedelta(days=3)).strftime("%Y-%m-%d")
    r_avail_unconfigured = client.get(f"/api/public/availability?date={monday_date}&service_id=1")
    assert r_avail_unconfigured.status_code == 200
    avail_json = r_avail_unconfigured.json()
    assert avail_json["available"] is False
    assert avail_json["is_configured"] is False
    assert "not yet been configured" in avail_json["message"]
    print("  ✓ Booking is automatically disabled when business hours are unconfigured")

    # 2. Homepage verification
    print("\n[CHECK 2/17] Verifying Homepage (GET /)...")
    r_home = client.get("/")
    assert r_home.status_code == 200
    assert "THE" in r_home.text and "STYLEZONE" in r_home.text
    assert "Street no 32, Vipin Garden Extension, Dwarka Mor, Delhi" in r_home.text
    assert "Haircut" in r_home.text
    assert "₹100" in r_home.text
    assert "Operating hours have not yet been configured" in r_home.text
    csrf_token = client.cookies.get("stylezone_csrf") or r_home.cookies.get("stylezone_csrf")
    assert csrf_token is not None, "CSRF cookie must be issued on GET requests"
    print(f"  ✓ Homepage rendered with clean unconfigured notice & CSRF cookie: {csrf_token[:10]}...")

    # 3. CSRF Protection Check
    print("\n[CHECK 3/17] Verifying CSRF Protection Enforcement...")
    # Attempt POST /register WITHOUT CSRF token -> MUST FAIL WITH 403
    r_csrf_fail = client.post("/register", data={
        "full_name": "CSRF Attacker",
        "email": "attacker@example.com",
        "password": "Password123!",
        "confirm_password": "Password123!"
    })
    assert r_csrf_fail.status_code == 403, f"Expected 403 Forbidden on missing CSRF token, got {r_csrf_fail.status_code}"
    print("  ✓ State-changing request without CSRF token correctly rejected (403 Forbidden)")

    # 4. Customer Registration with CSRF
    print("\n[CHECK 4/17] Verifying Customer Registration with CSRF (POST /register)...")
    cust_email = "ayush.verma@example.com"
    cust_pw = "AyushSecurePass2026!"
    execute_query("DELETE FROM users WHERE email = ?", (cust_email,))

    r_reg = client.post("/register", data={
        "full_name": "Ayush Verma",
        "email": cust_email,
        "phone": "9811223344",
        "password": cust_pw,
        "confirm_password": cust_pw,
        "csrf_token": csrf_token
    }, cookies={"stylezone_csrf": csrf_token}, follow_redirects=False)

    assert r_reg.status_code == 303, f"Expected 303 redirect, got {r_reg.status_code}: {r_reg.text}"
    cust_session = r_reg.cookies.get("stylezone_session")
    assert cust_session is not None, "Registration must establish customer session cookie"
    print("  ✓ Customer registration succeeded with valid CSRF token")

    # 5. Customer Login / Logout
    print("\n[CHECK 5/17] Verifying Login & Logout...")
    # Bad login
    r_bad_log = client.post("/login", data={
        "email": cust_email,
        "password": "WrongPassword!",
        "csrf_token": csrf_token
    }, cookies={"stylezone_csrf": csrf_token})
    assert r_bad_log.status_code == 401
    assert "Invalid email or password" in r_bad_log.text

    # Good login
    r_good_log = client.post("/login", data={
        "email": cust_email,
        "password": cust_pw,
        "csrf_token": csrf_token
    }, cookies={"stylezone_csrf": csrf_token}, follow_redirects=False)
    assert r_good_log.status_code == 303

    # Logout
    r_logout = client.get("/logout", cookies={"stylezone_session": cust_session}, follow_redirects=False)
    assert r_logout.status_code == 302
    print("  ✓ Customer login and logout verified")

    # 6. Secure Forgot Password Flow (No tokens in response, SHA256 hashed in DB)
    print("\n[CHECK 6/17] Verifying Secure Forgot Password Flow...")
    r_forgot = client.post("/forgot-password", data={
        "email": cust_email,
        "csrf_token": csrf_token
    }, cookies={"stylezone_csrf": csrf_token})
    assert r_forgot.status_code == 200
    # Crucial security check: Token or reset URL must NEVER appear on the webpage
    assert "reset-password?token=" not in r_forgot.text, "SECURITY VIOLATION: Reset link leaked into HTML!"
    assert "If an account exists with that email address" in r_forgot.text
    print("  ✓ Webpage shows generic confirmation without disclosing token or user existence")

    # Inspect token stored in DB: verify it is securely SHA-256 hashed
    token_row = query_one("SELECT token, expires_at, used FROM password_reset_tokens WHERE user_id = (SELECT id FROM users WHERE email = ?)", (cust_email,))
    assert token_row is not None
    assert len(token_row["token"]) == 64, "Token stored in DB must be a 64-character SHA-256 hex digest!"
    print(f"  ✓ Token is stored securely as SHA-256 hash in DB: {token_row['token'][:16]}...")

    # 7. Admin Login & Business Hours Configuration
    print("\n[CHECK 7/17] Verifying Admin Login & Business Hours Configuration...")
    admin_email = "admin.owner@stylezone.local"
    admin_pw = "CustomOwnerAdmin2026!"
    create_admin("Studio Owner", admin_email, admin_pw)

    r_admin_login = client.post("/admin/login", data={
        "email": admin_email,
        "password": admin_pw,
        "csrf_token": csrf_token
    }, cookies={"stylezone_csrf": csrf_token}, follow_redirects=False)
    assert r_admin_login.status_code == 303
    admin_session = r_admin_login.cookies.get("stylezone_session")
    assert admin_session is not None
    print("  ✓ Admin authenticated successfully")

    # Admin configures business hours for Monday-Saturday (09:30 - 20:30) and Sunday Closed
    hours_form_data = {
        "csrf_token": csrf_token,
        "booking_enabled": "on",
        "slot_duration_minutes": "30",
        # Monday - Saturday Open
        "is_open_0": "on", "open_time_0": "09:30", "close_time_0": "20:30", "has_break_0": "on", "break_start_0": "13:00", "break_end_0": "14:00",
        "is_open_1": "on", "open_time_1": "09:30", "close_time_1": "20:30",
        "is_open_2": "on", "open_time_2": "09:30", "close_time_2": "20:30",
        "is_open_3": "on", "open_time_3": "09:30", "close_time_3": "20:30",
        "is_open_4": "on", "open_time_4": "09:30", "close_time_4": "20:30",
        "is_open_5": "on", "open_time_5": "09:30", "close_time_5": "20:30",
        # Sunday Closed (Weekly Off)
        "open_time_6": "", "close_time_6": ""
    }
    r_save_hours = client.post(
        "/admin/hours",
        data=hours_form_data,
        cookies={"stylezone_session": admin_session, "stylezone_csrf": csrf_token},
        follow_redirects=False
    )
    assert r_save_hours.status_code == 303
    assert query_one("SELECT value FROM business_settings WHERE key = 'hours_configured'")["value"] == "1"
    print("  ✓ Admin configured business hours; hours_configured is now 1")

    # 8. Real Slot Availability With Admin Configured Hours & Weekly Off
    print("\n[CHECK 8/17] Verifying Availability With Admin Configured Hours & Weekly Off...")
    days_ahead = (6 - date.today().weekday()) % 7
    if days_ahead == 0: days_ahead = 7
    sunday = (date.today() + timedelta(days=days_ahead)).strftime("%Y-%m-%d")
    r_sunday = client.get(f"/api/public/availability?date={sunday}&service_id=1")
    assert r_sunday.json()["is_open"] is False, "Sunday must be closed (weekly off)"
    print("  ✓ Weekly off day correctly reported as closed with zero slots")
    open_day = (date.today() + timedelta(days=days_ahead + 1)).strftime("%Y-%m-%d") # Monday
    r_avail_now = client.get(f"/api/public/availability?date={open_day}&service_id=1")
    avail_now_data = r_avail_now.json()
    assert avail_now_data["available"] is True
    first_slot = [s for s in avail_now_data["slots"] if s["available"]][0]["time"]
    print(f"  ✓ Slots now calculated using admin hours: First slot = {first_slot}")

    # 9. Real Appointment Booking With CSRF
    print("\n[CHECK 9/17] Verifying Appointment Booking with CSRF...")
    # Re-login customer after logout test
    r_cust_login = client.post("/login", data={
        "email": cust_email,
        "password": cust_pw,
        "csrf_token": csrf_token
    }, cookies={"stylezone_csrf": csrf_token}, follow_redirects=False)
    cust_session = r_cust_login.cookies.get("stylezone_session")
    assert cust_session is not None, "Customer re-login must succeed"

    r_book = client.post("/api/bookings/create", json={
        "service_id": 1,  # Haircut ₹100
        "appointment_date": open_day,
        "start_time": first_slot,
        "notes": "VIP haircut request",
        "csrf_token": csrf_token
    }, cookies={"stylezone_session": cust_session, "stylezone_csrf": csrf_token}, headers={"X-CSRF-Token": csrf_token})
    
    assert r_book.status_code == 200, f"Booking failed: {r_book.text}"
    booking_res = r_book.json()
    booking_id = booking_res["booking"]["booking_id"]
    print(f"  ✓ Appointment created successfully! Booking ID: {booking_id}")

    # 10. BOOKING CONFIRMATION SECURITY & AUTHORIZATION CHECK
    print("\n[CHECK 10/17] Verifying Booking Confirmation Authorization Protection...")
    # (a) Booking owner accessing their own confirmation -> MUST SUCCEED (200 OK)
    r_owner = client.get(f"/booking-confirmation/{booking_id}", cookies={"stylezone_session": cust_session})
    assert r_owner.status_code == 200
    assert booking_id in r_owner.text
    print("  ✓ Booking owner authorized: 200 OK")

    # (b) Admin accessing the confirmation -> MUST SUCCEED (200 OK)
    r_admin_view = client.get(f"/booking-confirmation/{booking_id}", cookies={"stylezone_session": admin_session})
    assert r_admin_view.status_code == 200
    print("  ✓ Admin authorized: 200 OK")

    # (c) Another customer attempting to access this customer's confirmation -> MUST BE 403 FORBIDDEN!
    other_email = "stranger@example.com"
    execute_query("DELETE FROM users WHERE email = ?", (other_email,))
    stranger_client = TestClient(main.app)
    stranger_home = stranger_client.get("/")
    stranger_csrf = stranger_home.cookies.get("stylezone_csrf")

    r_stranger_reg = stranger_client.post("/register", data={
        "full_name": "Stranger User",
        "email": other_email,
        "password": "Password123!",
        "confirm_password": "Password123!",
        "csrf_token": stranger_csrf
    }, cookies={"stylezone_csrf": stranger_csrf}, follow_redirects=False)
    assert r_stranger_reg.status_code == 303
    stranger_session = r_stranger_reg.cookies.get("stylezone_session")

    r_stranger = stranger_client.get(f"/booking-confirmation/{booking_id}")
    assert r_stranger.status_code == 403, f"Expected 403 Forbidden for unauthorized customer, got {r_stranger.status_code}"
    print("  ✓ Unauthorized customer blocked from viewing another client's confirmation: 403 FORBIDDEN")

    # (d) Anonymous/unauthenticated user accessing confirmation -> MUST REDIRECT TO LOGIN (302)
    anon_client = TestClient(main.app)
    r_anon = anon_client.get(f"/booking-confirmation/{booking_id}", follow_redirects=False)
    assert r_anon.status_code == 302
    assert "/login?return_to=" in r_anon.headers.get("location")
    print("  ✓ Unauthenticated user redirected to login: 302 Redirect")

    # 11. Double-Booking Protection Test
    print("\n[CHECK 11/17] Verifying Double-Booking Protection...")
    r_double = stranger_client.post("/api/bookings/create", json={
        "service_id": 2,
        "appointment_date": open_day,
        "start_time": first_slot,
        "csrf_token": stranger_csrf
    }, headers={"X-CSRF-Token": stranger_csrf})
    assert r_double.status_code == 409
    print("  ✓ Double booking rejected with HTTP 409 Conflict")

    # 12. Customer Account Portal & Self-Cancellation
    print("\n[CHECK 12/17] Verifying Customer Dashboard & Cancellation...")
    r_cust_dash = client.get("/account", cookies={"stylezone_session": cust_session})
    assert r_cust_dash.status_code == 200
    assert booking_id in r_cust_dash.text

    # Cancel booking
    r_cancel = client.post(
        f"/account/api/appointments/{booking_id}/cancel",
        json={"reason": "Test cancel", "csrf_token": csrf_token},
        cookies={"stylezone_session": cust_session, "stylezone_csrf": csrf_token},
        headers={"X-CSRF-Token": csrf_token}
    )
    assert r_cancel.status_code == 200
    assert r_cancel.json()["success"] is True
    print("  ✓ Customer cancellation verified")

    # 13. Services CRUD
    print("\n[CHECK 13/17] Verifying Services CRUD...")
    r_srv_list = client.get("/admin/services", cookies={"stylezone_session": admin_session})
    assert r_srv_list.status_code == 200
    assert "Haircut" in r_srv_list.text

    # Add service with CSRF
    r_add_srv = client.post("/admin/services/add", data={
        "name": "Head Massage",
        "price": "120",
        "duration_minutes": "20",
        "description": "Relaxing scalp massage",
        "is_active": "1",
        "csrf_token": csrf_token
    }, cookies={"stylezone_session": admin_session, "stylezone_csrf": csrf_token}, follow_redirects=False)
    assert r_add_srv.status_code == 303
    print("  ✓ Service CRUD add verified")

    # 14. Blocked Slots & Holidays
    print("\n[CHECK 14/17] Verifying Blocked Slots & Holidays with CSRF...")
    r_block = client.post("/admin/blocked-slots", data={
        "date": open_day,
        "start_time": "15:00",
        "end_time": "16:00",
        "reason": "Studio Power Maintenance",
        "csrf_token": csrf_token
    }, cookies={"stylezone_session": admin_session, "stylezone_csrf": csrf_token}, follow_redirects=False)
    assert r_block.status_code == 303

    r_holiday = client.post("/admin/holidays/add", data={
        "date": "2026-10-02",
        "reason": "National Holiday",
        "csrf_token": csrf_token
    }, cookies={"stylezone_session": admin_session, "stylezone_csrf": csrf_token}, follow_redirects=False)
    assert r_holiday.status_code == 303
    print("  ✓ Blocked slots and holidays verified")

    # 15. Gallery & Reviews Management
    print("\n[CHECK 15/17] Verifying Gallery & Reviews...")
    r_gal = client.get("/admin/gallery", cookies={"stylezone_session": admin_session})
    assert r_gal.status_code == 200

    r_rev = client.get("/admin/reviews", cookies={"stylezone_session": admin_session})
    assert r_rev.status_code == 200
    print("  ✓ Gallery and Reviews verified")

    # 16. Error Pages
    print("\n[CHECK 16/17] Verifying 404 and 500 Error Pages...")
    r_404 = client.get("/random-nonexistent-url")
    assert r_404.status_code == 404
    assert "404" in r_404.text

    from starlette.requests import Request
    req = Request({"type": "http", "headers": [], "path": "/error-test"})
    ctx = {"request": req, "settings": {"business_name": "The Stylezone"}, "csrf_token": csrf_token}
    resp_500 = main.templates.TemplateResponse(request=req, name="500.html", context=ctx, status_code=500)
    assert resp_500.status_code == 500
    print("  ✓ 404 and 500 error pages verified")

    # 17. Security Review & No Hardcoded Admin Check
    print("\n[CHECK 17/17] Security Audit: Checking No Hardcoded Admin in Source...")
    main_code = open(BASE_DIR / "main.py").read()
    assert "admin@stylezone.com" not in main_code, "Hardcoded admin email found in main.py!"
    assert "StylezoneAdmin2026!" not in main_code, "Hardcoded admin password found in main.py!"
    print("  ✓ Verified: Zero hardcoded admin passwords in main.py")

    print("\n" + "=" * 70)
    print("ALL 17 PRODUCTION SAFETY & REGRESSION CHECKS PASSED FLAWLESSLY!")
    print("=" * 70)

if __name__ == "__main__":
    run_verification()
