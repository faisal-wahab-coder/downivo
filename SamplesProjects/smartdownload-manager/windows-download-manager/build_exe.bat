@echo off
title SmartDownload Manager - Standalone EXE Builder
echo =========================================================
echo   SmartDownload Manager - Compile Final Standalone EXE
echo =========================================================
echo.

:: 1. Detect Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python 3 was not found in PATH!
    echo Please install Python 3.10+ from https://python.org and check "Add to PATH".
    pause
    exit /b 1
)

echo [1/3] Checking and installing PyInstaller + PySide6...
python -m pip install --upgrade pyinstaller PySide6 requests cryptography

echo.
echo [2/3] Building standalone SmartDownloadManager.exe with PyInstaller...
python build_exe.py

echo.
echo [3/3] Checking build result...
if exist "dist\SmartDownloadManager.exe" (
    echo =========================================================
    echo [SUCCESS] Standalone executable created successfully!
    echo Location: %~dp0dist\SmartDownloadManager.exe
    echo =========================================================
    echo.
    echo Press any key to open the output folder...
    pause >nul
    explorer dist
) else (
    echo [ERROR] Build completed but dist\SmartDownloadManager.exe was not found.
    pause
)
