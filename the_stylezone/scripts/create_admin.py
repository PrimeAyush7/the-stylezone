import sys
import argparse
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

from app.database import get_db, init_db, save_db_snapshot, query_one
from app.security import hash_password

def create_admin(full_name: str, email: str, password: str, phone: str = ""):
    init_db()
    email_clean = email.strip().lower()
    
    existing = query_one("SELECT id, role FROM users WHERE email = ?", (email_clean,))
    pw_hash = hash_password(password)

    with get_db() as conn:
        if existing:
            conn.execute("""
            UPDATE users 
            SET full_name = ?, password_hash = ?, role = 'admin', phone = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
            """, (full_name, pw_hash, phone, existing["id"]))
            print(f"Updated existing user {email_clean} to ADMINISTRATOR role.")
        else:
            conn.execute("""
            INSERT INTO users (full_name, email, phone, password_hash, role, created_at, updated_at)
            VALUES (?, ?, ?, ?, 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """, (full_name, email_clean, phone, pw_hash))
            print(f"Created new ADMINISTRATOR account for {email_clean}.")

    save_db_snapshot()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create or update an Admin account for The Stylezone")
    parser.add_argument("--name", default="Admin Manager", help="Full name of administrator")
    parser.add_argument("--email", required=True, help="Admin email address")
    parser.add_argument("--password", required=True, help="Admin password")
    parser.add_argument("--phone", default="", help="Admin contact phone")
    
    args = parser.parse_args()
    create_admin(args.name, args.email, args.password, args.phone)
