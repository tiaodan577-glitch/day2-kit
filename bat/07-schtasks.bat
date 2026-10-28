@echo off
rem 07-schtasks.bat - scheduled tasks & startup persistence surface
setlocal
set "OUTDIR=%~dp0..\out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set "OUT=%OUTDIR%\07-schtasks.txt"

echo [*] 07-schtasks %DATE% %TIME%> "%OUT%"
echo.>> "%OUT%"

echo === scheduled tasks summary === >> "%OUT%" 2>&1
schtasks /query /fo TABLE >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === scheduled tasks verbose === >> "%OUT%" 2>&1
schtasks /query /fo LIST /v >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === startup entries (wmic) === >> "%OUT%" 2>&1
wmic startup get Caption,Command,Location,User >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === startup folders === >> "%OUT%" 2>&1
dir /a "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup" >> "%OUT%" 2>&1
dir /a "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === services auto-start non-Microsoft (paths) === >> "%OUT%" 2>&1
wmic service get Name,StartName,PathName,StartMode | findstr /i "Auto" >> "%OUT%" 2>&1

echo [+] saved %OUT%
endlocal
