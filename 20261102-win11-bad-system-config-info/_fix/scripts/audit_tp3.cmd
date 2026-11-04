@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
for %%S in (softaal QMUdisk TSSysKit TFsFlt qmbsec heyboxfilter Asusgio3 VBoxDrv VBoxNetLwf VBoxUSBMon VBoxUSB) do (
  echo --- %%S ---
  reg query "HKLM\VFSYS\ControlSet001\Services\%%S" /v Start 2>nul
  reg query "HKLM\VFSYS\ControlSet001\Services\%%S" /v ErrorControl 2>nul
  reg query "HKLM\VFSYS\ControlSet001\Services\%%S" /v ImagePath 2>nul
  reg query "HKLM\VFSYS\ControlSet001\Services\%%S" /v Type 2>nul
)
reg unload HKLM\VFSYS >nul 2>&1
echo.
echo ==== files ====
for %%F in (TFsFltX64_ev.sys qmbsecx64.sys VBoxDrv.sys VBoxNetLwf.sys VBoxUSBMon.sys) do @if exist "C:\Windows\System32\drivers\%%F" (echo OK %%F) else (echo MISSING %%F)
echo.
echo ==== QQPCMgr sys files ====
dir "C:\Program Files (x86)\Tencent\QQPCMgr\15.6.23169.211\*.sys" /b 2>nul
echo.
echo ==== qmbsec anywhere ====
dir C:\Windows\System32\drivers\qm* /b 2>nul
exit /b 0
