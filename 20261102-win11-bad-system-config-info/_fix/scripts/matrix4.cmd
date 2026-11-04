@echo off
chcp 936 >nul
echo == BBI dirty (53232/53231) as-is, with 0-byte LOG1/LOG2 ==
reg load HKLM\KB1 D:\_fix\mx5\BBI >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KB1 >nul 2>&1)

echo == BBI dirty, logs removed ==
reg load HKLM\KB2 D:\_fix\mx5\BBI_nolog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KB2 >nul 2>&1)

echo == current C: BBI (clean 53233) ==
reg load HKLM\KB3 C:\Windows\System32\config\BBI >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KB3 >nul 2>&1)
exit /b 0
