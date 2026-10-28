@echo off
rem collect-local.bat - local info collection, cmd built-ins only. No network, no PS.
rem Output: %TEMP%\syschk\*.txt  (+ syschk.zip at the end for easy handoff)
setlocal
set "OUT=%TEMP%\syschk"
if not exist "%OUT%" mkdir "%OUT%"
echo [*] collect start %DATE% %TIME%

echo [1/8 identity
> "%OUT%\00-whoami.txt" (
  echo === whoami /all ===
  whoami /all
  echo === whoami /priv ===
  whoami /priv
  echo === context ===
  echo USERDOMAIN=%USERDOMAIN%
  echo USERNAME=%USERNAME%
  echo LOGONSERVER=%LOGONSERVER%
  echo COMPUTERNAME=%COMPUTERNAME%
  echo USERDNSDOMAIN=%USERDNSDOMAIN%
  hostname
  ver
) 2>&1

echo [2/8 system
> "%OUT%\01-system.txt" (
  echo === systeminfo ===
  systeminfo
  echo === hotfixes ===
  wmic qfe get HotFixID,InstalledOn,Description
  echo === disks ===
  wmic logicaldisk get DeviceID,Size,FreeSpace,FileSystem
  echo === env ===
  set
) 2>&1

echo [3/8 accounts
> "%OUT%\02-accounts.txt" (
  echo === net user ===
  net user
  echo === local administrators ===
  net localgroup administrators
  echo === all local groups ===
  net localgroup
  echo === current user ===
  net user %USERNAME%
  echo === password policy ===
  net accounts
) 2>&1

echo [4/8 network
> "%OUT%\03-network.txt" (
  echo === ipconfig ===
  ipconfig /all
  echo === route ===
  route print
  echo === arp ===
  arp -a
  echo === netstat ===
  netstat -ano
  echo === mapped drives ===
  net use
  echo === shares ===
  net share
  echo === firewall profiles ===
  netsh advfirewall show allprofiles
) 2>&1

echo [5/8 processes and services
> "%OUT%\04-procs-svc.txt" (
  echo === tasklist /svc ===
  tasklist /svc
  echo === tasklist /v ===
  tasklist /v
  echo === services ===
  wmic service get Name,State,StartMode,StartName,PathName
) 2>&1

echo [6/8 autostart and tasks
> "%OUT%\05-autostart.txt" (
  echo === schtasks summary ===
  schtasks /query /fo table
  echo === startup commands ===
  wmic startup get Caption,Command,Location,User
  echo === Run keys HKLM ===
  reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
  echo === Run keys HKCU ===
  reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
  echo === RunOnce ===
  reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
  reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
  echo === winlogon ===
  reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
) 2>&1

echo [7/8 privesc surface
> "%OUT%\06-privesc.txt" (
  echo === AlwaysInstallElevated HKLM ===
  reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated
  echo === AlwaysInstallElevated HKCU ===
  reg query "HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated
  echo === UAC policy ===
  reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
  echo === icacls Program Files ===
  icacls "C:\Program Files"
  echo === icacls Program Files x86 ===
  icacls "C:\Program Files (x86)"
  echo === icacls TEMP ===
  icacls "%TEMP%"
  echo === icacls C root ===
  icacls "C:\"
  echo === unquoted candidates (non-Windows paths) ===
  wmic service get Name,PathName,StartMode,StartName
) 2>&1

echo [8/8 software
> "%OUT%\07-software.txt" (
  echo === uninstall 64 ===
  reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s
  echo === uninstall 32 ===
  reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s
  echo === uninstall user ===
  reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s
) 2>&1

echo [*] packing
tar -a -cf "%OUT%.zip" -C "%TEMP%" syschk 2>nul
if exist "%OUT%.zip" (
  echo [+] done, send this file: %OUT%.zip
) else (
  echo [+] done, send folder: %OUT%
)
echo [*] collect end %DATE% %TIME%
endlocal
