@echo off
chcp 936 >nul
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
echo ==== MountedDevices ====
reg query "HKLM\VFSYS\MountedDevices" 2>nul | find /c /v ""
echo.
echo ==== Storage class filters ====
for %%G in ("{4d36e967-e325-11ce-bfc1-08002be10318}" "{71a27cdd-812a-11d0-bec7-08002be2092f}" "{533c5b84-ec70-11d2-9505-00c04f79deaf}") do (
  echo -- %%G --
  reg query "HKLM\VFSYS\ControlSet001\Control\Class\%%~G" /v UpperFilters 2>nul
  reg query "HKLM\VFSYS\ControlSet001\Control\Class\%%~G" /v LowerFilters 2>nul
)
echo.
echo ==== Keyboard / Mouse class filters ====
for %%G in ("{4d36e96b-e325-11ce-bfc1-08002be10318}" "{4d36e96f-e325-11ce-bfc1-08002be10318}") do (
  echo -- %%G --
  reg query "HKLM\VFSYS\ControlSet001\Control\Class\%%~G" /v UpperFilters 2>nul
)
echo.
echo ==== FltMgr minifilters (boot) ====
reg query "HKLM\VFSYS\ControlSet001\Control\Class\{b1d1a169-c54f-4379-81db-bee7d88d7454}" 2>nul | find /c /v ""
reg unload HKLM\VFSYS >nul 2>&1
exit /b 0
