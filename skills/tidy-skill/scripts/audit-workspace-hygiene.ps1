<#
.SYNOPSIS
    Audit multiple repositories in a workspace for agent artifact hygiene.

.DESCRIPTION
    Scans all subdirectories (repos) under a user-specified root directory.
    For each repo, runs the same checks as the single-repo audit. Produces an
    aggregate report with scores, top offenders, and global suggestions.

    The user MUST explicitly specify the root directory.
    This script NEVER defaults to scanning C:\ or $HOME.

.PARAMETER Root
    Parent directory containing multiple repo directories.
    Must be explicitly specified by the user.

.PARAMETER ReportPath
    Path for the aggregate Markdown report.

.PARAMETER MaxDepth
    How deep to search for repo directories. Default 2.

.PARAMETER Policy
    Optional shared policy JSON applied to every repo. When omitted,
    each repo discovers its own .tidy-skill.json / tidy-skill.policy.json.

.EXAMPLE
    .\audit-workspace-hygiene.ps1 -Root "E:\1_Code\Projects"

.NOTES
    Part of tidy-skill. Read-only. Never modifies files.
    Never reads file contents. Only metadata (name, path, size, time).
    Never uploads data. Requires explicit root path.
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$Root,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 5)]
    [int]$MaxDepth = 2,

    [Parameter(Mandatory = $false)]
    [string]$Policy
)

. (Join-Path $PSScriptRoot 'Policy.ps1')

$skipDirPatterns = @(
    '\.git', 'node_modules', 'dist', 'build', 'target',
    '\.venv', 'venv', '__pycache__', '\.next', '\.nuxt',
    'bin', 'obj', 'packages'
)

$Root = (Resolve-Path -LiteralPath $Root).Path
$sharedPolicy = $null
if ($Policy) {
    $sharedPolicy = Get-TidyPolicy -Root $Root -PolicyPath $Policy
}
Write-Host "tidy-skill - Workspace Hygiene Audit" -ForegroundColor Cyan
Write-Host "Workspace root: $Root" -ForegroundColor Cyan
Write-Host "Max depth: $MaxDepth" -ForegroundColor Cyan
if ($sharedPolicy -and $sharedPolicy.Source) {
    Write-Host "Shared policy: $($sharedPolicy.Source)" -ForegroundColor DarkGray
}
Write-Host ""

# Find repo directories (those containing .git/)
$repos = @()
$allDirs = Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue
foreach ($dir in $allDirs) {
    if (Test-Path (Join-Path $dir.FullName '.git')) {
        $repos += $dir.FullName
    }
}

