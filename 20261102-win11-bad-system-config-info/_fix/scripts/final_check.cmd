@echo off
chcp 936 >nul
echo ==== 1. stale mounts (should be empty) ====
reg query HKLM /f VFSEC /k 2>nul | findstr /i "VFSEC"
reg query HKLM /f VFSYS /k 2>nul | findstr /i "VFSYS"
reg query HKLM /f VFSAM /k 2>nul | findstr /i "VFSAM"
reg query HKLM /f VFSOFT /k 2>nul | findstr /i "VFSOFT"
reg query HKLM /f VFCHK /k 2>nul | findstr /i "VFCHK"
reg query HKLM /f VFBBI /k 2>nul | findstr /i "VFBBI"
echo.
echo ==== 2. Select on SYSTEM ====
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
reg query HKLM\VFSYS\Select
reg unload HKLM\VFSYS >nul 2>&1
echo.
echo ==== 3. key files ====
for %%F in (C:\Windows\System32\config\SECURITY C:\Windows\System32\config\SECURITY.LOG1 C:\Windows\System32\config\BBI) do @if exist %%F (echo EXISTS %%F) else (echo MISSING %%F)
if exist C:\hiberfil.sys (echo hiberfil.sys STILL PRESENT) else (echo hiberfil.sys GONE)
echo.
echo ==== 4. free space ====
fsutil volume diskfree C: | findstr /i "KB"
echo.
echo ==== 5. boot ====
bcdedit /enum {default} | findstr /i "device path osdevice"
exit /b 0
