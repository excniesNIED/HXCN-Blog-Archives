@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
echo == a: DIRTY + stale LOG1/LOG2 ==
reg load HKLM\MKa D:\_fix\mx4\a_DIRTY >nul 2>&1
if errorlevel 1 (echo   RESULT=LOAD_FAIL) else (echo   RESULT=LOAD_OK& reg unload HKLM\MKa >nul 2>&1)

echo == g: DIRTY, no logs ==
reg load HKLM\Mkg D:\_fix\mx4\g_DIRTY >nul 2>&1
if errorlevel 1 (echo   RESULT=LOAD_FAIL) else (echo   RESULT=LOAD_OK& reg unload HKLM\Mkg >nul 2>&1)

echo == j: PATCHED + stale LOG1/LOG2 ==
reg load HKLM\MKj D:\_fix\mx4\j_PATCHED >nul 2>&1
if errorlevel 1 (echo   RESULT=LOAD_FAIL) else (echo   RESULT=LOAD_OK& reg unload HKLM\MKj >nul 2>&1)

echo == p: PATCHED, no logs ==
reg load HKLM\MKp D:\_fix\mx4\SEC_patched >nul 2>&1
if errorlevel 1 (echo   RESULT=LOAD_FAIL) else (echo   RESULT=LOAD_OK& reg unload HKLM\MKp >nul 2>&1)

echo == h: DIRTY + only LOG2 ==
if exist D:\_fix\mx4\h_DIRTY del /f /q D:\_fix\mx4\h_DIRTY
copy /y D:\_fix\mx4\g_DIRTY D:\_fix\mx4\h_DIRTY >nul
copy /y D:\_fix\quarantine\SECURITY.LOG2 D:\_fix\mx4\h_DIRTY.LOG2 >nul
reg load HKLM\MKh D:\_fix\mx4\h_DIRTY >nul 2>&1
if errorlevel 1 (echo   RESULT=LOAD_FAIL) else (echo   RESULT=LOAD_OK& reg unload HKLM\MKh >nul 2>&1)
exit /b 0