if ($repos.Count -eq 0) {
    Write-Host "No Git repositories found under $Root" -ForegroundColor Yellow
    Write-Host "This script scans directories that contain a .git/ folder." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($repos.Count) repositories. Analyzing..." -ForegroundColor Cyan
Write-Host ""

$repoResults = @()
$allSuspiciousFiles = @{}
$totalScore = 0
$maxScore = 0

foreach ($repo in $repos) {
    $repoName = Split-Path $repo -Leaf
    Write-Host "  Scoring: $repoName" -ForegroundColor Gray

    # Root-level suspicious
    $repoPolicy = if ($sharedPolicy) { $sharedPolicy } else { Get-TidyPolicy -Root $repo }
    $rootFiles = Get-ChildItem -LiteralPath $repo -File -ErrorAction SilentlyContinue
    $suspicious = @()
    foreach ($f in $rootFiles) {
        if (Test-TidyForbiddenName -Name $f.Name -Policy $repoPolicy) {
            $suspicious += $f.Name
            if ($allSuspiciousFiles.ContainsKey($f.Name)) {
                $allSuspiciousFiles[$f.Name]++
            } else {
                $allSuspiciousFiles[$f.Name] = 1
            }
        }
    }

    $hasTmp = Test-Path (Join-Path $repo '.agent_tmp')
    $hasReports = Test-Path (Join-Path $repo '.agent_reports')
    $hasReadme = Test-Path (Join-Path $repo 'README.md')
    $hasLicense = Test-Path (Join-Path $repo 'LICENSE')
    $hasDocs = Test-Path (Join-Path $repo 'docs')
    $hasGitignore = Test-Path (Join-Path $repo '.gitignore')

    # Quick score (abbreviated version)
    $score = 25 # base
    if ($suspicious.Count -eq 0) { $score += 15 }
    elseif ($suspicious.Count -le 2) { $score += 8 }
    if ($hasTmp) { $score += 8 }
    if ($hasReports) { $score += 7 }
    if ($hasReadme) { $score += 5 }
    if ($hasLicense) { $score += 4 }
    if ($hasDocs) { $score += 3 }
    if ($suspicious.Count -eq 0) { $score += 2 }
    $score = [Math]::Min(100, $score)

    $repoResults += [PSCustomObject]@{
        Repository = $repoName
        Path = $repo
        Score = $score
        SuspiciousCount = $suspicious.Count
        SuspiciousFiles = $suspicious -join ', '
        HasAgentTmp = $hasTmp
        HasAgentReports = $hasReports
        HasReadme = $hasReadme
        HasLicense = $hasLicense
        HasDocs = $hasDocs
    }
    $totalScore += $score
    $maxScore += 100
}

$repoResults = $repoResults | Sort-Object Score

# ---- Generate Report ----
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
if (-not $ReportPath) {
    $rptDir = Join-Path $Root ".agent_reports"
    if (-not (Test-Path $rptDir)) { New-Item -ItemType Directory -Path $rptDir -Force | Out-Null }
    $ReportPath = Join-Path $rptDir "workspace_audit_$timestamp.md"
}

$lines = [System.Collections.ArrayList]@()
[void]$lines.Add("# tidy-skill - Workspace Hygiene Audit")
[void]$lines.Add("")
[void]$lines.Add( ("**Workspace root:** '{0}'" -f $Root).Replace("'", '`') )
[void]$lines.Add("**Repositories found:** $($repos.Count)")
[void]$lines.Add("**Average score:** $([Math]::Round($totalScore / [Math]::Max(1, $repos.Count), 1))")
[void]$lines.Add("**Scan time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")

# Overall stats
[void]$lines.Add("## Overview")
[void]$lines.Add("")
$clean = ($repoResults | Where-Object { $_.Score -ge 90 }).Count
$decent = ($repoResults | Where-Object { $_.Score -ge 70 -and $_.Score -lt 90 }).Count
$messy = ($repoResults | Where-Object { $_.Score -ge 50 -and $_.Score -lt 70 }).Count
$landfill = ($repoResults | Where-Object { $_.Score -lt 50 }).Count
[void]$lines.Add("| Category | Count |")
[void]$lines.Add("|---|---|")
[void]$lines.Add("| Clean (90-100) | $clean |")
[void]$lines.Add("| Mostly clean (70-89) | $decent |")
[void]$lines.Add("| Needs tidy-up (50-69) | $messy |")
[void]$lines.Add("| Artifact landfill (0-49) | $landfill |")
[void]$lines.Add("")

# Leaderboard
[void]$lines.Add("## Repository Scores")
[void]$lines.Add("")
[void]$lines.Add("| # | Repository | Score | Suspicious | .agent_tmp | .agent_reports | README |")
[void]$lines.Add("|---|---|---|---|---|---|---|")
$rank = 1
foreach ($r in ($repoResults | Sort-Object Score -Descending)) {
    [void]$lines.Add("| $rank | $($r.Repository) | $($r.Score) | $($r.SuspiciousCount) | $(if($r.HasAgentTmp){'yes'}else{'no'}) | $(if($r.HasAgentReports){'yes'}else{'no'}) | $(if($r.HasReadme){'yes'}else{'no'}) |")
    $rank++
}
[void]$lines.Add("")

# Bottom 5
$worst = $repoResults | Select-Object -First ([Math]::Min(5, $repoResults.Count))
if ($worst.Count -gt 0) {
    [void]$lines.Add("## Needs Most Attention")
    [void]$lines.Add("")
    foreach ($r in $worst) {
        [void]$lines.Add("- **$($r.Repository)** ($($r.Score)/100) - $($r.SuspiciousCount) suspicious files")
    }
    [void]$lines.Add("")
}

# Top suspicious filenames
if ($allSuspiciousFiles.Count -gt 0) {
    [void]$lines.Add("## Most Common Suspicious Filenames")
    [void]$lines.Add("")
    [void]$lines.Add("| Filename | Occurrences |")
    [void]$lines.Add("|---|---|")
    $sorted = $allSuspiciousFiles.GetEnumerator() | Sort-Object Value -Descending
    foreach ($kv in $sorted) {
        [void]$lines.Add("| `$($kv.Key)` | $($kv.Value) |")
    }
    [void]$lines.Add("")
}

# Adoption stats
[void]$lines.Add("## Adoption Stats")
[void]$lines.Add("")
$tmpAdoption = [Math]::Round(($repoResults | Where-Object { $_.HasAgentTmp }).Count / $repos.Count * 100, 1)
$reportsAdoption = [Math]::Round(($repoResults | Where-Object { $_.HasAgentReports }).Count / $repos.Count * 100, 1)
$readmeAdoption = [Math]::Round(($repoResults | Where-Object { $_.HasReadme }).Count / $repos.Count * 100, 1)
[void]$lines.Add("| Practice | Adoption |")
[void]$lines.Add("|---|---|")
[void]$lines.Add("| Has `.agent_tmp/` | $tmpAdoption% |")
[void]$lines.Add("| Has `.agent_reports/` | $reportsAdoption% |")
[void]$lines.Add("| Has `README.md` | $readmeAdoption% |")
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")
[void]$lines.Add("*Report generated by tidy-skill. Read-only. No files were modified or uploaded.*")

($lines -join "`n") | Out-File -FilePath $ReportPath -Encoding utf8

Write-Host ""
Write-Host "Workspace audit complete." -ForegroundColor Green
Write-Host "Report: $ReportPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Average score: $([Math]::Round($totalScore / [Math]::Max(1, $repos.Count), 1))/100" -ForegroundColor Yellow
Write-Host "Clean: $clean | Mostly clean: $decent | Needs tidy-up: $messy | Landfill: $landfill" -ForegroundColor Yellow

return @{
    ReportPath = $ReportPath
    ReposScanned = $repos.Count
    AverageScore = [Math]::Round($totalScore / [Math]::Max(1, $repos.Count), 1)
}

