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

.PARAMETER Policy
    Optional policy JSON path. When omitted, discovers .tidy-skill.json
    or tidy-skill.policy.json under Root.

.EXAMPLE
    .\clean-agent-artifacts.ps1 -Root "C:\Projects\MyApp"

.EXAMPLE
    .\clean-agent-artifacts.ps1 -Root "C:\Projects\MyApp" -DryRun:$false

.EXAMPLE
    .\clean-agent-artifacts.ps1 -Root "C:\Projects\MyApp" -ConfirmClean

.NOTES
    Part of tidy-skill. Never modifies system settings.
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
    [switch]$ConfirmClean = $false,

    [Parameter(Mandatory = $false)]
    [string]$Policy
)

. (Join-Path $PSScriptRoot 'Policy.ps1')

# ---- Helpers ----

$skipDirPatterns = @(
    '\.git', 'node_modules', 'dist', 'build', 'target',
    '\.venv', 'venv', '__pycache__', '\.next', '\.nuxt',
    'bin', 'obj', 'packages'
)

$Root = (Resolve-Path -LiteralPath $Root).Path
# Canonicalize $Root so it prefix-matches FullNames returned by Get-ChildItem.
# On Windows CI runners, $env:TEMP often carries an 8.3 short name
# (C:\Users\RUNNER~1\...) while Get-ChildItem returns long-form FullNames
# (C:\Users\runneradmin\...); without canonicalization the substring-based
# Get-RelativePath below mis-strips and root files are dropped from the
# git-tracked check, causing git-tracked files to be wrongly deleted.
$probeDir = Get-Item -LiteralPath $Root
if ($probeDir -and $probeDir.FullName) {
    $Root = $probeDir.FullName.TrimEnd('\').TrimEnd('/')
}
$tidyPolicy = Get-TidyPolicy -Root $Root -PolicyPath $Policy

function Get-RelativePath {
    param([string]$FullPath)
    # Case-insensitive (Windows) prefix match; fall back to ordinal on others.
    if ($FullPath.Length -ge $Root.Length -and $FullPath.Substring(0, $Root.Length) -eq $Root) {
        $rel = $FullPath.Substring($Root.Length).TrimStart('\').TrimStart('/')
    } else {
        # Prefix mismatch (8.3 vs long name, junction, etc.): strip any leading
        # directory components and keep just the file name so root-level files
        # are still attributed to the root bucket instead of being dropped.
        $rel = [System.IO.Path]::GetFileName($FullPath)
    }
    if ($rel -eq '') { return '.' }
    return $rel
}

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $line -ForegroundColor $Color
}

function Test-Command {
    param([string]$Name)
    try {
        Get-Command $Name -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Get-GitTrackedMap {
    param([string]$RepoRoot)
    $tracked = @{}
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot ".git"))) { return $tracked }
    if (-not (Test-Command "git")) { return $tracked }
    try {
        $files = & git -C $RepoRoot ls-files 2>$null
        foreach ($file in $files) {
            if (-not $file) { continue }
            $tracked[$file.Replace('\', '/').ToLowerInvariant()] = $true
        }
    } catch {}
    return $tracked
}

function Test-GitTracked {
    param([string]$RelativePath)
    $key = $RelativePath.Replace('\', '/').ToLowerInvariant()
    return $script:gitTracked.ContainsKey($key)
}

# ---- Resolve ----
# $Root already resolved above for policy loading.

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  tidy-skill - Agent Artifact Cleanup" -ForegroundColor Cyan
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
$deleted = @{ Tmp = 0; Reports = 0; RootSuspicious = 0; GitTrackedSkipped = 0 }
$actionLabel = if ($DryRun) { 'Would delete' } else { 'Deleted' }
$gitTracked = Get-GitTrackedMap -RepoRoot $Root

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
            if (Test-GitTracked -RelativePath $rel) {
                Write-Log "Skipping Git-tracked tmp file: $rel" -Color "Gray"
                [void]$log.Add("Skipped Git-tracked tmp: $rel")
                $deleted.GitTrackedSkipped++
                continue
            }
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
            if (Test-GitTracked -RelativePath $rel) {
                Write-Log "Skipping Git-tracked report: $rel" -Color "Gray"
                [void]$log.Add("Skipped Git-tracked report: $rel")
                $deleted.GitTrackedSkipped++
                continue
            }
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
        $match = Test-TidyForbiddenName -Name $f.Name -Policy $tidyPolicy
        if ($match) {
            $found = $true
            $rel = Get-RelativePath -FullPath $f.FullName
            if (Test-GitTracked -RelativePath $rel) {
                Write-Log "Skipping Git-tracked root-level file: $rel" -Color "Gray"
                [void]$log.Add("Skipped Git-tracked root-level: $rel")
                $deleted.GitTrackedSkipped++
                continue
            }
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
if ($DryRun) { Write-Host "  Mode: DRY RUN - no files deleted." -ForegroundColor Yellow }
Write-Host "  .agent_tmp files:      $($deleted.Tmp) $(if ($DryRun) { 'would be deleted' } else { 'deleted' })"
Write-Host "  .agent_reports files:  $($deleted.Reports) $(if ($DryRun) { 'would be deleted' } else { 'deleted' })"
Write-Host "  Root-level suspicious: $($deleted.RootSuspicious) $(if ($DryRun) { 'would be deleted' } else { 'deleted' })"
Write-Host "  Git-tracked skipped:   $($deleted.GitTrackedSkipped)"
Write-Host "========================================" -ForegroundColor Cyan

$logDir = Join-Path -Path $Root -ChildPath ".agent_reports"
if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path -Path $logDir -ChildPath "cleanup_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"
($log -join "`n") | Out-File -FilePath $logFile -Encoding utf8

Write-Host "`nLog: $logFile" -ForegroundColor Cyan
Write-Host "`nRun with -DryRun:`$false for actual cleanup."
Write-Host "Add -ConfirmClean to include root-level suspicious files." -ForegroundColor Gray

