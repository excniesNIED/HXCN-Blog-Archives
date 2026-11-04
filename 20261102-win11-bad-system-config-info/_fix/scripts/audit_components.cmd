@echo off
chcp 936 >nul
echo ==== WinSxS\Temp top level ====
dir C:\Windows\WinSxS\Temp /b /a 2>nul
echo.
echo ==== WinSxS\Temp total ====
dir C:\Windows\WinSxS\Temp /s /-c 2>nul | findstr /c:"个文件"
echo.
echo ==== winevt logs ====
dir C:\Windows\System32\winevt\Logs /a /-c 2>nul | findstr /i ".evtx"
echo.
echo ==== WMI repository ====
dir C:\Windows\System32\wbem\Repository /a /-c 2>nul
echo.
echo ==== config\Journal ====
dir C:\Windows\System32\config\Journal /a /-c 2>nul
exit /b 0
