import os
import sys
import unittest
import asyncio
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

import app
import main
from starlette.testclient import TestClient
from app.database import query_one, execute_query, init_db
from app.security import verify_password

class TestAdminBootstrap(unittest.TestCase):
    def setUp(self):
        init_db()
        # Clean up any admin users for clean testing
        execute_query("DELETE FROM users WHERE role = 'admin'")
        os.environ.pop("ADMIN_EMAIL", None)
        os.environ.pop("ADMIN_PASSWORD", None)
        os.environ.pop("ADMIN_NAME", None)

    def tearDown(self):
        os.environ.pop("ADMIN_EMAIL", None)
        os.environ.pop("ADMIN_PASSWORD", None)
        os.environ.pop("ADMIN_NAME", None)

    def test_missing_env_vars_does_not_create_admin(self):
        # Run on_startup
        asyncio.run(main.on_startup())
        admin = query_one("SELECT * FROM users WHERE role = 'admin'")
        self.assertIsNone(admin)

    def test_partial_env_vars_does_not_create_admin(self):
        os.environ["ADMIN_EMAIL"] = "admin@stylezone.local"
        os.environ["ADMIN_PASSWORD"] = "Secret123!"
        # ADMIN_NAME is missing
        asyncio.run(main.on_startup())
        admin = query_one("SELECT * FROM users WHERE role = 'admin'")
        self.assertIsNone(admin)

    def test_bootstrap_creates_admin_and_allows_login(self):
        os.environ["ADMIN_EMAIL"] = "render.owner@stylezone.local"
        os.environ["ADMIN_PASSWORD"] = "RenderAdminPass2026!"
        os.environ["ADMIN_NAME"] = "Studio Head"

        # First startup -> Should bootstrap admin
        asyncio.run(main.on_startup())

        admin = query_one("SELECT * FROM users WHERE role = 'admin'")
        self.assertIsNotNone(admin)
        self.assertEqual(admin["email"], "render.owner@stylezone.local")
        self.assertEqual(admin["full_name"], "Studio Head")
        self.assertTrue(verify_password("RenderAdminPass2026!", admin["password_hash"]))

        # Verify admin can log in via HTTP
        client = TestClient(main.app)
        home = client.get("/")
        csrf = home.cookies.get("stylezone_csrf")

        login_resp = client.post("/admin/login", data={
            "email": "render.owner@stylezone.local",
            "password": "RenderAdminPass2026!",
            "csrf_token": csrf
        }, follow_redirects=False)

        self.assertEqual(login_resp.status_code, 303)
        self.assertEqual(login_resp.headers["location"], "/admin")
        admin_session = login_resp.cookies.get("stylezone_session")
        self.assertIsNotNone(admin_session)

        # Access dashboard
        dash_resp = client.get("/admin", cookies={"stylezone_session": admin_session})
        self.assertEqual(dash_resp.status_code, 200)
        self.assertIn("Studio Dashboard", dash_resp.text)

    def test_subsequent_restart_does_not_overwrite_password(self):
        # Create admin initially
        os.environ["ADMIN_EMAIL"] = "render.owner@stylezone.local"
        os.environ["ADMIN_PASSWORD"] = "InitialPass123!"
        os.environ["ADMIN_NAME"] = "Studio Head"
        asyncio.run(main.on_startup())

        orig_admin = query_one("SELECT * FROM users WHERE role = 'admin'")
        orig_hash = orig_admin["password_hash"]

        # Now simulate subsequent restart with different ADMIN_PASSWORD
        os.environ["ADMIN_PASSWORD"] = "DifferentPass456!"
        asyncio.run(main.on_startup())

        current_admin = query_one("SELECT * FROM users WHERE role = 'admin'")
        # Password hash MUST be unchanged
        self.assertEqual(current_admin["password_hash"], orig_hash)
        self.assertTrue(verify_password("InitialPass123!", current_admin["password_hash"]))
        self.assertFalse(verify_password("DifferentPass456!", current_admin["password_hash"]))

if __name__ == "__main__":
    unittest.main()
