@echo off
title SmartDownload Manager - Setup
echo ========================================================
echo   SmartDownload Manager - Automated Windows Setup
echo ========================================================
echo.

:: 1. Check for standard python in PATH
where python >nul 2>nul
if %errorlevel% equ 0 (
    echo [FOUND] python in PATH.
    set PY_CMD=python
    goto CREATE_VENV
)

:: 2. Check for Windows Python Launcher (py.exe)
where py >nul 2>nul
if %errorlevel% equ 0 (
    echo [FOUND] Windows Python Launcher (py.exe).
    set PY_CMD=py
    goto CREATE_VENV
)

:: 3. Check AppData Default Python locations
if exist "%LOCALAPPDATA%\Programs\Python\Python314\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\Programs\Python\Python314\python.exe"
    goto CREATE_VENV
)
if exist "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
    goto CREATE_VENV
)
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    goto CREATE_VENV
)
if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    goto CREATE_VENV
)
if exist "%LOCALAPPDATA%\Programs\Python\Python310\python.exe" (
    set PY_CMD="%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
    goto CREATE_VENV
)
if exist "C:\Program Files\Python314\python.exe" (
    set PY_CMD="C:\Program Files\Python314\python.exe"
    goto CREATE_VENV
)
if exist "C:\Program Files\Python312\python.exe" (
    set PY_CMD="C:\Program Files\Python312\python.exe"
    goto CREATE_VENV
)

echo [ERROR] Python was not detected on this system.
echo Please install Python 3.10+ from https://www.python.org/downloads/
echo Make sure to check the box "Add python.exe to PATH" during installation.
echo.
echo Or install via PowerShell:
echo winget install Python.Python.3.12
echo.
pause
exit /b 1

:CREATE_VENV
echo Creating virtual environment (venv)...
%PY_CMD% -m venv venv
if %errorlevel% neq 0 (
    echo [ERROR] Failed to create virtual environment.
    pause
    exit /b 1
)

echo.
echo Installing dependencies from requirements.txt...
call .\venv\Scripts\activate.bat
pip install --upgrade pip
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install dependencies.
    pause
    exit /b 1
)

echo.
echo ========================================================
echo [SUCCESS] Environment successfully configured!
echo You can now launch the app using: run.bat
echo ========================================================
pause
