<#
.SYNOPSIS
    Clean AI agent-generated artifacts from a project directory.

.DESCRIPTION
    Conservative cleanup of agent temporary files and expired reports.
    Defaults to DryRun mode. Never deletes formal documentation, source code,
    or tool state without explicit confirmation.

.PARAMETER Root
    Project root directory to clean.

.PARAMETER TmpRetentionDays
    Age after which .agent_tmp/ files are eligible for deletion. Default 7.

.PARAMETER ReportRetentionDays
    Age after which .agent_reports/ files are eligible for deletion. Default 30.

.PARAMETER DryRun
    When $true (default), preview only. When $false, perform deletion.

.PARAMETER ConfirmClean
    When specified, also cleans root-level suspicious Markdown files.

.EXAMPLE
    .\clean-agent-artifacts.ps1 -Root "C:\Projects\MyApp"

.EXAMPLE
    .\clean-agent-artifacts.ps1 -Root "C:\Projects\MyApp" -DryRun:$false

.EXAMPLE
    .\clean-agent-artifacts.ps1 -Root "C:\Projects\MyApp" -ConfirmClean

.NOTES
    Part of Tidy Skill. Never modifies system settings.
    Never uploads data. Safe for PowerShell 5.1+ and 7+.
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$Root,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$TmpRetentionDays = 7,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$ReportRetentionDays = 30,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun = $true,

    [Parameter(Mandatory = $false)]
    [switch]$ConfirmClean = $false
)

# ---- Helpers ----

$skipDirPatterns = @(
    '\.git', 'node_modules', 'dist', 'build', 'target',
    '\.venv', 'venv', '__pycache__', '\.next', '\.nuxt',
    'bin', 'obj', 'packages'
)

$forbiddenRootPatterns = @(
    '^todo\.md$', '^plan\.md$', '^notes\.md$', '^lessons\.md$',
    '^summary\.md$', '^report\.md$', '^final_report\.md$',
    '^implementation_plan\.md$', '^migration_plan\.md$',
    '^audit_report\.md$', '^cleanup_report\.md$', '^task_list\.md$',
    '^progress\.md$', '^work_summary\.md$', '^changes_summary\.md$',
    '^.+_summary\.md$', '^.+_report\.md$', '^.+_plan\.md$'
)

function Get-RelativePath {
    param([string]$FullPath)
    $rel = $FullPath.Substring($Root.Length).TrimStart('\').TrimStart('/')
    if ($rel -eq '') { return '.' }
    return $rel
}

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $line -ForegroundColor $Color
}

# ---- Resolve ----
$Root = (Resolve-Path -LiteralPath $Root).Path

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Tidy Skill — Agent Artifact Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Root:             $Root"
Write-Host "Mode:             $(if ($DryRun) { 'DRY RUN (preview only)' } else { 'LIVE (files will be deleted)' })"
Write-Host "Tmp retention:    $TmpRetentionDays days"
Write-Host "Report retention: $ReportRetentionDays days"
Write-Host "ConfirmClean:     $ConfirmClean"
Write-Host ""

if ($DryRun) {
    Write-Host ">>> DRY RUN MODE <<< No files will be deleted." -ForegroundColor Yellow
    Write-Host ""
}

$cutoffTmp = (Get-Date).AddDays(-$TmpRetentionDays)
$cutoffReport = (Get-Date).AddDays(-$ReportRetentionDays)

$log = New-Object System.Collections.ArrayList
$deleted = @{ Tmp = 0; Reports = 0; RootSuspicious = 0 }
$actionLabel = if ($DryRun) { 'Would delete' } else { 'Deleted' }

# ---- 1. Clean .agent_tmp/ ----
$tmpDir = Join-Path -Path $Root -ChildPath ".agent_tmp"
if (Test-Path -LiteralPath $tmpDir) {
    Write-Log "Scanning .agent_tmp (cutoff: $($cutoffTmp.ToString('yyyy-MM-dd')))" -Color "Cyan"
    $files = Get-ChildItem -LiteralPath $tmpDir -File -ErrorAction SilentlyContinue
    $found = $false
    foreach ($f in $files) {
        if ($f.LastWriteTime -lt $cutoffTmp) {
            $found = $true
            $rel = Get-RelativePath -FullPath $f.FullName
            $age = [Math]::Floor(((Get-Date) - $f.LastWriteTime).TotalDays)
            [void]$log.Add("$actionLabel tmp: $rel (age: ${age}d)")
            if ($DryRun) { Write-Log "[DRY RUN] Would delete: $rel (age: ${age}d)" -Color "Yellow" }
            else {
                try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
                      Write-Log "Deleted: $rel" -Color "Green"; $deleted.Tmp++ }
                catch { Write-Log "FAILED: $rel - $_" -Color "Red"
                        [void]$log.Add("FAILED: $rel - $_") }
            }
        }
    }
    if (-not $found) { Write-Log "No eligible files in .agent_tmp." -Color "Gray" }
}
else { Write-Log ".agent_tmp does not exist. Skipping." -Color "Gray" }

