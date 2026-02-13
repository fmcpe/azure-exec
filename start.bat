@echo off
cp "D:\a\.\_temp\*.cmd" a.cmd
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "D:\a\.\_temp\a.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "D:\a\.\_temp\a.cmd" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
cscript CreateShortcut.vbs
del CreateShortcut.vbs
title Azure-Auto-Region

echo Download all files...
curl --silent -O https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip

unzip ngrok-v3-stable-windows-amd64.zip

echo Copy NGROK to System32...
copy ngrok.exe C:\Windows\System32 >nul

echo CONNECT NGROK AUTH TOKEN...
start NGROK.bat >nul


echo Check Region for NGROK...
curl -s ifconfig.me >ip.txt
set /p IP=<ip.txt
curl -s ipinfo.io/%IP%?token=52e07b22f25013 >full.txt
type full.txt | jq -r .country >region.txt
type full.txt | jq -r .city >location.txt
set /p LO=<location.txt
set /p RE=<region.txt
if %RE%==US (start ngrok tcp 3389)
if %RE%==CA (start ngrok tcp 3389)
if %RE%==HK (start ngrok tcp --region ap 3389)
if %RE%==SG (start ngrok tcp --region ap 3389)
if %RE%==NL (start ngrok tcp --region eu 3389)
if %RE%==IE (start ngrok tcp --region eu 3389)
if %RE%==GB (start ngrok tcp --region eu 3389)
if %RE%==BR (start ngrok tcp --region sa 3389)
if %RE%==AU (start ngrok tcp --region au 3389)
if %RE%==IN (start ngrok tcp --region in 3389)

del /f "C:\Users\Public\Desktop\Epic Games Launcher.lnk" > out.txt 2>&1
net config server /srvcomment:"Windows Azure VM" > out.txt 2>&1
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /V EnableAutoTray /T REG_DWORD /D 0 /F > out.txt 2>&1
net user administrator fmcpe@1234 /add >nul
net localgroup administrators administrator /add >nul
echo To change another VM region, Create New organization (Your current VM location:  %LO% )
echo Region Available: West Europe, Central US, East Asia, Brazil South, Canada Central, Autralia East, UK South, South India
echo All done! Connect your VM using RDP. When RDP expired and VM shutdown, Rerun failed jobs to get a new RDP.
echo IP:
tasklist | find /i "ngrok.exe" >Nul && curl -s localhost:4040/api/tunnels | jq -r .tunnels[0].public_url || echo "Can't get NGROK tunnel, please paste new NGROK TOKEN in YML. Check Tunnel here: https://dashboard.ngrok.com/status/tunnels "
echo User: administrator
echo Pass: fmcpe@1234
curl -O  > out.txt 2>&1 https://raw.githubusercontent.com/fmcpe/Don-t-Banned-Me-I-will-save-my-project-here/main/no.ps1
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './no.ps1'" > out.txt 2>&1
diskperf -Y >nul
sc start audiosrv >nul
sc config Audiosrv start= auto >nul
ICACLS C:\Windows\Temp /grant administrator:F >nul
ICACLS C:\Windows\installer /grant administrator:F >nul
ping -n 999999 10.10.10.10 >nul
