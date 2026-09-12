"""
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
        print("
==================================================")
        print("[SUCCESS] Standalone EXE compiled successfully!")
        print(f"Binary location: {dist_path}")
        print("==================================================")
    else:
        print("
[ERROR] PyInstaller compilation failed. Review logs above.")

if __name__ == "__main__":
    onefile_mode = "--onedir" not in sys.argv
    build(onefile=onefile_mode)
