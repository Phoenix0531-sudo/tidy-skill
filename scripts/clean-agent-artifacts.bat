@echo off
REM =============================================
REM  Agent Artifact Cleanup — Wrapper Script
REM =============================================
REM
REM  This script invokes the PowerShell cleanup
REM  script in DryRun mode by default.
REM
REM  Usage:
REM    double-click       DryRun preview on current directory
REM    drag a folder      DryRun on that folder
REM    drag multiple      First folder only — use PowerShell for more
REM
REM  Safety:
REM    - Defaults to DryRun (no files deleted)
REM    - No administrator rights required
REM    - No system modifications
REM    - No scheduled task registration
REM =============================================

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "POWERSHELL_SCRIPT=%SCRIPT_DIR%clean-agent-artifacts.ps1"
set "TARGET=%~1"

if not exist "%POWERSHELL_SCRIPT%" (
    echo [ERROR] PowerShell script not found: %POWERSHELL_SCRIPT%
    echo.
    echo Make sure this batch file is in the same directory as clean-agent-artifacts.ps1
    pause
    exit /b 1
)

REM Default to current directory if no folder was dropped
if "%TARGET%"=="" set "TARGET=%CD%"

REM Verify the target exists
if not exist "%TARGET%" (
    echo [ERROR] Target does not exist: %TARGET%
    pause
    exit /b 1
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
