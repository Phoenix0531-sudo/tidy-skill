param()

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$policyPath = Join-Path $repoRoot "skills\tidy-skill\scripts\Policy.ps1"
$scorePath = Join-Path $repoRoot "skills\tidy-skill\scripts\score-repo-hygiene.ps1"
$auditPath = Join-Path $repoRoot "skills\tidy-skill\scripts\audit-agent-artifacts.ps1"

# ASCII check for Policy.ps1 and hygiene scripts that must stay ASCII-safe.
$asciiTargets = @(
    $policyPath,
    $scorePath,
    $auditPath,
    (Join-Path $repoRoot "skills\tidy-skill\scripts\audit-workspace-hygiene.ps1"),
    (Join-Path $repoRoot "skills\tidy-skill\scripts\clean-agent-artifacts.ps1")
)
foreach ($path in $asciiTargets) {
    $bytes = [IO.File]::ReadAllBytes($path)
    $offset = 0
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $offset = 3
    }
    for ($i = $offset; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -gt 127) {
            throw "Non-ASCII byte in $path at offset $i"
        }
    }
}

. $policyPath

$defaults = New-TidyPolicy
if (-not (Test-TidyForbiddenName -Name "plan.md" -Policy $defaults)) {
    throw "plan.md should be forbidden by default"
}
if (Test-TidyForbiddenName -Name "README.md" -Policy $defaults) {
    throw "README.md should not be forbidden"
}
if (-not (Test-TidyProtectedName -Name "README.md" -Policy $defaults)) {
    throw "README.md should be protected"
}

$caseRoot = Join-Path $env:TEMP ("tidy-policy-ps1-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $caseRoot | Out-Null
try {
    "scratch" | Out-File -FilePath (Join-Path $caseRoot "scratch.md") -Encoding utf8
    "vendor" | Out-File -FilePath (Join-Path $caseRoot "vendor_plan.md") -Encoding utf8
    "plan" | Out-File -FilePath (Join-Path $caseRoot "plan.md") -Encoding utf8
    "readme" | Out-File -FilePath (Join-Path $caseRoot "README.md") -Encoding utf8
    '{"forbidden_root_globs":["scratch.md"],"ignore_root_globs":["vendor_plan.md"]}' |
        Out-File -FilePath (Join-Path $caseRoot ".tidy-skill.json") -Encoding utf8

    $loaded = Get-TidyPolicy -Root $caseRoot
    if (-not (Test-TidyForbiddenName -Name "scratch.md" -Policy $loaded)) {
        throw "scratch.md should be forbidden via policy globs"
    }
    if (Test-TidyForbiddenName -Name "vendor_plan.md" -Policy $loaded) {
        throw "vendor_plan.md should be ignored via policy"
    }
    if (-not (Test-TidyForbiddenName -Name "plan.md" -Policy $loaded)) {
        throw "plan.md should remain forbidden"
    }

    $report = Join-Path $env:TEMP ("tidy-score-" + [guid]::NewGuid().ToString("N") + ".md")
    & $scorePath -Root $caseRoot -ReportPath $report | Out-Null
    if (-not (Test-Path -LiteralPath $report)) {
        throw "score report was not written"
    }
    $scoreText = Get-Content -LiteralPath $report -Raw
    if ($scoreText -notmatch "scratch\.md") {
        throw "score report should list scratch.md as suspicious under policy"
    }
    if ($scoreText -match "vendor_plan\.md") {
        throw "score report should not list ignored vendor_plan.md"
    }

    $auditReport = Join-Path $env:TEMP ("tidy-audit-" + [guid]::NewGuid().ToString("N") + ".md")
    & $auditPath -Root $caseRoot -ReportPath $auditReport -MaxDepth 1 | Out-Null
    $auditText = Get-Content -LiteralPath $auditReport -Raw
    if ($auditText -notmatch "scratch\.md") {
        throw "audit report should list scratch.md"
    }
    if ($auditText -match "vendor_plan\.md") {
        throw "audit report should not list vendor_plan.md"
    }
} finally {
    Remove-Item -LiteralPath $caseRoot -Recurse -Force -ErrorAction SilentlyContinue
    if ($report) { Remove-Item -LiteralPath $report -Force -ErrorAction SilentlyContinue }
    if ($auditReport) { Remove-Item -LiteralPath $auditReport -Force -ErrorAction SilentlyContinue }
}

Write-Host "[OK] Policy.ps1 defaults, discovery, score, and audit checks passed."
