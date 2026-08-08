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

# ---------------------------------------------------------------------------
# Resolve-TidyRoot / Get-RelativePath - shared path helpers.
# Windows CI runners expose $env:TEMP as an 8.3 short name
# (C:\Users\RUNNER~1\...) while Get-ChildItem returns long-form FullNames
# (C:\Users\runneradmin\...). Without canonicalization, substring-based
# relative-path math silently drops every root file from the suspicious scan
# and mis-keys git-tracked checks. Centralized here so every script that
# scans files against $Root uses the same, 8.3-safe normalization.
# ---------------------------------------------------------------------------
function Resolve-TidyRoot {
    param([Parameter(Mandatory = $true)][string]$Path)
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $probe = Get-Item -LiteralPath $resolved
    if ($probe -and $probe.FullName) {
        return $probe.FullName.TrimEnd('\').TrimEnd('/')
    }
    return $resolved.TrimEnd('\').TrimEnd('/')
}

function Get-RelativePath {
    param(
        [string]$FullPath,
        [Parameter(Mandatory = $true)][string]$Root
    )
    if (-not $Root) { return $FullPath }
    $cmp = [System.StringComparison]::OrdinalIgnoreCase
    if ($FullPath.Length -ge $Root.Length -and $FullPath.Substring(0, $Root.Length).Equals($Root, $cmp)) {
        $rel = $FullPath.Substring($Root.Length).TrimStart('\').TrimStart('/')
    } else {
        # Prefix mismatch (8.3 vs long name, junction, etc.): strip any leading
        # directory components and keep just the file name so root-level files
        # are still attributed to the root bucket instead of being dropped.
        $rel = [System.IO.Path]::GetFileName($FullPath)
    }
    if ($rel -eq '') { return '.' }
    return $rel
}

# ---------------------------------------------------------------------------
# Invoke-TidyRepair - PowerShell mirror of tidy_repair.py
# Safety verbs: dryrun (default) / careful (--Apply -MoveRoot) / guard (refuse
# host/git-tracked/protected). Never rewrites host configs or VHDX.
# ---------------------------------------------------------------------------
function Test-TidyGitTracked {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )
    $gitDir = Join-Path $Root '.git'
    if (-not (Test-Path -LiteralPath $gitDir)) { return $false }
    try {
        $null = & git -C $Root ls-files --error-unmatch -- $RelativePath 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Invoke-TidyRepair {
    param(
        [string]$Root = '.',
        $Policy,
        [switch]$Apply,
        [switch]$MoveRoot,
        [switch]$NoRootMoves,
        [int]$TmpDays = 7,
        [int]$ReportDays = 30
    )
    # Returns [pscustomobject]@{ Root; DryRun; Actions; Notes; ExitCode }
    # Action items: Kind, Path, Detail, Risk, Applied
    if ($null -eq $Policy) { $Policy = New-TidyPolicy }
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw "Root is not a directory: $Root"
    }
    $resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
    $actions = New-Object System.Collections.Generic.List[object]
    $notes = New-Object System.Collections.Generic.List[string]

    # --- layout dirs (safe) ---
    foreach ($name in @('.agent_tmp', '.agent_reports')) {
        $dir = Join-Path $resolvedRoot $name
        $gitkeep = Join-Path $dir '.gitkeep'
        if ((Test-Path -LiteralPath $dir -PathType Container) -and (Test-Path -LiteralPath $gitkeep -PathType Leaf)) {
            $actions.Add([pscustomobject]@{ Kind = 'skip'; Path = "$name/"; Detail = 'already present with .gitkeep'; Risk = 'safe'; Applied = $false })
            continue
        }
        if (Test-Path -LiteralPath $dir -PathType Container) {
            if (-not (Test-Path -LiteralPath $gitkeep -PathType Leaf)) {
                $actions.Add([pscustomobject]@{ Kind = 'create_dir'; Path = "$name/.gitkeep"; Detail = "add .gitkeep under existing $name/"; Risk = 'safe'; Applied = $false })
            }
        } else {
            $actions.Add([pscustomobject]@{ Kind = 'create_dir'; Path = "$name/"; Detail = "create $name/ with .gitkeep (explicit placement)"; Risk = 'safe'; Applied = $false })
        }
    }

    # --- root process moves (careful) ---
    if (-not $NoRootMoves) {
        Get-ChildItem -LiteralPath $resolvedRoot -File -ErrorAction SilentlyContinue | ForEach-Object {
            $fname = $_.Name
            if (-not (Test-TidyForbiddenName -Name $fname -Policy $Policy)) { return }
            if (Test-TidyProtectedName -Name $fname -Policy $Policy) {
                $actions.Add([pscustomobject]@{ Kind = 'skip'; Path = $fname; Detail = 'protected formal doc - never move'; Risk = 'manual'; Applied = $false })
                return
            }
            if (Test-TidyGitTracked -Root $resolvedRoot -RelativePath $fname) {
                $actions.Add([pscustomobject]@{ Kind = 'skip'; Path = $fname; Detail = 'git-tracked - refuse automatic move; untrack or move manually'; Risk = 'manual'; Applied = $false })
                return
            }
            $actions.Add([pscustomobject]@{ Kind = 'move_root'; Path = $fname; Detail = "move root process Markdown -> .agent_tmp/$fname (Class C)"; Risk = 'careful'; Applied = $false })
        }
    }

    # --- retention notes (careful, never auto-delete) ---
    $now = Get-Date
    foreach ($pair in @(
        @{ Dir = '.agent_tmp'; Days = $TmpDays },
        @{ Dir = '.agent_reports'; Days = $ReportDays }
    )) {
        $folder = Join-Path $resolvedRoot $pair.Dir
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        $eligible = 0
        Get-ChildItem -LiteralPath $folder -File -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -eq '.gitkeep') { return }
            $age = ($now - $_.LastWriteTime).Days
            if ($age -ge $pair.Days) { $eligible++ }
        }
        if ($eligible -gt 0) {
            $actions.Add([pscustomobject]@{
                Kind = 'retention_note'; Path = "$($pair.Dir)/"
                Detail = "$eligible file(s) older than $($pair.Days)d - preview with clean-agent-artifacts.ps1 -Root . -DryRun"
                Risk = 'careful'; Applied = $false
            })
        }
    }

    $notes.Add('Verbs: dryrun (default preview) / careful (root moves need -Apply -MoveRoot) / guard (never auto host/VHDX/config).')

    $exitCode = 0
    $dryRun = -not $Apply.IsPresent

    if ($Apply) {
        foreach ($action in $actions) {
            if ($action.Kind -eq 'create_dir') {
                $rel = $action.Path.TrimEnd('/', '\')
                if ($rel.EndsWith('.gitkeep')) {
                    $parent = Split-Path $rel -Parent
                    $targetDir = if ($parent) { Join-Path $resolvedRoot $parent } else { $resolvedRoot }
                    $gitkeep = Join-Path $resolvedRoot $rel
                } else {
                    $targetDir = Join-Path $resolvedRoot $rel
                    $gitkeep = Join-Path $targetDir '.gitkeep'
                }
                New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
                if (-not (Test-Path -LiteralPath $gitkeep -PathType Leaf)) {
                    New-Item -ItemType File -Force -Path $gitkeep | Out-Null
                }
                $action.Applied = $true
            } elseif ($action.Kind -eq 'move_root') {
                if (-not $MoveRoot) { continue }
                $src = Join-Path $resolvedRoot $action.Path
                $destDir = Join-Path $resolvedRoot '.agent_tmp'
                New-Item -ItemType Directory -Force -Path $destDir | Out-Null
                $dest = Join-Path $destDir $action.Path
                if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
                    $action.Detail = $action.Detail + ' (source missing at apply time)'
                    continue
                }
                if (Test-Path -LiteralPath $dest) {
                    $action.Detail = $action.Detail + " (refused: $($action.Path) already exists under .agent_tmp/)"
                    $exitCode = 2
                    break
                }
                if (Test-TidyGitTracked -Root $resolvedRoot -RelativePath $action.Path) {
                    $action.Detail = $action.Detail + ' (refused: became git-tracked)'
                    $exitCode = 2
                    break
                }
                Move-Item -LiteralPath $src -Destination $dest -Force
                $action.Applied = $true
            }
        }
        if (-not $MoveRoot -and ($actions | Where-Object { $_.Kind -eq 'move_root' })) {
            $notes.Add('Root moves planned but not applied (careful). Re-run with -Apply -MoveRoot.')
        }
    } else {
        $notes.Add('DryRun only. Re-run with -Apply for safe layout creates.')
        if ($actions | Where-Object { $_.Kind -eq 'move_root' }) {
            $notes.Add('Root moves need -Apply -MoveRoot (careful verb).')
        }
    }

    $actionArr = [object[]]@($actions.ToArray())
    $noteArr = [string[]]@($notes.ToArray())
    $safeN = 0
    $carefulN = 0
    foreach ($a in $actionArr) {
        if ($a.Risk -eq 'safe') { $safeN++ }
        elseif ($a.Risk -eq 'careful') { $carefulN++ }
    }
    $result = New-Object PSObject
    $result | Add-Member -NotePropertyName Root -NotePropertyValue $resolvedRoot
    $result | Add-Member -NotePropertyName DryRun -NotePropertyValue ([bool]$dryRun)
    $result | Add-Member -NotePropertyName Actions -NotePropertyValue $actionArr
    $result | Add-Member -NotePropertyName Notes -NotePropertyValue $noteArr
    $result | Add-Member -NotePropertyName ExitCode -NotePropertyValue ([int]$exitCode)
    $result | Add-Member -NotePropertyName SafeCount -NotePropertyValue ([int]$safeN)
    $result | Add-Member -NotePropertyName CarefulCount -NotePropertyValue ([int]$carefulN)
    return $result
}
