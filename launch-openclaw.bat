@echo off
title OpenClaw Launcher
color 0A
setlocal EnableDelayedExpansion

echo ============================================
echo         OpenClaw - Starting Services
echo ============================================
echo.

:: Clean up stale session lock files
echo [1/6] Cleaning stale lock files...
del /q "%USERPROFILE%\.openclaw\agents\main\sessions\*.lock" 2>nul
echo       Done.
echo.

:: Clean old tunnel log
del /q "%TEMP%\cloudflared.log" 2>nul

:: Check if Ollama is already running
echo [2/6] Starting Ollama...
tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | find /I "ollama.exe" >nul
if %ERRORLEVEL% equ 0 (
    echo       Ollama is already running.
) else (
    start "Ollama Server" cmd /k "title Ollama Server && color 0B && echo Starting Ollama... && ollama serve"
    timeout /t 3 /nobreak >nul
    echo       Ollama started.
)
echo.

:: Start Cloudflare Tunnel with output logged to temp file
echo [3/6] Starting Cloudflare Tunnel...
start "Cloudflare Tunnel" powershell -NoExit -Command "Write-Host 'Cloudflare Tunnel' -ForegroundColor Magenta; Write-Host ''; cloudflared tunnel --url http://localhost:3334 2>&1 | Tee-Object -FilePath $env:TEMP\cloudflared.log -Append"
echo       Waiting for tunnel URL...

:: Poll the log file for the tunnel URL (up to 30 seconds)
set TUNNEL_URL=
set /a ATTEMPTS=0
:poll_tunnel
if %ATTEMPTS% geq 15 goto tunnel_timeout
timeout /t 2 /nobreak >nul
set /a ATTEMPTS+=1
findstr /C:"trycloudflare.com" "%TEMP%\cloudflared.log" >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo       Waiting... (%ATTEMPTS%/15^)
    goto poll_tunnel
)

:: Extract the URL and update config
echo.
echo [4/6] Tunnel URL found! Updating config...
powershell -Command ^
  "$log = Get-Content $env:TEMP\cloudflared.log -Raw; ^
   $m = [regex]::Match($log, 'https://[a-zA-Z0-9\-]+\.trycloudflare\.com'); ^
   if ($m.Success) { ^
     $url = $m.Value + '/voice/webhook'; ^
     Write-Host ('       New URL: ' + $url); ^
     $cfgPath = Join-Path $env:USERPROFILE '.openclaw\openclaw.json'; ^
     $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json; ^
     $cfg.plugins.entries.'voice-call'.config.publicUrl = $url; ^
     $cfg | ConvertTo-Json -Depth 10 | Set-Content $cfgPath -Encoding UTF8; ^
     Write-Host '       Config updated successfully.'; ^
   } else { ^
     Write-Host '       ERROR: Could not parse tunnel URL from log.' -ForegroundColor Red; ^
   }"
goto start_gateway

:tunnel_timeout
echo.
echo       WARNING: Timed out waiting for tunnel URL.
echo       You may need to manually update publicUrl in openclaw.json.
echo.

:start_gateway
echo.
:: Start OpenClaw Gateway
echo [5/6] Starting OpenClaw Gateway...
start "OpenClaw Gateway" cmd /k "title OpenClaw Gateway && color 0E && echo Starting OpenClaw Gateway on port 18789... && echo Voice webhook on port 3334 && echo. && openclaw gateway run"
echo       OpenClaw Gateway starting...
echo.

:: Wait for gateway to be ready
echo       Waiting for gateway to come online...
set /a GW_ATTEMPTS=0
:poll_gateway
if %GW_ATTEMPTS% geq 20 goto gw_timeout
timeout /t 2 /nobreak >nul
set /a GW_ATTEMPTS+=1
netstat -ano | findstr "18789" | findstr "LISTENING" >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo       Waiting... (%GW_ATTEMPTS%/20^)
    goto poll_gateway
)

echo       Gateway is online!
echo.

:: Read token from config and open dashboard
echo [6/6] Opening dashboard in browser...
powershell -Command ^
  "$cfgPath = Join-Path $env:USERPROFILE '.openclaw\openclaw.json'; ^
   $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json; ^
   $token = $cfg.gateway.auth.token; ^
   Start-Process ('http://127.0.0.1:18789/#token=' + $token)"
echo       Dashboard opened!
goto all_done

:gw_timeout
echo.
echo       WARNING: Gateway did not start within 40 seconds.
echo       Check the OpenClaw Gateway terminal for errors.
echo.

:all_done
echo.
echo ============================================
echo       All services launched!
echo ============================================
echo.
echo   Ollama:      http://localhost:11434
echo   Gateway:     http://localhost:18789
echo   Webhook:     http://localhost:3334
echo.
echo   Tunnel URL was auto-detected and config
echo   was updated. No manual steps needed.
echo.
echo ============================================
echo.
echo Press any key to close this launcher window...
echo (Service windows will remain open)
pause >nul
