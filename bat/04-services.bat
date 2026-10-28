@echo off
rem 04-services.bat - services & processes: unquoted paths, writable bins, weak perms hints
setlocal
set "OUTDIR=%~dp0..\out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set "OUT=%OUTDIR%\04-services.txt"

echo [*] 04-services %DATE% %TIME%> "%OUT%"
echo.>> "%OUT%"

echo === services (name/path/start) === >> "%OUT%" 2>&1
wmic service get Name,StartName,StartMode,State,PathName >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === services running === >> "%OUT%" 2>&1
sc query type= service state= active >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === processes (pid/path) === >> "%OUT%" 2>&1
wmic process get Name,ProcessId,ParentProcessId,ExecutablePath,CommandLine >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === unquoted service paths candidate === >> "%OUT%" 2>&1
wmic service get Name,PathName | findstr /i /v "C:\Windows\system32" | findstr /i /v /c:"""" >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === auto-start services === >> "%OUT%" 2>&1
wmic service get Name,StartMode,State,PathName | findstr /i "Auto" >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === drivers === >> "%OUT%" 2>&1
driverquery /v >> "%OUT%" 2>&1

echo [+] saved %OUT%
endlocal
