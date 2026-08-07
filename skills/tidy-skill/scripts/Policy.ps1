# Shared tidy-skill policy helpers for PowerShell scripts (ASCII-only).
# Mirrors policy_loader.py defaults and optional .tidy-skill.json loading.
# Dot-source from sibling scripts: . (Join-Path $PSScriptRoot 'Policy.ps1')

$script:TidyDefaultForbiddenRegex = @(
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

$script:TidyDefaultProtectedRegex = @(
    '^readme\.md$',
    '^readme\..+\.md$',
    '^changelog\.md$',
    '^license$',
    '^license\..+$',
    '^contributing\.md$',
    '^code_of_conduct\.md$',
    '^security\.md$'
)

function New-TidyPolicy {
    return [pscustomobject]@{
        Version            = 1
        ForbiddenRegex     = @($script:TidyDefaultForbiddenRegex)
        ProtectedRegex     = @($script:TidyDefaultProtectedRegex)
        ForbiddenGlobs     = @()
        ProtectedGlobs     = @()
        IgnoreGlobs        = @()
        PlanningRootGlobs  = @()
        MinScore           = $null
        RequireAgentDirs   = $false
        Source             = $null
    }
}

function Test-TidyNameGlob {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Pattern
    )
    # Case-insensitive fnmatch-style: * and ?
    $regex = '^' + (
        [regex]::Escape($Pattern.ToLowerInvariant()) `
            -replace '\\\*', '.*' `
            -replace '\\\?', '.'
    ) + '$'
    return [bool]($Name.ToLowerInvariant() -match $regex)
}

function Get-TidyStringList {
    param(
        $Value,
        [string]$FieldName
    )
    if ($null -eq $Value) { return @() }
    if ($Value -isnot [System.Collections.IEnumerable] -or $Value -is [string]) {
        throw "$FieldName must be a list of strings"
    }
    $out = @()
    foreach ($item in $Value) {
        if ($null -eq $item) { continue }
        if ($item -isnot [string]) {
            throw "$FieldName entries must be strings"
        }
        $out += $item
    }
    return $out
}

function Import-TidyPolicyFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "policy file not found: $Path"
    }
    $rawText = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $raw = $rawText | ConvertFrom-Json
    if ($null -eq $raw) {
        throw "policy must be a JSON object"
    }

    $policy = New-TidyPolicy
    $policy.Source = $Path

    if ($null -ne $raw.version) {
        $policy.Version = [int]$raw.version
    }

    $extraRegex = Get-TidyStringList -Value $raw.forbidden_root_regex -FieldName 'forbidden_root_regex'
    if ($extraRegex.Count -gt 0) {
        $policy.ForbiddenRegex = @($script:TidyDefaultForbiddenRegex) + $extraRegex
    }
    if ($null -ne $raw.replace_forbidden_root_regex) {
        $policy.ForbiddenRegex = @(Get-TidyStringList -Value $raw.replace_forbidden_root_regex -FieldName 'replace_forbidden_root_regex')
    }

    $policy.ForbiddenGlobs = @(Get-TidyStringList -Value $raw.forbidden_root_globs -FieldName 'forbidden_root_globs')
    $policy.ProtectedGlobs = @(Get-TidyStringList -Value $raw.protected_root_globs -FieldName 'protected_root_globs')
    $policy.IgnoreGlobs = @(Get-TidyStringList -Value $raw.ignore_root_globs -FieldName 'ignore_root_globs')
    $policy.PlanningRootGlobs = @(Get-TidyStringList -Value $raw.planning_root_globs -FieldName 'planning_root_globs')

    $extraProtected = Get-TidyStringList -Value $raw.protected_root_regex -FieldName 'protected_root_regex'
    if ($extraProtected.Count -gt 0) {
        $policy.ProtectedRegex = @($script:TidyDefaultProtectedRegex) + $extraProtected
    }

    if ($null -ne $raw.min_score) {
        $policy.MinScore = [int]$raw.min_score
    }
    if ($null -ne $raw.require_agent_dirs) {
        $policy.RequireAgentDirs = [bool]$raw.require_agent_dirs
    }
    return $policy
}

