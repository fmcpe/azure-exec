@echo off
setlocal enabledelayedexpansion

:: --- Create shortcut to a.cmd (optional) ---
copy "D:\a\.\_temp\*.cmd" a.cmd 2>nul
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "D:\a\.\_temp\a.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "D:\a\.\_temp\a.cmd" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
cscript //nologo CreateShortcut.vbs
del CreateShortcut.vbs
title Azure-Auto-Region

:: --- Download and install ngrok ---
echo Downloading ngrok...
curl -# -O https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip

echo Extracting ngrok...
powershell -Command "Expand-Archive -Path ngrok-v3-stable-windows-amd64.zip -DestinationPath . -Force" >nul

echo Installing ngrok to System32...
copy /y ngrok.exe C:\Windows\System32\ >nul

:: --- Set ngrok authtoken (your token) ---
echo Configuring ngrok authtoken...
ngrok authtoken 26T0vkmrOsuaYADw0sjJXNZCbnJ_K8AgGjrmR2yzvW1As7eb >nul

:: --- Detect region (for display only) ---
echo Detecting VM region...
curl -s ifconfig.me > ip.txt
set /p IP=<ip.txt
curl -s "ipinfo.io/%IP%?token=52e07b22f25013" > full.txt
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content full.txt | ConvertFrom-Json).country"') do set RE=%%a
for /f "tokens=*" %%b in ('powershell -Command "(Get-Content full.txt | ConvertFrom-Json).city"') do set LO=%%b

:: --- Start ngrok tunnel (region auto-selected) ---
echo Starting ngrok tunnel for RDP (port 3389)...
start /b ngrok tcp 3389

:: --- System tweaks ---
del /f "C:\Users\Public\Desktop\Epic Games Launcher.lnk" > out.txt 2>&1
net config server /srvcomment:"Windows Azure VM" > out.txt 2>&1
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /V EnableAutoTray /T REG_DWORD /D 0 /F > out.txt 2>&1

:: Create local admin account
net user administrator fmcpe@1234 /add >nul
net localgroup administrators administrator /add >nul

echo.
echo To change VM region, create a new organization.
echo Your current VM location: %LO% (%RE%)
echo Region Available: West Europe, Central US, East Asia, Brazil South, Canada Central, Australia East, UK South, South India
echo.
echo All done! Connect to your VM using RDP. If RDP expires, rerun this job.
echo.

:: --- Get ngrok public URL ---
echo Getting ngrok tunnel info...
timeout /t 5 /nobreak >nul
tasklist | find /i "ngrok.exe" >nul
if !errorlevel! equ 0 (
    for /f "tokens=*" %%u in ('powershell -Command "(Invoke-RestMethod -Uri http://localhost:4040/api/tunnels).tunnels[0].public_url" 2^>nul') do set NGROK_URL=%%u
    if defined NGROK_URL (
        echo IP: %NGROK_URL%
    ) else (
        echo Unable to fetch ngrok URL. Check dashboard: https://dashboard.ngrok.com/status/tunnels
    )
) else (
    echo ngrok is not running. Start it manually with: ngrok tcp 3389
)

echo User: administrator
echo Pass: fmcpe@1234
echo.

:: --- Disable password complexity (via temporary PowerShell script) ---
echo Disabling password complexity...
set PSSCRIPT=%temp%\fixpolicy.ps1
(
echo secedit /export /cfg C:\secpol.cfg
echo (gc C:\secpol.cfg) -replace 'PasswordComplexity = 1', 'PasswordComplexity = 0' ^| Out-File C:\secpol.cfg
echo secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
echo Remove-Item C:\secpol.cfg -Force
) > "%PSSCRIPT%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PSSCRIPT%" > out.txt 2>&1
del "%PSSCRIPT%"

:: --- Enable performance counters and audio service ---
diskperf -Y >nul
sc start audiosrv >nul 2>&1
sc config Audiosrv start= auto >nul

:: --- Grant permissions to temp folders ---
ICACLS C:\Windows\Temp /grant administrator:F >nul 2>&1
ICACLS C:\Windows\installer /grant administrator:F >nul 2>&1

:: --- Keep script alive (maintains ngrok tunnel) ---
echo Script will now keep running to maintain the ngrok tunnel.
echo Close this window to stop ngrok.
ping -n 999999 10.10.10.10 >nul
