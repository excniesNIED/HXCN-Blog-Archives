@echo off
chcp 936 >nul
echo ==== RegBack ====
dir C:\Windows\System32\config\RegBack /a /-c 2>nul
echo.
echo ==== log files on C: ====
dir C:\Windows\System32\config\SECURITY* /a /-c 2>nul
echo.
echo ==== rollback material ====
dir D:\_fix\quarantine /a /-c 2>nul
dir C:\Windows\System32\config\CorruptBak /a /-c 2>nul
echo.
echo ==== minidump kept ====
dir C:\Windows\Minidump /a /-c 2>nul
echo.
echo ==== free space ====
fsutil volume diskfree C:
exit /b 0
