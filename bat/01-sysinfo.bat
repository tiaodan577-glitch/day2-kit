@echo off
rem 01-sysinfo.bat - OS detail, hotfixes, installed software via registry (no extra tools)
setlocal
set "OUTDIR=%~dp0..\out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set "OUT=%OUTDIR%\01-sysinfo.txt"

echo [*] 01-sysinfo %DATE% %TIME%> "%OUT%"
echo.>> "%OUT%"

echo === systeminfo === >> "%OUT%" 2>&1
systeminfo >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === hotfixes === >> "%OUT%" 2>&1
wmic qfe get HotFixID,InstalledOn,Description >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === cpu / memory === >> "%OUT%" 2>&1
wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors >> "%OUT%" 2>&1
wmic ComputerSystem get TotalPhysicalMemory,Manufacturer,Model >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === logical disks === >> "%OUT%" 2>&1
wmic logicaldisk get DeviceID,Size,FreeSpace,FileSystem >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === installed software (64-bit) === >> "%OUT%" 2>&1
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === installed software (32-bit view) === >> "%OUT%" 2>&1
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === user installed software === >> "%OUT%" 2>&1
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s >> "%OUT%" 2>&1

echo [+] saved %OUT%
endlocal
