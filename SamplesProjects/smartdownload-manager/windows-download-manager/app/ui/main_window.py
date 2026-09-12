"""
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
