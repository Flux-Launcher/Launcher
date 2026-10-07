@echo off
title Flux Launcher (Dev Mode)
echo ========================================
echo   Uruchamianie Flux Launcher w trybie DEV
echo ========================================
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    set "PATH=C:\Users\fraud\flutter\bin;%PATH%"
)
cd /d "%~dp0example"
flutter run -d windows
if %ERRORLEVEL% neq 0 (
    echo.
    echo Flux Launcher zakonczyl dzialanie z kodem bledu %ERRORLEVEL%.
    pause
)