# ---- 2. Clean .agent_reports/ ----
$rptDir = Join-Path -Path $Root -ChildPath ".agent_reports"
if (Test-Path -LiteralPath $rptDir) {
    Write-Log "Scanning .agent_reports (cutoff: $($cutoffReport.ToString('yyyy-MM-dd')))" -Color "Cyan"
    $files = Get-ChildItem -LiteralPath $rptDir -File -ErrorAction SilentlyContinue
    $found = $false
    foreach ($f in $files) {
        if ($f.LastWriteTime -lt $cutoffReport) {
            $found = $true
            $rel = Get-RelativePath -FullPath $f.FullName
            $age = [Math]::Floor(((Get-Date) - $f.LastWriteTime).TotalDays)
            [void]$log.Add("$actionLabel report: $rel (age: ${age}d)")
            if ($DryRun) { Write-Log "[DRY RUN] Would delete expired report: $rel (age: ${age}d)" -Color "Yellow" }
            else {
                try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
                      Write-Log "Deleted: $rel" -Color "Green"; $deleted.Reports++ }
                catch { Write-Log "FAILED: $rel - $_" -Color "Red"
                        [void]$log.Add("FAILED: $rel - $_") }
            }
        }
    }
    if (-not $found) { Write-Log "No expired reports found." -Color "Gray" }
}
else { Write-Log ".agent_reports does not exist. Skipping." -Color "Gray" }

# ---- 3. Root-level suspicious (only with -ConfirmClean) ----
if ($ConfirmClean) {
    Write-Log "ConfirmClean: checking root-level suspicious files..." -Color "Cyan"
    $rootFiles = Get-ChildItem -LiteralPath $Root -File -ErrorAction SilentlyContinue
    $found = $false
    foreach ($f in $rootFiles) {
        $match = $false
        foreach ($p in $forbiddenRootPatterns) {
            if ($f.Name -match $p) { $match = $true; break }
        }
        if ($match) {
            $found = $true
            $rel = Get-RelativePath -FullPath $f.FullName
            [void]$log.Add("$actionLabel root-level: $rel")
            if ($DryRun) { Write-Log "[DRY RUN] Would delete root-level: $rel" -Color "Yellow" }
            else {
                try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
                      Write-Log "Deleted: $rel" -Color "Green"; $deleted.RootSuspicious++ }
                catch { Write-Log "FAILED: $rel - $_" -Color "Red"
                        [void]$log.Add("FAILED: $rel - $_") }
            }
        }
    }
    if (-not $found) { Write-Log "No root-level suspicious files to clean." -Color "Gray" }
}
else { Write-Log "Skipping root-level. Use -ConfirmClean to include." -Color "Gray" }

# ---- Summary ----
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cleanup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
if ($DryRun) { Write-Host "  Mode: DRY RUN — no files deleted." -ForegroundColor Yellow }
Write-Host "  .agent_tmp files:      $($deleted.Tmp) $(if ($DryRun) { 'would be deleted' } else { 'deleted' })"
Write-Host "  .agent_reports files:  $($deleted.Reports) $(if ($DryRun) { 'would be deleted' } else { 'deleted' })"
Write-Host "  Root-level suspicious: $($deleted.RootSuspicious) $(if ($DryRun) { 'would be deleted' } else { 'deleted' })"
Write-Host "========================================" -ForegroundColor Cyan

$logDir = Join-Path -Path $Root -ChildPath ".agent_reports"
if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path -Path $logDir -ChildPath "cleanup_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"
($log -join "`n") | Out-File -FilePath $logFile -Encoding utf8

Write-Host "`nLog: $logFile" -ForegroundColor Cyan
Write-Host "`nRun with -DryRun:$false for actual cleanup."
Write-Host "Add -ConfirmClean to include root-level suspicious files." -ForegroundColor Gray

