import sqlite3
import contextlib
from pathlib import Path
from typing import Generator, Any, Dict, List, Optional
from app.config import DATABASE_PATH, SNAPSHOT_SQL_PATH

_active_db_path: Optional[Path] = None

def get_db_connection() -> sqlite3.Connection:
    global _active_db_path
    target_path = _active_db_path or DATABASE_PATH
    target_path.parent.mkdir(parents=True, exist_ok=True)
    
    try:
        conn = sqlite3.connect(str(target_path), timeout=30.0, isolation_level=None)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON;")
        conn.execute("PRAGMA busy_timeout = 15000;")
        # Test write capability (will trigger OperationalError on locking-deficient filesystems)
        conn.execute("CREATE TABLE IF NOT EXISTS _fs_test (id INT PRIMARY KEY);")
        _active_db_path = target_path
        return conn
    except sqlite3.OperationalError as oe:
        # Graceful fallback exclusively for virtualized filesystems (e.g. 9p network mounts) that reject POSIX fcntl locks
        if "disk I/O error" in str(oe) and target_path != Path("/tmp/the_stylezone.db"):
            _active_db_path = Path("/tmp/the_stylezone.db")
            conn = sqlite3.connect(str(_active_db_path), timeout=30.0, isolation_level=None)
            conn.row_factory = sqlite3.Row
            conn.execute("PRAGMA foreign_keys = ON;")
            conn.execute("PRAGMA busy_timeout = 15000;")
            return conn
        raise oe

@contextlib.contextmanager
def get_db() -> Generator[sqlite3.Connection, None, None]:
    conn = get_db_connection()
    try:
        yield conn
    finally:
        conn.close()

def save_db_snapshot():
    """Dumps the current SQLite database to data/the_stylezone.sql for repository persistence."""
    try:
        SNAPSHOT_SQL_PATH.parent.mkdir(parents=True, exist_ok=True)
        with get_db() as conn:
            with open(SNAPSHOT_SQL_PATH, "w", encoding="utf-8") as f:
                for line in conn.iterdump():
                    f.write(f"{line}\n")
    except Exception as e:
        print(f"Notice: Snapshot sync: {e}")

def init_db():
    """Initializes tables, indexes, constraints, and restores snapshot if newly created."""
    target_path = _active_db_path or DATABASE_PATH
    db_existed = target_path.exists()
    
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("BEGIN TRANSACTION;")
        try:
            # Users table
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
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
            """)

            # Sessions table
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS sessions (
                session_id TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                role TEXT NOT NULL DEFAULT 'customer',
                expires_at DATETIME NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
            """)

            # Services table
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS services (
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
            """)

            # Business settings table
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS business_settings (
                key TEXT PRIMARY KEY,
                value TEXT,
                description TEXT,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            """)

            # Business hours table
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS business_hours (
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
            """)

            # Holidays table
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS holidays (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT UNIQUE NOT NULL,
                reason TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            """)

            # Blocked slots table
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS blocked_slots (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL,
                start_time TEXT NOT NULL,
                end_time TEXT NOT NULL,
                reason TEXT,
                created_by INTEGER,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
            );
            """)

            # Appointments table
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS appointments (
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
            """)

            # Double-booking prevention index
            cursor.execute("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_slot 
            ON appointments(appointment_date, start_time) 
            WHERE status != 'cancelled';
            """)

            # Gallery table
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS gallery (
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
            """)

            # Reviews table
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS reviews (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                author_name TEXT NOT NULL,
                rating INTEGER NOT NULL DEFAULT 5 CHECK(rating BETWEEN 1 AND 5),
                content TEXT NOT NULL,
                service_mentioned TEXT,
                is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
                is_demo INTEGER NOT NULL DEFAULT 1 CHECK(is_demo IN (0, 1)),
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            """)

            # Password reset tokens table (stores token hash for security)
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS password_reset_tokens (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                token TEXT UNIQUE NOT NULL,
                expires_at DATETIME NOT NULL,
                used INTEGER NOT NULL DEFAULT 0 CHECK(used IN (0, 1)),
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
            """)

            # Performance indexes
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_appointments_customer ON appointments(customer_id);")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_blocked_slots_date ON blocked_slots(date);")

            cursor.execute("COMMIT;")
        except Exception as e:
            cursor.execute("ROLLBACK;")
            raise e

    # Restore snapshot if newly created db and snapshot exists
    if not db_existed and SNAPSHOT_SQL_PATH.exists():
        try:
            with open(SNAPSHOT_SQL_PATH, "r", encoding="utf-8") as f:
                sql_content = f.read()
            with get_db() as conn:
                conn.executescript(sql_content)
        except Exception as err:
            print(f"Notice: Snapshot restore: {err}")

def query_one(sql: str, params: tuple = ()) -> Optional[Dict[str, Any]]:
    with get_db() as conn:
        row = conn.execute(sql, params).fetchone()
        return dict(row) if row else None

def query_all(sql: str, params: tuple = ()) -> List[Dict[str, Any]]:
    with get_db() as conn:
        rows = conn.execute(sql, params).fetchall()
        return [dict(row) for row in rows]

def execute_write(sql: str, params: tuple = ()) -> int:
    with get_db() as conn:
        cur = conn.execute(sql, params)
        res = cur.lastrowid
    save_db_snapshot()
    return res

def execute_query(sql: str, params: tuple = ()):
    with get_db() as conn:
        conn.execute(sql, params)
    save_db_snapshot()

def get_setting(key: str, default: str = "") -> str:
    row = query_one("SELECT value FROM business_settings WHERE key = ?", (key,))
    return row["value"] if row and row["value"] is not None else default

def set_setting(key: str, value: str, description: str = ""):
    with get_db() as conn:
        conn.execute("""
        INSERT INTO business_settings (key, value, description, updated_at)
        VALUES (?, ?, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP;
        """, (key, value, description))
    save_db_snapshot()