function Get-TidyPolicy {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string]$PolicyPath
    )
    if ($PolicyPath) {
        return Import-TidyPolicyFile -Path $PolicyPath
    }
    foreach ($name in @('.tidy-skill.json', 'tidy-skill.policy.json')) {
        $candidate = Join-Path $Root $name
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return Import-TidyPolicyFile -Path $candidate
        }
    }
    return New-TidyPolicy
}

function Test-TidyIgnoredName {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]$Policy
    )
    foreach ($pattern in @($Policy.IgnoreGlobs)) {
        if (Test-TidyNameGlob -Name $Name -Pattern $pattern) { return $true }
    }
    return $false
}

function Test-TidyForbiddenName {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        $Policy
    )
    if ($null -eq $Policy) { $Policy = New-TidyPolicy }
    if (Test-TidyIgnoredName -Name $Name -Policy $Policy) { return $false }
    # Honor the intentional planning-layout opt-in (planning-with-files):
    # a recognized, gitignored root working-memory triple is not litter, so it
    # must not be flagged as suspicious nor picked up by cleanup sweeps.
    if (@($Policy.PlanningRootGlobs).Count -gt 0) {
        $lowered = $Name.ToLowerInvariant()
        foreach ($pattern in @($Policy.PlanningRootGlobs)) {
            if (Test-TidyNameGlob -Name $Name -Pattern $pattern) { return $false }
            if ($lowered -eq $pattern.ToLowerInvariant()) { return $false }
        }
    }
    $lowered = $Name.ToLowerInvariant()
    foreach ($pattern in @($Policy.ForbiddenGlobs)) {
        if (Test-TidyNameGlob -Name $Name -Pattern $pattern) { return $true }
    }
    foreach ($pattern in @($Policy.ForbiddenRegex)) {
        if ($lowered -match $pattern) { return $true }
    }
    return $false
}

function Test-TidyProtectedName {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        $Policy
    )
    if ($null -eq $Policy) { $Policy = New-TidyPolicy }
    $lowered = $Name.ToLowerInvariant()
    foreach ($pattern in @($Policy.ProtectedGlobs)) {
        if (Test-TidyNameGlob -Name $Name -Pattern $pattern) { return $true }
    }
    foreach ($pattern in @($Policy.ProtectedRegex)) {
        if ($lowered -match $pattern) { return $true }
    }
    return $false
}

# Recognized host hook config files that *may* wire tidy-skill's stop hook.
# Mirrors tidy_doctor.py HOST_HOOK_CONFIGS. Read-only: we only substring-scan.
$script:TidyHostHookConfigs = [ordered]@{
    'Claude Code' = @('.claude/settings.json')
    'Codex'       = @('.codex/config.json', '.codex/settings.json')
    'Cursor'      = @('.cursor/hooks.json', '.cursor/rules/hooks.mdc')
    'Pi'          = @('pi-permissions.jsonc', '.pi/config.json')
}

$script:TidyHookMarker = 'stop-hygiene-check'

function Test-TidyHostHookIntegration {
    param(
        [Parameter(Mandatory = $true)][string]$Root
    )
    # Returns [pscustomobject]@{ HostLabel; ConfigPath; Verdict }
    # Verdict is one of: wired, unwired, absent.
    # Read-only: substring-scan only, never parse JSON strictly so
    # malformed configs are tolerated.
    foreach ($kv in $script:TidyHostHookConfigs.GetEnumerator()) {
        $label = $kv.Key
        foreach ($rel in $kv.Value) {
            $candidate = Join-Path $Root $rel
            if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
            try {
                $text = [IO.File]::ReadAllText($candidate)
            } catch {
                continue
            }
            $verdict = if ($text -match [regex]::Escape($script:TidyHookMarker)) { 'wired' } else { 'unwired' }
            return [pscustomobject]@{ HostLabel = $label; ConfigPath = $rel; Verdict = $verdict }
        }
    }
    return [pscustomobject]@{ HostLabel = $null; ConfigPath = $null; Verdict = 'absent' }
}

