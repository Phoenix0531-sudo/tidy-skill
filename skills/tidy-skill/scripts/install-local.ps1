<#
.SYNOPSIS
    Install tidy-skill into local agent skill directories.

.DESCRIPTION
    Copies the packaged skill folder into one or more local agent hubs.
    Defaults to DryRun. Also validates SKILL.md and agents/openai.yaml.

.PARAMETER SkillDir
    Source skill directory. Defaults to the parent directory of this script.

.PARAMETER Codex
    Install to ~/.codex/skills/tidy-skill.

.PARAMETER Claude
    Install to ~/.claude/skills/tidy-skill.

.PARAMETER Cursor
    Install to ~/.cursor/skills/tidy-skill.

.PARAMETER Pi
    Install to ~/.pi/agent/skills/tidy-skill.

.PARAMETER OpenCode
    Install to ~/.config/opencode/skills/tidy-skill.

.PARAMETER All
    Install to every supported target.

.PARAMETER DryRun
    Preview only by default. Pass -DryRun:$false to copy files.

.PARAMETER Force
    Replace an existing installed skill directory.

.PARAMETER SelfCheckOnly
    Validate the source skill package without copying.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SkillDir,

    [Parameter(Mandatory = $false)]
    [switch]$Codex = $false,

    [Parameter(Mandatory = $false)]
    [switch]$Claude = $false,

    [Parameter(Mandatory = $false)]
    [switch]$Cursor = $false,

    [Parameter(Mandatory = $false)]
    [switch]$Pi = $false,

    [Parameter(Mandatory = $false)]
    [switch]$OpenCode = $false,

    [Parameter(Mandatory = $false)]
    [switch]$All = $false,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Force = $false,

    [Parameter(Mandatory = $false)]
    [switch]$SelfCheckOnly = $false
)

function Get-DisplayName {
    return ([char]0x6D01).ToString() + ([char]0x7656).ToString() + ".skill"
}

function Add-Issue {
    param([System.Collections.ArrayList]$Issues, [string]$Message)
    [void]$Issues.Add($Message)
}

function Test-SkillPackage {
    param([string]$Path)
    $issues = [System.Collections.ArrayList]@()
    $displayName = Get-DisplayName

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Add-Issue -Issues $issues -Message "Skill directory not found: $Path"
        return $issues
    }

    $required = @(
        "SKILL.md",
        "agents\openai.yaml",
        "scripts\score_repo_hygiene.py",
        "scripts\audit_agent_artifacts.py",
        "references\script-usage.md"
    )
    foreach ($relative in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path $relative))) {
            Add-Issue -Issues $issues -Message "Missing required file: $relative"
        }
    }

    $skillPath = Join-Path $Path "SKILL.md"
    if (Test-Path -LiteralPath $skillPath -PathType Leaf) {
        $skillText = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
        if ($skillText -notmatch "(?m)^name:\s*tidy-skill\s*$") {
            Add-Issue -Issues $issues -Message "SKILL.md frontmatter name must be tidy-skill."
        }
        if ($skillText -notmatch "(?m)^description:\s*.+") {
            Add-Issue -Issues $issues -Message "SKILL.md frontmatter description is missing."
        }
    }

    $openaiPath = Join-Path $Path "agents\openai.yaml"
    if (Test-Path -LiteralPath $openaiPath -PathType Leaf) {
        $openaiText = Get-Content -LiteralPath $openaiPath -Raw -Encoding UTF8
        if (-not $openaiText.Contains("display_name: `"$displayName`"")) {
            Add-Issue -Issues $issues -Message "agents/openai.yaml display_name must be $displayName."
        }
    }

    return $issues
}

function Invoke-InstallTarget {
    param([string]$Name, [string]$Source, [string]$Destination)

    $parent = Split-Path -Parent $Destination
    Write-Host ""
    Write-Host "Target: $Name"
    Write-Host "  Source:      $Source"
    Write-Host "  Destination: $Destination"

    if ($DryRun) {
        Write-Host "  DryRun: would copy the skill package." -ForegroundColor Yellow
        if (Test-Path -LiteralPath $Destination) {
            Write-Host "  Existing install detected. Use -Force with -DryRun:`$false to replace it." -ForegroundColor Yellow
        }
        return
    }

    if (Test-Path -LiteralPath $Destination) {
        if (-not $Force) {
            throw "Destination already exists: $Destination. Re-run with -Force to replace it."
        }
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
    $issues = Test-SkillPackage -Path $Destination
    if ($issues.Count -gt 0) {
        throw "Installed package failed self-check: $($issues -join '; ')"
    }
    Write-Host "  Installed and validated." -ForegroundColor Green
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $SkillDir) {
    $SkillDir = Join-Path $scriptDir ".."
}
$SkillDir = (Resolve-Path -LiteralPath $SkillDir).Path

Write-Host "tidy-skill local installer"
Write-Host "Display name check: $(Get-DisplayName)"
Write-Host "Mode: $(if($DryRun){'DryRun'}else{'Live install'})"

$sourceIssues = Test-SkillPackage -Path $SkillDir
if ($sourceIssues.Count -gt 0) {
    Write-Host "Self-check failed:" -ForegroundColor Red
    foreach ($issue in $sourceIssues) { Write-Host "  - $issue" -ForegroundColor Red }
    exit 1
}
Write-Host "Source package self-check passed." -ForegroundColor Green

if ($SelfCheckOnly) {
    exit 0
}

$anyExplicit = $Codex -or $Claude -or $Cursor -or $Pi -or $OpenCode -or $All
# Default pair remains Codex + Claude for backward compatibility.
$useDefaultPair = -not $anyExplicit

$targets = @()
if ($Codex -or $All -or $useDefaultPair) {
    $targets += @{ Name = "Codex"; Destination = (Join-Path $env:USERPROFILE ".codex\skills\tidy-skill") }
}
if ($Claude -or $All -or $useDefaultPair) {
    $targets += @{ Name = "Claude"; Destination = (Join-Path $env:USERPROFILE ".claude\skills\tidy-skill") }
}
if ($Cursor -or $All) {
    $targets += @{ Name = "Cursor"; Destination = (Join-Path $env:USERPROFILE ".cursor\skills\tidy-skill") }
}
if ($Pi -or $All) {
    $targets += @{ Name = "Pi"; Destination = (Join-Path $env:USERPROFILE ".pi\agent\skills\tidy-skill") }
}
if ($OpenCode -or $All) {
    $configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:USERPROFILE ".config" }
    $targets += @{ Name = "OpenCode"; Destination = (Join-Path $configHome "opencode\skills\tidy-skill") }
}

foreach ($target in $targets) {
    Invoke-InstallTarget -Name $target.Name -Source $SkillDir -Destination $target.Destination
}

Write-Host ""
if ($DryRun) {
    Write-Host "DryRun complete. Re-run with -DryRun:`$false to install." -ForegroundColor Yellow
} else {
    Write-Host "Install complete. Restart or refresh the skill host if it does not appear immediately." -ForegroundColor Green
}
