@echo off
chcp 936 >nul
call :t a D:\_fix\mx8\a_dirty_logs
call :t b D:\_fix\mx8\b_engine_logs
call :t c D:\_fix\mx8\c_engine_nolog
call :t d D:\_fix\mx8\d_foreign_logs
call :t e D:\_fix\mx8\e_foreign_nolog
call :t f D:\_fix\mx8\f_foreign203_logs
call :t g D:\_fix\mx8\g_dirty_nolog
call :t h D:\_fix\mx8\h_dirty_log2
call :t i D:\_fix\mx8\i_patch_nolog
call :t j D:\_fix\mx8\j_patch_logs
exit /b 0

:t
reg load HKLM\MJ%1 %2 >nul 2>&1
if errorlevel 1 (echo %1 = LOAD_FAIL) else (echo %1 = LOAD_OK& reg unload HKLM\MJ%1 >nul 2>&1)
exit /b 0
