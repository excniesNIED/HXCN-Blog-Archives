@echo off
chcp 936 >nul
echo ==== Setup state ====
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
reg query "HKLM\VFSYS\ControlSet001\Control\Session Manager" /v SetupType
reg query "HKLM\VFSYS\ControlSet001\Control\Session Manager" /v SystemSetupInProgress
reg query "HKLM\VFSYS\ControlSet001\Control\Session Manager" /v PendingFileRenameOperations
reg query "HKLM\VFSYS\ControlSet001\Control\Session Manager" /v BootExecute
reg unload HKLM\VFSYS >nul 2>&1
echo.
echo ==== Setup log tail ====
if exist C:\Windows\Panther\setupact.log (
  for /f "usebackq tokens=*" %%L in (`powershell -NoProfile -Command "Get-Content 'C:\Windows\Panther\setupact.log' -Tail 12"`) do echo %%L
) else echo no setupact.log
echo.
echo ==== CbsTemp / pending ====
if exist C:\Windows\WinSxS\pending.xml (echo PENDING_XML_PRESENT) else echo no pending.xml
dir C:\Windows\CbsTemp /b 2>nul | find /c /v ""
echo.
echo ==== Free space ====
fsutil volume diskfree C: | findstr /i "avail"
exit /b 0
