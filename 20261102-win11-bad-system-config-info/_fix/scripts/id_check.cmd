@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
echo ==== SOFTWARE ProfileList SIDs ====
reg load HKLM\VFSOFT C:\Windows\System32\config\SOFTWARE >nul 2>&1
if errorlevel 1 (echo SOFTWARE LOAD FAIL) else (
  for /f "tokens=*" %%K in ('reg query "HKLM\VFSOFT\Microsoft\Windows NT\CurrentVersion\ProfileList" 2^>nul ^| findstr /i "S-1-5-21"') do (
    set "K=%%K"
    for /f "tokens=2,*" %%A in ('reg query "%%K" /v ProfileImagePath 2^>nul ^| findstr /i "ProfileImagePath"') do echo !K!  -^>  %%B
  )
  reg unload HKLM\VFSOFT >nul 2>&1
)
echo.
echo ==== SAM user RIDs ====
reg load HKLM\VFSAM C:\Windows\System32\config\SAM >nul 2>&1
if errorlevel 1 (echo SAM LOAD FAIL) else (
  reg query HKLM\VFSAM\SAM\Domains\Account\Users 2>nul | findstr /i "0000" 
  reg unload HKLM\VFSAM >nul 2>&1
)
echo.
echo ==== SYSTEM ComputerName / ProductName ====
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
reg query "HKLM\VFSYS\ControlSet001\Control\ComputerName\ActiveComputerName" /v ComputerName
reg unload HKLM\VFSYS >nul 2>&1
exit /b 0
