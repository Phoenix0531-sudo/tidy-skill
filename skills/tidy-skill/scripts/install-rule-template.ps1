<#
.SYNOPSIS
    Install tidy-skill rule templates into a target project.

.DESCRIPTION
    Copies AGENTS.md, CLAUDE.md, or Cursor rule templates from the packaged
    skill into a project. Defaults to DryRun and never overwrites existing files
    unless -Force is provided.

.PARAMETER TargetRoot
    Project directory that should receive the rule template.

.PARAMETER Template
    Template to install: AGENTS, CLAUDE, cursor, or all. Defaults to all.

.PARAMETER DryRun
    Preview only by default. Pass -DryRun:$false to copy files.

.PARAMETER Force
    Overwrite existing target files.
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$TargetRoot,

    [Parameter(Mandatory = $false)]
    [ValidateSet("AGENTS", "CLAUDE", "cursor", "all")]
    [string]$Template = "all",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Force = $false
)

function Add-Template {
    param(
        [System.Collections.ArrayList]$Items,
        [string]$Name,
        [string]$Source,
        [string]$Destination
    )
    [void]$Items.Add(@{ Name = $Name; Source = $Source; Destination = $Destination })
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillDir = (Resolve-Path -LiteralPath (Join-Path $scriptDir "..")).Path
$templateDir = Join-Path $skillDir "templates"
$TargetRoot = (Resolve-Path -LiteralPath $TargetRoot).Path

$items = [System.Collections.ArrayList]@()
if ($Template -eq "AGENTS" -or $Template -eq "all") {
    Add-Template -Items $items -Name "AGENTS.md" -Source (Join-Path $templateDir "AGENTS.md") -Destination (Join-Path $TargetRoot "AGENTS.md")
}
if ($Template -eq "CLAUDE" -or $Template -eq "all") {
    Add-Template -Items $items -Name "CLAUDE.md" -Source (Join-Path $templateDir "CLAUDE.md") -Destination (Join-Path $TargetRoot "CLAUDE.md")
}
if ($Template -eq "cursor" -or $Template -eq "all") {
    Add-Template -Items $items -Name "Cursor rule" -Source (Join-Path $templateDir "cursor-rule.mdc") -Destination (Join-Path $TargetRoot ".cursor\rules\tidy-skill.mdc")
}

Write-Host "tidy-skill rule template installer"
Write-Host "Target: $TargetRoot"
Write-Host "Mode: $(if($DryRun){'DryRun'}else{'Live install'})"
Write-Host ""

foreach ($item in $items) {
    if (-not (Test-Path -LiteralPath $item.Source -PathType Leaf)) {
        throw "Template source missing: $($item.Source)"
    }

    $exists = Test-Path -LiteralPath $item.Destination -PathType Leaf
    Write-Host "$($item.Name)"
    Write-Host "  Source:      $($item.Source)"
    Write-Host "  Destination: $($item.Destination)"

    if ($exists -and -not $Force) {
        Write-Host "  Skipped: destination exists. Use -Force to replace." -ForegroundColor Yellow
        continue
    }

    if ($DryRun) {
        Write-Host "  DryRun: would copy template." -ForegroundColor Yellow
        continue
    }

    $parent = Split-Path -Parent $item.Destination
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    Copy-Item -LiteralPath $item.Source -Destination $item.Destination -Force
    Write-Host "  Installed." -ForegroundColor Green
}

Write-Host ""
if ($DryRun) {
    Write-Host "DryRun complete. Re-run with -DryRun:`$false to install." -ForegroundColor Yellow
} else {
    Write-Host "Template install complete." -ForegroundColor Green
}
