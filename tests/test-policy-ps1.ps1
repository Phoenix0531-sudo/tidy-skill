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

# Planning-layout opt-in (planning-with-files coexistence).
$pwfRoot = Join-Path $env:TEMP ("tidy-policy-pwf-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $pwfRoot | Out-Null
try {
    "phases" | Out-File -FilePath (Join-Path $pwfRoot "task_plan.md") -Encoding utf8
    "notes" | Out-File -FilePath (Join-Path $pwfRoot "findings.md") -Encoding utf8
    "log" | Out-File -FilePath (Join-Path $pwfRoot "progress.md") -Encoding utf8
    "bad" | Out-File -FilePath (Join-Path $pwfRoot "plan.md") -Encoding utf8
    '{"planning_root_globs":["task_plan.md","findings.md","progress.md"]}' |
        Out-File -FilePath (Join-Path $pwfRoot ".tidy-skill.json") -Encoding utf8

    $pwfPolicy = Get-TidyPolicy -Root $pwfRoot
    if (Test-TidyForbiddenName -Name "task_plan.md" -Policy $pwfPolicy) {
        throw "task_plan.md should not be forbidden under planning_root_globs"
    }
    if (Test-TidyForbiddenName -Name "progress.md" -Policy $pwfPolicy) {
        throw "progress.md should not be forbidden under planning_root_globs"
    }
    if (-not (Test-TidyForbiddenName -Name "plan.md" -Policy $pwfPolicy)) {
        throw "plan.md should remain forbidden even with PWF opt-in"
    }

    $pwfReport = Join-Path $env:TEMP ("tidy-pwf-score-" + [guid]::NewGuid().ToString("N") + ".md")
    & $scorePath -Root $pwfRoot -ReportPath $pwfReport | Out-Null
    $pwfText = Get-Content -LiteralPath $pwfReport -Raw
    if ($pwfText -match "task_plan\.md") {
        throw "score report should not list opted-in task_plan.md as suspicious"
    }
    if ($pwfText -notmatch "plan\.md") {
        throw "score report should still list plan.md as suspicious"
    }
} finally {
    Remove-Item -LiteralPath $pwfRoot -Recurse -Force -ErrorAction SilentlyContinue
    if ($pwfReport) { Remove-Item -LiteralPath $pwfReport -Force -ErrorAction SilentlyContinue }
}

# Host hook integration (mirrors tidy_doctor.py detect_host_hook_integration).
$hookRoot = Join-Path $env:TEMP ("tidy-hook-ps1-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $hookRoot | Out-Null
try {
    # absent: no host config present.
    $absent = Test-TidyHostHookIntegration -Root $hookRoot
    if ($absent.Verdict -ne 'absent') {
        throw "expected absent, got $($absent.Verdict)"
    }

    # unwired: .claude/settings.json exists but has no stop-hygiene-check reference.
    New-Item -ItemType Directory -Force -Path (Join-Path $hookRoot ".claude") | Out-Null
    '{"hooks": {}}' | Out-File -FilePath (Join-Path $hookRoot ".claude/settings.json") -Encoding utf8
    $unwired = Test-TidyHostHookIntegration -Root $hookRoot
    if ($unwired.Verdict -ne 'unwired') {
        throw "expected unwired, got $($unwired.Verdict)"
    }
    if ($unwired.HostLabel -ne 'Claude Code') {
        throw "expected Claude Code, got $($unwired.HostLabel)"
    }
    if ($unwired.ConfigPath -ne '.claude/settings.json') {
        throw "expected .claude/settings.json, got $($unwired.ConfigPath)"
    }

    # wired: same config now references the stop hook.
    '{"hooks": {"Stop": [{"command": "python stop-hygiene-check.py --root ."}}]}' |
        Out-File -FilePath (Join-Path $hookRoot ".claude/settings.json") -Encoding utf8
    $wired = Test-TidyHostHookIntegration -Root $hookRoot
    if ($wired.Verdict -ne 'wired') {
        throw "expected wired, got $($wired.Verdict)"
    }
} finally {
    Remove-Item -LiteralPath $hookRoot -Recurse -Force -ErrorAction SilentlyContinue
}

# Get-TidyArtifactClass (PowerShell mirror of classify_artifact.py).
$classPolicy = New-TidyPolicy
$a = Get-TidyArtifactClass -Path 'README.md' -Root $repoRoot -Policy $classPolicy
if ($a.ClassId -ne 'A') { throw "README.md should be Class A, got $($a.ClassId)" }
$e = Get-TidyArtifactClass -Path '.claude/state.json' -Root $repoRoot -Policy $classPolicy
if ($e.ClassId -ne 'E') { throw ".claude/state.json should be Class E, got $($e.ClassId)" }
$cTmp = Get-TidyArtifactClass -Path '.agent_tmp/notes.md' -Root $repoRoot -Policy $classPolicy
if ($cTmp.ClassId -ne 'C') { throw ".agent_tmp/notes.md should be Class C, got $($cTmp.ClassId)" }
$cPlan = Get-TidyArtifactClass -Path '.planning/2026/demo/task_plan.md' -Root $repoRoot -Policy $classPolicy
if ($cPlan.ClassId -ne 'C') { throw ".planning/... should be Class C, got $($cPlan.ClassId)" }
$d = Get-TidyArtifactClass -Path 'mission_complete.md' -Root $repoRoot -Policy $classPolicy
if ($d.ClassId -ne 'D') { throw "mission_complete.md should be Class D, got $($d.ClassId)" }
$cMis = Get-TidyArtifactClass -Path 'plan.md' -Root $repoRoot -Policy $classPolicy
if ($cMis.ClassId -ne 'C' -or $cMis.Allowed) { throw "plan.md should be Class C not allowed, got $($cMis.ClassId) allowed=$($cMis.Allowed)" }

# Invoke-TidyRepair (PowerShell mirror of tidy_repair.py).
$repairRoot = Join-Path $env:TEMP ("tidy-repair-ps1-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $repairRoot | Out-Null
try {
    "plan" | Out-File -FilePath (Join-Path $repairRoot "plan.md") -Encoding utf8
    "readme" | Out-File -FilePath (Join-Path $repairRoot "README.md") -Encoding utf8

    # DryRun: plan only, nothing on disk yet.
    $dry = Invoke-TidyRepair -Root $repairRoot
    if (-not $dry.DryRun) { throw "expected DryRun=true" }
    if ($dry.ExitCode -ne 0) { throw "DryRun exit should be 0, got $($dry.ExitCode)" }
    $kinds = @($dry.Actions | ForEach-Object { $_.Kind })
    if ($kinds -notcontains 'create_dir') { throw "expected create_dir in DryRun plan" }
    if ($kinds -notcontains 'move_root') { throw "expected move_root for plan.md" }
    if (Test-Path -LiteralPath (Join-Path $repairRoot ".agent_tmp")) {
        throw "DryRun must not create .agent_tmp"
    }

    # Apply layout only (safe): dirs created, plan.md stays.
    $safe = Invoke-TidyRepair -Root $repairRoot -Apply
    if ($safe.ExitCode -ne 0) { throw "safe apply exit should be 0, got $($safe.ExitCode)" }
    if (-not (Test-Path -LiteralPath (Join-Path $repairRoot ".agent_tmp\.gitkeep"))) {
        throw ".agent_tmp/.gitkeep missing after -Apply"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $repairRoot ".agent_reports\.gitkeep"))) {
        throw ".agent_reports/.gitkeep missing after -Apply"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $repairRoot "plan.md"))) {
        throw "plan.md must stay without -MoveRoot"
    }

    # Careful: move untracked plan.md into .agent_tmp/.
    $careful = Invoke-TidyRepair -Root $repairRoot -Apply -MoveRoot
    if ($careful.ExitCode -ne 0) { throw "careful apply exit should be 0, got $($careful.ExitCode)" }
    if (Test-Path -LiteralPath (Join-Path $repairRoot "plan.md")) {
        throw "plan.md should have moved under -Apply -MoveRoot"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $repairRoot ".agent_tmp\plan.md"))) {
        throw "plan.md missing under .agent_tmp after move"
    }
    # README stays (protected).
    if (-not (Test-Path -LiteralPath (Join-Path $repairRoot "README.md"))) {
        throw "README.md must never be moved"
    }
} finally {
    Remove-Item -LiteralPath $repairRoot -Recurse -Force -ErrorAction SilentlyContinue
}

# Guard: git-tracked process file is skipped, not moved.
$guardRoot = Join-Path $env:TEMP ("tidy-repair-guard-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $guardRoot | Out-Null
try {
    "tracked plan" | Out-File -FilePath (Join-Path $guardRoot "plan.md") -Encoding utf8
    & git -C $guardRoot init 2>$null | Out-Null
    & git -C $guardRoot add plan.md 2>$null | Out-Null
    $guard = Invoke-TidyRepair -Root $guardRoot -Apply -MoveRoot
    $planActs = @($guard.Actions | Where-Object { $_.Path -eq 'plan.md' })
    if ($planActs.Count -lt 1) { throw "expected an action for tracked plan.md" }
    foreach ($a in $planActs) {
        if ($a.Kind -ne 'skip') { throw "tracked plan.md must be skip, got $($a.Kind)" }
        if ($a.Risk -ne 'manual') { throw "tracked plan.md risk must be manual, got $($a.Risk)" }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $guardRoot "plan.md"))) {
        throw "git-tracked plan.md must remain in place"
    }
} finally {
    Remove-Item -LiteralPath $guardRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "[OK] Policy.ps1 defaults, discovery, score, audit, planning opt-in, host hook, artifact class, and repair checks passed."
