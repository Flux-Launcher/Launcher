@echo off
title Flux Launcher (Dev Mode)
echo ========================================
echo   Uruchamianie Flux Launcher w trybie DEV
echo ========================================
cd /d "%~dp0"
flutter run -d windows
if %ERRORLEVEL% neq 0 (
    echo.
    echo Flux Launcher zakonczyl dzialanie z kodem bledu %ERRORLEVEL%.
    pause
)
