@echo off
title ThinkPad T450 Optimization - Apply
cd /d "%~dp0"
echo ========================================================
echo  ThinkPad T450 Performance Optimizer - Live Apply
echo ========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\optimize_t450_performance.ps1"
echo.
echo ========================================================
echo  Optimization complete.
echo ========================================================
pause
