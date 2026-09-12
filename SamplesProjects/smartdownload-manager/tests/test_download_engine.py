"""
Unit and Integration Tests for SmartDownload Manager
"""
import unittest
import sys
import os

# Add windows-download-manager to sys.path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'windows-download-manager'))

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
