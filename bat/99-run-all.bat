@echo off
rem 99-run-all.bat - run every enum stage in order, one log per stage in ..\out\
setlocal
set "HERE=%~dp0"
if not exist "%HERE%..\out" mkdir "%HERE%..\out"

echo ============================================
echo  Day2 enum suite  %DATE% %TIME%
echo ============================================

for %%F in ("%HERE%0*.bat" "%HERE%1*.bat" "%HERE%2*.bat" "%HERE%3*.bat" "%HERE%4*.bat" "%HERE%5*.bat" "%HERE%6*.bat" "%HERE%7*.bat") do (
  if /I not "%%~nxF"=="99-run-all.bat" (
    echo [RUN] %%~nxF
    call "%%~F"
  )
)

echo.
echo [+] all stages done, logs in %HERE%..\out\
dir /b "%HERE%..\out"
endlocal
