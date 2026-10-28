@echo off
rem 00-context.bat - identity & host context (cmd built-ins + signed sysinternals-free)
setlocal
set "OUTDIR=%~dp0..\out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set "OUT=%OUTDIR%\00-context.txt"

echo [*] 00-context %DATE% %TIME%> "%OUT%"
echo.>> "%OUT%"

echo === whoami === >> "%OUT%" 2>&1
whoami >> "%OUT%" 2>&1
whoami /all >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === host === >> "%OUT%" 2>&1
hostname >> "%OUT%" 2>&1
ver >> "%OUT%" 2>&1
echo %USERDOMAIN%\%USERNAME% / %COMPUTERNAME% >> "%OUT%" 2>&1
echo USERDNSDOMAIN=%USERDNSDOMAIN% >> "%OUT%" 2>&1
echo LOGONSERVER=%LOGONSERVER% >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === session & policy === >> "%OUT%" 2>&1
net accounts >> "%OUT%" 2>&1
net config workstation >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === local admin check === >> "%OUT%" 2>&1
net localgroup administrators >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === environment === >> "%OUT%" 2>&1
set >> "%OUT%" 2>&1

echo [+] saved %OUT%
endlocal
