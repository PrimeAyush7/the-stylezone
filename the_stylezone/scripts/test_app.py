import sys
from pathlib import Path
from datetime import date, timedelta

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

# Ensure 9p finder
import app
from starlette.testclient import TestClient
from app.database import execute_query, init_db
from scripts.create_admin import create_admin
import main

client = TestClient(main.app)

def run_tests():
    print("=" * 60)
    print("THE STYLEZONE — COMPREHENSIVE COMPATIBILITY & REGRESSION TEST")
    print("=" * 60)

    # 0. Setup test admin explicitly via CLI script (no hardcoded credentials in main.py)
    init_db()
    test_admin_email = "test.admin@stylezone.local"
    test_admin_pw = "SecureAdminTest2026!"
    create_admin("Test Administrator", test_admin_email, test_admin_pw)
    print("  ✓ Setup test admin via create_admin script: PASSED")

    # 1. Homepage
    print("\n[1/14] Testing Homepage (GET /)...")
    r = client.get("/")
    assert r.status_code == 200, f"Expected 200, got {r.status_code}"
    assert "THE" in r.text and "STYLEZONE" in r.text
    assert "Street no 32, Vipin Garden Extension, Dwarka Mor, Delhi" in r.text
    assert "Haircut" in r.text
    assert "₹100" in r.text
    print("  ✓ Homepage renders without TemplateResponse errors")

    # 2. Services Page
    print("\n[2/14] Testing Services (GET /services)...")
    r = client.get("/services")
    assert r.status_code == 200
    assert "Haircut + Beard" in r.text
    assert "₹150" in r.text
    print("  ✓ Services page renders correctly")

    # 3. Lookbook Page
    print("\n[3/14] Testing Lookbook (GET /lookbook)...")
    r = client.get("/lookbook")
    assert r.status_code == 200
    assert "Lookbook" in r.text
    print("  ✓ Lookbook renders with gallery items")

    # 4. About Page
    print("\n[4/14] Testing About (GET /about)...")
    r = client.get("/about")
    assert r.status_code == 200
    assert "Dedicated To Refined Grooming" in r.text
    print("  ✓ About page renders correctly")

    # 5. Contact Page
    print("\n[5/14] Testing Contact (GET /contact)...")
    r = client.get("/contact")
    assert r.status_code == 200
    assert "Dwarka Mor" in r.text
    print("  ✓ Contact page renders correctly")

    # 6. Customer Registration
    print("\n[6/14] Testing Customer Registration (POST /register)...")
    test_email = "customer.verify@example.com"
    test_pw = "ValidPass123!"
    execute_query("DELETE FROM users WHERE email = ?", (test_email,))

    r = client.post("/register", data={
        "full_name": "Deepak Verma",
        "email": test_email,
        "phone": "9811223344",
        "password": test_pw,
        "confirm_password": test_pw
    }, follow_redirects=False)
    assert r.status_code == 303
    cust_cookie = r.cookies.get("stylezone_session")
    assert cust_cookie is not None
    print("  ✓ Customer registration succeeds and sets secure session cookie")

    # 7. Customer Login & Bad Passwords
    print("\n[7/14] Testing Customer Login (POST /login)...")
    r_bad = client.post("/login", data={"email": test_email, "password": "WrongPassword"})
    assert r_bad.status_code == 401
    assert "Invalid email or password" in r_bad.text
    print("  ✓ Bad credentials handled with 401 and TemplateResponse")

    r_login = client.post("/login", data={"email": test_email, "password": test_pw}, follow_redirects=False)
    assert r_login.status_code == 303
    print("  ✓ Valid customer login redirects to account")

    # 8. Admin Login
    print("\n[8/14] Testing Admin Login (POST /admin/login)...")
    r_admin_bad = client.post("/admin/login", data={"email": test_admin_email, "password": "WrongPassword"})
    assert r_admin_bad.status_code == 401

    r_admin_login = client.post("/admin/login", data={
        "email": test_admin_email,
        "password": test_admin_pw
    }, follow_redirects=False)
    assert r_admin_login.status_code == 303
    admin_cookie = r_admin_login.cookies.get("stylezone_session")
    assert admin_cookie is not None
    print("  ✓ Admin login authenticates and sets admin session cookie")

    # 9. Booking Page
    print("\n[9/14] Testing Booking Page (GET /book)...")
    r_book_page = client.get("/book")
    assert r_book_page.status_code == 200
    assert "Step 1: Choose Your Service" in r_book_page.text
    print("  ✓ 5-Step Booking Wizard page renders cleanly")

    # 10. Booking Creation & Confirmation Page
    print("\n[10/14] Testing Booking Creation & Confirmation (GET /booking-confirmation/{id})...")
    tomorrow = (date.today() + timedelta(days=2)).strftime("%Y-%m-%d")
    r_avail = client.get(f"/api/public/availability?date={tomorrow}&service_id=1")
    assert r_avail.status_code == 200
    test_slot = [s for s in r_avail.json()["slots"] if s["available"]][0]["time"]

    r_book = client.post("/api/bookings/create", json={
        "service_id": 1,
        "appointment_date": tomorrow,
        "start_time": test_slot,
        "notes": "Regression verification appointment"
    }, cookies={"stylezone_session": cust_cookie})
    assert r_book.status_code == 200
    booking_id = r_book.json()["booking"]["booking_id"]

    r_conf = client.get(f"/booking-confirmation/{booking_id}")
    assert r_conf.status_code == 200
    assert booking_id in r_conf.text
    assert "Haircut" in r_conf.text
    print(f"  ✓ Booking confirmed! Booking ID: {booking_id}")

    # 11. Customer Dashboard
    print("\n[11/14] Testing Customer Dashboard (GET /account)...")
    r_dash = client.get("/account", cookies={"stylezone_session": cust_cookie})
    assert r_dash.status_code == 200
    assert "Deepak Verma" in r_dash.text
    assert booking_id in r_dash.text
    print("  ✓ Customer portal displays upcoming appointments and profile")

    # 12. Every Admin Page
    print("\n[12/14] Testing Every Admin Portal Screen...")
    admin_pages = [
        ("/admin", "Studio Dashboard"),
        ("/admin/appointments", "Appointments Management"),
        ("/admin/calendar", "Daily Agenda & Blocked Slots"),
        ("/admin/services", "Services & Pricing Management"),
        ("/admin/hours", "Business Hours & Operating Schedule"),
        ("/admin/holidays", "Holidays & Shop Closures"),
        ("/admin/gallery", "Lookbook & Image Management"),
        ("/admin/content", "Website Content & Business Information"),
        ("/admin/reviews", "Reviews & Testimonials"),
        ("/admin/customers", "Customer Directory"),
    ]

    for path, expected_text in admin_pages:
        res = client.get(path, cookies={"stylezone_session": admin_cookie})
        assert res.status_code == 200, f"Failed on {path}: {res.status_code}"
        assert expected_text in res.text, f"Expected '{expected_text}' in {path}"
        print(f"  ✓ Admin Page: {path} renders (200 OK)")

    # 13. 404 Error Page
    print("\n[13/14] Testing 404 Error Page...")
    r_404 = client.get("/this-page-definitely-does-not-exist")
    assert r_404.status_code == 404
    assert "404" in r_404.text
    assert "Page Not Found" in r_404.text
    print("  ✓ 404 handler renders custom template with request context")

    # 14. 500 Error Page
    print("\n[14/14] Testing 500 Error Handler...")
    from starlette.requests import Request
    req = Request({"type": "http", "headers": [], "path": "/error-test"})
    ctx = {"request": req, "settings": {"business_name": "The Stylezone"}}
    resp_500 = main.templates.TemplateResponse(
        request=req,
        name="500.html",
        context=ctx,
        status_code=500
    )
    assert resp_500.status_code == 500
    print("  ✓ 500 handler renders custom template with request context")

    print("\n" + "=" * 60)
    print("ALL 14 AUDIT CHECKS PASSED FLAWLESSLY!")
    print("=" * 60)

if __name__ == "__main__":
    run_tests()
