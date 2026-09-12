"""
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
                filename = cd.split('filename=')[-1].strip('"\'')
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
