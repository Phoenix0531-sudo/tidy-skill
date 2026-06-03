<#
.SYNOPSIS
    Clean AI agent-generated artifacts from a project directory.

.DESCRIPTION
    Performs conservative cleanup of agent temporary files and expired reports.
    Defaults to DryRun mode — no files are deleted unless -DryRun is $false.
    Does not delete formal documentation, source code, tool state, or
    suspicious root-level files without explicit confirmation.

.PARAMETER Root
    Path to the project root directory to clean.

.PARAMETER TmpRetentionDays
    Age in days after which files in .agent_tmp/ are eligible for deletion.
    Default 7.

.PARAMETER ReportRetentionDays
    Age in days after which files in .agent_reports/ are eligible for deletion.
    Default 30.

.PARAMETER DryRun
    When $true (default), lists what would be deleted without deleting anything.

.PARAMETER ConfirmClean
    When specified, also cleans suspicious root-level Markdown files that match
    known agent-produce patterns. Requires explicit user confirmation.
    Default $false.

.EXAMPLE
    .\clean-agent-artifacts.ps1 -Root "C:\Projects\MyApp"
    # DryRun only — shows what would be cleaned.

.EXAMPLE
    .\clean-agent-artifacts.ps1 -Root "C:\Projects\MyApp" -DryRun:$false -TmpRetentionDays 3
    # Actually cleans .agent_tmp/ files older than 3 days.

.EXAMPLE
    .\clean-agent-artifacts.ps1 -Root "C:\Projects\MyApp" -DryRun -ConfirmClean
    # DryRun that also includes root-level suspicious files in preview.

.NOTES
    Safety: never deletes Git-tracked files by default.
    Never deletes files under docs/, src/, or protected doc names.
    Never requires administrator privileges.
    Never uploads or transmits data.
    Safe for PowerShell 5.1+ and PowerShell 7+.
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

$protectedDocNames = @(
    'README.md', 'CHANGELOG.md', 'LICENSE', 'CONTRIBUTING.md',
    'CODE_OF_CONDUCT.md', 'SECURITY.md'
)

# Note: These patterns match files in the root. *_summary.md, *_report.md, *_plan.md
# are broad patterns — used here only with ConfirmClean.
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

