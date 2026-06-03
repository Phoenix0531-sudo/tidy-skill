<#
.SYNOPSIS
    Audit a project directory for AI agent-generated artifacts.

.DESCRIPTION
    Scans a project root for temporary agent files, user-requested reports,
    and suspicious root-level Markdown that may be agent litter. Produces a
    read-only Markdown report. No files are modified.

.PARAMETER Root
    Path to the project root directory to audit.

.PARAMETER ReportPath
    Path where the audit report should be written. Defaults to
    "$Root\.agent_reports\audit_<timestamp>.md".

.PARAMETER MaxDepth
    Maximum subdirectory depth to scan. Default 3. Use 0 for current dir only.

.EXAMPLE
    .\audit-agent-artifacts.ps1 -Root "C:\Projects\MyApp"

.EXAMPLE
    .\audit-agent-artifacts.ps1 -Root "C:\Projects\MyApp" -ReportPath "C:\reports\audit.md" -MaxDepth 5

.NOTES
    This script is read-only. It does not delete or modify any files.
    It does not upload or transmit any data.
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$Root,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 10)]
    [int]$MaxDepth = 3
)

# ---- Utility ----
function Get-RelativePath {
    param([string]$FullPath)
    return $FullPath.Substring($Root.Length).TrimStart('\').TrimStart('/')
}

function Format-FileSize {
    param([long]$Bytes)
    if ($Bytes -ge 1MB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

# ---- Classification helpers ----
$forbiddenRootPatterns = @(
    '^todo\.md$',
    '^plan\.md$',
    '^notes\.md$',
    '^lessons\.md$',
    '^summary\.md$',
    '^report\.md$',
    '^final_report\.md$',
    '^implementation_plan\.md$',
    '^migration_plan\.md$',
    '^audit_report\.md$',
    '^cleanup_report\.md$',
    '^task_list\.md$',
    '^progress\.md$',
    '^work_summary\.md$',
    '^changes_summary\.md$',
    '^.+_summary\.md$',
    '^.+_report\.md$',
    '^.+_plan\.md$'
)

$protectedDocPatterns = @(
    '^README\.md$',
    '^README\..+\.md$',
    '^CHANGELOG\.md$',
    '^LICENSE$',
    '^LICENSE\..+$',
    '^CONTRIBUTING\.md$',
    '^CODE_OF_CONDUCT\.md$',
    '^SECURITY\.md$'
)

$skipDirs = @(
    '.git', 'node_modules', 'dist', 'build', 'target',
    '.venv', 'venv', '__pycache__', '.next', '.nuxt',
    'bin', 'obj', 'packages'
)

# ---- Resolve path ----
$Root = (Resolve-Path -LiteralPath $Root).Path

# ---- Scan ----
$results = @{
    AgentTmp     = @()
    AgentReports = @()
    RootSuspicious = @()
    ProtectedDocs   = @()
    SkippedDirs     = @()
}

Write-Host "Scanning: $Root" -ForegroundColor Cyan
Write-Host "Max depth: $MaxDepth" -ForegroundColor Cyan

# Get all files with bounded depth
$allFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -Depth $MaxDepth -ErrorAction SilentlyContinue

foreach ($file in $allFiles) {
    $relPath = Get-RelativePath -FullPath $file.FullName
    $relDir = [System.IO.Path]::GetDirectoryName($relPath)

    # Check if file is inside a skip directory
    $shouldSkip = $false
    foreach ($skip in $skipDirs) {
        if ($relPath -match "(^|\\|\/)$skip($|\\|\/)") {
            $shouldSkip = $true
            break
        }
    }
    if ($shouldSkip) { continue }

    # Classify
    if ($relDir -eq '.agent_tmp' -or $relPath -match '^\.agent_tmp[\\/]') {
        $results.AgentTmp += $file
    }
    elseif ($relDir -eq '.agent_reports' -or $relPath -match '^\.agent_reports[\\/]') {
        $results.AgentReports += $file
    }
    elseif ($relDir -eq '' -or $relDir -eq '.') {
        # Root-level file classification
        $name = $file.Name
        $isProtected = $false
        foreach ($p in $protectedDocPatterns) {
            if ($name -match $p) { $isProtected = $true; break }
        }
        if ($isProtected) {
            $results.ProtectedDocs += $file
        }
        else {
            $isSuspicious = $false
            foreach ($p in $forbiddenRootPatterns) {
                if ($name -match $p) { $isSuspicious = $true; break }
            }
            if ($isSuspicious) {
                $results.RootSuspicious += $file
            }
        }
    }
}

# ---- Generate Report ----
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
if (-not $ReportPath) {
    $reportDir = Join-Path -Path $Root -ChildPath ".agent_reports"
    if (-not (Test-Path -LiteralPath $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    $ReportPath = Join-Path -Path $reportDir -ChildPath "audit_$timestamp.md"
}

$reportLines = @()

$reportLines += "# Agent Artifact Audit Report"
$reportLines += ""
$reportLines += "**Project root:** `$Root`"
$reportLines += "**Scan time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$reportLines += "**Max depth:** $MaxDepth"
$reportLines += ""
$reportLines += "---"
$reportLines += ""

# 1. Suspicious root-level files
$reportLines += "## Suspicious root-level Markdown files"
$reportLines += ""
$reportLines += "These files match known agent-produce patterns and are in the project root."
$reportLines += "They are **not deleted automatically**. Review and decide."
$reportLines += ""
if ($results.RootSuspicious.Count -eq 0) {
    $reportLines += "_None found._"
}
else {
    $reportLines += "| File | Size | Last modified |"
    $reportLines += "|---|---|---|"
    foreach ($f in $results.RootSuspicious) {
        $reportLines += "| $($f.Name) | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |"
    }
}
$reportLines += ""

# 2. Agent tmp files
$reportLines += "## Temporary artifacts (`.agent_tmp/`)"
$reportLines += ""
if ($results.AgentTmp.Count -eq 0) {
    $reportLines += "_Empty or no directory found._"
}
else {
    $reportLines += "| File | Size | Last modified |"
    $reportLines += "|---|---|---|"
    foreach ($f in $results.AgentTmp) {
        $rel = Get-RelativePath -FullPath $f.FullName
        $reportLines += "| $rel | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |"
    }
}
$reportLines += ""

# 3. Agent reports
$reportLines += "## Persistent reports (`.agent_reports/`)"
$reportLines += ""
if ($results.AgentReports.Count -eq 0) {
    $reportLines += "_Empty or no directory found._"
}
else {
    $reportLines += "| File | Size | Last modified |"
    $reportLines += "|---|---|---|"
    foreach ($f in $results.AgentReports) {
        $rel = Get-RelativePath -FullPath $f.FullName
        $reportLines += "| $rel | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |"
    }
}
$reportLines += ""

# 4. Protected docs found
$reportLines += "## Protected documentation found"
$reportLines += ""
if ($results.ProtectedDocs.Count -eq 0) {
    $reportLines += "_None found._"
}
else {
    $reportLines += "| File | Size | Last modified |"
    $reportLines += "|---|---|---|"
    foreach ($f in $results.ProtectedDocs) {
        $reportLines += "| $($f.Name) | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |"
    }
}
$reportLines += ""
$reportLines += "---"
$reportLines += ""

# 5. Summary and suggestions
$reportLines += "## Summary"
$reportLines += ""
$reportLines += "- **Suspicious root-level files:** $($results.RootSuspicious.Count) (review manually)"
$reportLines += "- **Temporary artifacts (`.agent_tmp/`):** $($results.AgentTmp.Count)"
$reportLines += "- **Persistent reports (`.agent_reports/`):** $($results.AgentReports.Count)"
$reportLines += "- **Protected docs:** $($results.ProtectedDocs.Count) (not touched)"
$reportLines += ""
$reportLines += "## Suggested actions"
$reportLines += ""

if ($results.RootSuspicious.Count -gt 0) {
    $reportLines += "1. Review each suspicious root-level file. If it is no longer needed, delete it manually or move it to the appropriate directory."
}
if ($results.AgentTmp.Count -gt 0) {
    $reportLines += "2. Review `.agent_tmp/` contents. Files older than 7 days are candidates for cleanup."
}
if ($results.AgentReports.Count -gt 0) {
    $reportLines += "3. Review `.agent_reports/` contents. Files older than 30 days are candidates for archival or deletion."
}
if ($results.RootSuspicious.Count -eq 0 -and $results.AgentTmp.Count -eq 0 -and $results.AgentReports.Count -eq 0) {
    $reportLines += "- No agent-generated artifacts found. The project is clean."
}
$reportLines += ""
$reportLines += "**Next step:** Run the cleanup script with `-DryRun` to preview what would be cleaned:"
$reportLines += ""
$reportLines += '```powershell'
$reportLines += "powershell -ExecutionPolicy Bypass -File scripts\clean-agent-artifacts.ps1 -Root `"$Root`" -DryRun"
$reportLines += '```'
$reportLines += ""

# Write report
$reportContent = $reportLines -join "`n"
$reportContent | Out-File -FilePath $ReportPath -Encoding utf8

Write-Host "`nAudit complete." -ForegroundColor Green
Write-Host "Report written to: $ReportPath" -ForegroundColor Cyan

# Console summary
Write-Host "`n--- Summary ---" -ForegroundColor Yellow
Write-Host "Suspicious root-level files: $($results.RootSuspicious.Count)" -ForegroundColor $(if ($results.RootSuspicious.Count -gt 0) { "Red" } else { "Green" })
Write-Host "Temporary artifacts: $($results.AgentTmp.Count)"
Write-Host "Persistent reports: $($results.AgentReports.Count)"
Write-Host "Protected docs: $($results.ProtectedDocs.Count)"

return @{
    ReportPath = $ReportPath
    Summary = @{
        SuspiciousRoot = $results.RootSuspicious.Count
        AgentTmp = $results.AgentTmp.Count
        AgentReports = $results.AgentReports.Count
        ProtectedDocs = $results.ProtectedDocs.Count
    }
}
