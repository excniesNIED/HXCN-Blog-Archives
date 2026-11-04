@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
if errorlevel 1 (echo SYSTEM LOAD FAIL & exit /b 1)
set MISSING=0
set COUNT=0
for /f "tokens=*" %%K in ('reg query HKLM\VFSYS\ControlSet001\Services 2^>nul') do (
  set "SVC=%%K"
  set "ST="
  for /f "tokens=3" %%V in ('reg query "!SVC!" /v Start 2^>nul ^| findstr /i "REG_DWORD"') do set "ST=%%V"
  if defined ST (
    if "!ST!"=="0x0" call :check "!SVC!"
    if "!ST!"=="0x1" call :check "!SVC!"
  )
)
echo.
echo Boot/System-start drivers checked: !COUNT!   missing image: !MISSING!
reg unload HKLM\VFSYS >nul 2>&1
exit /b 0

:check
set "IP="
for /f "tokens=2,*" %%A in ('reg query %1 /v ImagePath 2^>nul ^| findstr /i "ImagePath"') do set "IP=%%B"
if not defined IP exit /b 0
set /a COUNT+=1
set "P=!IP!"
set "P=!P:\??\=!"
set "P=!P:systemroot\=C:\Windows\!"
set "P=!P:\SystemRoot\=C:\Windows\!"
echo !P! | findstr /i /c:".sys" >nul || exit /b 0
echo !P! | findstr /i /c:"\" >nul || exit /b 0
if not exist "!P!" (
  set /a MISSING+=1
  echo MISSING_IMAGE  %1  -^>  !P!
)
exit /b 0
