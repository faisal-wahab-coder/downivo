# SmartDownload Manager (Windows Edition & Web App)

Professional IDM-style Windows download manager with 8-stream socket acceleration, YouTube video extraction, live throughput graphing, and Chrome extension integration.

## 🚀 How to Run the Windows Desktop App

### Method 1: 1-Click Launch (Recommended)
Simply **double-click `RUN_WINDOWS_APP.bat`** in this folder!

It will:
1. Automatically detect your Python installation (including Python 3.14, 3.13, 3.12, etc.).
2. Automatically verify/install the required packages (`PySide6`, `requests`, `yt-dlp`).
3. Launch the full dark-mode Windows Desktop application!

### Method 2: From PowerShell / Command Line
```powershell
cd windows-download-manager
.\run.bat
```
Or directly with your Python interpreter:
```powershell
& "C:\Users\Khaswer lala\AppData\Local\Programs\Python\Python314\python.exe" main.py
```

---

## 🌐 How to Run the Web Dashboard (Optional)
If you want to run the web simulator in your browser:
```powershell
npm install
npm run dev
```
Then visit `http://localhost:3000`.
