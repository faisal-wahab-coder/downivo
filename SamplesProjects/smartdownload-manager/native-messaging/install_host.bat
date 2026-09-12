@echo off
echo =========================================================
echo   Registering SmartDownload Manager Native Messaging Host
echo =========================================================
echo.

set HOST_NAME=com.smartdownload.manager
set MANIFEST_PATH=%~dp0com.smartdownload.manager.json

echo Registering in Chrome Registry...
reg add "HKCU\Software\Google\Chrome\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%MANIFEST_PATH%" /f

echo Registering in Edge Registry...
reg add "HKCU\Software\Microsoft\Edge\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%MANIFEST_PATH%" /f

echo.
echo [SUCCESS] Native Messaging Host registered successfully!
pause
