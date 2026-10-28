@echo off
rem 06-av-check.bat - identify security products & their services/processes (context for later stages)
setlocal
set "OUTDIR=%~dp0..\out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set "OUT=%OUTDIR%\06-av-check.txt"

echo [*] 06-av-check %DATE% %TIME%> "%OUT%"
echo.>> "%OUT%"

echo === security center products (WSC) === >> "%OUT%" 2>&1
wmic /namespace:\\root\SecurityCenter2 path AntiVirusProduct get displayName,productState,pathToSignedProductExe >> "%OUT%" 2>&1
wmic /namespace:\\root\SecurityCenter2 path FirewallProduct get displayName,productState >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === known product processes === >> "%OUT%" 2>&1
tasklist /svc | findstr /i "cortex xdr cyserver cyvera trellix mcafee cb carbon parity appcontrol sensor windefend msmpeng" >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === known product services === >> "%OUT%" 2>&1
sc query state= all | findstr /i "cortex xdr cyserver cyvera trellix mcafee cb carbon parity appcontrol sensor windefend sense" >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === product install dirs === >> "%OUT%" 2>&1
dir /b "C:\Program Files" >> "%OUT%" 2>&1
dir /b "C:\Program Files (x86)" >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === full process list === >> "%OUT%" 2>&1
tasklist /v >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === app control agent hints (registry) === >> "%OUT%" 2>&1
reg query "HKLM\SOFTWARE\CarbonBlack" /s >> "%OUT%" 2>&1
reg query "HKLM\SOFTWARE\Bit9" /s >> "%OUT%" 2>&1
reg query "HKLM\SOFTWARE\Palo Alto Networks" /s >> "%OUT%" 2>&1
reg query "HKLM\SOFTWARE\Trellix" /s >> "%OUT%" 2>&1

echo [+] saved %OUT%
endlocal
