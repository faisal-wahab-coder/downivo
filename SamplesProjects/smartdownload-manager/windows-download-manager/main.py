"""
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