function Is-InSkipDirectory {
    param([string]$Path)
    $normalized = $Path.Replace('/', '\').ToLowerInvariant()
    $rootNorm = $Root.Replace('/', '\').TrimEnd('\').ToLowerInvariant()
    $relative = $normalized.Substring($rootNorm.Length).TrimStart('\')
    foreach ($skip in $skipDirPatterns) {
        # Check if any path segment matches
        $segments = $relative.Split('\')
        foreach ($seg in $segments) {
            if ($seg -eq $skip.TrimStart('\.')) { return $true }
            if ($seg -eq $skip) { return $true }
        }
    }
    return $false
}

# ---- Resolve path ----
$Root = (Resolve-Path -LiteralPath $Root).Path

# ---- Display mode banner ----
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Agent Artifact Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Root:             $Root"
Write-Host "Mode:             $(if ($DryRun) { 'DRY RUN (no files will be deleted)' } else { 'LIVE (files WILL be deleted)' })"
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
$tmpRoot = Join-Path -Path $Root -ChildPath ".agent_tmp"
if (Test-Path -LiteralPath $tmpRoot) {
    Write-Log "Scanning .agent_tmp (cutoff: $($cutoffTmp.ToString('yyyy-MM-dd')))" -Color "Cyan"
    $tmpFiles = Get-ChildItem -LiteralPath $tmpRoot -File -ErrorAction SilentlyContinue
    $found = $false

    foreach ($f in $tmpFiles) {
        if ($f.LastWriteTime -lt $cutoffTmp) {
            $found = $true
            $rel = Get-RelativePath -FullPath $f.FullName
            $ageDays = [Math]::Floor(((Get-Date) - $f.LastWriteTime).TotalDays)
            [void]$log.Add("$actionLabel tmp file: $rel (age: ${ageDays}d)")

            if ($DryRun) {
                Write-Log "[DRY RUN] Would delete: $rel (age: ${ageDays}d)" -Color "Yellow"
            } else {
                try {
                    Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
                    Write-Log "Deleted: $rel" -Color "Green"
                    $deleted.Tmp++
                }
                catch {
                    Write-Log "FAILED to delete: $rel - $_" -Color "Red"
                    [void]$log.Add("FAILED to delete tmp file: $rel - $_")
                }
            }
        }
    }

    if (-not $found) {
        Write-Log "No files in .agent_tmp eligible for cleanup." -Color "Gray"
    }
}
else {
    Write-Log ".agent_tmp does not exist. Skipping." -Color "Gray"
}

# ---- 2. Clean .agent_reports/ ----
$reportsRoot = Join-Path -Path $Root -ChildPath ".agent_reports"
if (Test-Path -LiteralPath $reportsRoot) {
    Write-Log "Scanning .agent_reports (cutoff: $($cutoffReport.ToString('yyyy-MM-dd')))" -Color "Cyan"
    $reportFiles = Get-ChildItem -LiteralPath $reportsRoot -File -ErrorAction SilentlyContinue
    $found = $false

    foreach ($f in $reportFiles) {
        if ($f.LastWriteTime -lt $cutoffReport) {
            $found = $true
            $rel = Get-RelativePath -FullPath $f.FullName
            $ageDays = [Math]::Floor(((Get-Date) - $f.LastWriteTime).TotalDays)
            [void]$log.Add("$actionLabel report: $rel (age: ${ageDays}d)")

            if ($DryRun) {
                Write-Log "[DRY RUN] Would delete expired report: $rel (age: ${ageDays}d)" -Color "Yellow"
            } else {
                try {
                    Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
                    Write-Log "Deleted expired report: $rel" -Color "Green"
                    $deleted.Reports++
                }
                catch {
                    Write-Log "FAILED to delete: $rel - $_" -Color "Red"
                    [void]$log.Add("FAILED to delete report: $rel - $_")
                }
            }
        }
    }

    if (-not $found) {
        Write-Log "No expired reports found." -Color "Gray"
    }
}
else {
    Write-Log ".agent_reports does not exist. Skipping." -Color "Gray"
}

# ---- 3. Root-level suspicious files (only with -ConfirmClean) ----
if ($ConfirmClean) {
    Write-Log "ConfirmClean enabled. Checking root-level suspicious files..." -Color "Cyan"
    $rootFiles = Get-ChildItem -LiteralPath $Root -File -ErrorAction SilentlyContinue
    $found = $false

    foreach ($f in $rootFiles) {
        $shouldDelete = $false
        foreach ($p in $forbiddenRootPatterns) {
            if ($f.Name -match $p) { $shouldDelete = $true; break }
        }
        if ($shouldDelete) {
            $found = $true
            $rel = Get-RelativePath -FullPath $f.FullName
            [void]$log.Add("$actionLabel root-level: $rel")

            if ($DryRun) {
                Write-Log "[DRY RUN] Would delete root-level suspicious: $rel" -Color "Yellow"
            } else {
                try {
                    Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
                    Write-Log "Deleted root-level: $rel" -Color "Green"
                    $deleted.RootSuspicious++
                }
                catch {
                    Write-Log "FAILED to delete: $rel - $_" -Color "Red"
                    [void]$log.Add("FAILED to delete root-level: $rel - $_")
                }
            }
        }
    }

    if (-not $found) {
        Write-Log "No root-level suspicious files to clean." -Color "Gray"
    }
}
else {
    Write-Log "ConfirmClean not set. Skipping root-level suspicious files. Use -ConfirmClean to include them." -Color "Gray"
}

# ---- Summary ----
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cleanup Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  Mode: DRY RUN - no files were actually deleted." -ForegroundColor Yellow
}
Write-Host "  .agent_tmp files:      $($deleted.Tmp) $(if ($DryRun) { 'would be deleted' } else { 'deleted' })"
Write-Host "  .agent_reports files:  $($deleted.Reports) $(if ($DryRun) { 'would be deleted' } else { 'deleted' })"
Write-Host "  Root-level suspicious: $($deleted.RootSuspicious) $(if ($DryRun) { 'would be deleted' } else { 'deleted' })"
Write-Host "========================================" -ForegroundColor Cyan

# Save log
$logDir = Join-Path -Path $Root -ChildPath ".agent_reports"
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile = Join-Path -Path $logDir -ChildPath "cleanup_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"
$logContent = $log -join "`n"
$logContent | Out-File -FilePath $logFile -Encoding utf8

Write-Host ""
Write-Host "Log written to: $logFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tips:" -ForegroundColor Cyan
Write-Host "- Run with -DryRun (default) to preview before deleting."
Write-Host "- Run with -DryRun:`$false to perform actual cleanup."
Write-Host "- Add -ConfirmClean to include root-level suspicious files."
Write-Host "- Run the audit script first to see what exists:"
Write-Host "  .\audit-agent-artifacts.ps1 -Root `"$Root`""
Write-Host ""
