@echo off
chcp 936 >nul
echo == t1: dirty SECURITY, seq2=17963 (csum fixed) ==
reg load HKLM\KT1 D:\_fix\mx7\t1_sec_dirty2 >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KT1 >nul 2>&1)

echo == t2: clean SECURITY at 17964 (csum fixed) ==
reg load HKLM\KT2 D:\_fix\mx7\t2_sec_clean17964 >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KT2 >nul 2>&1)

echo == t3: dirty BBI, seq2=53230 (csum fixed) ==
reg load HKLM\KT3 D:\_fix\mx7\t3_bbi_dirty2 >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KT3 >nul 2>&1)

echo == t4: clean BBI at 53231 (csum fixed) ==
reg load HKLM\KT4 D:\_fix\mx7\t4_bbi_clean >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KT4 >nul 2>&1)

echo == t5: current C: SECURITY (clean 17970) ==
reg load HKLM\KT5 D:\_fix\mx7\t5_sec_clean >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KT5 >nul 2>&1)
exit /b 0
