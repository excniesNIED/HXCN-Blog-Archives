@echo off
chcp 936 >nul
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
echo --PagingFiles--
reg query "HKLM\VFSYS\ControlSet001\Control\Session Manager\Memory Management" /v PagingFiles
echo --ExistingPageFiles--
reg query "HKLM\VFSYS\ControlSet001\Control\Session Manager\Memory Management" /v ExistingPageFiles
echo --CrashControl--
reg query "HKLM\VFSYS\ControlSet001\Control\CrashControl"
reg unload HKLM\VFSYS >nul 2>&1
exit /b 0
