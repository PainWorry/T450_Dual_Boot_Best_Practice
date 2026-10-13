@echo off
title ThinkPad T450 Optimization - Dry Run Preview
cd /d "%~dp0"
echo ========================================================
echo  ThinkPad T450 Performance Optimizer (Dry-Run Preview)
echo ========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\optimize_t450_performance.ps1" -DryRun
echo.
echo ========================================================
echo  Preview complete. No system changes were applied.
echo ========================================================
pause
