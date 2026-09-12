"""
SmartDownload Manager - SQLite Database
Thread-safe persistent storage for download tasks, categories, settings, and scheduler
"""
import sqlite3
import os
import threading

DB_FILE = os.path.expanduser("~/AppData/Roaming/SmartDownloadManager/data.sqlite3")

class Database:
    def __init__(self, db_path=None):
        self.db_path = db_path or DB_FILE
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        self._local = threading.local()

    def get_conn(self):
        if not hasattr(self._local, "conn") or self._local.conn is None:
            self._local.conn = sqlite3.connect(self.db_path)
            self._local.conn.execute("PRAGMA journal_mode=WAL;")
            self._local.conn.execute("PRAGMA synchronous=NORMAL;")
        return self._local.conn

    def init_schema(self):
        conn = self.get_conn()
        with conn:
            conn.executescript("""
            CREATE TABLE IF NOT EXISTS downloads (
                id TEXT PRIMARY KEY,
                url TEXT NOT NULL,
                filename TEXT NOT NULL,
                category TEXT NOT NULL,
                status TEXT NOT NULL,
                total_bytes INTEGER DEFAULT 0,
                downloaded_bytes INTEGER DEFAULT 0,
                connections INTEGER DEFAULT 8,
                save_path TEXT NOT NULL,
                mime_type TEXT,
                checksum TEXT,
                created_at INTEGER,
                completed_at INTEGER,
                error_message TEXT
            );

            CREATE TABLE IF NOT EXISTS categories (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                icon TEXT,
                default_path TEXT NOT NULL,
                extensions TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS scheduled_tasks (
                id TEXT PRIMARY KEY,
                start_time TEXT,
                stop_time TEXT,
                action TEXT,
                enabled INTEGER DEFAULT 0
            );
            """)

    def get_speed_settings(self):
        return {'enabled': False, 'limit_bytes_per_sec': 0}

    def get_scheduler_config(self):
        return {'enabled': False, 'start_time': None, 'stop_time': None, 'action_on_completion': 'none'}

    def save_task(self, task):
        conn = self.get_conn()
        with conn:
            conn.execute("""
            INSERT OR REPLACE INTO downloads 
            (id, url, filename, category, status, total_bytes, downloaded_bytes, connections, save_path, mime_type, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                task.id, task.url, task.filename, task.category, task.status,
                task.total_bytes, task.downloaded_bytes, getattr(task, 'connections', 8),
                task.save_dir, getattr(task, 'mime_type', ''), getattr(task, 'created_at', int(time.time()))
            ))

    def update_progress(self, task_id: str, downloaded: int, status: str):
        conn = self.get_conn()
        with conn:
            conn.execute("UPDATE downloads SET downloaded_bytes = ?, status = ? WHERE id = ?", (downloaded, status, task_id))

    def mark_completed(self, task_id: str, final_path: str, checksum: str):
        conn = self.get_conn()
        with conn:
            conn.execute("UPDATE downloads SET status = 'completed', save_path = ?, checksum = ?, completed_at = ? WHERE id = ?",
                         (final_path, checksum, int(time.time()), task_id))

    def mark_failed(self, task_id: str, error: str):
        conn = self.get_conn()
        with conn:
            conn.execute("UPDATE downloads SET status = 'failed', error_message = ? WHERE id = ?", (error, task_id))
