@echo off
title OpenClaw Installer
color 0A
setlocal EnableDelayedExpansion

echo.
echo  ============================================
echo       OpenClaw - One-Click Installer
echo  ============================================
echo.

:: -----------------------------------------------
:: 1. Check prerequisites
:: -----------------------------------------------
echo  [1/7] Checking prerequisites...
echo.

:: Check Ollama
where ollama >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo    ERROR: Ollama is not installed.
    echo    Install it from https://ollama.com and re-run this script.
    echo.
    pause
    exit /b 1
)
echo    [OK] Ollama found.

:: Check Node.js
where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo    [..] Node.js not found. Installing via winget...
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements -h
    if !ERRORLEVEL! neq 0 (
        echo    ERROR: Failed to install Node.js. Install manually from https://nodejs.org
        pause
        exit /b 1
    )
    :: Refresh PATH so npm is available in this session
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
    set "PATH=!SYS_PATH!;!USR_PATH!;%APPDATA%\npm"
    echo    [OK] Node.js installed.
    echo    NOTE: If npm is not found below, close and re-run this script.
) else (
    echo    [OK] Node.js found.
)

:: Check cloudflared
where cloudflared >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo    [..] cloudflared not found. Installing via winget...
    winget install Cloudflare.cloudflared --accept-source-agreements --accept-package-agreements -h
    if !ERRORLEVEL! neq 0 (
        echo    ERROR: Failed to install cloudflared.
        echo    Install manually from https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/
        pause
        exit /b 1
    )
    echo    [OK] cloudflared installed.
) else (
    echo    [OK] cloudflared found.
)
echo.

:: -----------------------------------------------
:: 2. Install OpenClaw
:: -----------------------------------------------
echo  [2/7] Installing OpenClaw...
call npm install -g openclaw
if %ERRORLEVEL% neq 0 (
    echo    ERROR: Failed to install OpenClaw via npm.
    pause
    exit /b 1
)
echo    [OK] OpenClaw installed.
echo.

:: -----------------------------------------------
:: 3. Pull default Ollama model
:: -----------------------------------------------
echo  [3/7] Pulling Ollama model (llama3.2)...
ollama pull llama3.2
if %ERRORLEVEL% neq 0 (
    echo    WARNING: Failed to pull model. You can pull it manually later with: ollama pull llama3.2
) else (
    echo    [OK] Model ready.
)
echo.

:: Set script directory once, outside any code block
set "SCRIPT_DIR=%~dp0"

:: -----------------------------------------------
:: 4. Create config directory
:: -----------------------------------------------
echo  [4/7] Setting up config...
set "OC_DIR=%USERPROFILE%\.openclaw"
if not exist "%OC_DIR%" mkdir "%OC_DIR%"

:: Only create config if one doesn't already exist
if exist "%OC_DIR%\openclaw.json" (
    echo    Config already exists, skipping.
) else (
    powershell -ExecutionPolicy Bypass -File "!SCRIPT_DIR!create-config.ps1"
    echo    [OK] Config template created.
    echo    Edit %OC_DIR%\openclaw.json to add your API keys.
)
echo.

:: -----------------------------------------------
:: 5. Generate icon
:: -----------------------------------------------
echo  [5/7] Generating app icon...
set "APP_DIR=%USERPROFILE%\Desktop\OpenClaw"
if not exist "%APP_DIR%" mkdir "%APP_DIR%"
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%create-icon.ps1" -OutputPath "%APP_DIR%\openclaw.ico"
echo    [OK] Icon created.
echo.

:: -----------------------------------------------
:: 6. Copy launcher
:: -----------------------------------------------
echo  [6/7] Installing launcher...
copy /Y "%SCRIPT_DIR%launch-openclaw.bat" "%APP_DIR%\launch-openclaw.bat" >nul
echo    [OK] Launcher copied.
echo.

:: -----------------------------------------------
:: 7. Create desktop shortcut
:: -----------------------------------------------
echo  [7/7] Creating desktop shortcut...
powershell -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell; ^
   $sc = $ws.CreateShortcut('%USERPROFILE%\Desktop\OpenClaw.lnk'); ^
   $sc.TargetPath = '%APP_DIR%\launch-openclaw.bat'; ^
   $sc.WorkingDirectory = '%APP_DIR%'; ^
   $sc.IconLocation = '%APP_DIR%\openclaw.ico, 0'; ^
   $sc.Description = 'Launch all OpenClaw services'; ^
   $sc.WindowStyle = 1; ^
   $sc.Save()"
echo    [OK] Desktop shortcut created.
echo.

echo  ============================================
echo       Installation complete!
echo  ============================================
echo.
echo  Next steps:
echo    1. Edit %OC_DIR%\openclaw.json
echo       and fill in your API keys (Twilio,
echo       ElevenLabs, OpenAI for STT).
echo.
echo    2. Double-click the "OpenClaw" shortcut
echo       on your desktop to start all services.
echo.
echo  ============================================
echo.
pause
