@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
if errorlevel 1 (echo LOAD FAIL & exit /b 1)
echo ==== third-party boot drivers: Start / file ====
for %%S in (softaal QMUdisk TSSysKit TFsFlt qmbsec heyboxfilter Asusgio3 VBoxDrv VBoxNetLwf VBoxUSBMon) do call :one %%S
echo.
echo ==== QQPCMgr dir ====
if exist "C:\Program Files (x86)\Tencent\QQPCMgr" (dir "C:\Program Files (x86)\Tencent\QQPCMgr" /b) else (echo QQPCMgr DIR ABSENT)
reg unload HKLM\VFSYS >nul 2>&1
exit /b 0

:one
set "K=HKLM\VFSYS\ControlSet001\Services\%1"
set "ST=absent"
set "IP="
for /f "tokens=3" %%V in ('reg query "%K%" /v Start 2^>nul ^| findstr /i "REG_DWORD"') do set "ST=%%V"
for /f "tokens=2,*" %%A in ('reg query "%K%" /v ImagePath 2^>nul ^| findstr /i "ImagePath"') do set "IP=%%B"
if /i "%ST%"=="absent" (echo %1  NOT_PRESENT & exit /b 0)
set "P=%IP%"
set "P=!P:\??\=!"
set "P=!P:systemroot\=C:\Windows\!"
set "P=!P:\SystemRoot\=C:\Windows\!"
set "EX=NOFILE"
if exist "!P!" set "EX=FILE_OK"
echo %1  Start=%ST%  %EX%  -^> !P!
exit /b 0
