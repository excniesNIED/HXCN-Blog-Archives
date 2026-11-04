@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
if errorlevel 1 (echo SYSTEM LOAD FAIL & exit /b 1)
echo ==== Start 0/1 drivers with non-standard ImagePath ====
for /f "tokens=*" %%K in ('reg query HKLM\VFSYS\ControlSet001\Services 2^>nul') do (
  set "SVC=%%K"
  set "ST="
  for /f "tokens=3" %%V in ('reg query "!SVC!" /v Start 2^>nul ^| findstr /i "REG_DWORD"') do set "ST=%%V"
  if "!ST!"=="0x0" call :chk "!SVC!"
  if "!ST!"=="0x1" call :chk "!SVC!"
)
echo.
echo ==== Security-software services still enabled ====
for %%N in (QQPCMgr QQPCMgrRealTimeProtect QQPCMgrAntiVirus QQPCTray 360Safe 360rp 360sd zhudongfangyu kxetray TESafe TrustedInstaller_ 360Box) do (
  reg query "HKLM\VFSYS\ControlSet001\Services\%%N" /v Start >nul 2>&1 && echo PRESENT %%N
)
reg unload HKLM\VFSYS >nul 2>&1
exit /b 0

:chk
set "IP="
for /f "tokens=2,*" %%A in ('reg query %1 /v ImagePath 2^>nul ^| findstr /i "ImagePath"') do set "IP=%%B"
if not defined IP exit /b 0
echo %1 | findstr /i /c:"\\SystemRoot\\" >nul && exit /b 0
echo %1 | findstr /i /c:"\\??\\C:\\Windows\\" >nul && exit /b 0
echo %1 | findstr /i /c:"system32\\drivers" >nul && exit /b 0
echo NONSTD  %1  -^>  !IP!
exit /b 0
