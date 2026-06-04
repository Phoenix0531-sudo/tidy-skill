@echo off
REM =============================================
REM  tidy-skill - Agent Artifact Cleanup Wrapper
REM =============================================
REM
REM  Invokes the PowerShell cleanup script in
REM  DryRun mode by default.
REM
REM  Usage:
REM    double-click       DryRun on current directory
REM    drag a folder      DryRun on that folder
REM
REM  Safety:
REM    - Defaults to DryRun (no files deleted)
REM    - No admin rights required
REM    - No system modifications
REM =============================================

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "POWERSHELL_SCRIPT=%SCRIPT_DIR%clean-agent-artifacts.ps1"
set "TARGET=%~1"

if not exist "%POWERSHELL_SCRIPT%" (
    echo [ERROR] PowerShell script not found: %POWERSHELL_SCRIPT%
    echo.
    pause
    exit /b 1
)

if "%TARGET%"=="" set "TARGET=%CD%"

if not exist "%TARGET%" (
    echo [ERROR] Target does not exist: %TARGET%
    pause
    exit /b 1
)

echo ============================================
echo  tidy-skill - Artifact Cleanup
echo  Mode: DRY RUN (no files will be deleted)
echo ============================================
echo.
echo Target: %TARGET%
echo.
echo To perform actual cleanup:
echo   powershell -ExecutionPolicy Bypass -File "%POWERSHELL_SCRIPT%" -Root "%TARGET%" -DryRun:^$false
echo.
echo ============================================
echo.

powershell -ExecutionPolicy Bypass -File "%POWERSHELL_SCRIPT%" -Root "%TARGET%" -DryRun

echo.
echo ============================================
echo  Dry run complete. No files deleted.
echo ============================================
echo.
pause
