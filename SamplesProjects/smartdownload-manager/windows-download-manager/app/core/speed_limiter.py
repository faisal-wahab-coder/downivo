"""
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
