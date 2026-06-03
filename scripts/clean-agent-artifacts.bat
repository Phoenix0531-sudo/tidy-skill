@echo off
REM =============================================
REM  Agent Artifact Cleanup — Wrapper Script
REM =============================================
REM
REM  This script invokes the PowerShell cleanup
REM  script in DryRun mode by default.
REM
REM  Usage:
REM    double-click       DryRun preview
REM    drag a folder     DryRun on that folder
REM
REM =============================================

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "POWERSHELL_SCRIPT=%SCRIPT_DIR%clean-agent-artifacts.ps1"

if not exist "%POWERSHELL_SCRIPT%" (
    echo [ERROR] PowerShell script not found: %POWERSHELL_SCRIPT%
    echo.
    echo Make sure this batch file is in the same directory as clean-agent-artifacts.ps1
    pause
    exit /b 1
)

REM If a folder was dropped onto this script, use it as Root
if not "%~1"=="" (
    set "TARGET=%~1"
) else (
    set "TARGET=%CD%"
)

echo ============================================
echo  Agent Artifact Cleanup
echo  Mode: DRY RUN (no files will be deleted)
echo ============================================
echo.
echo Target: %TARGET%
echo.
echo To perform actual cleanup, run the PowerShell script directly:
echo   powershell -ExecutionPolicy Bypass -File "%POWERSHELL_SCRIPT%" -Root "%TARGET%" -DryRun:^$false
echo.
echo ============================================
echo.

powershell -ExecutionPolicy Bypass -File "%POWERSHELL_SCRIPT%" -Root "%TARGET%" -DryRun

echo.
echo ============================================
echo  Dry run complete.
echo  No files were deleted.
echo ============================================
echo.

pause
