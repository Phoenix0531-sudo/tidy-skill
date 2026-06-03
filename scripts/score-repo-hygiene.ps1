<#
.SYNOPSIS
    Score repository hygiene on a 0–100 scale.

.DESCRIPTION
    Evaluates a project directory across six dimensions:
    - Root cleanliness (25 pts)
    - Artifact placement (20 pts)
    - Protected docs clarity (15 pts)
    - Git hygiene (15 pts)
    - Agent state isolation (15 pts)
    - Cleanup readiness (10 pts)

    Produces a Markdown report. Read-only — never modifies files.

.PARAMETER Root
    Project root directory to score.

.PARAMETER ReportPath
    Path for the Markdown report. Defaults to
    "$Root\.agent_reports\hygiene_score_<timestamp>.md".

.EXAMPLE
    .\score-repo-hygiene.ps1 -Root "C:\Projects\MyApp"

.NOTES
    Part of Tidy Skill. Read-only. Never uploads data.
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$Root,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath
)

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

$Root = (Resolve-Path -LiteralPath $Root).Path
Write-Host "Tidy Skill — Repo Hygiene Score" -ForegroundColor Cyan
Write-Host "Scoring: $Root" -ForegroundColor Cyan

# Helper: check if path matches skip pattern
function Is-SkipDir {
    param([string]$RelativePath)
    foreach ($skip in $skipDirPatterns) {
        if ($RelativePath -match "(^|\\)$skip(\\)|(^|/)$skip(/)") { return $true }
    }
    return $false
}

# ---- Dimension 1: Root cleanliness (25 pts) ----
$rootFiles = Get-ChildItem -LiteralPath $Root -File -ErrorAction SilentlyContinue
$rootSuspiciousCount = 0
$rootMarkdownCount = 0
foreach ($f in $rootFiles) {
    if ($f.Extension -eq '.md') { $rootMarkdownCount++ }
    foreach ($p in $forbiddenRootPatterns) {
        if ($f.Name -match $p) { $rootSuspiciousCount++; break }
    }
}
if ($rootSuspiciousCount -eq 0) { $scoreRoot = 25 }
elseif ($rootSuspiciousCount -le 2) { $scoreRoot = 18 }
elseif ($rootSuspiciousCount -le 5) { $scoreRoot = 10 }
else { $scoreRoot = 5 }

# ---- Dimension 2: Artifact placement (20 pts) ----
$hasAgentTmp = Test-Path (Join-Path $Root '.agent_tmp')
$hasAgentReports = Test-Path (Join-Path $Root '.agent_reports')
$rootOnly = 0
# Check if temp files incorrectly in root
foreach ($f in $rootFiles) {
    if ($forbiddenRootPatterns | Where-Object { $f.Name -match $_ }) { $rootOnly++ }
}
$scorePlacement = 0
if ($hasAgentTmp) { $scorePlacement += 8 }
if ($hasAgentReports) { $scorePlacement += 7 }
if ($rootOnly -eq 0) { $scorePlacement += 5 }
elseif ($rootOnly -le 3) { $scorePlacement += 2 }

# ---- Dimension 3: Protected docs clarity (15 pts) ----
$hasReadme = Test-Path (Join-Path $Root 'README.md')
$hasLicense = Test-Path (Join-Path $Root 'LICENSE')
$hasChangelog = Test-Path (Join-Path $Root 'CHANGELOG.md')
$hasDocs = Test-Path (Join-Path $Root 'docs')
$scoreDocs = 0
if ($hasReadme) { $scoreDocs += 5 }
if ($hasLicense) { $scoreDocs += 4 }
if ($hasChangelog) { $scoreDocs += 3 }
if ($hasDocs) { $scoreDocs += 3 }

# ---- Dimension 4: Git hygiene (15 pts) ----
$gitIgnorePath = Join-Path $Root '.gitignore'
$scoreGit = 5  # base: has .git
if (Test-Path $gitIgnorePath) {
    $giContent = Get-Content $gitIgnorePath -Raw -ErrorAction SilentlyContinue
    $scoreGit += 3
    if ($giContent -match '\.agent_tmp') { $scoreGit += 4 }
    if ($giContent -match '\.agent_reports') { $scoreGit += 3 }
}

# ---- Dimension 5: Agent state isolation (15 pts) ----
$stateDirs = @('.codex', '.claude', '.cursor', '.vscode', '.idea')
$stateInProject = 0
foreach ($sd in $stateDirs) {
    if (Test-Path (Join-Path $Root $sd)) { $stateInProject++ }
}
$scoreIsolation = 15  # perfect score
# No deduction for having state dirs — they belong there

# Check if state dirs are mixed with source
if ($hasDocs -or $hasReadme) {
    # Good — project has clear doc structure
    if ($stateInProject -gt 3) { $scoreIsolation = 12 }
}

# ---- Dimension 6: Cleanup readiness (10 pts) ----
$scoreCleanup = 0
if ($hasAgentTmp) { $scoreCleanup += 3 }
if ($hasAgentReports) { $scoreCleanup += 3 }
if ($rootSuspiciousCount -eq 0) { $scoreCleanup += 2 }
if ($hasAgentTmp -or $hasAgentReports) {
    # Check if retention logic could work (files exist)
    $tmpFiles = Get-ChildItem (Join-Path $Root '.agent_tmp') -File -ErrorAction SilentlyContinue
    $rptFiles = Get-ChildItem (Join-Path $Root '.agent_reports') -File -ErrorAction SilentlyContinue
    if ($tmpFiles.Count -gt 0 -or $rptFiles.Count -gt 0) { $scoreCleanup += 2 }
}

