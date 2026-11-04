@echo off
chcp 936 >nul
reg load HKLM\VFCOMP C:\Windows\System32\config\COMPONENTS >nul 2>&1
if errorlevel 1 (echo COMPONENTS LOAD FAIL & exit /b 1)
echo ==== CBS root values ====
reg query "HKLM\VFCOMP\Microsoft\Windows\CurrentVersion\Component Based Servicing"
echo.
echo ==== PackagesPending ====
reg query "HKLM\VFCOMP\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending" 2>nul
echo.
echo ==== RebootPending subkeys ====
reg query "HKLM\VFCOMP\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" 2>nul
echo.
echo ==== PackagesPending count via /s ====
reg query "HKLM\VFCOMP\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending" /s 2>nul | find /c /v ""
reg unload HKLM\VFCOMP >nul 2>&1
exit /b 0
