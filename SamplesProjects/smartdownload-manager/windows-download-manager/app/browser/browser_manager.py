"""
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
            key_path = f"Software\\Google\\Chrome\\NativeMessagingHosts\\{HOST_NAME}"
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
            key_path = f"Software\\Microsoft\\Edge\\NativeMessagingHosts\\{HOST_NAME}"
            key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, key_path)
            winreg.SetValueEx(key, "", 0, winreg.REG_SZ, manifest_file)
            winreg.CloseKey(key)
            return True
        except Exception as e:
            print(f"Edge registry error: {e}")
            return False
