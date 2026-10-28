@echo off
rem 05-privesc.bat - local privilege-escalation surface checks (read-only, user context)
setlocal
set "OUTDIR=%~dp0..\out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set "OUT=%OUTDIR%\05-privesc.txt"

echo [*] 05-privesc %DATE% %TIME%> "%OUT%"
echo.>> "%OUT%"

echo === AlwaysInstallElevated === >> "%OUT%" 2>&1
reg query "HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated >> "%OUT%" 2>&1
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === unattended answer files (creds) === >> "%OUT%" 2>&1
dir /s /b C:\Windows\Panther\Unattend.xml C:\Windows\Panther\Unattend\Unattend.xml C:\Windows\System32\Sysprep\Unattend.xml C:\Windows\System32\Sysprep\Panther\Unattend.xml 2>>nul
type C:\Windows\Panther\Unattend.xml >> "%OUT%" 2>&1
type C:\Windows\System32\Sysprep\Unattend.xml >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === winlogon autologon === >> "%OUT%" 2>&1
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === autorun locations === >> "%OUT%" 2>&1
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" >> "%OUT%" 2>&1
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" >> "%OUT%" 2>&1
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" >> "%OUT%" 2>&1
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === PATH hijack candidates (unquoted / writable?) === >> "%OUT%" 2>&1
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === folder perms sample (Program Files, Temp) === >> "%OUT%" 2>&1
icacls "C:\Program Files" >> "%OUT%" 2>&1
icacls "C:\Program Files (x86)" >> "%OUT%" 2>&1
icacls "%TEMP%" >> "%OUT%" 2>&1
icacls "C:\" >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === always-elevated MSI / UAC policy === >> "%OUT%" 2>&1
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === token privileges === >> "%OUT%" 2>&1
whoami /priv >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === scheduled tasks (may be large) === >> "%OUT%" 2>&1
schtasks /query /fo LIST /v >> "%OUT%" 2>&1

echo [+] saved %OUT%
endlocal
