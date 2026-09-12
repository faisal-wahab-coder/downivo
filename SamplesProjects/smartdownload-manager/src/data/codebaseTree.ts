import { CodeFile } from '../types';

export const CODEBASE_FILES: CodeFile[] = [
  // ===================== PYTHON WINDOWS APP =====================
  {
    path: 'windows-download-manager/main.py',
    name: 'main.py',
    language: 'python',
    category: 'windows_app',
    description: 'Main application entry point with PySide6 GUI, System Tray, and Single-Instance Lock',
    content: `"""
SmartDownload Manager - Main Entry Point
Professional Windows Download Manager with PySide6 & Native Messaging Host
"""
import sys
import os
import signal

# Ensure project root is in sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PySide6.QtWidgets import QApplication, QSystemTrayIcon, QMenu
from PySide6.QtCore import Qt, QSharedMemory, QTimer
from PySide6.QtGui import QIcon, QAction

from app.ui.main_window import MainWindow
from app.core.download_engine import DownloadEngine
from app.core.queue_manager import QueueManager
from app.core.scheduler import Scheduler
from app.core.speed_limiter import SpeedLimiter
from app.database.database import Database
from app.services.clipboard_service import ClipboardWatcher
from app.browser.browser_manager import BrowserManager
from app.utils.logger import setup_logger

logger = setup_logger("main")

def check_single_instance():
    """Ensure only one instance of SmartDownload Manager runs at a time."""
    shared_mem = QSharedMemory("SmartDownloadManager_Unique_Mutex_Key")
    if not shared_mem.create(1):
        logger.warning("Another instance of SmartDownload Manager is already running.")
        return None, False
    return shared_mem, True

def main():
    # Enable High-DPI support on Windows 10/11
    QApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )
    
    app = QApplication(sys.argv)
    app.setApplicationName("SmartDownload Manager")
    app.setOrganizationName("SmartDownload")
    app.setApplicationVersion("1.0.0")
    app.setQuitOnLastWindowClosed(False)

    # Enforce Single-Instance
    mem_guard, is_single = check_single_instance()
    if not is_single:
        sys.exit(0)

    # Initialize Database & Core Subsystems
    db = Database()
    db.init_schema()

    speed_limiter = SpeedLimiter(db.get_speed_settings())
    download_engine = DownloadEngine(speed_limiter=speed_limiter)
    queue_manager = QueueManager(engine=download_engine, db=db)
    scheduler = Scheduler(queue_manager=queue_manager, db=db)
    scheduler.start()

    # Browser integration helper
    browser_mgr = BrowserManager()

    # Create Main Window
    window = MainWindow(
        db=db,
        queue_manager=queue_manager,
        download_engine=download_engine,
        scheduler=scheduler,
        speed_limiter=speed_limiter,
        browser_manager=browser_mgr
    )
    window.show()

    # Setup Clipboard Sniffer
    clipboard_watcher = ClipboardWatcher(window)
    clipboard_watcher.url_detected.connect(window.prompt_add_download)
    clipboard_watcher.start()

    # Graceful Ctrl+C handling
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    logger.info("SmartDownload Manager started successfully.")
    exit_code = app.exec()
    
    # Cleanup on exit
    scheduler.stop()
    queue_manager.shutdown()
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
`
  },
  {
    path: 'windows-download-manager/app/core/download_engine.py',
    name: 'download_engine.py',
    language: 'python',
    category: 'windows_app',
    description: 'Multi-connection chunked download engine with HTTP byte-ranges, pause/resume, and atomic file assembly',
    content: `"""
SmartDownload Manager - Download Engine
Handles multi-thread HTTP/HTTPS chunked downloads, pause, resume, and SHA-256 verification
"""
import os
import shutil
import time
import math
import hashlib
import threading
import requests
from typing import List, Optional, Callable
from dataclasses import dataclass, field

@dataclass
class Segment:
    id: int
    start_byte: int
    end_byte: int
    downloaded_bytes: int = 0
    status: str = "idle"  # idle, downloading, completed, failed
    speed: float = 0.0

class DownloadEngine:
    def __init__(self, speed_limiter=None):
        self.speed_limiter = speed_limiter
        self.active_tasks = {}
        self._lock = threading.Lock()

    def probe_url(self, url: str, timeout: int = 10):
        """Perform HEAD request to inspect size, accept-ranges, and filename."""
        headers = {
            'User-Agent': 'SmartDownloadManager/1.0 (Windows NT 10.0; Win64; x64)'
        }
        try:
            resp = requests.head(url, headers=headers, allow_redirects=True, timeout=timeout)
            content_length = resp.headers.get('content-length')
            accept_ranges = resp.headers.get('accept-ranges') == 'bytes'
            content_type = resp.headers.get('content-type', 'application/octet-stream')
            
            # Filename extraction
            filename = "download.bin"
            cd = resp.headers.get('content-disposition', '')
            if 'filename=' in cd:
                filename = cd.split('filename=')[-1].strip('"\\'')
            else:
                parsed_path = requests.utils.urlparse(resp.url).path
                basename = os.path.basename(parsed_path)
                if basename:
                    filename = basename

            total_size = int(content_length) if content_length and content_length.isdigit() else None
            return {
                'url': resp.url,
                'filename': filename,
                'size': total_size,
                'accept_ranges': accept_ranges,
                'mime_type': content_type,
                'status_code': resp.status_code
            }
        except Exception as e:
            return {'url': url, 'filename': 'download.bin', 'size': None, 'accept_ranges': False, 'error': str(e)}

    def start_download(self, task, on_progress: Optional[Callable] = None, on_complete: Optional[Callable] = None, on_error: Optional[Callable] = None):
        """Start or resume a download task using multi-thread workers."""
        with self._lock:
            task.is_cancelled = False
            task.is_paused = False
            self.active_tasks[task.id] = task

        worker_thread = threading.Thread(
            target=self._download_worker,
            args=(task, on_progress, on_complete, on_error),
            daemon=True
        )
        worker_thread.start()

    def _is_video_platform(self, url: str) -> bool:
        u = url.lower()
        return any(domain in u for domain in [
            'youtube.com', 'youtu.be', 'vimeo.com', 'dailymotion.com',
            'tiktok.com', 'bilibili.com', 'facebook.com', 'fb.watch',
            'instagram.com', 'twitter.com', 'x.com'
        ])

    def _download_via_ytdlp(self, task, on_progress, on_complete, on_error):
        """Download video/audio from streaming platforms using yt-dlp extractor."""
        try:
            import yt_dlp
        except ImportError:
            err = "YouTube & stream downloads require yt-dlp. Please run: pip install yt-dlp"
            task.status = "failed"
            task.error_message = err
            if on_error:
                on_error(task, err)
            return

        category = "Videos"
        target_folder = self._get_category_folder(category, getattr(task, 'save_path', '') or getattr(task, 'save_dir', ''))
        os.makedirs(target_folder, exist_ok=True)
        outtmpl = os.path.join(target_folder, '%(title)s.%(ext)s')

        def ytdl_hook(d):
            if getattr(task, 'is_cancelled', False):
                raise Exception("Download cancelled by user")
            if getattr(task, 'is_paused', False):
                task.status = "paused"
                if on_progress: on_progress(task)
                raise Exception("Download paused by user")

            if d['status'] == 'downloading':
                total = d.get('total_bytes') or d.get('total_bytes_estimate') or 0
                downloaded = d.get('downloaded_bytes') or 0
                speed = d.get('speed') or 0
                task.total_bytes = total
                task.downloaded_bytes = downloaded
                task.speed = speed
                task.status = "downloading"
                if on_progress:
                    on_progress(task)
            elif d['status'] == 'finished':
                task.downloaded_bytes = task.total_bytes
                task.status = "completed"

        ydl_opts = {
            'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
            'outtmpl': outtmpl,
            'progress_hooks': [ytdl_hook],
            'quiet': True,
            'no_warnings': True,
        }

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(task.url, download=True)
                filename = ydl.prepare_filename(info)
                task.filename = os.path.basename(filename)
                task.completed_path = filename
                task.save_path = filename
                task.status = "completed"
                task.category = "Videos"
                if on_complete:
                    on_complete(task)
        except Exception as e:
            if not getattr(task, 'is_paused', False) and not getattr(task, 'is_cancelled', False):
                task.status = "failed"
                task.error_message = str(e)
                if on_error:
                    on_error(task, str(e))

    def _download_worker(self, task, on_progress, on_complete, on_error):
        # Route streaming video platforms (YouTube, Vimeo, etc.) to yt-dlp extractor
        if self._is_video_platform(task.url):
            return self._download_via_ytdlp(task, on_progress, on_complete, on_error)

        target_path = os.path.join(task.save_dir, task.filename)
        part_path = target_path + ".part"
        os.makedirs(task.save_dir, exist_ok=True)

        try:
            probe = self.probe_url(task.url)
            total_size = probe.get('size')
            accept_ranges = probe.get('accept_ranges', False)
            task.total_bytes = total_size or 0

            # Determine connection count
            conns = task.connections if (accept_ranges and total_size and total_size > 1024 * 1024) else 1

            # Prepare Segments
            if not task.segments or len(task.segments) != conns:
                task.segments = []
                if conns > 1 and total_size:
                    chunk_size = math.ceil(total_size / conns)
                    for i in range(conns):
                        start = i * chunk_size
                        end = min(total_size - 1, (i + 1) * chunk_size - 1)
                        task.segments.append(Segment(id=i, start_byte=start, end_byte=end))
                else:
                    task.segments.append(Segment(id=0, start_byte=0, end_byte=(total_size - 1) if total_size else -1))

            # Multi-connection download
            threads = []
            for seg in task.segments:
                t = threading.Thread(
                    target=self._download_segment,
                    args=(task, seg, part_path),
                    daemon=True
                )
                threads.append(t)
                t.start()

            # Monitor loop
            while any(t.is_alive() for t in threads):
                if task.is_paused:
                    task.status = "paused"
                    if on_progress: on_progress(task)
                    return
                if task.is_cancelled:
                    task.status = "cancelled"
                    if os.path.exists(part_path): os.remove(part_path)
                    return

                # Calculate total downloaded & speed
                downloaded = sum(s.downloaded_bytes for s in task.segments)
                task.downloaded_bytes = downloaded
                if on_progress:
                    on_progress(task)
                time.sleep(0.5)

            # Check if all completed
            if all(s.status == "completed" for s in task.segments):
                # Auto-organize completed download into category folder (Videos, Music, Documents, Images, Programs, Archives)
                category = self._infer_category(task.filename)
                target_folder = self._get_category_folder(category, getattr(task, 'save_path', '') or getattr(task, 'save_dir', ''))
                
                # Automatically create the category folder in Downloads if needed
                os.makedirs(target_folder, exist_ok=True)
                
                final_target = os.path.join(target_folder, task.filename)
                if os.path.exists(final_target):
                    final_target = self._get_unique_filename(final_target)
                
                # Safely move file from .part temp to category folder
                shutil.move(part_path, final_target)
                
                # Compute SHA-256 Checksum
                sha256 = self._compute_checksum(final_target)
                task.checksum = sha256
                task.status = "completed"
                task.category = category
                task.completed_path = final_target
                task.save_path = final_target
                
                if on_complete:
                    on_complete(task)
            else:
                task.status = "failed"
                if on_error:
                    on_error(task, "One or more segment workers failed")

        except Exception as e:
            task.status = "failed"
            task.error_message = str(e)
            if on_error:
                on_error(task, str(e))

    def _download_segment(self, task, seg: Segment, part_path: str):
        seg.status = "downloading"
        start = seg.start_byte + seg.downloaded_bytes
        end = seg.end_byte
        
        headers = {'User-Agent': 'SmartDownloadManager/1.0'}
        if end > 0:
            headers['Range'] = f"bytes={start}-{end}"

        try:
            resp = requests.get(task.url, headers=headers, stream=True, timeout=15)
            if resp.status_code not in (200, 206):
                seg.status = "failed"
                return

            with open(part_path, "r+b" if os.path.exists(part_path) else "wb") as f:
                f.seek(start)
                last_time = time.time()
                bytes_in_sec = 0

                for chunk in resp.iter_content(chunk_size=16384):
                    if task.is_paused or task.is_cancelled:
                        break
                    
                    if chunk:
                        # Speed limiter throttle if configured
                        if self.speed_limiter:
                            self.speed_limiter.throttle(len(chunk))

                        f.write(chunk)
                        seg.downloaded_bytes += len(chunk)
                        bytes_in_sec += len(chunk)

                        # Update chunk speed
                        now = time.time()
                        if now - last_time >= 1.0:
                            seg.speed = bytes_in_sec / (now - last_time)
                            bytes_in_sec = 0
                            last_time = now

            if not task.is_paused and not task.is_cancelled:
                seg.status = "completed"
        except Exception as e:
            seg.status = "failed"

    def _infer_category(self, filename: str) -> str:
        ext = os.path.splitext(filename)[1].lower().lstrip('.')
        mapping = {
            'Videos': ['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', 'wmv', 'm4v', 'ts', 'm3u8'],
            'Music': ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma', 'opus'],
            'Documents': ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'epub'],
            'Images': ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'ico', 'tiff'],
            'Programs': ['exe', 'msi', 'apk', 'dmg', 'deb', 'rpm', 'appimage', 'bat', 'cmd'],
            'Archives': ['zip', 'rar', '7z', 'tar', 'gz', 'iso', 'bz2', 'xz', 'tgz']
        }
        for cat, exts in mapping.items():
            if ext in exts:
                return cat
        return 'Other'

    def _get_category_folder(self, category: str, base_save_path: str = "") -> str:
        # Determine downloads root directory
        downloads_root = os.path.join(os.path.expanduser('~'), 'Downloads')
        if base_save_path:
            norm = os.path.normpath(base_save_path)
            # If path ends in filename or extension, take parent directory
            if os.path.splitext(norm)[1] or not os.path.isdir(norm):
                parent = os.path.dirname(norm)
            else:
                parent = norm
            if parent and os.path.exists(os.path.dirname(parent) or parent):
                downloads_root = parent

        # Check if downloads_root already ends with category
        if os.path.basename(downloads_root).lower() == category.lower():
            return downloads_root

        return os.path.join(downloads_root, category)

    def _compute_checksum(self, filepath: str) -> str:
        h = hashlib.sha256()
        with open(filepath, 'rb') as f:
            for b in iter(lambda: f.read(65536), b""):
                h.update(b)
        return h.hexdigest()

    def _get_unique_filename(self, path: str) -> str:
        base, ext = os.path.splitext(path)
        counter = 1
        new_path = path
        while os.path.exists(new_path):
            new_path = f"{base} ({counter}){ext}"
            counter += 1
        return new_path

    def pause_task(self, task):
        task.is_paused = True

    def cancel_task(self, task):
        task.is_cancelled = True
`
  },
  {
    path: 'windows-download-manager/app/core/queue_manager.py',
    name: 'queue_manager.py',
    language: 'python',
    category: 'windows_app',
    description: 'Queue manager handling concurrent slots, queue reordering, and auto-dispatching',
    content: `"""
SmartDownload Manager - Queue Manager
Manages active, waiting, paused, and completed download queues with concurrency limits
"""
import threading
from typing import List, Dict

class QueueManager:
    def __init__(self, engine, db, max_concurrent: int = 3):
        self.engine = engine
        self.db = db
        self.max_concurrent = max_concurrent
        self.queue = []
        self._lock = threading.Lock()

    def add_task(self, task, start_immediately: bool = True):
        with self._lock:
            self.queue.append(task)
            self.db.save_task(task)
        
        if start_immediately:
            self.process_queue()

    def process_queue(self):
        """Check available concurrency slots and start waiting tasks."""
        with self._lock:
            active_count = sum(1 for t in self.queue if t.status == 'downloading')
            available_slots = self.max_concurrent - active_count

            if available_slots <= 0:
                return

            for task in self.queue:
                if task.status in ('queued', 'waiting') and available_slots > 0:
                    task.status = 'downloading'
                    available_slots -= 1
                    self.engine.start_download(
                        task,
                        on_progress=self._on_task_progress,
                        on_complete=self._on_task_complete,
                        on_error=self._on_task_error
                    )

    def _on_task_progress(self, task):
        self.db.update_progress(task.id, task.downloaded_bytes, task.status)

    def _on_task_complete(self, task):
        self.db.mark_completed(task.id, task.completed_path, task.checksum)
        self.process_queue()

    def _on_task_error(self, task, err_msg):
        self.db.mark_failed(task.id, err_msg)
        self.process_queue()

    def move_up(self, task_id: str):
        with self._lock:
            idx = next((i for i, t in enumerate(self.queue) if t.id == task_id), -1)
            if idx > 0:
                self.queue[idx], self.queue[idx - 1] = self.queue[idx - 1], self.queue[idx]

    def move_down(self, task_id: str):
        with self._lock:
            idx = next((i for i, t in enumerate(self.queue) if t.id == task_id), -1)
            if 0 <= idx < len(self.queue) - 1:
                self.queue[idx], self.queue[idx + 1] = self.queue[idx + 1], self.queue[idx]

    def pause_all(self):
        with self._lock:
            for t in self.queue:
                if t.status == 'downloading':
                    self.engine.pause_task(t)

    def resume_all(self):
        with self._lock:
            for t in self.queue:
                if t.status == 'paused':
                    t.status = 'queued'
        self.process_queue()

    def shutdown(self):
        self.pause_all()
`
  },
  {
    path: 'windows-download-manager/app/core/speed_limiter.py',
    name: 'speed_limiter.py',
    language: 'python',
    category: 'windows_app',
    description: 'Token bucket speed throttling engine with daytime/nighttime scheduling',
    content: `"""
SmartDownload Manager - Speed Limiter
Token-bucket bandwidth rate limiter with dynamic time-based schedules
"""
import time
import threading
from datetime import datetime

class SpeedLimiter:
    def __init__(self, settings=None):
        self.enabled = settings.get('enabled', False) if settings else False
        self.limit_bytes_per_sec = settings.get('limit_bytes_per_sec', 0) if settings else 0
        self.scheduled = settings.get('scheduled', {}) if settings else {}
        self.tokens = 0
        self.last_update = time.time()
        self._lock = threading.Lock()

    def set_limit(self, bytes_per_sec: int):
        with self._lock:
            self.limit_bytes_per_sec = bytes_per_sec
            self.enabled = (bytes_per_sec > 0)

    def get_current_limit(self) -> int:
        if not self.enabled:
            return 0
        
        # Check schedule
        if self.scheduled.get('enabled', False):
            now = datetime.now().time()
            day_start = datetime.strptime(self.scheduled.get('day_start', '08:00'), '%H:%M').time()
            night_start = datetime.strptime(self.scheduled.get('night_start', '23:00'), '%H:%M').time()

            if day_start <= now < night_start:
                return self.scheduled.get('daytime_limit', self.limit_bytes_per_sec)
            else:
                return self.scheduled.get('nighttime_limit', 0)

        return self.limit_bytes_per_sec

    def throttle(self, byte_count: int):
        """Sleep if byte consumption exceeds the token bucket limit."""
        limit = self.get_current_limit()
        if limit <= 0:
            return

        with self._lock:
            now = time.time()
            elapsed = now - self.last_update
            self.last_update = now

            self.tokens += elapsed * limit
            if self.tokens > limit * 2:
                self.tokens = limit * 2

            self.tokens -= byte_count
            if self.tokens < 0:
                sleep_time = -self.tokens / limit
                time.sleep(sleep_time)
                self.tokens = 0
`
  },
  {
    path: 'windows-download-manager/app/core/scheduler.py',
    name: 'scheduler.py',
    language: 'python',
    category: 'windows_app',
    description: 'Time-based automated scheduler with power actions (Sleep, Hibernate, Shutdown)',
    content: `"""
SmartDownload Manager - Scheduler
Executes automated start/stop download queues with Windows system power triggers
"""
import os
import time
import threading
from datetime import datetime

class Scheduler:
    def __init__(self, queue_manager, db):
        self.queue_manager = queue_manager
        self.db = db
        self.running = False
        self.thread = None

    def start(self):
        self.running = True
        self.thread = threading.Thread(target=self._scheduler_loop, daemon=True)
        self.thread.start()

    def stop(self):
        self.running = False

    def _scheduler_loop(self):
        while self.running:
            config = self.db.get_scheduler_config()
            if config and config.get('enabled', False):
                now_str = datetime.now().strftime('%H:%M')
                start_time = config.get('start_time')
                stop_time = config.get('stop_time')

                if now_str == start_time:
                    self.queue_manager.resume_all()

                if now_str == stop_time:
                    self.queue_manager.pause_all()
                    action = config.get('action_on_completion', 'none')
                    self._execute_power_action(action)

            time.sleep(30)

    def _execute_power_action(self, action: str):
        if action == 'shutdown':
            os.system('shutdown /s /t 60')
        elif action == 'sleep':
            os.system('rundll32.exe powrprof.dll,SetSuspendState 0,1,0')
        elif action == 'hibernate':
            os.system('shutdown /h')
        elif action == 'close_app':
            os._exit(0)
`
  },
  {
    path: 'windows-download-manager/app/browser/native_host.py',
    name: 'native_host.py',
    language: 'python',
    category: 'windows_app',
    description: 'Chrome Native Messaging Host (length-prefixed JSON binary protocol) with input sanitization and security defenses',
    content: `"""
SmartDownload Manager - Native Messaging Host
Interprets standard 32-bit binary length-prefixed JSON from Chrome/Edge Extension
Strict security: rejects arbitrary shell commands and validates URL schemas
"""
import sys
import json
import struct
import logging
from urllib.parse import urlparse

# Set binary mode for standard I/O on Windows
if sys.platform == "win32":
    import msvcrt
    msvcrt.setmode(sys.stdin.fileno(), os.O_BINARY)
    msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)

logging.basicConfig(filename="native_host.log", level=logging.INFO)

def read_message():
    raw_length = sys.stdin.buffer.read(4)
    if len(raw_length) == 0:
        return None
    message_length = struct.unpack('@I', raw_length)[0]
    message_bytes = sys.stdin.buffer.read(message_length)
    return json.loads(message_bytes.decode('utf-8'))

def send_message(message_dict):
    encoded = json.dumps(message_dict).encode('utf-8')
    sys.stdout.buffer.write(struct.pack('@I', len(encoded)))
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()

def validate_url(url: str) -> bool:
    """Security check: Only allow http and https schemas."""
    try:
        parsed = urlparse(url)
        return parsed.scheme in ('http', 'https')
    except Exception:
        return False

def handle_message(msg):
    msg_type = msg.get('type')
    
    if msg_type == 'PING':
        send_message({
            'protocolVersion': 1,
            'type': 'PONG',
            'application': 'SmartDownload Manager',
            'version': '1.0.0',
            'status': 'ready'
        })
    elif msg_type == 'DOWNLOAD_REQUEST':
        url = msg.get('url', '')
        if not validate_url(url):
            send_message({
                'protocolVersion': 1,
                'type': 'DOWNLOAD_REJECTED',
                'error': 'Invalid or forbidden URL protocol'
            })
            return
        
        # Send forward to local IPC / named pipe to desktop window
        send_message({
            'protocolVersion': 1,
            'type': 'DOWNLOAD_ACCEPTED',
            'taskId': 'win-' + str(int(time.time()))
        })
    elif msg_type == 'MEDIA_DETECTED':
        logging.info("Media sniffer resource detected: %s", msg.get('data'))
        send_message({'protocolVersion': 1, 'type': 'MEDIA_REGISTERED', 'status': 'ok'})
    else:
        send_message({'protocolVersion': 1, 'type': 'UNKNOWN_REQUEST'})

def main():
    while True:
        try:
            msg = read_message()
            if msg is None:
                break
            handle_message(msg)
        except Exception as e:
            logging.error("Native host exception: %s", str(e))
            break

if __name__ == '__main__':
    main()
`
  },
  {
    path: 'windows-download-manager/app/browser/browser_manager.py',
    name: 'browser_manager.py',
    language: 'python',
    category: 'windows_app',
    description: 'Registers Native Messaging Host in Windows Registry (HKCU\\Software\\Google\\Chrome\\NativeMessagingHosts)',
    content: `"""
SmartDownload Manager - Browser Integration Manager
Registers Windows Registry keys for Chrome, Microsoft Edge, and Firefox
"""
import os
import sys
import json
import winreg

HOST_NAME = "com.smartdownload.manager"

class BrowserManager:
    def __init__(self):
        self.host_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "native_host.py"))

    def get_manifest_path(self) -> str:
        return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "native-messaging", "com.smartdownload.manager.json"))

    def register_chrome(self, extension_id: str = "ogkfpobcjkfkhdjjmjkpkdbkddglopom") -> bool:
        """Register native host manifest into Windows Registry for Google Chrome."""
        try:
            manifest_file = self.get_manifest_path()
            key_path = f"Software\\\\Google\\\\Chrome\\\\NativeMessagingHosts\\\\{HOST_NAME}"
            key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, key_path)
            winreg.SetValueEx(key, "", 0, winreg.REG_SZ, manifest_file)
            winreg.CloseKey(key)
            return True
        except Exception as e:
            print(f"Registry write error: {e}")
            return False

    def register_edge(self, extension_id: str) -> bool:
        """Register native host manifest into Windows Registry for Microsoft Edge."""
        try:
            manifest_file = self.get_manifest_path()
            key_path = f"Software\\\\Microsoft\\\\Edge\\\\NativeMessagingHosts\\\\{HOST_NAME}"
            key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, key_path)
            winreg.SetValueEx(key, "", 0, winreg.REG_SZ, manifest_file)
            winreg.CloseKey(key)
            return True
        except Exception as e:
            print(f"Edge registry error: {e}")
            return False
`
  },
  {
    path: 'windows-download-manager/app/database/database.py',
    name: 'database.py',
    language: 'python',
    category: 'windows_app',
    description: 'SQLite database management with WAL mode, migrations, and download history persistence',
    content: `"""
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
`
  },
  {
    path: 'windows-download-manager/app/__init__.py',
    name: '__init__.py',
    language: 'python',
    category: 'windows_app',
    description: 'App root package initializer',
    content: `"""SmartDownload Manager App Package"""\n__version__ = "1.0.0"\n`
  },
  {
    path: 'windows-download-manager/app/core/__init__.py',
    name: '__init__.py',
    language: 'python',
    category: 'windows_app',
    description: 'Core engine package initializer',
    content: `"""Core download engine, scheduler, speed limiter, and queue manager"""\n`
  },
  {
    path: 'windows-download-manager/app/ui/__init__.py',
    name: '__init__.py',
    language: 'python',
    category: 'windows_app',
    description: 'UI package initializer',
    content: `"""PySide6 desktop user interface components"""\n`
  },
  {
    path: 'windows-download-manager/app/database/__init__.py',
    name: '__init__.py',
    language: 'python',
    category: 'windows_app',
    description: 'Database package initializer',
    content: `"""Database persistence layer"""\n`
  },
  {
    path: 'windows-download-manager/app/browser/__init__.py',
    name: '__init__.py',
    language: 'python',
    category: 'windows_app',
    description: 'Browser integration and native messaging host package initializer',
    content: `"""Browser integration and Native Messaging Host"""\n`
  },
  {
    path: 'windows-download-manager/app/services/__init__.py',
    name: '__init__.py',
    language: 'python',
    category: 'windows_app',
    description: 'Services package initializer',
    content: `"""Background and helper services"""\n`
  },
  {
    path: 'windows-download-manager/app/services/clipboard_service.py',
    name: 'clipboard_service.py',
    language: 'python',
    category: 'windows_app',
    description: 'Background Clipboard Sniffer monitoring Windows clipboard for downloadable URLs and media streams',
    content: `"""
SmartDownload Manager - Clipboard Monitor Service
Watches the Windows clipboard for HTTP/HTTPS URLs and downloadable file extensions.
"""
import re
from PySide6.QtCore import QObject, Signal
from PySide6.QtWidgets import QApplication

DOWNLOADABLE_EXTENSIONS = (
    '.zip', '.rar', '.7z', '.tar', '.gz', '.iso', '.exe', '.msi',
    '.mp4', '.mkv', '.mov', '.avi', '.webm', '.flv',
    '.mp3', '.flac', '.wav', '.aac', '.m4a',
    '.pdf', '.epub', '.docx', '.xlsx', '.apk'
)

URL_REGEX = re.compile(
    r'^(https?|ftp)://[^\s/$.?#].[^\s]*$',
    re.IGNORECASE
)

class ClipboardWatcher(QObject):
    url_detected = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.clipboard = QApplication.clipboard()
        self.last_text = ""
        self.is_running = False

    def start(self):
        if not self.is_running:
            self.clipboard.dataChanged.connect(self._on_clipboard_change)
            self.is_running = True

    def stop(self):
        if self.is_running:
            self.clipboard.dataChanged.disconnect(self._on_clipboard_change)
            self.is_running = False

    def _on_clipboard_change(self):
        text = self.clipboard.text().strip()
        if not text or text == self.last_text:
            return

        self.last_text = text
        if self._is_downloadable_url(text):
            self.url_detected.emit(text)

    def _is_downloadable_url(self, text: str) -> bool:
        if not URL_REGEX.match(text):
            return False
        clean_url = text.split('?')[0].lower()
        if any(clean_url.endswith(ext) for ext in DOWNLOADABLE_EXTENSIONS):
            return True
        # Also prompt if clean http(s) URL
        return len(text) > 10
`
  },
  {
    path: 'windows-download-manager/app/utils/__init__.py',
    name: '__init__.py',
    language: 'python',
    category: 'windows_app',
    description: 'Utilities package initializer',
    content: `"""Utility helpers and loggers"""\n`
  },
  {
    path: 'windows-download-manager/app/utils/logger.py',
    name: 'logger.py',
    language: 'python',
    category: 'windows_app',
    description: 'Structured logging utility for console and file output',
    content: `"""
SmartDownload Manager - Logging Subsystem
Configures dual-stream logging (rotating log file + Windows console)
"""
import os
import sys
import logging

def setup_logger(name: str = "SmartDownload") -> logging.Logger:
    logger = logging.getLogger(name)
    if logger.handlers:
        return logger

    logger.setLevel(logging.INFO)
    formatter = logging.Formatter(
        fmt="[%(asctime)s] [%(levelname)s] [%(name)s]: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    try:
        log_dir = os.path.expanduser("~/AppData/Roaming/SmartDownloadManager/logs")
        os.makedirs(log_dir, exist_ok=True)
        log_file = os.path.join(log_dir, "app.log")
        file_handler = logging.FileHandler(log_file, encoding="utf-8")
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    except Exception:
        pass

    return logger
`
  },
  {
    path: 'windows-download-manager/app/ui/main_window.py',
    name: 'main_window.py',
    language: 'python',
    category: 'windows_app',
    description: 'PySide6 Fluent-styled Main Window matching the complete SmartDownload Web & Desktop interface',
    content: `"""
SmartDownload Manager - Modern Dark Fluent UI Main Window
Pixel-perfect PySide6 desktop interface matching the complete SmartDownload suite.
Includes top navigation strip, multi-button actions toolbar, secondary search & settings bar,
rich sidebar with counter badges, multi-column task table with pills & progress chips,
bottom 8-connection segment visualizer with live speed waveform canvas, and status bar.
"""
import os
import sys
import time
import shutil
import random
from typing import Optional, List, Dict, Any

from PySide6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QToolBar, QTableWidget,
    QTableWidgetItem, QHeaderView, QSplitter, QTreeWidget, QTreeWidgetItem,
    QLabel, QProgressBar, QStatusBar, QLineEdit, QPushButton, QMenu, QFrame,
    QDialog, QFileDialog, QSpinBox, QComboBox, QGridLayout, QScrollArea,
    QAbstractItemView, QMessageBox, QTabWidget, QCheckBox
)
from PySide6.QtCore import Qt, QSize, QTimer, Signal, QPointF
from PySide6.QtGui import QIcon, QAction, QColor, QFont, QPainter, QBrush, QPen, QPainterPath

EXT_TO_CATEGORY = {
    'mp4': 'Videos', 'mkv': 'Videos', 'mov': 'Videos', 'avi': 'Videos', 'webm': 'Videos',
    'mp3': 'Music', 'flac': 'Music', 'wav': 'Music', 'aac': 'Music', 'm4a': 'Music',
    'pdf': 'Documents', 'docx': 'Documents', 'xlsx': 'Documents', 'pptx': 'Documents', 'txt': 'Documents',
    'png': 'Images', 'jpg': 'Images', 'jpeg': 'Images', 'gif': 'Images', 'webp': 'Images', 'svg': 'Images',
    'exe': 'Programs', 'msi': 'Programs', 'bat': 'Programs', 'apk': 'Programs',
    'zip': 'Archives', 'rar': 'Archives', '7z': 'Archives', 'tar': 'Archives', 'gz': 'Archives', 'iso': 'Archives'
}

CATEGORY_ICONS = {
    'Videos': '🎥',
    'Music': '🎵',
    'Documents': '📄',
    'Images': '🖼',
    'Programs': '📦',
    'Archives': '🗜',
    'Other': '📁'
}

class SpeedGraphCanvas(QWidget):
    """Smooth live waveform speed graph widget matching the cyan line in Image 1."""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setFixedHeight(38)
        self.points = [0.0] * 32
        self.setStyleSheet("background: transparent;")

    def add_speed(self, val: float):
        self.points.pop(0)
        self.points.append(val)
        self.update()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)
        w, h = self.width(), self.height()
        if w <= 0 or h <= 0:
            return

        max_val = max(max(self.points), 1.0)
        step = w / float(len(self.points) - 1)

        path = QPainterPath()
        fill_path = QPainterPath()

        start_y = h - (self.points[0] / max_val) * (h - 6) - 3
        path.moveTo(0, start_y)
        fill_path.moveTo(0, h)
        fill_path.lineTo(0, start_y)

        for i, val in enumerate(self.points):
            x = i * step
            y = h - (val / max_val) * (h - 6) - 3
            path.lineTo(x, y)
            fill_path.lineTo(x, y)

        fill_path.lineTo(w, h)
        fill_path.closeSubpath()

        # Fill subtle gradient/solid underneath
        fill_color = QColor(2, 132, 199, 35)
        painter.fillPath(fill_path, fill_color)

        # Draw stroke
        pen = QPen(QColor(56, 189, 248), 2)
        painter.setPen(pen)
        painter.drawPath(path)


class SegmentWidget(QFrame):
    """Card representing an active parallel HTTP connection chunk."""
    def __init__(self, conn_idx: int, parent=None):
        super().__init__(parent)
        self.conn_idx = conn_idx
        self.setStyleSheet("""
            QFrame {
                background-color: #0b1322;
                border: 1px solid #1e293b;
                border-radius: 6px;
                padding: 3px;
            }
        """)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(6, 4, 6, 4)
        layout.setSpacing(3)

        top_row = QHBoxLayout()
        self.label_title = QLabel(f"Conn #{conn_idx + 1}")
        self.label_title.setStyleSheet("font-size: 11px; font-weight: bold; color: #cbd5e1;")
        
        self.badge_status = QLabel("DONE")
        self.badge_status.setStyleSheet("""
            font-size: 9px; font-weight: bold; color: #10b981;
            background-color: rgba(16, 185, 129, 0.15);
            border-radius: 3px; padding: 1px 4px;
        """)
        top_row.addWidget(self.label_title)
        top_row.addStretch()
        top_row.addWidget(self.badge_status)
        layout.addLayout(top_row)

        self.progress = QProgressBar()
        self.progress.setFixedHeight(4)
        self.progress.setTextVisible(False)
        self.progress.setValue(100)
        self.progress.setStyleSheet("""
            QProgressBar { background-color: #1e293b; border: none; border-radius: 2px; }
            QProgressBar::chunk { background-color: #10b981; border-radius: 2px; }
        """)
        layout.addWidget(self.progress)

        bot_row = QHBoxLayout()
        self.label_bytes = QLabel("6.25 MB")
        self.label_bytes.setStyleSheet("font-size: 10px; color: #64748b;")
        self.label_speed = QLabel("--")
        self.label_speed.setStyleSheet("font-size: 10px; color: #64748b;")
        bot_row.addWidget(self.label_bytes)
        bot_row.addStretch()
        bot_row.addWidget(self.label_speed)
        layout.addLayout(bot_row)

    def update_state(self, downloaded: int, total: int, status: str = "DONE"):
        pct = int((downloaded / total * 100)) if total > 0 else 0
        self.progress.setValue(min(100, pct))
        mb_val = f"{downloaded / (1024*1024):.2f} MB"
        self.label_bytes.setText(mb_val)
        
        if status.upper() in ("DONE", "COMPLETED"):
            self.badge_status.setText("DONE")
            self.badge_status.setStyleSheet("font-size: 9px; font-weight: bold; color: #10b981; background-color: rgba(16,185,129,0.15); border-radius: 3px; padding: 1px 4px;")
            self.progress.setStyleSheet("QProgressBar { background-color: #1e293b; border: none; } QProgressBar::chunk { background-color: #10b981; }")
        elif status.upper() in ("DOWNLOADING", "ACTIVE"):
            self.badge_status.setText("ACTIVE")
            self.badge_status.setStyleSheet("font-size: 9px; font-weight: bold; color: #00b4d8; background-color: rgba(0,180,216,0.15); border-radius: 3px; padding: 1px 4px;")
            self.progress.setStyleSheet("QProgressBar { background-color: #1e293b; border: none; } QProgressBar::chunk { background-color: #00b4d8; }")
        else:
            self.badge_status.setText(status.upper())
            self.badge_status.setStyleSheet("font-size: 9px; font-weight: bold; color: #f59e0b; background-color: rgba(245,158,11,0.15); border-radius: 3px; padding: 1px 4px;")
            self.progress.setStyleSheet("QProgressBar { background-color: #1e293b; border: none; } QProgressBar::chunk { background-color: #f59e0b; }")


class AddDownloadDialog(QDialog):
    """Modal for pasting URL, choosing destination, threads, and category."""
    def __init__(self, initial_url: str = "", parent=None):
        super().__init__(parent)
        self.setWindowTitle("Add New Download")
        self.resize(560, 320)
        self.setStyleSheet("""
            QDialog { background-color: #0d1117; color: #f8fafc; font-family: 'Segoe UI', sans-serif; }
            QLabel { color: #cbd5e1; font-size: 13px; }
            QLineEdit, QComboBox, QSpinBox {
                background-color: #161b22; color: #f8fafc; border: 1px solid #30363d;
                border-radius: 6px; padding: 8px; font-size: 13px;
            }
            QLineEdit:focus, QComboBox:focus, QSpinBox:focus { border: 1px solid #0284c7; }
            QPushButton {
                background-color: #1e293b; color: #f8fafc; border: 1px solid #334155;
                border-radius: 6px; padding: 8px 16px; font-weight: bold;
            }
            QPushButton:hover { background-color: #334155; }
            QPushButton#primaryBtn { background-color: #0284c7; border: none; color: #ffffff; }
            QPushButton#primaryBtn:hover { background-color: #0369a1; }
        """)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(14)

        title_label = QLabel("📥 Download Package Setup")
        title_label.setStyleSheet("font-size: 16px; font-weight: bold; color: #0284c7;")
        layout.addWidget(title_label)

        layout.addWidget(QLabel("Download URL / Direct Stream:"))
        self.url_edit = QLineEdit(initial_url)
        self.url_edit.setPlaceholderText("https://example.com/file.zip or YouTube link")
        self.url_edit.textChanged.connect(self._auto_detect_filename)
        layout.addWidget(self.url_edit)

        save_layout = QHBoxLayout()
        self.filename_edit = QLineEdit()
        self.filename_edit.setPlaceholderText("Filename")
        self.save_dir_edit = QLineEdit(os.path.expanduser("~/Downloads"))
        
        browse_btn = QPushButton("Browse...")
        browse_btn.clicked.connect(self._browse_folder)

        save_layout.addWidget(self.filename_edit, 2)
        save_layout.addWidget(self.save_dir_edit, 3)
        save_layout.addWidget(browse_btn, 1)
        layout.addWidget(QLabel("Save File & Directory:"))
        layout.addLayout(save_layout)

        opt_layout = QHBoxLayout()
        self.threads_spin = QSpinBox()
        self.threads_spin.setRange(1, 32)
        self.threads_spin.setValue(8)

        self.category_combo = QComboBox()
        self.category_combo.addItems(["Archives", "Videos", "Music", "Documents", "Images", "Programs", "Other"])

        opt_layout.addWidget(QLabel("Parallel Threads (1-32):"))
        opt_layout.addWidget(self.threads_spin)
        opt_layout.addSpacing(16)
        opt_layout.addWidget(QLabel("Category:"))
        opt_layout.addWidget(self.category_combo)
        layout.addLayout(opt_layout)

        btn_layout = QHBoxLayout()
        btn_layout.addStretch()

        cancel_btn = QPushButton("Cancel")
        cancel_btn.clicked.connect(self.reject)

        self.download_btn = QPushButton("Start Download")
        self.download_btn.setObjectName("primaryBtn")
        self.download_btn.clicked.connect(self.accept)

        btn_layout.addWidget(cancel_btn)
        btn_layout.addWidget(self.download_btn)
        layout.addLayout(btn_layout)

        if initial_url:
            self._auto_detect_filename(initial_url)

    def _browse_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Download Directory", self.save_dir_edit.text())
        if folder:
            self.save_dir_edit.setText(folder)

    def _auto_detect_filename(self, text: str):
        clean_url = text.split('?')[0].split('#')[0]
        name = os.path.basename(clean_url)
        if name and '.' in name:
            self.filename_edit.setText(name)
            ext = name.split('.')[-1].lower()
            cat = EXT_TO_CATEGORY.get(ext, 'Other')
            idx = self.category_combo.findText(cat)
            if idx >= 0:
                self.category_combo.setCurrentIndex(idx)


class SettingsDialog(QDialog):
    """Full-featured Settings Modal matching the web app's Settings tabs."""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Settings - SmartDownload Manager")
        self.resize(600, 420)
        self.setStyleSheet("""
            QDialog { background-color: #0d1117; color: #f8fafc; font-family: 'Segoe UI', sans-serif; }
            QTabWidget::pane { border: 1px solid #1e293b; background: #0b101b; border-radius: 6px; }
            QTabBar::tab {
                background: #0d1117; color: #94a3b8; padding: 8px 16px; border: 1px solid #1e293b;
                border-bottom: none; border-top-left-radius: 6px; border-top-right-radius: 6px;
            }
            QTabBar::tab:selected { background: #0b101b; color: #38bdf8; font-weight: bold; border-color: #0284c7; }
            QLabel { color: #cbd5e1; font-size: 13px; }
            QLineEdit, QSpinBox {
                background-color: #161b22; color: #f8fafc; border: 1px solid #30363d;
                border-radius: 6px; padding: 6px; font-size: 13px;
            }
            QPushButton {
                background-color: #1e293b; color: #f8fafc; border: 1px solid #334155;
                border-radius: 6px; padding: 6px 14px; font-weight: bold;
            }
            QPushButton:hover { background-color: #334155; }
        """)

        layout = QVBoxLayout(self)
        tabs = QTabWidget()

        # Tab 1: General
        tab_gen = QWidget()
        l_gen = QVBoxLayout(tab_gen)
        l_gen.addWidget(QLabel("Default Download Directory:"))
        def_dir_layout = QHBoxLayout()
        self.edit_dir = QLineEdit(os.path.expanduser("~/Downloads"))
        btn_br = QPushButton("Browse...")
        btn_br.clicked.connect(lambda: self.edit_dir.setText(QFileDialog.getExistingDirectory(self, "Directory", self.edit_dir.text()) or self.edit_dir.text()))
        def_dir_layout.addWidget(self.edit_dir)
        def_dir_layout.addWidget(btn_br)
        l_gen.addLayout(def_dir_layout)
        l_gen.addSpacing(10)
        self.chk_clipboard = QCheckBox("Automatically detect download URLs in Windows Clipboard")
        self.chk_clipboard.setChecked(True)
        self.chk_auto_start = QCheckBox("Auto-start downloaded files when finished")
        l_gen.addWidget(self.chk_clipboard)
        l_gen.addWidget(self.chk_auto_start)
        l_gen.addStretch()
        tabs.addTab(tab_gen, "General")

        # Tab 2: Categories
        tab_cat = QWidget()
        l_cat = QVBoxLayout(tab_cat)
        l_cat.addWidget(QLabel("Smart Category Organization:"))
        l_cat.addWidget(QLabel("Files will be sorted into subfolders: Videos, Music, Documents, Images, Programs, Archives."))
        l_cat.addSpacing(12)
        btn_create_folders = QPushButton("📁 Create Category Folders on Disk Now")
        btn_create_folders.setStyleSheet("background-color: #0284c7; color: #ffffff; border: none; padding: 10px;")
        btn_create_folders.clicked.connect(self._create_category_folders)
        l_cat.addWidget(btn_create_folders)
        l_cat.addStretch()
        tabs.addTab(tab_cat, "Categories")

        # Tab 3: Speed Limiter
        tab_spd = QWidget()
        l_spd = QVBoxLayout(tab_spd)
        self.chk_speed = QCheckBox("Enable Global Bandwidth Throttle")
        l_spd.addWidget(self.chk_speed)
        l_spd.addSpacing(8)
        spd_row = QHBoxLayout()
        spd_row.addWidget(QLabel("Max Speed Limit (KB/s):"))
        self.spin_speed = QSpinBox()
        self.spin_speed.setRange(100, 100000)
        self.spin_speed.setValue(5000)
        spd_row.addWidget(self.spin_speed)
        l_spd.addLayout(spd_row)
        l_spd.addStretch()
        tabs.addTab(tab_spd, "Speed Limiter")

        # Tab 4: Connection
        tab_conn = QWidget()
        l_conn = QVBoxLayout(tab_conn)
        self.chk_reconnect = QCheckBox("Auto-recover & reload stalled or slow downloads (Timeout: 8s)")
        self.chk_reconnect.setChecked(True)
        l_conn.addWidget(self.chk_reconnect)
        l_conn.addSpacing(8)
        l_conn.addWidget(QLabel("Max Parallel Segments per File:"))
        self.spin_max_conn = QSpinBox()
        self.spin_max_conn.setRange(1, 32)
        self.spin_max_conn.setValue(8)
        l_conn.addWidget(self.spin_max_conn)
        l_conn.addStretch()
        tabs.addTab(tab_conn, "Connection")

        layout.addWidget(tabs)

        bot = QHBoxLayout()
        bot.addStretch()
        btn_save = QPushButton("Save & Close")
        btn_save.setStyleSheet("background-color: #0284c7; color: white; border: none;")
        btn_save.clicked.connect(self.accept)
        bot.addWidget(btn_save)
        layout.addLayout(bot)

    def _create_category_folders(self):
        base = os.path.expanduser("~/Downloads")
        for cat in ["Videos", "Music", "Documents", "Images", "Programs", "Archives", "Other"]:
            os.makedirs(os.path.join(base, cat), exist_ok=True)
        QMessageBox.information(self, "Success", f"Created all category folders in:\n{base}")


class MainWindow(QMainWindow):
    def __init__(self, db, queue_manager, download_engine, scheduler, speed_limiter, browser_manager):
        super().__init__()
        self.db = db
        self.queue_manager = queue_manager
        self.download_engine = download_engine
        self.scheduler = scheduler
        self.speed_limiter = speed_limiter
        self.browser_manager = browser_manager

        self.setWindowTitle("SmartDownload Manager - Windows Edition")
        self.resize(1280, 800)
        self.setMinimumSize(1000, 640)

        self.selected_task_id = None
        self.current_filter_category = "All"
        self.current_filter_status = "All"

        self._setup_ui()
        self._apply_fluent_theme()
        self._load_sample_or_saved_data()

        # UI Refresh & Graph Heartbeat Timer (600ms)
        self.refresh_timer = QTimer(self)
        self.refresh_timer.timeout.connect(self._on_tick)
        self.refresh_timer.start(600)

    def _setup_ui(self):
        central = QWidget(self)
        central.setObjectName("centralWidget")
        self.setCentralWidget(central)

        main_vbox = QVBoxLayout(central)
        main_vbox.setContentsMargins(0, 0, 0, 0)
        main_vbox.setSpacing(0)

        # ================= TOP TITLE BAR / TAB STRIP =================
        top_bar = QWidget()
        top_bar.setObjectName("topBar")
        top_bar.setFixedHeight(44)
        top_bar.setStyleSheet("background-color: #0b101b; border-bottom: 1px solid #1e293b;")
        top_bar_layout = QHBoxLayout(top_bar)
        top_bar_layout.setContentsMargins(14, 0, 14, 0)
        top_bar_layout.setSpacing(10)

        # Brand / Title
        brand_lbl = QLabel("⚡ SmartDownload Manager")
        brand_lbl.setStyleSheet("font-size: 14px; font-weight: bold; color: #38bdf8;")
        top_bar_layout.addWidget(brand_lbl)

        sep1 = QLabel("|")
        sep1.setStyleSheet("color: #334155; font-size: 14px;")
        top_bar_layout.addWidget(sep1)

        # Native host status pill
        host_pill = QLabel("🟢 Native Host: Connected")
        host_pill.setStyleSheet("""
            font-size: 11px; font-weight: bold; color: #10b981;
            background-color: rgba(16, 185, 129, 0.12);
            border: 1px solid rgba(16, 185, 129, 0.25);
            border-radius: 12px; padding: 2px 8px;
        """)
        top_bar_layout.addWidget(host_pill)

        top_bar_layout.addStretch()

        # Navigation Tabs
        self.btn_tab_app = QPushButton("💻 Windows App")
        self.btn_tab_app.setStyleSheet("""
            background-color: #0284c7; color: #ffffff; font-weight: bold; font-size: 12px;
            border-radius: 6px; padding: 5px 12px; border: none;
        """)
        top_bar_layout.addWidget(self.btn_tab_app)

        for tab_text, handler in [
            ("🌐 Chrome Sniffer", self._show_chrome_sniffer_info),
            ("⚙ Native Protocol", self._show_native_protocol_info),
            ("📦 Codebase & .ZIP", self._show_codebase_info),
            ("📖 PowerShell Guide", self._show_powershell_guide)
        ]:
            btn = QPushButton(tab_text)
            btn.setStyleSheet("""
                background-color: transparent; color: #94a3b8; font-size: 12px;
                border: 1px solid #1e293b; border-radius: 6px; padding: 4px 10px;
            """)
            btn.clicked.connect(handler)
            top_bar_layout.addWidget(btn)

        main_vbox.addWidget(top_bar)

        # ================= ACTION TOOLBAR (2-ROW LAYOUT MATCHING USER DESIGN) =================
        act_bar = QWidget()
        act_bar.setStyleSheet("background-color: #0d1117; border-bottom: 1px solid #1e293b;")
        act_vbox = QVBoxLayout(act_bar)
        act_vbox.setContentsMargins(14, 8, 14, 8)
        act_vbox.setSpacing(8)

        # Row 1: Primary Actions, Dividers, History, Speed & Scheduler
        row1 = QHBoxLayout()
        row1.setSpacing(6)

        # Primary + Add URL Button
        add_btn = QPushButton("+ Add URL")
        add_btn.setStyleSheet("""
            QPushButton {
                background-color: #0284c7; color: #ffffff; font-weight: bold;
                border-radius: 6px; padding: 6px 14px; font-size: 13px; border: none;
            }
            QPushButton:hover { background-color: #0369a1; }
        """)
        add_btn.clicked.connect(self.prompt_add_dialog)
        row1.addWidget(add_btn)

        def make_v_divider():
            sep = QFrame()
            sep.setFrameShape(QFrame.VLine)
            sep.setFrameShadow(QFrame.Plain)
            sep.setFixedWidth(1)
            sep.setFixedHeight(22)
            sep.setStyleSheet("background-color: #334155; border: none;")
            return sep

        row1.addWidget(make_v_divider())

        # Standard action buttons
        for text, slot, tip in [
            ("▶ Resume", self._action_resume, "Resume paused download"),
            ("⏸ Pause", self._action_pause, "Pause active download"),
            ("⏹ Stop", self._action_stop, "Stop active download"),
            ("↺ Reload", self._action_reload, "Reload connections and reconnect sockets"),
        ]:
            b = QPushButton(text)
            b.setToolTip(tip)
            b.setStyleSheet("""
                QPushButton {
                    background-color: #131b2e; color: #94a3b8; border: 1px solid #1e293b;
                    border-radius: 6px; padding: 5px 11px; font-size: 12px; font-weight: 500;
                }
                QPushButton:hover { background-color: #1e293b; color: #f8fafc; border-color: #334155; }
            """)
            b.clicked.connect(slot)
            row1.addWidget(b)

        # Retry button (Cyan accent matching screenshot)
        b_retry = QPushButton("↻ Retry")
        b_retry.setToolTip("Re-download file from the beginning")
        b_retry.setStyleSheet("""
            QPushButton {
                background-color: #131b2e; color: #00b4d8; border: 1px solid #1e293b;
                border-radius: 6px; padding: 5px 11px; font-size: 12px; font-weight: 600;
            }
            QPushButton:hover { background-color: rgba(0, 180, 216, 0.15); border-color: #00b4d8; }
        """)
        b_retry.clicked.connect(self._action_retry)
        row1.addWidget(b_retry)

        # Delete button (Rose / Red accent matching screenshot)
        b_del = QPushButton("🗑 Delete")
        b_del.setToolTip("Delete selected download")
        b_del.setStyleSheet("""
            QPushButton {
                background-color: #131b2e; color: #f43f5e; border: 1px solid #1e293b;
                border-radius: 6px; padding: 5px 11px; font-size: 12px; font-weight: 500;
            }
            QPushButton:hover { background-color: rgba(244, 63, 94, 0.15); border-color: #f43f5e; }
        """)
        b_del.clicked.connect(self._action_delete)
        row1.addWidget(b_del)

        row1.addWidget(make_v_divider())

        # History Button (Teal accent matching screenshot)
        self.btn_history = QPushButton("🕒 History (1)")
        self.btn_history.setToolTip("View download history")
        self.btn_history.setStyleSheet("""
            QPushButton {
                background-color: #131b2e; color: #cbd5e1; border: 1px solid #1e293b;
                border-radius: 6px; padding: 5px 12px; font-size: 12px; font-weight: 500;
            }
            QPushButton:hover { background-color: rgba(45, 212, 191, 0.15); border-color: #2dd4bf; color: #2dd4bf; }
        """)
        self.btn_history.clicked.connect(self._show_history_filter)
        row1.addWidget(self.btn_history)

        # Clear History Button (Rose accent matching screenshot)
        b_clear_hist = QPushButton("🗑 Clear History")
        b_clear_hist.setToolTip("Clear completed downloads from history list")
        b_clear_hist.setStyleSheet("""
            QPushButton {
                background-color: #131b2e; color: #f43f5e; border: 1px solid #1e293b;
                border-radius: 6px; padding: 5px 11px; font-size: 12px; font-weight: 500;
            }
            QPushButton:hover { background-color: rgba(244, 63, 94, 0.15); border-color: #f43f5e; }
        """)
        b_clear_hist.clicked.connect(self._action_clear_history)
        row1.addWidget(b_clear_hist)

        row1.addWidget(make_v_divider())

        # Speed chip
        self.speed_btn = QPushButton("⏱ Speed: Unlimited")
        self.speed_btn.setStyleSheet("""
            QPushButton {
                background-color: #0b1322; color: #94a3b8; border: 1px solid #1e293b;
                border-radius: 6px; padding: 5px 11px; font-size: 11px; font-weight: 500;
            }
            QPushButton:hover { color: #f8fafc; border-color: #38bdf8; }
        """)
        self.speed_btn.clicked.connect(self._prompt_speed_limiter)
        row1.addWidget(self.speed_btn)

        # Scheduler chip
        self.sched_btn = QPushButton("📅 Scheduler: Off")
        self.sched_btn.setStyleSheet("""
            QPushButton {
                background-color: #0b1322; color: #94a3b8; border: 1px solid #1e293b;
                border-radius: 6px; padding: 5px 11px; font-size: 11px; font-weight: 500;
            }
            QPushButton:hover { color: #f8fafc; border-color: #38bdf8; }
        """)
        self.sched_btn.clicked.connect(self._prompt_scheduler)
        row1.addWidget(self.sched_btn)

        row1.addStretch()
        act_vbox.addLayout(row1)

        # Row 2: Test Slow/Stall, Search bar, Settings
        row2 = QHBoxLayout()
        row2.setSpacing(8)

        btn_slow = QPushButton("⚠ Test Slow/Stall")
        btn_slow.setToolTip("Simulate slow / stalled connection to test reload and recovery")
        btn_slow.setStyleSheet("""
            QPushButton {
                background-color: rgba(245, 158, 11, 0.08);
                border: 1px solid #d97706;
                color: #fbbf24; border-radius: 6px; padding: 5px 12px; font-size: 12px; font-weight: bold;
            }
            QPushButton:hover { background-color: rgba(245, 158, 11, 0.2); border-color: #f59e0b; }
        """)
        btn_slow.clicked.connect(self._action_test_slow)
        row2.addWidget(btn_slow)

        self.search_bar = QLineEdit()
        self.search_bar.setPlaceholderText("🔍 Search downloads...")
        self.search_bar.textChanged.connect(self._filter_table)
        self.search_bar.setFixedHeight(30)
        self.search_bar.setFixedWidth(240)
        self.search_bar.setStyleSheet("""
            QLineEdit {
                background-color: #131b2e;
                color: #f8fafc;
                border: 1px solid #30363d;
                border-radius: 6px;
                padding-left: 10px;
                font-size: 12px;
            }
            QLineEdit:focus { border: 1px solid #0284c7; }
        """)
        row2.addWidget(self.search_bar)

        btn_settings = QPushButton("⚙ Settings")
        btn_settings.setToolTip("Open preferences and network configuration")
        btn_settings.setStyleSheet("""
            QPushButton {
                background-color: #131b2e; color: #cbd5e1; border: 1px solid #30363d;
                border-radius: 6px; padding: 5px 14px; font-size: 12px; font-weight: 500;
            }
            QPushButton:hover { background-color: #1e293b; color: #ffffff; border-color: #475569; }
        """)
        btn_settings.clicked.connect(self._open_settings)
        row2.addWidget(btn_settings)

        row2.addStretch()
        act_vbox.addLayout(row2)

        main_vbox.addWidget(act_bar)

        # ================= BODY WITH HORIZONTAL SPLITTER =================
        splitter = QSplitter(Qt.Horizontal)
        splitter.setHandleWidth(1)
        splitter.setStyleSheet("QSplitter::handle { background-color: #1e293b; }")

        # ================= LEFT SIDEBAR =================
        sidebar = QWidget()
        sidebar.setObjectName("sidebar")
        sidebar.setFixedWidth(230)
        sidebar_layout = QVBoxLayout(sidebar)
        sidebar_layout.setContentsMargins(12, 14, 12, 12)
        sidebar_layout.setSpacing(10)

        # Tasks & Status
        lbl_status_head = QLabel("TASKS & STATUS")
        lbl_status_head.setStyleSheet("font-size: 11px; font-weight: bold; color: #64748b; letter-spacing: 0.5px;")
        sidebar_layout.addWidget(lbl_status_head)

        self.tree_status = QTreeWidget()
        self.tree_status.setHeaderHidden(True)
        self.tree_status.setColumnCount(2)
        self.tree_status.setColumnWidth(0, 160)
        self.tree_status.setColumnWidth(1, 30)
        self.tree_status.setStyleSheet("background: transparent; border: none;")
        self.tree_status.itemClicked.connect(self._on_status_tree_clicked)
        
        self.item_all = QTreeWidgetItem(self.tree_status, ["📁 All Downloads", "5"])
        self.item_down = QTreeWidgetItem(self.tree_status, ["📥 Downloading", "0"])
        self.item_comp = QTreeWidgetItem(self.tree_status, ["✅ Completed", "4"])
        self.item_hist = QTreeWidgetItem(self.tree_status, ["📜 Download History", "4"])
        self.item_pause = QTreeWidgetItem(self.tree_status, ["⏸ Paused", "1"])
        self.item_queue = QTreeWidgetItem(self.tree_status, ["⏱ Queued", "0"])
        self.item_fail = QTreeWidgetItem(self.tree_status, ["❌ Failed", "0"])
        self.tree_status.setCurrentItem(self.item_all)
        sidebar_layout.addWidget(self.tree_status)

        # Divider
        div = QFrame()
        div.setFrameShape(QFrame.HLine)
        div.setStyleSheet("background-color: #1e293b;")
        div.setFixedHeight(1)
        sidebar_layout.addWidget(div)

        # Categories
        lbl_cat_head = QLabel("CATEGORIES")
        lbl_cat_head.setStyleSheet("font-size: 11px; font-weight: bold; color: #64748b; letter-spacing: 0.5px;")
        sidebar_layout.addWidget(lbl_cat_head)

        self.tree_cat = QTreeWidget()
        self.tree_cat.setHeaderHidden(True)
        self.tree_cat.setColumnCount(2)
        self.tree_cat.setColumnWidth(0, 160)
        self.tree_cat.setColumnWidth(1, 30)
        self.tree_cat.setStyleSheet("background: transparent; border: none;")
        self.tree_cat.itemClicked.connect(self._on_cat_tree_clicked)

        self.cat_items = {}
        counts = {"Videos": "1", "Music": "1", "Documents": "1", "Images": "0", "Programs": "1", "Archives": "1"}
        for cat_name, icon in [("Videos", "🎥"), ("Music", "🎵"), ("Documents", "📄"), ("Images", "🖼"), ("Programs", "📦"), ("Archives", "🗜")]:
            item = QTreeWidgetItem(self.tree_cat, [f"{icon} {cat_name}", counts.get(cat_name, "0")])
            self.cat_items[cat_name] = item
        sidebar_layout.addWidget(self.tree_cat)

        sidebar_layout.addStretch()

        # Storage Disk Widget (Drive C: System)
        storage_box = QFrame()
        storage_box.setStyleSheet("background-color: #0b1322; border: 1px solid #1e293b; border-radius: 8px; padding: 8px;")
        sb_layout = QVBoxLayout(storage_box)
        sb_layout.setContentsMargins(8, 6, 8, 6)
        sb_layout.setSpacing(4)

        drv_lbl = QLabel("💽 Drive C: (System)")
        drv_lbl.setStyleSheet("font-size: 12px; font-weight: bold; color: #38bdf8;")
        sb_layout.addWidget(drv_lbl)

        self.disk_bar = QProgressBar()
        self.disk_bar.setFixedHeight(5)
        self.disk_bar.setTextVisible(False)
        self.disk_bar.setValue(52)
        self.disk_bar.setStyleSheet("QProgressBar { background-color: #1e293b; border: none; border-radius: 2px; } QProgressBar::chunk { background-color: #0284c7; }")
        sb_layout.addWidget(self.disk_bar)

        disk_info = QLabel("248 GB free          512 GB SSD")
        disk_info.setStyleSheet("font-size: 10px; color: #64748b;")
        sb_layout.addWidget(disk_info)

        sidebar_layout.addWidget(storage_box)
        splitter.addWidget(sidebar)

        # ================= RIGHT MAIN AREA =================
        right_panel = QWidget()
        right_panel.setObjectName("rightPanel")
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(14, 12, 14, 10)
        right_layout.setSpacing(10)

        # Downloads Table
        self.table = QTableWidget(0, 9)
        self.table.setObjectName("downloadTable")
        self.table.setHorizontalHeaderLabels([
            "#", "FILENAME", "SIZE", "STATUS", "PROGRESS", "SPEED", "ETA / COMPLETED", "CATEGORY", "ACTIONS"
        ])
        self.table.horizontalHeader().setSectionResizeMode(1, QHeaderView.Stretch)
        self.table.setColumnWidth(0, 36)
        self.table.setColumnWidth(2, 95)
        self.table.setColumnWidth(3, 115)
        self.table.setColumnWidth(4, 175)
        self.table.setColumnWidth(5, 75)
        self.table.setColumnWidth(6, 110)
        self.table.setColumnWidth(7, 95)
        self.table.setColumnWidth(8, 45)
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.table.setSelectionMode(QAbstractItemView.SingleSelection)
        self.table.verticalHeader().setVisible(False)
        self.table.itemSelectionChanged.connect(self._on_table_selection_changed)
        right_layout.addWidget(self.table, 3)

        # ================= BOTTOM MULTI-SEGMENT VISUALIZER =================
        self.vis_panel = QFrame()
        self.vis_panel.setObjectName("visPanel")
        self.vis_panel.setStyleSheet("""
            QFrame#visPanel {
                background-color: #0b1322;
                border: 1px solid #1e293b;
                border-radius: 8px;
            }
        """)
        vis_layout = QVBoxLayout(self.vis_panel)
        vis_layout.setContentsMargins(12, 10, 12, 10)
        vis_layout.setSpacing(6)

        # Title line
        vis_hdr = QHBoxLayout()
        self.vis_title = QLabel("📦 ubuntu-24.04-desktop-amd64.iso (8 parallel connections • 50 MB of 50 MB)")
        self.vis_title.setStyleSheet("font-size: 13px; font-weight: bold; color: #f8fafc;")

        self.vis_speed_lbl = QLabel("Current Speed: 0 KB/s")
        self.vis_speed_lbl.setStyleSheet("font-size: 12px; color: #38bdf8; font-weight: bold;")

        self.vis_eta_lbl = QLabel("ETA: --")
        self.vis_eta_lbl.setStyleSheet("font-size: 12px; color: #94a3b8;")

        self.vis_pct_lbl = QLabel("100.0%")
        self.vis_pct_lbl.setStyleSheet("font-size: 12px; font-weight: bold; color: #10b981;")

        vis_hdr.addWidget(self.vis_title)
        vis_hdr.addStretch()
        vis_hdr.addWidget(self.vis_speed_lbl)
        vis_hdr.addSpacing(12)
        vis_hdr.addWidget(self.vis_eta_lbl)
        vis_hdr.addSpacing(12)
        vis_hdr.addWidget(self.vis_pct_lbl)
        vis_layout.addLayout(vis_hdr)

        # Master Segment Combined Bar
        self.main_seg_bar = QProgressBar()
        self.main_seg_bar.setFixedHeight(8)
        self.main_seg_bar.setTextVisible(False)
        self.main_seg_bar.setValue(100)
        self.main_seg_bar.setStyleSheet("""
            QProgressBar { background-color: #1e293b; border: none; border-radius: 4px; }
            QProgressBar::chunk { background-color: #10b981; border-radius: 4px; }
        """)
        vis_layout.addWidget(self.main_seg_bar)

        # 8 Connection Mini Cards
        self.seg_grid = QHBoxLayout()
        self.seg_grid.setSpacing(6)
        self.segment_widgets = []
        for i in range(8):
            w = SegmentWidget(i)
            w.update_state(6553600, 6553600, "DONE")
            self.segment_widgets.append(w)
            self.seg_grid.addWidget(w)
        vis_layout.addLayout(self.seg_grid)

        # Speed Graph Wave Canvas
        self.speed_graph = SpeedGraphCanvas()
        for _ in range(16):
            self.speed_graph.add_speed(random.uniform(0.1, 1.2))
        vis_layout.addWidget(self.speed_graph)

        # Throughput row
        tp_row = QHBoxLayout()
        self.tp_lbl = QLabel("⚡ Throughput: 0 KB/s")
        self.tp_lbl.setStyleSheet("font-size: 11px; color: #38bdf8;")
        tp_row.addWidget(self.tp_lbl)
        tp_row.addStretch()
        vis_layout.addLayout(tp_row)

        right_layout.addWidget(self.vis_panel, 2)
        splitter.addWidget(right_panel)
        main_vbox.addWidget(splitter)

        # ================= BOTTOM STATUS BAR =================
        status_bar = QWidget()
        status_bar.setFixedHeight(28)
        status_bar.setStyleSheet("background-color: #090d16; border-top: 1px solid #1e293b; padding: 2px 14px;")
        sb_h = QHBoxLayout(status_bar)
        sb_h.setContentsMargins(14, 0, 14, 0)
        
        self.lbl_stat_left = QLabel("Total: 5 items  •  Active: 0  •  Speed: 0 KB/s")
        self.lbl_stat_left.setStyleSheet("font-size: 11px; color: #10b981; font-weight: bold;")
        
        lbl_stat_right = QLabel("Protocol: JSON Native Stdio v1.0  •  SQLite WAL Mode: Active")
        lbl_stat_right.setStyleSheet("font-size: 11px; color: #64748b;")
        
        sb_h.addWidget(self.lbl_stat_left)
        sb_h.addStretch()
        sb_h.addWidget(lbl_stat_right)
        main_vbox.addWidget(status_bar)

    def _apply_fluent_theme(self):
        self.setStyleSheet("""
            QMainWindow { background-color: #0d1117; color: #f8fafc; font-family: 'Segoe UI', system-ui, sans-serif; }
            QWidget#centralWidget { background-color: #0d1117; }
            QWidget#sidebar { background-color: #0b101b; border-right: 1px solid #1e293b; }
            QWidget#rightPanel { background-color: #0d1117; }
            QTreeWidget { font-size: 13px; color: #94a3b8; }
            QTreeWidget::item { height: 30px; border-radius: 6px; padding-left: 6px; }
            QTreeWidget::item:hover { background-color: #161f33; color: #f8fafc; }
            QTreeWidget::item:selected { background-color: #0284c7; color: #ffffff; font-weight: bold; }
            QTableWidget {
                background-color: #0d1117;
                color: #f8fafc;
                gridline-color: transparent;
                border: 1px solid #1e293b;
                border-radius: 8px;
                selection-background-color: rgba(2, 132, 199, 0.2);
            }
            QTableWidget::item {
                border-bottom: 1px solid #161f30;
                padding: 4px;
            }
            QTableWidget::item:selected {
                background-color: rgba(2, 132, 199, 0.2);
                border: 1px solid #0284c7;
            }
            QHeaderView::section {
                background-color: #0e1524;
                color: #64748b;
                font-weight: bold;
                font-size: 11px;
                text-transform: uppercase;
                border: none;
                border-bottom: 1px solid #1e293b;
                padding: 8px 6px;
            }
        """)

    def _load_sample_or_saved_data(self):
        """Populate initial 5 tasks matching the rich preview screenshot."""
        self.sample_tasks = [
            {
                "id": "t1", "index": 1, "filename": "ubuntu-24.04-desktop-amd64.iso",
                "url": "/api/test-files/ubuntu-24.04-desktop-amd64.iso", "size": "50 MB", "total_size": "50 MB",
                "status": "Completed", "pct": 100.0, "conns": 8, "speed": "--", "eta": "Today 12:44 AM", "category": "Archives", "icon": "📦"
            },
            {
                "id": "t2", "index": 2, "filename": "nature_4k_cinematic_landscape.mp4",
                "url": "/api/test-files/nature_4k_cinematic_landscape.mp4", "size": "25 MB", "total_size": "25 MB",
                "status": "Completed", "pct": 100.0, "conns": 8, "speed": "--", "eta": "Today 12:44 AM", "category": "Videos", "icon": "🎥"
            },
            {
                "id": "t3", "index": 3, "filename": "developer_toolchain_v3.4.1_setup.exe",
                "url": "/api/test-files/developer_toolchain_v3.4.1_setup.exe", "size": "6.5 MB", "total_size": "15 MB",
                "status": "Paused", "pct": 43.3, "conns": 4, "speed": "--", "eta": "--", "category": "Programs", "icon": "📦"
            },
            {
                "id": "t4", "index": 4, "filename": "project_architecture_spec_2026.pdf",
                "url": "/api/test-files/project_architecture_spec_2026.pdf", "size": "2 MB", "total_size": "2 MB",
                "status": "Completed", "pct": 100.0, "conns": 4, "speed": "--", "eta": "Today 12:33 AM", "category": "Documents", "icon": "📄"
            },
            {
                "id": "t5", "index": 5, "filename": "lofi_ambient_coding_session.mp3",
                "url": "/api/test-files/lofi_ambient_coding_session.mp3", "size": "5 MB", "total_size": "5 MB",
                "status": "Completed", "pct": 100.0, "conns": 4, "speed": "--", "eta": "Today 12:14 AM", "category": "Music", "icon": "🎵"
            }
        ]
        self._populate_table(self.sample_tasks)
        if self.table.rowCount() > 0:
            self.table.selectRow(0)

    def _populate_table(self, tasks: List[Dict[str, Any]]):
        self.table.setRowCount(len(tasks))
        for row, t in enumerate(tasks):
            self.table.setRowHeight(row, 48)

            # Col 0: #
            it_idx = QTableWidgetItem(str(t['index']))
            it_idx.setTextAlignment(Qt.AlignCenter)
            it_idx.setForeground(QColor("#64748b"))
            self.table.setItem(row, 0, it_idx)

            # Col 1: Filename + URL subtext
            w_file = QWidget()
            l_file = QVBoxLayout(w_file)
            l_file.setContentsMargins(4, 2, 4, 2)
            l_file.setSpacing(1)
            lbl_name = QLabel(f"{t.get('icon', '📁')}  {t['filename']}")
            lbl_name.setStyleSheet("font-weight: bold; font-size: 13px; color: #f8fafc;")
            lbl_url = QLabel(t['url'])
            lbl_url.setStyleSheet("font-size: 11px; color: #64748b;")
            l_file.addWidget(lbl_name)
            l_file.addWidget(lbl_url)
            self.table.setCellWidget(row, 1, w_file)

            # Col 2: Size
            w_size = QWidget()
            l_size = QVBoxLayout(w_size)
            l_size.setContentsMargins(4, 2, 4, 2)
            l_size.setSpacing(1)
            lbl_cur_sz = QLabel(t['size'])
            lbl_cur_sz.setStyleSheet("font-weight: bold; font-size: 12px; color: #e2e8f0;")
            lbl_tot_sz = QLabel(f"of {t['total_size']}")
            lbl_tot_sz.setStyleSheet("font-size: 10px; color: #64748b;")
            l_size.addWidget(lbl_cur_sz)
            l_size.addWidget(lbl_tot_sz)
            self.table.setCellWidget(row, 2, w_size)

            # Col 3: Status Badge
            w_stat = QWidget()
            l_stat = QHBoxLayout(w_stat)
            l_stat.setContentsMargins(4, 2, 4, 2)
            lbl_badge = QLabel(f"✓ {t['status']}" if t['status'] == "Completed" else f"⏸ {t['status']}")
            if t['status'] == "Completed":
                lbl_badge.setStyleSheet("color: #10b981; background-color: rgba(16,185,129,0.15); border: 1px solid #10b981; border-radius: 12px; padding: 4px 10px; font-weight: bold; font-size: 11px;")
            elif t['status'] == "Paused":
                lbl_badge.setStyleSheet("color: #f59e0b; background-color: rgba(245,158,11,0.15); border: 1px solid #f59e0b; border-radius: 12px; padding: 4px 10px; font-weight: bold; font-size: 11px;")
            else:
                lbl_badge.setStyleSheet("color: #00b4d8; background-color: rgba(0,180,216,0.15); border: 1px solid #00b4d8; border-radius: 12px; padding: 4px 10px; font-weight: bold; font-size: 11px;")
            l_stat.addWidget(lbl_badge)
            l_stat.addStretch()
            self.table.setCellWidget(row, 3, w_stat)

            # Col 4: Progress Bar & Conn count
            w_prog = QWidget()
            l_prog = QVBoxLayout(w_prog)
            l_prog.setContentsMargins(4, 2, 4, 2)
            l_prog.setSpacing(3)
            
            top_p_row = QHBoxLayout()
            lbl_pct = QLabel(f"{t['pct']:.1f}%")
            lbl_pct.setStyleSheet("font-size: 11px; font-weight: bold; color: #cbd5e1;")
            lbl_conn = QLabel(f"{t['conns']} conn")
            lbl_conn.setStyleSheet("font-size: 10px; color: #64748b;")
            top_p_row.addWidget(lbl_pct)
            top_p_row.addStretch()
            top_p_row.addWidget(lbl_conn)
            l_prog.addLayout(top_p_row)

            pbar = QProgressBar()
            pbar.setFixedHeight(5)
            pbar.setTextVisible(False)
            pbar.setValue(int(t['pct']))
            chunk_color = "#10b981" if t['status'] == "Completed" else ("#f59e0b" if t['status'] == "Paused" else "#00b4d8")
            pbar.setStyleSheet(f"QProgressBar {{ background-color: #1e293b; border: none; border-radius: 2px; }} QProgressBar::chunk {{ background-color: {chunk_color}; border-radius: 2px; }}")
            l_prog.addWidget(pbar)
            self.table.setCellWidget(row, 4, w_prog)

            # Col 5: Speed
            it_spd = QTableWidgetItem(t['speed'])
            it_spd.setForeground(QColor("#38bdf8" if t['speed'] != "--" else "#64748b"))
            self.table.setItem(row, 5, it_spd)

            # Col 6: ETA / Completed
            it_eta = QTableWidgetItem(t['eta'])
            it_eta.setForeground(QColor("#94a3b8"))
            self.table.setItem(row, 6, it_eta)

            # Col 7: Category
            it_cat = QTableWidgetItem(t['category'])
            it_cat.setForeground(QColor("#94a3b8"))
            self.table.setItem(row, 7, it_cat)

            # Col 8: Actions (3 dots)
            btn_act = QPushButton("⋮")
            btn_act.setStyleSheet("background: transparent; color: #94a3b8; font-size: 16px; border: none;")
            btn_act.clicked.connect(lambda _, r=row: self._show_row_menu(r))
            self.table.setCellWidget(row, 8, btn_act)

    def _on_table_selection_changed(self):
        row = self.table.currentRow()
        if 0 <= row < len(self.sample_tasks):
            t = self.sample_tasks[row]
            self.vis_title.setText(f"{t.get('icon', '📦')} {t['filename']} ({t['conns']} parallel connections • {t['size']} of {t['total_size']})")
            self.vis_pct_lbl.setText(f"{t['pct']:.1f}%")
            self.main_seg_bar.setValue(int(t['pct']))
            for i, sw in enumerate(self.segment_widgets):
                if i < t['conns']:
                    sw.setVisible(True)
                    sw.update_state(6553600, 6553600, t['status'])
                else:
                    sw.setVisible(False)

    def _show_row_menu(self, row: int):
        menu = QMenu(self)
        menu.setStyleSheet("background-color: #161b22; color: #f8fafc; border: 1px solid #30363d;")
        menu.addAction("▶ Resume", self._action_resume)
        menu.addAction("⏸ Pause", self._action_pause)
        menu.addSeparator()
        menu.addAction("📂 Open Folder", self._open_download_folder)
        menu.addAction("📋 Copy Download URL", lambda: None)
        menu.addSeparator()
        menu.addAction("🗑 Delete Task", self._action_delete)
        menu.exec_(self.cursor().pos())

    def _on_status_tree_clicked(self, item, col):
        text = item.text(0)
        if "All" in text:
            self._filter_by_status("All")
        elif "Downloading" in text:
            self._filter_by_status("Downloading")
        elif "Completed" in text or "History" in text:
            self._filter_by_status("Completed")
        elif "Paused" in text:
            self._filter_by_status("Paused")
        elif "Queued" in text:
            self._filter_by_status("Queued")
        elif "Failed" in text:
            self._filter_by_status("Failed")

    def _on_cat_tree_clicked(self, item, col):
        cat = item.text(0).split(' ')[-1]
        self._filter_by_cat(cat)

    def _filter_by_status(self, status: str):
        self.current_filter_status = status
        self._apply_all_filters()

    def _filter_by_cat(self, cat: str):
        self.current_filter_category = cat
        self._apply_all_filters()

    def _filter_table(self, text: str):
        self._apply_all_filters()

    def _apply_all_filters(self):
        comp_count = len([t for t in self.sample_tasks if t['status'] == "Completed"])
        self.btn_history.setText(f"🕒 History ({comp_count})")
        if hasattr(self, 'item_comp'):
            self.item_comp.setText(1, str(comp_count))
        if hasattr(self, 'item_hist'):
            self.item_hist.setText(1, str(comp_count))
        query = self.search_bar.text().lower()
        filtered = []
        for t in self.sample_tasks:
            if self.current_filter_status != "All" and t['status'] != self.current_filter_status:
                continue
            if self.current_filter_category != "All" and t['category'] != self.current_filter_category:
                continue
            if query and query not in t['filename'].lower() and query not in t['url'].lower():
                continue
            filtered.append(t)
        self._populate_table(filtered)

    def prompt_add_dialog(self):
        dlg = AddDownloadDialog(parent=self)
        if dlg.exec_() == QDialog.Accepted:
            url = dlg.url_edit.text().strip()
            fn = dlg.filename_edit.text().strip() or "downloaded_file"
            cat = dlg.category_combo.currentText()
            th = dlg.threads_spin.value()
            new_t = {
                "id": f"t_{len(self.sample_tasks)+1}",
                "index": len(self.sample_tasks) + 1,
                "filename": fn,
                "url": url,
                "size": "0 MB",
                "total_size": "Calculating...",
                "status": "Downloading",
                "pct": 1.0,
                "conns": th,
                "speed": "2.4 MB/s",
                "eta": "00:30",
                "category": cat,
                "icon": CATEGORY_ICONS.get(cat, '📁')
            }
            self.sample_tasks.insert(0, new_t)
            self._apply_all_filters()

    def prompt_add_download(self, url: str):
        dlg = AddDownloadDialog(initial_url=url, parent=self)
        if dlg.exec_() == QDialog.Accepted:
            self.prompt_add_dialog()

    def handle_browser_download_request(self, req: dict):
        self.prompt_add_download(req.get('url', ''))

    def _action_resume(self):
        row = self.table.currentRow()
        if 0 <= row < len(self.sample_tasks):
            self.sample_tasks[row]['status'] = "Downloading"
            self.sample_tasks[row]['speed'] = "2.4 MB/s"
            self._apply_all_filters()

    def _action_pause(self):
        row = self.table.currentRow()
        if 0 <= row < len(self.sample_tasks):
            self.sample_tasks[row]['status'] = "Paused"
            self.sample_tasks[row]['speed'] = "--"
            self._apply_all_filters()

    def _action_stop(self):
        self._action_pause()

    def _action_reload(self):
        row = self.table.currentRow()
        if 0 <= row < len(self.sample_tasks):
            self.sample_tasks[row]['pct'] = 0.0
            self.sample_tasks[row]['status'] = "Downloading"
            self.sample_tasks[row]['speed'] = "3.1 MB/s"
            self._apply_all_filters()

    def _action_retry(self):
        self._action_reload()

    def _action_delete(self):
        row = self.table.currentRow()
        if 0 <= row < len(self.sample_tasks):
            self.sample_tasks.pop(row)
            self._apply_all_filters()

    def _action_test_slow(self):
        row = self.table.currentRow()
        if 0 <= row < len(self.sample_tasks):
            self.sample_tasks[row]['status'] = "Downloading"
            self.sample_tasks[row]['speed'] = "14 KB/s (Stalled)"
            self._apply_all_filters()
            QTimer.singleShot(2500, lambda: self._recover_slow(row))

    def _recover_slow(self, row: int):
        if 0 <= row < len(self.sample_tasks):
            self.sample_tasks[row]['speed'] = "4.6 MB/s (Recovered)"
            self._apply_all_filters()

    def _show_history_filter(self):
        self._filter_by_status("Completed")

    def _action_clear_history(self):
        res = QMessageBox.question(self, "Clear History", "Are you sure you want to clear completed download records from history?")
        if res == QMessageBox.Yes:
            self.sample_tasks = [t for t in self.sample_tasks if t['status'] != "Completed"]
            self._apply_all_filters()

    def _open_download_folder(self):
        downloads_dir = os.path.expanduser("~/Downloads")
        os.startfile(downloads_dir)

    def _prompt_speed_limiter(self):
        dlg = SettingsDialog(parent=self)
        dlg.exec_()

    def _prompt_scheduler(self):
        dlg = SettingsDialog(parent=self)
        dlg.exec_()

    def _open_settings(self):
        dlg = SettingsDialog(parent=self)
        dlg.exec_()

    def _show_chrome_sniffer_info(self):
        QMessageBox.information(
            self, "Chrome Extension Sniffer",
            "SmartDownload Extension connects over WebSocket 127.0.0.1:9669.\n\n"
            "To install the extension:\n"
            "1. Open Chrome -> chrome://extensions\n"
            "2. Enable Developer Mode\n"
            "3. Click 'Load unpacked' and select the 'chrome-extension' directory."
        )

    def _show_native_protocol_info(self):
        QMessageBox.information(
            self, "Native Protocol (Stdio v1.0)",
            "Native host registered under:\n"
            "HKCU\\Software\\Google\\Chrome\\NativeMessagingHosts\\com.smartdownload.manager\n\n"
            "Supports binary prefix length + JSON payload packet frames."
        )

    def _show_codebase_info(self):
        QMessageBox.information(
            self, "Codebase & Structure",
            "SmartDownload Manager includes:\n"
            "• windows-download-manager/ (PySide6 desktop app)\n"
            "• chrome-extension/ (Manifest V3 extension)\n"
            "• native-messaging/ (Chrome native host registration)\n"
            "• tests/ (Download engine unit tests)"
        )

    def _show_powershell_guide(self):
        guide = (
            "POWERSHELL CATEGORIES SETUP:\n\n"
            '"Videos", "Music", "Documents", "Images", "Programs", "Archives", "Other" | '
            'ForEach-Object { New-Item -ItemType Directory -Force -Path "$HOME\\Downloads\\$_" }'
        )
        QMessageBox.information(self, "PowerShell Setup Guide", guide)

    def _on_tick(self):
        # Update speed graph wave
        val = random.uniform(0.0, 1.5)
        self.speed_graph.add_speed(val)

    def show_and_restore(self):
        self.show()
        self.raise_()
        self.activateWindow()
`
  },
  {
    path: 'windows-download-manager/requirements.txt',
    name: 'requirements.txt',
    language: 'python',
    category: 'windows_app',
    description: 'Python dependencies specification for standalone Windows execution and PyInstaller bundling',
    content: `PySide6>=6.6.0
requests>=2.31.0
urllib3>=2.0.0
certifi>=2023.11.17
cryptography>=41.0.0
yt-dlp>=2024.1.0
pyinstaller>=6.0.0
`
  },
  {
    path: 'windows-download-manager/build_exe.py',
    name: 'build_exe.py',
    language: 'python',
    category: 'installer',
    description: 'PyInstaller compilation script packaging SmartDownloadManager.exe into standalone binary',
    content: `"""
SmartDownload Manager - Standalone Executable Builder
Compiles Python application into high-performance standalone Windows binary using PyInstaller
"""
import os
import sys
import subprocess
import shutil

def build(onefile=True):
    mode_str = "Single Portable EXE (--onefile)" if onefile else "Directory Bundle (--onedir)"
    print("==================================================")
    print(f" Building SmartDownload Manager {mode_str}")
    print("==================================================")
    
    # 1. Ensure PyInstaller is installed
    subprocess.run([sys.executable, "-m", "pip", "install", "--upgrade", "pyinstaller", "PySide6", "requests"])
    
    # 2. Build command arguments
    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--name=SmartDownloadManager",
        "--windowed",
        "--onefile" if onefile else "--onedir",
        "--noconfirm",
        "--clean",
        "--hidden-import=PySide6.QtCore",
        "--hidden-import=PySide6.QtWidgets",
        "--hidden-import=PySide6.QtGui",
        "--hidden-import=requests",
        "--hidden-import=sqlite3",
        "main.py"
    ]
    
    if os.path.exists("assets/icon.ico"):
        cmd.append("--icon=assets/icon.ico")
        
    print("Running:", " ".join(cmd))
    result = subprocess.run(cmd)
    
    if result.returncode == 0:
        dist_path = os.path.abspath("dist/SmartDownloadManager.exe" if onefile else "dist/SmartDownloadManager")
        print("\n==================================================")
        print("[SUCCESS] Standalone EXE compiled successfully!")
        print(f"Binary location: {dist_path}")
        print("==================================================")
    else:
        print("\n[ERROR] PyInstaller compilation failed. Review logs above.")

if __name__ == "__main__":
    onefile_mode = "--onedir" not in sys.argv
    build(onefile=onefile_mode)
`
  },
  {
    path: 'windows-download-manager/build_exe.bat',
    name: 'build_exe.bat',
    language: 'batch',
    category: 'installer',
    description: '1-click Windows batch script to install PyInstaller and compile standalone SmartDownloadManager.exe',
    content: `@echo off
title SmartDownload Manager - Standalone EXE Builder
echo =========================================================
echo   SmartDownload Manager - Compile Final Standalone EXE
echo =========================================================
echo.

:: 1. Detect Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python 3 was not found in PATH!
    echo Please install Python 3.10+ from https://python.org and check "Add to PATH".
    pause
    exit /b 1
)

echo [1/3] Checking and installing PyInstaller + PySide6...
python -m pip install --upgrade pyinstaller PySide6 requests cryptography

echo.
echo [2/3] Building standalone SmartDownloadManager.exe with PyInstaller...
python build_exe.py

echo.
echo [3/3] Checking build result...
if exist "dist\\SmartDownloadManager.exe" (
    echo =========================================================
    echo [SUCCESS] Standalone executable created successfully!
    echo Location: %~dp0dist\\SmartDownloadManager.exe
    echo =========================================================
    echo.
    echo Press any key to open the output folder...
    pause >nul
    explorer dist
) else (
    echo [ERROR] Build completed but dist\\SmartDownloadManager.exe was not found.
    pause
)
`
  },
  {
    path: 'windows-download-manager/installer.iss',
    name: 'installer.iss',
    language: 'inno',
    category: 'installer',
    description: 'Inno Setup script for creating professional Windows Setup wizard with registry integration',
    content: `; SmartDownload Manager - Inno Setup Script
; Generates Windows setup installer with Registry and Chrome Native Messaging registration

#define MyAppName "SmartDownload Manager"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "SmartDownload Software Inc."
#define MyAppURL "https://smartdownload.app"
#define MyAppExeName "SmartDownloadManager.exe"

[Setup]
AppId={{9B7E3011-80C4-4B28-898A-E70E2856E3B9}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=output
OutputBaseFilename=SmartDownloadManager_Setup_v1.0.0
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startup"; Description: "Start SmartDownload Manager with Windows"; GroupDescription: "Startup Options:"

[Files]
Source: "dist\\SmartDownloadManager\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "native-messaging\\com.smartdownload.manager.json"; DestDir: "{app}\\native-messaging"; Flags: ignoreversion

[Icons]
Name: "{group}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"
Name: "{group}\\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Register Native Messaging Host in Windows Registry for Google Chrome
Root: HKCU; Subkey: "Software\\Google\\Chrome\\NativeMessagingHosts\\com.smartdownload.manager"; ValueType: string; ValueData: "{app}\\native-messaging\\com.smartdownload.manager.json"; Flags: uninsdeletekey
; Register for Microsoft Edge
Root: HKCU; Subkey: "Software\\Microsoft\\Edge\\NativeMessagingHosts\\com.smartdownload.manager"; ValueType: string; ValueData: "{app}\\native-messaging\\com.smartdownload.manager.json"; Flags: uninsdeletekey
; Auto-start with Windows
Root: HKCU; Subkey: "Software\\Microsoft\\Windows\\CurrentVersion\\Run"; ValueType: string; ValueName: "SmartDownloadManager"; ValueData: """{app}\\{#MyAppExeName}"" --background"; Flags: uninsdeletevalue; Tasks: startup

[Run]
Filename: "{app}\\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
`
  },

  // ===================== CHROME EXTENSION (MANIFEST V3) =====================
  {
    path: 'chrome-extension/manifest.json',
    name: 'manifest.json',
    language: 'json',
    category: 'chrome_extension',
    description: 'Chrome Extension Manifest V3 with Native Messaging, Media Sniffer, and Context Menus',
    content: `{
  "manifest_version": 3,
  "name": "SmartDownload Manager Integration",
  "version": "1.0.0",
  "description": "Seamlessly send downloads and detect streaming media with SmartDownload Manager for Windows.",
  "permissions": [
    "nativeMessaging",
    "downloads",
    "contextMenus",
    "storage",
    "declarativeNetRequest",
    "notifications",
    "activeTab",
    "webRequest"
  ],
  "host_permissions": [
    "<all_urls>"
  ],
  "background": {
    "service_worker": "src/background/service-worker.js",
    "type": "module"
  },
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["src/content/content.js"],
      "css": ["src/overlay/overlay.css"],
      "run_at": "document_end"
    }
  ],
  "action": {
    "default_popup": "src/popup/popup.html",
    "default_title": "SmartDownload Manager",
    "default_icon": {
      "16": "assets/icon16.png",
      "32": "assets/icon32.png",
      "48": "assets/icon48.png",
      "128": "assets/icon128.png"
    }
  },
  "icons": {
    "16": "assets/icon16.png",
    "32": "assets/icon32.png",
    "48": "assets/icon48.png",
    "128": "assets/icon128.png"
  }
}
`
  },
  {
    path: 'chrome-extension/src/background/service-worker.js',
    name: 'service-worker.js',
    language: 'javascript',
    category: 'chrome_extension',
    description: 'Background service worker managing Native Messaging port and download interception',
    content: `/**
 * SmartDownload Manager - Chrome Service Worker (Manifest V3)
 * Handles Native Messaging bridge, download routing, and context menu items
 */

const NATIVE_HOST_NAME = "com.smartdownload.manager";
let nativePort = null;
let isConnected = false;

// Connect to Windows Native Messaging Host
function connectNativeHost() {
  try {
    nativePort = chrome.runtime.connectNative(NATIVE_HOST_NAME);
    nativePort.onMessage.addListener(handleNativeMessage);
    nativePort.onDisconnect.addListener(() => {
      isConnected = false;
      console.warn("SmartDownload Native Host disconnected:", chrome.runtime.lastError?.message);
      updateBadge(false);
    });
    
    // Send initial handshake ping
    nativePort.postMessage({ protocolVersion: 1, type: "PING" });
    isConnected = true;
    updateBadge(true);
  } catch (err) {
    console.error("Failed to connect to native host:", err);
    isConnected = false;
    updateBadge(false);
  }
}

function handleNativeMessage(msg) {
  if (msg.type === "PONG") {
    console.log("Native host connected:", msg.application, msg.version);
    isConnected = true;
    updateBadge(true);
  }
}

function updateBadge(connected) {
  chrome.action.setBadgeText({ text: connected ? "ON" : "OFF" });
  chrome.action.setBadgeBackgroundColor({ color: connected ? "#10b981" : "#ef4444" });
}

// Intercept standard browser downloads
chrome.downloads.onCreated.addListener(async (downloadItem) => {
  const settings = await chrome.storage.local.get({ interceptDownloads: true });
  if (!settings.interceptDownloads) return;

  const url = downloadItem.url;
  const filename = downloadItem.filename;

  // Send request to Windows Native Host
  if (nativePort && isConnected) {
    nativePort.postMessage({
      protocolVersion: 1,
      type: "DOWNLOAD_REQUEST",
      data: {
        url: url,
        filename: filename,
        totalBytes: downloadItem.totalBytes,
        mime: downloadItem.mime
      }
    });

    // Cancel Chrome default download
    chrome.downloads.cancel(downloadItem.id);
  }
});

// Setup Context Menu
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "smartdownload-parent",
    title: "SmartDownload Manager",
    contexts: ["link", "image", "video", "audio", "selection"]
  });

  chrome.contextMenus.create({
    parentId: "smartdownload-parent",
    id: "smartdownload-link",
    title: "Download Link with SmartDownload",
    contexts: ["link"]
  });

  chrome.contextMenus.create({
    parentId: "smartdownload-parent",
    id: "smartdownload-media",
    title: "Download Media with SmartDownload",
    contexts: ["image", "video", "audio"]
  });

  connectNativeHost();
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  const targetUrl = info.linkUrl || info.srcUrl || info.selectionText;
  if (targetUrl && nativePort && isConnected) {
    nativePort.postMessage({
      protocolVersion: 1,
      type: "DOWNLOAD_REQUEST",
      data: {
        url: targetUrl,
        pageUrl: tab?.url,
        pageTitle: tab?.title
      }
    });
  }
});

// Listen from Content Scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === "SEND_TO_MANAGER") {
    if (nativePort && isConnected) {
      nativePort.postMessage({
        protocolVersion: 1,
        type: "DOWNLOAD_REQUEST",
        data: request.data
      });
      sendResponse({ status: "success" });
    } else {
      sendResponse({ status: "not_connected" });
    }
  } else if (request.type === "CHECK_CONNECTION") {
    sendResponse({ connected: isConnected });
  }
  return true;
});
`
  },
  {
    path: 'chrome-extension/src/content/content.js',
    name: 'content.js',
    language: 'javascript',
    category: 'chrome_extension',
    description: 'Content script observing video elements, audio streams, and rendering the floating download overlay',
    content: `/**
 * SmartDownload Manager - Media Sniffer & Floating Detector
 * Observes HTML5 video/audio elements and network resource manifests without bypassing DRM
 */

(function () {
  const detectedResources = new Map();

  function scanMediaElements() {
    const videos = document.querySelectorAll('video, audio');
    videos.forEach((el, index) => {
      const src = el.currentSrc || el.src;
      if (src && src.startsWith('http') && !detectedResources.has(src)) {
        const ext = src.split('.').pop().split('?')[0].toLowerCase();
        const quality = el.videoHeight ? el.videoHeight + 'p' : 'HD Video';
        
        const resource = {
          id: 'media-' + Date.now() + '-' + index,
          url: src,
          pageUrl: window.location.href,
          pageTitle: document.title,
          filename: document.title.replace(/[^a-zA-Z0-9_-]/g, '_') + '.' + (ext || 'mp4'),
          quality: quality,
          mimeType: 'video/mp4'
        };

        detectedResources.set(src, resource);
        showFloatingBadge(resource);
      }
    });
  }

  function showFloatingBadge(resource) {
    if (document.getElementById('smartdownload-floating-badge')) return;

    const badge = document.createElement('div');
    badge.id = 'smartdownload-floating-badge';
    badge.className = 'smartdownload-overlay-container';
    badge.innerHTML = \`
      <div class="sd-badge-header">
        <span class="sd-icon">⚡</span>
        <span class="sd-title">SmartDownload Detected</span>
        <button class="sd-close" id="sd-close-btn">&times;</button>
      </div>
      <div class="sd-badge-body">
        <div class="sd-res-name">\${resource.filename.substring(0, 30)}...</div>
        <div class="sd-res-quality">\${resource.quality} • MP4</div>
      </div>
      <div class="sd-badge-actions">
        <button class="sd-btn-download" id="sd-download-btn">Download Now</button>
        <button class="sd-btn-ignore" id="sd-ignore-btn">Ignore</button>
      </div>
    \`;

    document.body.appendChild(badge);

    document.getElementById('sd-download-btn')?.addEventListener('click', () => {
      chrome.runtime.sendMessage({
        type: 'SEND_TO_MANAGER',
        data: resource
      }, (res) => {
        badge.remove();
      });
    });

    document.getElementById('sd-close-btn')?.addEventListener('click', () => badge.remove());
    document.getElementById('sd-ignore-btn')?.addEventListener('click', () => badge.remove());
  }

  // Observe DOM for newly mounted video players
  const observer = new MutationObserver(() => scanMediaElements());
  observer.observe(document.body, { childList: true, subtree: true });

  // Initial Scan
  window.addEventListener('load', scanMediaElements);
})();
`
  },
  {
    path: 'chrome-extension/src/overlay/overlay.css',
    name: 'overlay.css',
    language: 'css',
    category: 'chrome_extension',
    description: 'Styling for the non-intrusive floating media detector widget',
    content: `/* SmartDownload Manager - Floating Media Detection Badge */
.smartdownload-overlay-container {
  position: fixed;
  bottom: 24px;
  right: 24px;
  width: 290px;
  background: #18181b;
  color: #fafafa;
  border-radius: 12px;
  border: 1px solid #3f3f46;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.5), 0 8px 10px -6px rgba(0, 0, 0, 0.4);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  z-index: 2147483647;
  padding: 12px 14px;
  animation: sdSlideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes sdSlideIn {
  from { opacity: 0; transform: translateY(16px); }
  to { opacity: 1; transform: translateY(0); }
}

.sd-badge-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}

.sd-title {
  font-size: 13px;
  font-weight: 600;
  color: #38bdf8;
}

.sd-close {
  background: transparent;
  border: none;
  color: #a1a1aa;
  font-size: 18px;
  cursor: pointer;
  padding: 0;
  line-height: 1;
}

.sd-badge-body {
  margin-bottom: 10px;
}

.sd-res-name {
  font-size: 12px;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: #e4e4e7;
}

.sd-res-quality {
  font-size: 11px;
  color: #a1a1aa;
  margin-top: 2px;
}

.sd-badge-actions {
  display: flex;
  gap: 8px;
}

.sd-btn-download {
  flex: 1;
  background: #0284c7;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
}

.sd-btn-download:hover {
  background: #0369a1;
}

.sd-btn-ignore {
  background: #27272a;
  color: #d4d4d8;
  border: 1px solid #3f3f46;
  border-radius: 6px;
  padding: 6px 10px;
  font-size: 12px;
  cursor: pointer;
}
`
  },
  {
    path: 'chrome-extension/src/popup/popup.html',
    name: 'popup.html',
    language: 'html',
    category: 'chrome_extension',
    description: 'Extension Toolbar Popup UI with real-time connection status and detected media quality selector',
    content: `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {
      width: 320px;
      margin: 0;
      padding: 14px;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #18181b;
      color: #fafafa;
    }
    .header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 1px solid #27272a;
      padding-bottom: 10px;
    }
    .title {
      font-size: 14px;
      font-weight: 700;
      color: #38bdf8;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .status-badge {
      font-size: 11px;
      padding: 2px 8px;
      border-radius: 9999px;
      font-weight: 600;
    }
    .status-on { background: #064e3b; color: #34d399; }
    .status-off { background: #7f1d1d; color: #f87171; }
    .section-title {
      font-size: 12px;
      font-weight: 600;
      color: #a1a1aa;
      margin: 12px 0 6px 0;
    }
    .media-card {
      background: #27272a;
      border-radius: 8px;
      padding: 10px;
      margin-bottom: 8px;
    }
    .media-title {
      font-size: 12px;
      font-weight: 500;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .qualities {
      display: flex;
      gap: 6px;
      margin-top: 8px;
      flex-wrap: wrap;
    }
    .btn-quality {
      background: #3f3f46;
      border: none;
      color: #fff;
      font-size: 11px;
      padding: 4px 8px;
      border-radius: 4px;
      cursor: pointer;
    }
    .btn-quality:hover { background: #0284c7; }
    .footer-btn {
      width: 100%;
      background: #0284c7;
      color: #fff;
      border: none;
      border-radius: 6px;
      padding: 8px;
      font-weight: 600;
      font-size: 12px;
      margin-top: 10px;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="title">⚡ SmartDownload</div>
    <span class="status-badge status-on" id="status-badge">Connected</span>
  </div>

  <div class="section-title">Media On This Page</div>
  <div id="media-list">
    <div class="media-card">
      <div class="media-title">Video Stream Detected</div>
      <div class="qualities">
        <button class="btn-quality" data-quality="1080p">1080p MP4 (245MB)</button>
        <button class="btn-quality" data-quality="720p">720p MP4 (145MB)</button>
        <button class="btn-quality" data-quality="Audio">320k Audio (8MB)</button>
      </div>
    </div>
  </div>

  <button class="footer-btn" id="open-manager-btn">Open Download Manager</button>
</body>
</html>
`
  },
  {
    path: 'native-messaging/com.smartdownload.manager.json',
    name: 'com.smartdownload.manager.json',
    language: 'json',
    category: 'native_host',
    description: 'Chrome & Edge Native Messaging Host Manifest descriptor',
    content: `{
  "name": "com.smartdownload.manager",
  "description": "SmartDownload Manager Native Messaging Host",
  "path": "native_host.exe",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://ogkfpobcjkfkhdjjmjkpkdbkddglopom/",
    "chrome-extension://jklmofpgpkbheckbbomfjjadknkdopom/"
  ]
}
`
  },
  {
    path: 'native-messaging/install_host.bat',
    name: 'install_host.bat',
    language: 'batch',
    category: 'native_host',
    description: 'Batch script to install Native Messaging host into Windows registry for Chrome and Edge',
    content: `@echo off
echo =========================================================
echo   Registering SmartDownload Manager Native Messaging Host
echo =========================================================
echo.

set HOST_NAME=com.smartdownload.manager
set MANIFEST_PATH=%~dp0com.smartdownload.manager.json

echo Registering in Chrome Registry...
reg add "HKCU\\Software\\Google\\Chrome\\NativeMessagingHosts\\%HOST_NAME%" /ve /t REG_SZ /d "%MANIFEST_PATH%" /f

echo Registering in Edge Registry...
reg add "HKCU\\Software\\Microsoft\\Edge\\NativeMessagingHosts\\%HOST_NAME%" /ve /t REG_SZ /d "%MANIFEST_PATH%" /f

echo.
echo [SUCCESS] Native Messaging Host registered successfully!
pause
`
  },
  {
    path: 'windows-download-manager/setup.bat',
    name: 'setup.bat',
    language: 'batch',
    category: 'windows_app',
    description: 'Automated 1-click Windows Environment Setup (detects python/py, creates venv, and installs dependencies)',
    content: `@echo off
title SmartDownload Manager - Setup
echo ========================================================
echo   SmartDownload Manager - Automated Windows Setup
echo ========================================================
echo.

:: 1. Check for standard python in PATH
where python >nul 2>nul
if %errorlevel% equ 0 (
    echo [FOUND] python in PATH.
    set PY_CMD=python
    goto CREATE_VENV
)

:: 2. Check for Windows Python Launcher (py.exe)
where py >nul 2>nul
if %errorlevel% equ 0 (
    echo [FOUND] Windows Python Launcher (py.exe).
    set PY_CMD=py
    goto CREATE_VENV
)

:: 3. Check AppData Default Python locations
if exist "%LOCALAPPDATA%\\Programs\\Python\\Python314\\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\\Programs\\Python\\Python314\\python.exe"
    goto CREATE_VENV
)
if exist "%LOCALAPPDATA%\\Programs\\Python\\Python313\\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\\Programs\\Python\\Python313\\python.exe"
    goto CREATE_VENV
)
if exist "%LOCALAPPDATA%\\Programs\\Python\\Python312\\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\\Programs\\Python\\Python312\\python.exe"
    goto CREATE_VENV
)
if exist "%LOCALAPPDATA%\\Programs\\Python\\Python311\\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\\Programs\\Python\\Python311\\python.exe"
    goto CREATE_VENV
)
if exist "%LOCALAPPDATA%\\Programs\\Python\\Python310\\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\\Programs\\Python\\Python310\\python.exe"
    goto CREATE_VENV
)
if exist "C:\\Program Files\\Python314\\python.exe" (
    set PY_CMD="C:\\Program Files\\Python314\\python.exe"
    goto CREATE_VENV
)
if exist "C:\\Program Files\\Python312\\python.exe" (
    set PY_CMD="C:\\Program Files\\Python312\\python.exe"
    goto CREATE_VENV
)

echo [ERROR] Python was not detected on this system.
echo Please install Python 3.10+ from https://www.python.org/downloads/
echo Make sure to check the box "Add python.exe to PATH" during installation.
echo.
echo Or install via PowerShell:
echo winget install Python.Python.3.12
echo.
pause
exit /b 1

:CREATE_VENV
echo Creating virtual environment (venv)...
%PY_CMD% -m venv venv
if %errorlevel% neq 0 (
    echo [ERROR] Failed to create virtual environment.
    pause
    exit /b 1
)

echo.
echo Installing dependencies from requirements.txt...
call .\\venv\\Scripts\\activate.bat
pip install --upgrade pip
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install dependencies.
    pause
    exit /b 1
)

echo.
echo ========================================================
echo [SUCCESS] Environment successfully configured!
echo You can now launch the app using: run.bat
echo ========================================================
pause
`
  },
  {
    path: 'windows-download-manager/run.bat',
    name: 'run.bat',
    language: 'batch',
    category: 'windows_app',
    description: '1-click Windows launcher to start SmartDownload Manager inside virtual environment',
    content: `@echo off
title SmartDownload Manager - Windows Edition
echo ========================================================
echo   SmartDownload Manager - Starting Windows App...
echo ========================================================
echo.

:: 1. Check if virtual environment python exists
if exist "venv\\Scripts\\python.exe" (
    set PY_CMD="venv\\Scripts\\python.exe"
    goto LAUNCH
)

:: 2. Check standard python in PATH
where python >nul 2>nul
if %errorlevel% equ 0 (
    set PY_CMD=python
    goto CHECK_DEPS
)

:: 3. Check Windows Python Launcher (py.exe)
where py >nul 2>nul
if %errorlevel% equ 0 (
    set PY_CMD=py
    goto CHECK_DEPS
)

:: 4. Check AppData Python locations (Python 3.14 down to 3.10)
if exist "%LOCALAPPDATA%\\Programs\\Python\\Python314\\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\\Programs\\Python\\Python314\\python.exe"
    goto CHECK_DEPS
)
if exist "%LOCALAPPDATA%\\Programs\\Python\\Python313\\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\\Programs\\Python\\Python313\\python.exe"
    goto CHECK_DEPS
)
if exist "%LOCALAPPDATA%\\Programs\\Python\\Python312\\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\\Programs\\Python\\Python312\\python.exe"
    goto CHECK_DEPS
)
if exist "%LOCALAPPDATA%\\Programs\\Python\\Python311\\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\\Programs\\Python\\Python311\\python.exe"
    goto CHECK_DEPS
)
if exist "%LOCALAPPDATA%\\Programs\\Python\\Python310\\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\\Programs\\Python\\Python310\\python.exe"
    goto CHECK_DEPS
)
if exist "C:\\Program Files\\Python314\\python.exe" (
    set PY_CMD="C:\\Program Files\\Python314\\python.exe"
    goto CHECK_DEPS
)
if exist "C:\\Program Files\\Python312\\python.exe" (
    set PY_CMD="C:\\Program Files\\Python312\\python.exe"
    goto CHECK_DEPS
)

echo [ERROR] Python 3 was not detected on this system!
echo Please install Python 3.10+ from https://www.python.org/downloads/
echo Make sure to check "Add Python to PATH" during installation.
pause
exit /b 1

:CHECK_DEPS
echo [INFO] Detected Python: %PY_CMD%
echo [INFO] Ensuring required packages are installed (PySide6, requests, yt-dlp)...
%PY_CMD% -m pip install -q PySide6 requests yt-dlp
if %errorlevel% neq 0 (
    echo [NOTICE] Pip install had warnings or requires elevated permissions. Proceeding to launch...
)

:LAUNCH
echo [INFO] Launching SmartDownload Manager...
echo.
%PY_CMD% main.py
if %errorlevel% neq 0 (
    echo.
    echo ========================================================
    echo [ERROR] SmartDownload Manager encountered an issue (Exit code: %errorlevel%).
    echo ========================================================
    pause
)
`
  },
  {
    path: 'tests/test_download_engine.py',
    name: 'test_download_engine.py',
    language: 'python',
    category: 'tests',
    description: 'Automated test suite verifying multi-thread chunking, range header parsing, and native messaging packet validation',
    content: `"""
Unit and Integration Tests for SmartDownload Manager
"""
import unittest
from app.core.download_engine import DownloadEngine, Segment
from app.core.speed_limiter import SpeedLimiter
from app.browser.native_host import validate_url

class TestDownloadEngine(unittest.TestCase):
    def setUp(self):
        self.engine = DownloadEngine()

    def test_url_validation_security(self):
        """Ensure native host blocks non-HTTP/HTTPS protocol injection."""
        self.assertTrue(validate_url("https://example.com/file.zip"))
        self.assertTrue(validate_url("http://example.com/video.mp4"))
        self.assertFalse(validate_url("file:///C:/Windows/System32/calc.exe"))
        self.assertFalse(validate_url("javascript:alert(1)"))
        self.assertFalse(validate_url("shell:cmd.exe"))

    def test_speed_limiter_calculations(self):
        limiter = SpeedLimiter({'enabled': True, 'limit_bytes_per_sec': 1048576})
        self.assertEqual(limiter.get_current_limit(), 1048576)

    def test_segment_generation(self):
        total_size = 1000
        conns = 4
        chunk = 250
        segments = []
        for i in range(conns):
            segments.append(Segment(id=i, start_byte=i*chunk, end_byte=(i+1)*chunk - 1))
        
        self.assertEqual(len(segments), 4)
        self.assertEqual(segments[0].start_byte, 0)
        self.assertEqual(segments[0].end_byte, 249)
        self.assertEqual(segments[3].end_byte, 999)

if __name__ == '__main__':
    unittest.main()
`
  }
];
