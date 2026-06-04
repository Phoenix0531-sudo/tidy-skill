param()

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$scriptPath = Join-Path $repoRoot "skills\tidy-skill\scripts\clean-agent-artifacts.ps1"
$caseRoot = Join-Path $env:TEMP ("tidy-clean-test-" + [guid]::NewGuid().ToString("N"))

New-Item -ItemType Directory -Force -Path $caseRoot | Out-Null
try {
    Push-Location $caseRoot
    git init | Out-Null
    "tracked root plan" | Out-File -FilePath "plan.md" -Encoding utf8
    git add plan.md | Out-Null

    & $scriptPath -Root $caseRoot -ConfirmClean -DryRun:$false | Out-Null

    if (-not (Test-Path -LiteralPath (Join-Path $caseRoot "plan.md") -PathType Leaf)) {
        throw "Git-tracked suspicious root file was deleted."
    }
} finally {
    Pop-Location
    Remove-Item -LiteralPath $caseRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "[OK] Git-tracked files are skipped by cleanup."
