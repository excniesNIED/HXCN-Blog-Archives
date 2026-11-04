@echo off
chcp 936 >nul
echo ==== HIVES ON DISK ====
dir /b C:\Windows\System32\config\*.LOG* 2>nul
echo.
echo ==== MOUNT LEFTOVERS ====
reg query HKLM /f VF /k 2>nul | findstr /i "VFSEC VFSYS VFSAM VFSOFT VFCHK VFBBI"
echo (empty above = none)
echo.
echo ==== HIBERNATION ====
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
reg query "HKLM\VFSYS\ControlSet001\Control\Session Manager\Power" /v HiberbootEnabled
reg query "HKLM\VFSYS\ControlSet001\Control\Power" /v HibernateEnabled
reg query "HKLM\VFSYS\ControlSet002\Services\softaal" /v Start 2>nul
reg unload HKLM\VFSYS >nul 2>&1
echo.
echo ==== WINRE ====
if exist L:\Recovery\WindowsRE\Winre.wim (echo Winre.wim OK) else (echo Winre.wim MISSING)
echo.
echo ==== FREE SPACE ====
fsutil volume diskfree C: | findstr /i "KB"
exit /b 0
