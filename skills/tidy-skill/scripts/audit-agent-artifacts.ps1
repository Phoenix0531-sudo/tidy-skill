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

.PARAMETER Policy
    Optional policy JSON path. When omitted, discovers .tidy-skill.json
    or tidy-skill.policy.json under Root.

.EXAMPLE
    .\audit-agent-artifacts.ps1 -Root "C:\Projects\MyApp"

.EXAMPLE
    .\audit-agent-artifacts.ps1 -Root "C:\Projects\MyApp" -ReportPath "C:\reports\audit.md" -MaxDepth 5

.NOTES
    Part of tidy-skill. Read-only. Never modifies files. Never uploads data.
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
    [int]$MaxDepth = 3,

    [Parameter(Mandatory = $false)]
    [string]$Policy
)

. (Join-Path $PSScriptRoot 'Policy.ps1')

# ---- Helpers ----

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
        return Get-ChildItem -LiteralPath $Path -File -ErrorAction SilentlyContinue
    }

    try {
        $files = Get-ChildItem -LiteralPath $Path -Recurse -File -Depth $Depth -ErrorAction Stop
        return $files
    }
    catch {
        $files = Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue
        $rootNorm = $Path.TrimEnd('\').TrimEnd('/')
        return $files | Where-Object {
            $parent = $_.DirectoryName
            $rel = $parent.Substring($rootNorm.Length).TrimStart('\').TrimStart('/')
            if ($rel -eq '') { return $true }
            $level = $rel.Split([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar).Count
            return $level -le $Depth
        }
    }
}

# ---- Patterns ----

$skipDirPatterns = @(
    '\.git', 'node_modules', 'dist', 'build', 'target',
    '\.venv', 'venv', '__pycache__', '\.next', '\.nuxt',
    'bin', 'obj', 'packages'
)

# ---- Resolve ----
$Root = (Resolve-Path -LiteralPath $Root).Path
$tidyPolicy = Get-TidyPolicy -Root $Root -PolicyPath $Policy

Write-Host "tidy-skill - Artifact Audit" -ForegroundColor Cyan
Write-Host "Scanning: $Root" -ForegroundColor Cyan
Write-Host "Max depth: $MaxDepth" -ForegroundColor Cyan
if ($tidyPolicy.Source) {
    Write-Host "Policy: $($tidyPolicy.Source)" -ForegroundColor DarkGray
}
Write-Host ""

# ---- Scan ----
$results = @{
    AgentTmp       = New-Object System.Collections.ArrayList
    AgentReports   = New-Object System.Collections.ArrayList
    RootSuspicious = New-Object System.Collections.ArrayList
    ProtectedDocs  = New-Object System.Collections.ArrayList
}

$allFiles = Get-FilesRecursive -Path $Root -Depth $MaxDepth

foreach ($file in $allFiles) {
    $relPath = Get-RelativePath -FullPath $file.FullName
    $relDir = [System.IO.Path]::GetDirectoryName($relPath)
    if ($relDir -eq '.') { $relDir = '' }

    $shouldSkip = $false
    foreach ($skip in $skipDirPatterns) {
        if ($relPath -match "(^|\\)$skip(\\)|(^|/)$skip(/)") {
            $shouldSkip = $true
            break
        }
    }
    if ($shouldSkip) { continue }

    if ($relDir -eq '.agent_tmp' -or $relPath -match '^\.agent_tmp[\\/]') {
        [void]$results.AgentTmp.Add($file)
    }
    elseif ($relDir -eq '.agent_reports' -or $relPath -match '^\.agent_reports[\\/]') {
        [void]$results.AgentReports.Add($file)
    }
    elseif ($relDir -eq '' -or $relDir -eq '.') {
        $name = $file.Name
        if (Test-TidyProtectedName -Name $name -Policy $tidyPolicy) {
            [void]$results.ProtectedDocs.Add($file)
        }
        elseif (Test-TidyForbiddenName -Name $name -Policy $tidyPolicy) {
            [void]$results.RootSuspicious.Add($file)
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

$lines = [System.Collections.ArrayList]@()
[void]$lines.Add("# tidy-skill - Artifact Audit Report")
[void]$lines.Add("")
[void]$lines.Add( ("**Project root:** '{0}'" -f $Root).Replace("'", '`') )
[void]$lines.Add("**Scan time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$lines.Add("**Max depth:** $MaxDepth")
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")

# 1. Root suspicious
[void]$lines.Add("## Suspicious Root-Level Files")
[void]$lines.Add("")
[void]$lines.Add("These match known agent-produce patterns and sit in the project root. **Reported, not deleted.**")
[void]$lines.Add("")
if ($results.RootSuspicious.Count -eq 0) {
    [void]$lines.Add("_None found._")
}
else {
    [void]$lines.Add("| File | Size | Last modified |")
    [void]$lines.Add("|---|---|---|")
    foreach ($f in $results.RootSuspicious) {
        [void]$lines.Add("| $($f.Name) | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |")
    }
}
[void]$lines.Add("")

# 2. agent_tmp
[void]$lines.Add("## Temporary Artifacts (`.agent_tmp/`)")
[void]$lines.Add("")
if ($results.AgentTmp.Count -eq 0) {
    [void]$lines.Add("_Empty or no directory found._")
}
else {
    [void]$lines.Add("| File | Size | Last modified |")
    [void]$lines.Add("|---|---|---|")
    foreach ($f in $results.AgentTmp) {
        [void]$lines.Add("| $(Get-RelativePath $f.FullName) | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |")
    }
}
[void]$lines.Add("")

# 3. agent_reports
[void]$lines.Add("## Persistent Reports (`.agent_reports/`)")
[void]$lines.Add("")
if ($results.AgentReports.Count -eq 0) {
    [void]$lines.Add("_Empty or no directory found._")
}
else {
    [void]$lines.Add("| File | Size | Last modified |")
    [void]$lines.Add("|---|---|---|")
    foreach ($f in $results.AgentReports) {
        [void]$lines.Add("| $(Get-RelativePath $f.FullName) | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |")
    }
}
[void]$lines.Add("")

# 4. Protected docs
[void]$lines.Add("## Protected Documentation Found")
[void]$lines.Add("")
if ($results.ProtectedDocs.Count -eq 0) {
    [void]$lines.Add("_None found._")
}
else {
    [void]$lines.Add("| File | Size | Last modified |")
    [void]$lines.Add("|---|---|---|")
    foreach ($f in $results.ProtectedDocs) {
        [void]$lines.Add("| $($f.Name) | $(Format-FileSize $f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |")
    }
}
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")

# 5. Summary
[void]$lines.Add("## Summary")
[void]$lines.Add("")
[void]$lines.Add("- **Suspicious root-level files:** $($results.RootSuspicious.Count) (review manually)")
[void]$lines.Add("- **Temporary artifacts:** $($results.AgentTmp.Count)")
[void]$lines.Add("- **Persistent reports:** $($results.AgentReports.Count)")
[void]$lines.Add("- **Protected docs:** $($results.ProtectedDocs.Count) (never touched)")
[void]$lines.Add("")

[void]$lines.Add("## Suggested Actions")
[void]$lines.Add("")
if ($results.RootSuspicious.Count -gt 0) {
    [void]$lines.Add("1. Review root-level suspicious files. Delete or move to appropriate directories.")
}
if ($results.AgentTmp.Count -gt 0) {
    [void]$lines.Add("2. Check `.agent_tmp/`. Files older than 7 days are cleanup candidates.")
}
if ($results.AgentReports.Count -gt 0) {
    [void]$lines.Add("3. Check `.agent_reports/`. Files older than 30 days are cleanup candidates.")
}
if ($results.RootSuspicious.Count -eq 0 -and $results.AgentTmp.Count -eq 0 -and $results.AgentReports.Count -eq 0) {
    [void]$lines.Add("- No agent artifacts found. This repo is clean.")
}
[void]$lines.Add("")

$reportContent = $lines -join "`n"
$reportContent | Out-File -FilePath $ReportPath -Encoding utf8

Write-Host "Audit complete." -ForegroundColor Green
Write-Host "Report: $ReportPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "--- Summary ---" -ForegroundColor Yellow
Write-Host "Suspicious root files: $($results.RootSuspicious.Count)" -ForegroundColor $(if ($results.RootSuspicious.Count -gt 0) { 'Red' } else { 'Green' })
Write-Host "Temporary artifacts:   $($results.AgentTmp.Count)"
Write-Host "Persistent reports:    $($results.AgentReports.Count)"
Write-Host "Protected docs:        $($results.ProtectedDocs.Count)"

return @{
    ReportPath = $ReportPath
    Summary = @{
        SuspiciousRoot = $results.RootSuspicious.Count
        AgentTmp       = $results.AgentTmp.Count
        AgentReports   = $results.AgentReports.Count
        ProtectedDocs  = $results.ProtectedDocs.Count
    }
}

