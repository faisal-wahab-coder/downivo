"""
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
