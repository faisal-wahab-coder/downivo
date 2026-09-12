@echo off
title SmartDownload Manager - Windows Edition
echo ========================================================
echo   SmartDownload Manager - Starting Windows App...
echo ========================================================
echo.

:: 1. Check if virtual environment python exists
if exist "venv\Scripts\python.exe" (
    set PY_CMD="venv\Scripts\python.exe"
    goto LAUNCH
)

:: 2. Check standard python in PATH
where python >nul 2>nul
if %errorlevel% equ 0 (
    set PY_CMD=python
    goto CHECK_DEPS
)

:: 3. Check Windows Python Launcher (py.exe)
where py >nul 2>nul
if %errorlevel% equ 0 (
    set PY_CMD=py
    goto CHECK_DEPS
)

:: 4. Check AppData Python locations (Python 3.14 down to 3.10)
if exist "%LOCALAPPDATA%\Programs\Python\Python314\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\Programs\Python\Python314\python.exe"
    goto CHECK_DEPS
)
if exist "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
    goto CHECK_DEPS
)
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    goto CHECK_DEPS
)
if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    goto CHECK_DEPS
)
if exist "%LOCALAPPDATA%\Programs\Python\Python310\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
    goto CHECK_DEPS
)
if exist "C:\Program Files\Python314\python.exe" (
    set PY_CMD="C:\Program Files\Python314\python.exe"
    goto CHECK_DEPS
)
if exist "C:\Program Files\Python312\python.exe" (
    set PY_CMD="C:\Program Files\Python312\python.exe"
    goto CHECK_DEPS
)

echo [ERROR] Python 3 was not detected on this system!
echo Please install Python 3.10+ from https://www.python.org/downloads/
echo Make sure to check "Add Python to PATH" during installation.
pause
exit /b 1

:CHECK_DEPS
echo [INFO] Detected Python: %PY_CMD%
echo [INFO] Ensuring required packages are installed (PySide6, requests, yt-dlp)...
%PY_CMD% -m pip install -q PySide6 requests yt-dlp
if %errorlevel% neq 0 (
    echo [NOTICE] Pip install had warnings or requires elevated permissions. Proceeding to launch...
)

:LAUNCH
echo [INFO] Launching SmartDownload Manager...
echo.
%PY_CMD% main.py
if %errorlevel% neq 0 (
    echo.
    echo ========================================================
    echo [ERROR] SmartDownload Manager encountered an issue (Exit code: %errorlevel%).
    echo ========================================================
    pause
)
