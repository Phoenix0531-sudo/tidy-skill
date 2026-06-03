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
    Cross-compatible with PowerShell 5+ and PowerShell 7+.

.EXAMPLE
    .\audit-agent-artifacts.ps1 -Root "C:\Projects\MyApp"

.EXAMPLE
    .\audit-agent-artifacts.ps1 -Root "C:\Projects\MyApp" -ReportPath "C:\reports\audit.md" -MaxDepth 5

.NOTES
    This script is read-only. It does not delete or modify any files.
    It does not upload or transmit any data.
    Safe for PowerShell 5.1+ and PowerShell 7+.
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

# ---- Utility functions ----

function Get-RelativePath {
    param([string]$FullPath)
    $rel = $FullPath.Substring($Root.Length).TrimStart('\').TrimStart('/')
    if ($rel -eq '') { return '.' }
    return $rel
}

function Format-FileSize {
    param([long]$Bytes)
    if ($Bytes -ge 1MB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Get-FilesRecursive {
    param([string]$Path, [int]$Depth)

    if ($Depth -le 0) {
        # Depth 0 = current directory only (no recursion)
        return Get-ChildItem -LiteralPath $Path -File -ErrorAction SilentlyContinue
    }

    # PowerShell 5.0+ supports -Depth; fallback to full recursion for older versions
    try {
        $files = Get-ChildItem -LiteralPath $Path -Recurse -File -Depth $Depth -ErrorAction Stop
        return $files
    }
    catch {
        # Fallback: get files and filter by depth manually
        $files = Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue
        $rootNormalized = $Path.TrimEnd('\').TrimEnd('/')
        return $files | Where-Object {
            $parent = $_.DirectoryName
            $rel = $parent.Substring($rootNormalized.Length).TrimStart('\').TrimStart('/')
            if ($rel -eq '') { return $true } # direct child
            $level = $rel.Split([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar).Count
            return $level -le $Depth
        }
    }
}

# ---- Classification patterns ----

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

$skipDirPatterns = @(
    '\.git',
    'node_modules',
    'dist',
    'build',
    'target',
    '\.venv',
    'venv',
    '__pycache__',
    '\.next',
    '\.nuxt',
    'bin',
    'obj',
    'packages'
)

# ---- Resolve root path ----
$Root = (Resolve-Path -LiteralPath $Root).Path

Write-Host "Scanning: $Root" -ForegroundColor Cyan
Write-Host "Max depth: $MaxDepth" -ForegroundColor Cyan
Write-Host ""

# ---- Scan ----
$results = @{
    AgentTmp       = @()
    AgentReports   = @()
    RootSuspicious = @()
    ProtectedDocs  = @()
}

# Determine PowerShell version for compatibility info
$psVersion = $PSVersionTable.PSVersion.ToString()

$allFiles = Get-FilesRecursive -Path $Root -Depth $MaxDepth

foreach ($file in $allFiles) {
    $relPath = Get-RelativePath -FullPath $file.FullName
    $relDir = [System.IO.Path]::GetDirectoryName($relPath)
    if ($relDir -eq '.') { $relDir = '' }

    # Skip files inside skip directories
    $shouldSkip = $false
    foreach ($skip in $skipDirPatterns) {
        if ($relPath -match "(^|\\)$skip(\\)|(^|/)$skip(/)") {
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

$reportLines = [System.Collections.ArrayList]@()

[void]$reportLines.Add("# Agent Artifact Audit Report")
[void]$reportLines.Add("")
[void]$reportLines.Add("**Project root:** `$Root`")
[void]$reportLines.Add("**Scan time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$reportLines.Add("**Max depth:** $MaxDepth")
[void]$reportLines.Add("**PowerShell version:** $psVersion")
[void]$reportLines.Add("")
[void]$reportLines.Add("---")
[void]$reportLines.Add("")

# 1. Suspicious root-level files
[void]$reportLines.Add("## Suspicious root-level Markdown files")
[void]$reportLines.Add("")
[void]$reportLines.Add("These files match known agent-produce patterns and are in the project root.")
[void]$reportLines.Add("They are **not deleted automatically**. Review and decide.")
[void]$reportLines.Add("")
if ($results.RootSuspicious.Count -eq 0) {
    [void]$reportLines.Add("_None found._")
}
else {
    [void]$reportLines.Add("| File | Size | Last modified |")
    [void]$reportLines.Add("|---|---|---|")
    foreach ($f in $results.RootSuspicious) {
        [void]$reportLines.Add("| $($f.Name) | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |")
    }
}
[void]$reportLines.Add("")

# 2. Agent tmp files
[void]$reportLines.Add("## Temporary artifacts (`.agent_tmp/`)")
[void]$reportLines.Add("")
if ($results.AgentTmp.Count -eq 0) {
    [void]$reportLines.Add("_Empty or no directory found._")
}
else {
    [void]$reportLines.Add("| File | Size | Last modified |")
    [void]$reportLines.Add("|---|---|---|")
    foreach ($f in $results.AgentTmp) {
        $rel = Get-RelativePath -FullPath $f.FullName
        [void]$reportLines.Add("| $rel | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |")
    }
}
[void]$reportLines.Add("")

# 3. Agent reports
[void]$reportLines.Add("## Persistent reports (`.agent_reports/`)")
[void]$reportLines.Add("")
if ($results.AgentReports.Count -eq 0) {
    [void]$reportLines.Add("_Empty or no directory found._")
}
else {
    [void]$reportLines.Add("| File | Size | Last modified |")
    [void]$reportLines.Add("|---|---|---|")
    foreach ($f in $results.AgentReports) {
        $rel = Get-RelativePath -FullPath $f.FullName
        [void]$reportLines.Add("| $rel | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |")
    }
}
[void]$reportLines.Add("")

# 4. Protected docs found
[void]$reportLines.Add("## Protected documentation found")
[void]$reportLines.Add("")
if ($results.ProtectedDocs.Count -eq 0) {
    [void]$reportLines.Add("_None found._")
}
else {
    [void]$reportLines.Add("| File | Size | Last modified |")
    [void]$reportLines.Add("|---|---|---|")
    foreach ($f in $results.ProtectedDocs) {
        [void]$reportLines.Add("| $($f.Name) | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |")
    }
}
[void]$reportLines.Add("")
[void]$reportLines.Add("---")
[void]$reportLines.Add("")

# 5. Summary and suggestions
[void]$reportLines.Add("## Summary")
[void]$reportLines.Add("")
[void]$reportLines.Add("- **Suspicious root-level files:** $($results.RootSuspicious.Count) (review manually)")
[void]$reportLines.Add("- **Temporary artifacts (`.agent_tmp/`):** $($results.AgentTmp.Count)")
[void]$reportLines.Add("- **Persistent reports (`.agent_reports/`):** $($results.AgentReports.Count)")
[void]$reportLines.Add("- **Protected docs:** $($results.ProtectedDocs.Count) (not touched)")
[void]$reportLines.Add("")
[void]$reportLines.Add("## Suggested actions")
[void]$reportLines.Add("")

if ($results.RootSuspicious.Count -gt 0) {
    [void]$reportLines.Add("1. Review each suspicious root-level file. If no longer needed, delete it manually or move to the appropriate directory.")
}
if ($results.AgentTmp.Count -gt 0) {
    [void]$reportLines.Add("2. Review `.agent_tmp/` contents. Files older than 7 days are candidates for cleanup.")
}
if ($results.AgentReports.Count -gt 0) {
    [void]$reportLines.Add("3. Review `.agent_reports/` contents. Files older than 30 days are candidates for archival or deletion.")
}
if ($results.RootSuspicious.Count -eq 0 -and $results.AgentTmp.Count -eq 0 -and $results.AgentReports.Count -eq 0) {
    [void]$reportLines.Add("- No agent-generated artifacts found. The project is clean.")
}
[void]$reportLines.Add("")
[void]$reportLines.Add("**Next step:** Run the cleanup script with `-DryRun` to preview what would be cleaned:")
[void]$reportLines.Add("")
[void]$reportLines.Add("```powershell")
[void]$reportLines.Add("powershell -ExecutionPolicy Bypass -File scripts\clean-agent-artifacts.ps1 -Root `"$Root`" -DryRun")
[void]$reportLines.Add("```")
[void]$reportLines.Add("")

# Write report
$reportContent = $reportLines -join "`n"
$reportContent | Out-File -FilePath $ReportPath -Encoding utf8

Write-Host "" -ForegroundColor Green
Write-Host "Audit complete." -ForegroundColor Green
Write-Host "Report written to: $ReportPath" -ForegroundColor Cyan

# Console summary
Write-Host "" -ForegroundColor Yellow
Write-Host "--- Summary ---" -ForegroundColor Yellow
$suspiciousColor = if ($results.RootSuspicious.Count -gt 0) { "Red" } else { "Green" }
Write-Host "Suspicious root-level files: $($results.RootSuspicious.Count)" -ForegroundColor $suspiciousColor
Write-Host "Temporary artifacts (tmp):    $($results.AgentTmp.Count)"
Write-Host "Persistent reports (reports): $($results.AgentReports.Count)"
Write-Host "Protected docs:               $($results.ProtectedDocs.Count)"
Write-Host ""

# Return summary object
return @{
    ReportPath = $ReportPath
    Summary = @{
        SuspiciousRoot = $results.RootSuspicious.Count
        AgentTmp       = $results.AgentTmp.Count
        AgentReports   = $results.AgentReports.Count
        ProtectedDocs  = $results.ProtectedDocs.Count
    }
}
