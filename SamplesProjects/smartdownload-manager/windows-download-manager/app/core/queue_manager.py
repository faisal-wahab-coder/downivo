"""
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
