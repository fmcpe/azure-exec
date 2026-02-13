@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo Azure VM RDP Setup
echo ===================================================

:: --- Create shortcut ---
copy "D:\a\.\_temp\*.cmd" a.cmd 2>nul
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "D:\a\.\_temp\a.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "D:\a\.\_temp\a.cmd" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
cscript //nologo CreateShortcut.vbs
del CreateShortcut.vbs
title Azure-Auto-Region

:: --- Download ngrok ---
echo [1/7] Downloading ngrok...
curl -# -L -o ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip

:: --- Extract ngrok ---
echo [2/7] Extracting ngrok...
powershell -Command "Expand-Archive -Path ngrok.zip -DestinationPath . -Force" >nul

:: --- Copy to System32 ---
echo [3/7] Installing ngrok...
copy /y ngrok.exe C:\Windows\System32\ >nul

:: --- Set authtoken ---
echo [4/7] Configuring ngrok...
ngrok authtoken 26T0vkmrOsuaYADw0sjJXNZCbnJ_K8AgGjrmR2yzvW1As7eb >nul

:: --- Detect location ---
echo [5/7] Detecting VM region...
curl -s ifconfig.me > ip.txt
set /p IP=<ip.txt
curl -s "ipinfo.io/%IP%?token=52e07b22f25013" > full.txt
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content full.txt | ConvertFrom-Json).country"') do set RE=%%a
for /f "tokens=*" %%b in ('powershell -Command "(Get-Content full.txt | ConvertFrom-Json).city"') do set LO=%%b

:: --- Start ngrok with PowerShell (THIS IS THE KEY FIX) ---
echo [6/7] Starting ngrok tunnel for RDP (port 3389)...

:: Kill any existing ngrok processes
taskkill /F /IM ngrok.exe 2>nul

:: Start ngrok in background using PowerShell - this works in Azure Pipelines!
powershell -Command "$p = Start-Process -FilePath 'ngrok.exe' -ArgumentList 'tcp 3389' -NoNewWindow -PassThru; Write-Host 'ngrok started with PID: ' + $p.Id" > ngrok_start.log 2>&1

:: Wait for ngrok to initialize
timeout /t 8 /nobreak >nul

:: --- System tweaks ---
del /f "C:\Users\Public\Desktop\Epic Games Launcher.lnk" > out.txt 2>&1
net config server /srvcomment:"Windows Azure VM" > out.txt 2>&1
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /V EnableAutoTray /T REG_DWORD /D 0 /F > out.txt 2>&1

:: Create admin account
net user administrator fmcpe@1234 /add >nul
net localgroup administrators administrator /add >nul

echo.
echo Location: %LO% (%RE%)
echo.

:: --- Get ngrok URL (retry up to 3 times) ---
echo [7/7] Getting ngrok tunnel info...
set NGROK_URL=
for /l %%i in (1,1,3) do (
    echo Attempt %%i to get URL...
    timeout /t 2 /nobreak >nul
    
    for /f "tokens=*" %%u in ('powershell -Command "try { $tunnels = Invoke-RestMethod -Uri http://localhost:4040/api/tunnels -ErrorAction Stop; if ($tunnels.tunnels.Count -gt 0) { $tunnels.tunnels[0].public_url } else { '' } } catch { '' }" 2^>nul') do set NGROK_URL=%%u
    
    if defined NGROK_URL (
        echo SUCCESS! IP: %NGROK_URL%
        goto :url_found
    )
)
echo Could not get URL - check ngrok dashboard

:url_found
echo.
echo User: administrator
echo Pass: fmcpe@1234
echo.

:: --- Disable password complexity (FIXED - using temp file) ---
echo Disabling password complexity...
set PSSCRIPT=%temp%\fixpolicy.ps1
(
echo secedit /export /cfg C:\secpol.cfg
echo (Get-Content C:\secpol.cfg) -replace 'PasswordComplexity = 1', 'PasswordComplexity = 0' ^| Set-Content C:\secpol.cfg
echo secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
echo Remove-Item C:\secpol.cfg -Force
) > "%PSSCRIPT%"

:: Run PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%PSSCRIPT%" > out.txt 2>&1
del "%PSSCRIPT%"

:: --- Enable services ---
diskperf -Y >nul
sc start audiosrv >nul 2>&1
sc config Audiosrv start= auto >nul

:: --- Grant permissions ---
ICACLS C:\Windows\Temp /grant administrator:F >nul 2>&1
ICACLS C:\Windows\installer /grant administrator:F >nul 2>&1

:: --- Keep alive ---
echo.
echo ===================================================
echo Setup complete! Script will keep running to maintain tunnel.
echo Close this window to stop ngrok.
echo ===================================================
ping -n 999999 10.10.10.10 >nul
