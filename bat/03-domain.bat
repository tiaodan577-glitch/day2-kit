@echo off
rem 03-domain.bat - domain & trust surface (signed tools only: nltest, net, nslookup, dsquery-less)
setlocal
set "OUTDIR=%~dp0..\out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set "OUT=%OUTDIR%\03-domain.txt"

echo [*] 03-domain %DATE% %TIME%> "%OUT%"
echo.>> "%OUT%"

echo === whoami /groups === >> "%OUT%" 2>&1
whoami /groups >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === logon context === >> "%OUT%" 2>&1
echo USERDNSDOMAIN=%USERDNSDOMAIN% >> "%OUT%" 2>&1
echo LOGONSERVER=%LOGONSERVER% >> "%OUT%" 2>&1
nltest /dsgetdc:%USERDNSDOMAIN% >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === domain controllers === >> "%OUT%" 2>&1
nltest /dclist:%USERDNSDOMAIN% >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === trusts === >> "%OUT%" 2>&1
nltest /domain_trusts >> "%OUT%" 2>&1
nltest /domain_trusts /all_trusts >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === dc discovery via dns === >> "%OUT%" 2>&1
nslookup -type=SRV _ldap._tcp.dc._msdcs.%USERDNSDOMAIN% >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === domain groups of interest === >> "%OUT%" 2>&1
net group "Domain Admins" /domain >> "%OUT%" 2>&1
net group "Enterprise Admins" /domain >> "%OUT%" 2>&1
net group "Domain Controllers" /domain >> "%OUT%" 2>&1
net group "Schema Admins" /domain >> "%OUT%" 2>&1
net group "Group Policy Creator Owners" /domain >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === domain users (may be large) === >> "%OUT%" 2>&1
net user /domain >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === current user domain info === >> "%OUT%" 2>&1
net user %USERNAME% /domain >> "%OUT%" 2>&1
echo.>> "%OUT%"

echo === local groups membership === >> "%OUT%" 2>&1
net localgroup >> "%OUT%" 2>&1

echo [+] saved %OUT%
endlocal
