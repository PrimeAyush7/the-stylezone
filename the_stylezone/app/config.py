import os
import secrets
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

SECRET_KEY = os.getenv("SECRET_KEY", "the_stylezone_luxury_secret_key_2026")
SESSION_COOKIE_NAME = "stylezone_session"
CSRF_COOKIE_NAME = "stylezone_csrf"
SESSION_MAX_AGE = 7 * 24 * 60 * 60  # 7 days

# Environment mode
ENV = os.getenv("ENV", "development").lower()
DEBUG = os.getenv("DEBUG", "False").lower() in ("true", "1", "yes") or ENV == "development"

# Configurable Database Path: defaults to data/the_stylezone.db for persistent production/local storage
DEFAULT_DB_PATH = BASE_DIR / "data" / "the_stylezone.db"
env_db = os.getenv("DATABASE_PATH")
DATABASE_PATH = Path(env_db) if env_db else DEFAULT_DB_PATH

SNAPSHOT_SQL_PATH = BASE_DIR / "data" / "the_stylezone.sql"

# OAuth Credentials
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET", "")
FACEBOOK_CLIENT_ID = os.getenv("FACEBOOK_CLIENT_ID", "")
FACEBOOK_CLIENT_SECRET = os.getenv("FACEBOOK_CLIENT_SECRET", "")
APP_URL = os.getenv("APP_URL", "http://localhost:8000")

UPLOAD_DIR = BASE_DIR / "app" / "static" / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
