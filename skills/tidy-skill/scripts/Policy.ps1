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
