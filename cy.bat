@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "NYX=%SCRIPT_DIR%nyx.exe"

if not exist "%NYX%" (
    echo Error: nyx.exe not found at %NYX%
    exit /b 1
)

if "%~1"=="" (
    echo Usage: cy ^<file.cy^>
    exit /b 1
)

"%NYX%" %*
