"""
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
    r'^(https?|ftp)://[^s/$.?#].[^s]*$',
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
