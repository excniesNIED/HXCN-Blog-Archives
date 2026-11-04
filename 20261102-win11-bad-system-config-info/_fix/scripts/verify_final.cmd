@echo off
setlocal enabledelayedexpansion
echo ==== HIVE SEQ / LOAD TEST ====
for %%H in (SYSTEM SOFTWARE SAM SECURITY DEFAULT DRIVERS COMPONENTS ELAM BBI) do call :chk %%H
echo.
echo ==== SECURITY IDENTITY ====
reg load HKLM\VFSEC C:\Windows\System32\config\SECURITY >nul 2>&1
if errorlevel 1 (echo VFSEC LOAD FAIL) else (
  reg query "HKLM\VFSEC\Policy\Accounts" /s 2>nul | findstr /i "PolAcDm" 
  reg query "HKLM\VFSEC\Policy" /v PolAcDmN 2>nul
  echo -- Secrets --
  reg query "HKLM\VFSEC\Policy\Secrets" 2>nul | findstr /i "DPAPI RasDial"
  reg unload HKLM\VFSEC >nul 2>&1
)
echo.
echo ==== BBI LOAD TEST ====
reg load HKLM\VFBBI C:\Windows\System32\config\BBI >nul 2>&1
if errorlevel 1 (echo BBI LOAD FAIL) else (echo BBI LOAD OK & reg unload HKLM\VFBBI >nul 2>&1)
echo.
echo ==== BOOT CHAIN ====
bcdedit /enum {default} | findstr /i "device path"
echo.
echo ==== VOLUME ====
fsutil dirty query C:
exit /b 0

:chk
set "F=C:\Windows\System32\config\%1"
if not exist "%F%" (echo %1 MISSING & exit /b 0)
for %%A in ("%F%") do set SZ=%%~zA
reg load HKLM\VFCHK "%F%" >nul 2>&1
if errorlevel 1 (set R=LOAD_FAIL) else (set R=LOAD_OK & reg unload HKLM\VFCHK >nul 2>&1)
echo %1  size=%SZ%  %R%
exit /b 0