# ---- Total ----
$totalScore = $scoreRoot + $scorePlacement + $scoreDocs + $scoreGit + $scoreIsolation + $scoreCleanup
$totalScore = [Math]::Min(100, [Math]::Max(0, $totalScore))

if ($totalScore -ge 90) { $rating = "Clean"; $ratingCn = "很干净" }
elseif ($totalScore -ge 70) { $rating = "Mostly clean"; $ratingCn = "基本干净" }
elseif ($totalScore -ge 50) { $rating = "Needs tidy-up"; $ratingCn = "需要整理" }
else { $rating = "Artifact landfill"; $ratingCn = "Agent 产物垃圾场" }

# ---- Generate Report ----
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
if (-not $ReportPath) {
    $rptDir = Join-Path $Root ".agent_reports"
    if (-not (Test-Path $rptDir)) { New-Item -ItemType Directory -Path $rptDir -Force | Out-Null }
    $ReportPath = Join-Path $rptDir "hygiene_score_$timestamp.md"
}

$lines = [System.Collections.ArrayList]@()
[void]$lines.Add("# Tidy Skill — Repo Hygiene Score")
[void]$lines.Add("")
[void]$lines.Add( ("**Repository:** '{0}'" -f $Root).Replace("'", '`') )
[void]$lines.Add("**Score:** $totalScore / 100 — **$rating** ($ratingCn)")
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")
[void]$lines.Add("## Dimension Breakdown")
[void]$lines.Add("")
[void]$lines.Add("| Dimension | Score | Max | Notes |")
[void]$lines.Add("|---|---|---|---|")
[void]$lines.Add("| Root cleanliness | $scoreRoot | 25 | Suspicious root-level files: $rootSuspiciousCount |")
[void]$lines.Add("| Artifact placement | $scorePlacement | 20 | .agent_tmp: $(if($hasAgentTmp){'yes'}else{'no'}), .agent_reports: $(if($hasAgentReports){'yes'}else{'no'}) |")
[void]$lines.Add("| Protected docs clarity | $scoreDocs | 15 | README: $(if($hasReadme){'yes'}else{'no'}), LICENSE: $(if($hasLicense){'yes'}else{'no'}), docs/: $(if($hasDocs){'yes'}else{'no'}) |")
[void]$lines.Add("| Git hygiene | $scoreGit | 15 | .gitignore: $(if(Test-Path $gitIgnorePath){'yes'}else{'no'}) |")
[void]$lines.Add("| Agent state isolation | $scoreIsolation | 15 | Tool state dirs found: $stateInProject |")
[void]$lines.Add("| Cleanup readiness | $scoreCleanup | 10 | Cleanup directories: $(if($hasAgentTmp -or $hasAgentReports){'yes'}else{'no'}) |")
[void]$lines.Add("| **Total** | **$totalScore** | **100** | **$rating** |")
[void]$lines.Add("")

# Suspicious files
if ($rootSuspiciousCount -gt 0) {
    [void]$lines.Add("## Suspicious Files in Root")
    [void]$lines.Add("")
    foreach ($f in $rootFiles) {
        foreach ($p in $forbiddenRootPatterns) {
            if ($f.Name -match $p) {
                [void]$lines.Add("- `$($f.Name)` ($(Format-FileSize $f.Length), modified $($f.LastWriteTime.ToString('yyyy-MM-dd')))")
                break
            }
        }
    }
    [void]$lines.Add("")
}

[void]$lines.Add("## Recommendations")
[void]$lines.Add("")
if ($rootSuspiciousCount -gt 0) { [void]$lines.Add("- Move or remove the suspicious root-level files.") }
if (-not $hasAgentTmp) { [void]$lines.Add("- Create `.agent_tmp/` for temporary agent files.") }
if (-not $hasAgentReports) { [void]$lines.Add("- Create `.agent_reports/` for user-requested reports.") }
if (-not $hasChangelog) { [void]$lines.Add("- Add a `CHANGELOG.md` to improve documentation structure.") }
if (-not $hasDocs) { [void]$lines.Add("- Create a `docs/` directory for formal documentation.") }
[void]$lines.Add("")

($lines -join "`n") | Out-File -FilePath $ReportPath -Encoding utf8

Write-Host "`nScore: $totalScore / 100 — $rating ($ratingCn)" -ForegroundColor $(if ($totalScore -ge 70) { 'Green' } elseif ($totalScore -ge 50) { 'Yellow' } else { 'Red' })
Write-Host "Report: $ReportPath" -ForegroundColor Cyan

function Format-FileSize {
    param([long]$Bytes)
    if ($Bytes -ge 1MB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

return @{
    Score = $totalScore
    Rating = $rating
    ReportPath = $ReportPath
    Dimensions = @{
        RootCleanliness = $scoreRoot
        ArtifactPlacement = $scorePlacement
        ProtectedDocsClarity = $scoreDocs
        GitHygiene = $scoreGit
        AgentStateIsolation = $scoreIsolation
        CleanupReadiness = $scoreCleanup
    }
}

