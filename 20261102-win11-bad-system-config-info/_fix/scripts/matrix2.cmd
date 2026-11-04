@echo off
chcp 936 >nul
echo == s1: DIRTY, no log files ==
reg load HKLM\KS1 D:\_fix\mx6\s1_dirty_nolog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS1 >nul 2>&1)

echo == s2: DIRTY, zero-length LOG1/LOG2 ==
reg load HKLM\KS2 D:\_fix\mx6\s2_dirty_zerolog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS2 >nul 2>&1)

echo == s3: DIRTY + stale LOG1(208)/LOG2(17963) ==
reg load HKLM\KS3 D:\_fix\mx6\s3_dirty_stalelog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS3 >nul 2>&1)

echo == s4: CLEAN but wrong header checksum ==
reg load HKLM\KS4 D:\_fix\mx6\s4_clean_badcsum >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS4 >nul 2>&1)
exit /b 0