# Mirrors classify_artifact.py STATE_DIR_NAMES. All lowercased.
$script:TidyStateDirNames = @(
    '.codex', '.claude', '.cursor', '.vscode', '.idea', '.pi', '.agents',
    '__pycache__', '.pytest_cache', '.ruff_cache', 'node_modules', '.venv', 'venv'
)

# Mirrors classify_artifact.py NOISE_NAME_PATTERNS (lowercased).
$script:TidyNoiseNameRegex = @(
    '^mission_complete', '^task_complete', '^done\.md$', '^finished\.md$',
    '^success\.md$', '^ai_summary', '^auto_generated'
)

function Test-TidyPlanningRootName {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        $Policy
    )
    if ($null -eq $Policy) { $Policy = New-TidyPolicy }
    if (@($Policy.PlanningRootGlobs).Count -eq 0) { return $false }
    foreach ($pattern in @($Policy.PlanningRootGlobs)) {
        if (Test-TidyNameGlob -Name $Name -Pattern $pattern) { return $true }
        if ($Name.ToLowerInvariant() -eq $pattern.ToLowerInvariant()) { return $true }
    }
    return $false
}

function Get-TidyArtifactClass {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$Root = '.',
        $Policy
    )
    # Returns [pscustomobject]@{
    #   Path; ClassId; ClassName; Placement; Allowed; Confidence; Reasons; SafeSuggestion
    # }
    # Mirrors classify_artifact.py: A formal docs, B deliverable, C temp/planning,
    # D noise, E tool state. Read-only; pure function of the path string.
    if ($null -eq $Policy) { $Policy = New-TidyPolicy }
    $parts = $Path -split '[/\\]'
    $name = $parts[-1]
    $loweredParts = @($parts | ForEach-Object { $_.ToLowerInvariant() })
    $nameL = $name.ToLowerInvariant()
    $display = ($parts -join '/')

    # Class E - tool / agent state
    foreach ($p in $loweredParts) {
        if ($script:TidyStateDirNames -contains $p) {
            return [pscustomobject]@{
                Path = $display; ClassId = 'E'; ClassName = 'Tool / agent state'
                Placement = 'outside tracked tree or ignored'; Allowed = $true
                Confidence = 'high'; Reasons = @('Path includes a known tool/state directory name.')
                SafeSuggestion = 'Keep ignored; do not commit session caches.'
            }
        }
    }

    # Class A - formal docs
    if ($loweredParts -contains 'docs' -or (Test-TidyProtectedName -Name $name -Policy $Policy)) {
        return [pscustomobject]@{
            Path = $display; ClassId = 'A'; ClassName = 'Formal documentation'
            Placement = 'repo root / docs/'; Allowed = $true
            Confidence = 'high'; Reasons = @('Matches protected documentation patterns or lives under docs/.')
            SafeSuggestion = 'Edit only when the user explicitly requests documentation changes.'
        }
    }

    # Class B - user deliverables in reports dir
    if ($loweredParts -contains '.agent_reports') {
        return [pscustomobject]@{
            Path = $display; ClassId = 'B'; ClassName = 'User-requested deliverable'
            Placement = '.agent_reports/'; Allowed = $true
            Confidence = 'high'; Reasons = @('Lives under .agent_reports/.')
            SafeSuggestion = 'Keep dated, task-specific filenames; promote to docs/ only if long-lived.'
        }
    }

    # Class C - temp
    if ($loweredParts -contains '.agent_tmp') {
        return [pscustomobject]@{
            Path = $display; ClassId = 'C'; ClassName = 'Temporary working artifact'
            Placement = '.agent_tmp/'; Allowed = $true
            Confidence = 'high'; Reasons = @('Lives under .agent_tmp/.')
            SafeSuggestion = 'Delete or expire after the task; never promote to root.'
        }
    }

    # Class C - intentional planning layout (.planning/)
    if ($loweredParts -contains '.planning') {
        return [pscustomobject]@{
            Path = $display; ClassId = 'C'; ClassName = 'Planning working memory'
            Placement = '.planning/ (intentional layout)'; Allowed = $true
            Confidence = 'high'
            Reasons = @(
                'Lives under .planning/ - an intentional, gitignored planning layout.',
                'Recognized as working memory, not root pollution.'
            )
            SafeSuggestion = 'Keep .planning/ gitignored; expire slug folders after the task.'
        }
    }

    # Depth-aware decisions for root-ish paths.
    # With a Root, recompute depth against the resolved relative path.
    $depth = $parts.Length
    if ($Root -and (Test-Path -LiteralPath $Root -PathType Container)) {
        $resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
        $candidatePath = if ([IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $resolvedRoot $Path }
        $relParts = ($candidatePath -replace [regex]::Escape($resolvedRoot + [IO.Path]::DirectorySeparatorChar), '') -split '[/\\]'
        $depth = $relParts.Length
        $display = ($relParts -join '/')
    }

    if ($depth -le 1) {
        foreach ($pat in $script:TidyNoiseNameRegex) {
            if ($nameL -match $pat) {
                return [pscustomobject]@{
                    Path = $display; ClassId = 'D'; ClassName = 'Self-congratulatory noise'
                    Placement = 'do not keep'; Allowed = $false
                    Confidence = 'medium'; Reasons = @('Name looks like completion fluff.')
                    SafeSuggestion = 'Do not create this file; summarize in chat instead.'
                }
            }
        }
        if (Test-TidyPlanningRootName -Name $name -Policy $Policy) {
            return [pscustomobject]@{
                Path = $display; ClassId = 'C'; ClassName = 'Planning working memory'
                Placement = 'repo root (intentional PWF-style triple)'; Allowed = $true
                Confidence = 'high'
                Reasons = @(
                    'Filename matches the project planning_root_globs opt-in.',
                    'Working-memory file gitignored by convention, not litter.'
                )
                SafeSuggestion = 'Confirm .gitignore excludes this file; review at task end.'
            }
        }
        if (Test-TidyForbiddenName -Name $name -Policy $Policy) {
            return [pscustomobject]@{
                Path = $display; ClassId = 'C'; ClassName = 'Temporary working artifact (misplaced)'
                Placement = '.agent_tmp/ (preferred) or chat'; Allowed = $false
                Confidence = 'high'
                Reasons = @(
                    'Filename matches forbidden root process-Markdown patterns.',
                    'Root placement is discouraged for process files.'
                )
                SafeSuggestion = "Prefer chat, or write to .agent_tmp/$name if a file is truly required."
            }
        }
        if ($nameL -like '*.md') {
            return [pscustomobject]@{
                Path = $display; ClassId = 'B'; ClassName = 'Possible deliverable / ambiguous root Markdown'
                Placement = 'user-specified path, .agent_reports/, or docs/'; Allowed = $false
                Confidence = 'low'; Reasons = @('Root Markdown that is not a known protected formal doc.')
                SafeSuggestion = 'Confirm user intent; avoid generic names; prefer .agent_reports/ or docs/.'
            }
        }
    }

    return [pscustomobject]@{
        Path = $display; ClassId = 'C'; ClassName = 'Unclassified working file'
        Placement = 'task-appropriate path with explicit lifecycle'; Allowed = $true
        Confidence = 'low'
        Reasons = @('No strong formal/forbidden signal; treat as working output with a clear owner.')
        SafeSuggestion = 'Run the Artifact Intent Check before creating; set lifetime and reader.'
    }
}
