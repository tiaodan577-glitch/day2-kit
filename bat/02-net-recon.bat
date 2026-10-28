@echo off
rem 02-net-recon.bat - network posture: interfaces, routes, neighbors, listeners, firewall
setlocal
set "OUTDIR=%~dp0..\out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set "OUT=%OUTDIR%\02-net-recon.txt"

echo [*] 02-net-recon %DATE% %TIME%> "%OUT%"
echo.>> "%OUT%"

echo === ipconfig === >> "%OUT%" 2>&1
ipconfig /all >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === route === >> "%OUT%" 2>&1
route print >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === arp === >> "%OUT%" 2>&1
arp -a >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === netstat listeners & conns === >> "%OUT%" 2>&1
netstat -ano >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === netstat named pipes (smb) === >> "%OUT%" 2>&1
netstat -anob >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === nbtstat === >> "%OUT%" 2>&1
nbtstat -n >> "%OUT%" 2>&1
nbtstat -s >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === firewall profiles === >> "%OUT%" 2>&1
netsh advfirewall show allprofiles >> "%OUT%" 2>&1
netsh advfirewall firewall show rule name=all dir=in status=active >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === shares & mapped drives === >> "%OUT%" 2>&1
net share >> "%OUT%" 2>&1
net use >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === dns cache (recent internal names) === >> "%OUT%" 2>&1
ipconfig /displaydns >> "%OUT%" 2>&1

echo [+] saved %OUT%
endlocal
