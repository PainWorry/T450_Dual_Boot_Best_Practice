@echo off
title ThinkPad T450 Optimization - Rollback
cd /d "%~dp0"
echo ========================================================
echo  ThinkPad T450 Performance Optimizer - Rollback
echo ========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\rollback_t450_performance.ps1"
echo.
echo ========================================================
echo  Rollback complete. Factory settings restored.
echo ========================================================
pause
