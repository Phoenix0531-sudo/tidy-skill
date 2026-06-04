<#
.SYNOPSIS
    Audit developer environment hygiene, focusing on toolchains, runtimes, virtualization, and AI model caches.

.DESCRIPTION
    Analyzes local developer environments (NPM, Python, Go, Rust, Java, Docker, WSL, AI model caches, and IDE configs)
    to map system drive footprints, identify redundant caches, and calculate environment hygiene scores.
    Read-only. Never modifies environment variables, files, system settings, or registers scheduled tasks.

.PARAMETER Roots
    Specific workspace or project paths to audit (e.g. "D:\Projects", "E:\1_Code").

.PARAMETER ReportPath
    Path where the Markdown report should be written. Defaults to
    ".agent_reports\dev_env_hygiene_<timestamp>.md" in the first specified Root directory,
    or the current directory if no Roots are specified.

.PARAMETER IncludeUserProfile
    Explicit user switch to include the user home profile directory (~ or $HOME) in the scan.

.PARAMETER IncludeDrives
    Explicit user switch to scan drive root directories for caches (only profiles and common folders).

.PARAMETER MaxDepth
    Maximum folder search depth when scanning for workspace node_modules, target, venv directories. Default 3.

.EXAMPLE
    .\audit-dev-environment.ps1 -Roots "E:\1_Code" -ReportPath ".\report.md"

.EXAMPLE
    .\audit-dev-environment.ps1 -Roots "E:\1_Code","D:\Projects" -IncludeUserProfile -ReportPath ".\report.md"

.NOTES
    Part of tidy-skill. Local-first, privacy-first, read-only.
    Never uploads data. Never reads authorization tokens or private sessions.
#>

param(
    [Parameter(Mandatory = $false)]
    [string[]]$Roots = @(),

    [Parameter(Mandatory = $false)]
    [string]$ReportPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeUserProfile = $false,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeDrives = $false,

    [Parameter(Mandatory = $false)]
    [int]$MaxDepth = 3
)

# ---- Helper Functions ----

function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Get-DirSize {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return 0 }
    $size = [long]0
    try {
        $files = Get-ChildItem -LiteralPath $Path -File -Recurse -ErrorAction SilentlyContinue
        foreach ($f in $files) { $size += $f.Length }
    } catch {}
    return $size
}

function Test-Command {
    param([string]$Name)
    $oldErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $cmd = Get-Command $Name -ErrorAction Stop
        return $true
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $oldErrorAction
    }
}

function Run-SafeCommand {
    param([string]$Cmd, [string]$ArgsStr)
    if (-not (Test-Command $Cmd)) { return "Not Installed" }
    try {
        $argList = @()
        if ($ArgsStr) { $argList = $ArgsStr -split '\s+' }
        $out = & $Cmd @argList 2>$null | Out-String
        if ($out) { return ($out -replace [char]0, '').Trim() }
    } catch {}
    return "Unknown / Error running command"
}

function Get-ConfigValue {
    param([string]$Content, [string]$Key)
    if (-not $Content) { return "" }
    $pattern = "(?im)^\s*$([regex]::Escape($Key))\s*=\s*(.+?)\s*$"
    $match = [regex]::Match($Content, $pattern)
    if ($match.Success) { return $match.Groups[1].Value.Trim() }
    return ""
}

function Parse-WslVerboseList {
    param([string]$Text)
    $rows = @()
    if (-not $Text -or $Text -eq "Not Installed") { return $rows }
    $lines = $Text -split "`r?`n"
    foreach ($line in $lines) {
        $clean = ($line -replace [char]0, '').Trim()
        if (-not $clean) { continue }
        if ($clean -match 'NAME\s+STATE\s+VERSION') { continue }
        $clean = $clean.TrimStart('*').Trim()
        if ($clean -match '^(.+?)\s+(Running|Stopped|Installing|Uninstalling|Converting)\s+([12])$') {
            $rows += @{
                Name = $matches[1].Trim()
                State = $matches[2].Trim()
                Version = $matches[3].Trim()
            }
        }
    }
    return $rows
}

function Test-ReadableText {
    param([string]$Text)
    if (-not $Text) { return $false }
    if ($Text -match [char]0xfffd) { return $false }
    if ($Text -match '[\x00-\x08\x0B\x0C\x0E-\x1F]') { return $false }
    return $true
}

function Get-PathTouchClass {
    param([string]$Path)
    if (-not $Path) { return "Review only" }
    if ($Path -match '\.vhdx$' -or $Path -match '\\Docker\\wsl\\' -or $Path -match '\\Packages\\') { return "Manual" }
    if ($Path -match '\\\.claude($|\\)' -or $Path -match '\\\.codex($|\\)' -or $Path -match '\\\.cursor($|\\)' -or $Path -match '\\\.vscode($|\\)' -or $Path -match '\\Code($|\\)') { return "Do not clean automatically" }
    if ($Path -match 'huggingface' -or $Path -match 'ollama' -or $Path -match 'lmstudio' -or $Path -match 'lm-studio' -or $Path -match 'torch') { return "Manual" }
    if ($Path -match 'node_modules' -or $Path -match '\\\.venv($|\\)' -or $Path -match '\\venv($|\\)' -or $Path -match '\\target($|\\)') { return "Review project first" }
    return "Safe to review"
}

function Get-PathNextStep {
    param([string]$Path)
    $touchClass = Get-PathTouchClass $Path
    if ($touchClass -eq "Manual") { return "Inspect owner and use tool-supported migration or cleanup commands only." }
    if ($touchClass -eq "Do not clean automatically") { return "Leave it alone unless the owning tool documents a cleanup path." }
    if ($touchClass -eq "Review project first") { return "Confirm the project can rebuild it, then clean from that project context." }
    return "Review owner first; prefer the package manager's cache command over manual deletion."
}

function Add-OptimizationItem {
    param(
        [System.Collections.ArrayList]$Items,
        [string]$Area,
        [string]$Why,
        [string]$CanTouch,
        [string]$NextStep,
        [long]$Size = 0,
        [int]$Priority = 50
    )
    [void]$Items.Add([pscustomobject]@{
        Area = $Area
        Why = $Why
        CanTouch = $CanTouch
        NextStep = $NextStep
        Size = $Size
        Priority = $Priority
    })
}

# ---- Initialize ----
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  tidy-skill - Dev Environment Audit" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Local-first, read-only, privacy-first."

$resolvedRoots = [System.Collections.ArrayList]@()
foreach ($r in $Roots) {
    if (Test-Path -LiteralPath $r -PathType Container) {
        [void]$resolvedRoots.Add((Resolve-Path -LiteralPath $r).Path)
    }
}

Write-Host "Roots to scan:   $($resolvedRoots -join ', ')"
Write-Host "Known cache paths: Yes"
Write-Host "User deep scan:  $(if($IncludeUserProfile){'Yes'}else{'No (pass -IncludeUserProfile to include WSL package VHDX scan)'})"
Write-Host "Drive scan:      $(if($IncludeDrives){'Yes'}else{'No (pass -IncludeDrives to enable)'})"
Write-Host "Max depth:       $MaxDepth"
Write-Host ""

$userProfile = $env:USERPROFILE
$appdataLocal = $env:LOCALAPPDATA
$appdataRoaming = $env:APPDATA

# ---- Gather Environment Data ----

$envData = @{
    Node = @{}
    Python = @{}
    Go = @{}
    Rust = @{}
    Java = @{}
    DockerWsl = @{}
    AgentsIde = @{}
    ModelCaches = @{}
    Playwright = @{}
    PackageEnv = @{}
}

# 1. Node / NPM
Write-Host "Auditing Node/NPM..." -ForegroundColor Cyan
$envData.Node.Version = Run-SafeCommand "node" "--version"
$envData.Node.NpmVersion = Run-SafeCommand "npm" "--version"
$envData.Node.Prefix = Run-SafeCommand "npm" "config get prefix"
$envData.Node.Cache = Run-SafeCommand "npm" "config get cache"

$nodePaths = @(
    (Join-Path $userProfile ".npm"),
    (Join-Path $appdataRoaming "npm-cache"),
    (Join-Path $appdataLocal "npm-cache"),
    (Join-Path $userProfile ".pnpm-store"),
    (Join-Path $userProfile ".yarn")
)
$envData.Node.Caches = @()
foreach ($p in $nodePaths) {
    if (Test-Path -LiteralPath $p) {
        $size = Get-DirSize $p
        $envData.Node.Caches += @{ Path = $p; Size = $size }
    }
}

# 2. Python
Write-Host "Auditing Python..." -ForegroundColor Cyan
$envData.Python.Version = Run-SafeCommand "python" "--version"
$envData.Python.UvVersion = Run-SafeCommand "uv" "--version"
$envData.Python.PipCacheDir = Run-SafeCommand "pip" "cache dir"

$pyPaths = @(
    (Join-Path $userProfile ".cache\pip"),
    (Join-Path $appdataLocal "pip\cache"),
    (Join-Path $appdataLocal "uv"),
    (Join-Path $userProfile ".pipx"),
    (Join-Path $userProfile ".conda"),
    (Join-Path $userProfile ".poetry")
)
$envData.Python.Caches = @()
foreach ($p in $pyPaths) {
    if (Test-Path -LiteralPath $p) {
        $size = Get-DirSize $p
        $envData.Python.Caches += @{ Path = $p; Size = $size }
    }
}

# 3. Go
Write-Host "Auditing Go..." -ForegroundColor Cyan
$envData.Go.Version = Run-SafeCommand "go" "version"
$envData.Go.Goroot = Run-SafeCommand "go" "env GOROOT"
$envData.Go.Gopath = Run-SafeCommand "go" "env GOPATH"
$envData.Go.Gocache = Run-SafeCommand "go" "env GOCACHE"
$envData.Go.Gomodcache = Run-SafeCommand "go" "env GOMODCACHE"

$goPaths = @()
if ($envData.Go.Gopath -and $envData.Go.Gopath -ne "Not Installed") { $goPaths += $envData.Go.Gopath }
if ($envData.Go.Gocache -and $envData.Go.Gocache -ne "Not Installed") { $goPaths += $envData.Go.Gocache }
if ($envData.Go.Gomodcache -and $envData.Go.Gomodcache -ne "Not Installed") { $goPaths += $envData.Go.Gomodcache }

$envData.Go.Caches = @()
foreach ($p in ($goPaths | Select-Object -Unique)) {
    if (Test-Path -LiteralPath $p) {
        $size = Get-DirSize $p
        $envData.Go.Caches += @{ Path = $p; Size = $size }
    }
}

# 4. Rust
Write-Host "Auditing Rust..." -ForegroundColor Cyan
$envData.Rust.Version = Run-SafeCommand "rustc" "--version"
$envData.Rust.CargoVersion = Run-SafeCommand "cargo" "--version"

$rustPaths = @(
    (Join-Path $userProfile ".cargo"),
    (Join-Path $userProfile ".rustup")
)
$envData.Rust.Caches = @()
foreach ($p in $rustPaths) {
    if (Test-Path -LiteralPath $p) {
        $size = Get-DirSize $p
        $envData.Rust.Caches += @{ Path = $p; Size = $size }
    }
}

# 5. Java
Write-Host "Auditing Java..." -ForegroundColor Cyan
$envData.Java.JavaHome = $env:JAVA_HOME
$javaPaths = @(
    (Join-Path $userProfile ".m2"),
    (Join-Path $userProfile ".gradle")
)
$envData.Java.Caches = @()
foreach ($p in $javaPaths) {
    if (Test-Path -LiteralPath $p) {
        $size = Get-DirSize $p
        $envData.Java.Caches += @{ Path = $p; Size = $size }
    }
}

# 6. Docker / WSL
Write-Host "Auditing Docker and WSL..." -ForegroundColor Cyan
$envData.DockerWsl.WslStatus = Run-SafeCommand "wsl" "--status"
$envData.DockerWsl.WslStatusReadable = Test-ReadableText $envData.DockerWsl.WslStatus
$envData.DockerWsl.WslList = Run-SafeCommand "wsl" "--list --verbose"
$envData.DockerWsl.Distros = @(Parse-WslVerboseList $envData.DockerWsl.WslList)
$envData.DockerWsl.DockerVersion = Run-SafeCommand "docker" "--version"

$wslConfigPath = Join-Path $userProfile ".wslconfig"
$wslConfigContent = ""
if (Test-Path -LiteralPath $wslConfigPath -PathType Leaf) {
    $wslConfigContent = Get-Content -LiteralPath $wslConfigPath -Raw -ErrorAction SilentlyContinue
}
$envData.DockerWsl.WslConfig = @{
    Path = $wslConfigPath
    Exists = (Test-Path -LiteralPath $wslConfigPath -PathType Leaf)
    Memory = Get-ConfigValue $wslConfigContent "memory"
    Swap = Get-ConfigValue $wslConfigContent "swap"
    Processors = Get-ConfigValue $wslConfigContent "processors"
    DefaultVhdSize = Get-ConfigValue $wslConfigContent "defaultVhdSize"
    AutoMemoryReclaim = Get-ConfigValue $wslConfigContent "autoMemoryReclaim"
    SparseVhd = Get-ConfigValue $wslConfigContent "sparseVhd"
}

$wslPaths = @(
    (Join-Path $appdataLocal "Docker\wsl"),
    (Join-Path $appdataLocal "Packages")
)
$envData.DockerWsl.Caches = @()
$dockerVhdHints = @(
    (Join-Path $appdataLocal "Docker\wsl\data\ext4.vhdx"),
    (Join-Path $appdataLocal "Docker\wsl\distro\ext4.vhdx")
)
foreach ($hint in $dockerVhdHints) {
    if (Test-Path -LiteralPath $hint -PathType Leaf) {
        $f = Get-Item -LiteralPath $hint -ErrorAction SilentlyContinue
        if ($f) { $envData.DockerWsl.Caches += @{ Path = $f.FullName; Size = $f.Length; Owner = "Docker Desktop WSL backend" } }
    }
}
if ($IncludeUserProfile -or $IncludeDrives) {
    foreach ($p in $wslPaths) {
        if (Test-Path -LiteralPath $p) {
            # Only scan for VHDX sizes to be fast and safe.
            try {
                $vhdxFiles = Get-ChildItem -LiteralPath $p -Filter "*.vhdx" -Recurse -File -ErrorAction SilentlyContinue
                foreach ($v in $vhdxFiles) {
                    $owner = "WSL/Docker"
                    if ($v.FullName -match "\\Docker\\wsl\\") { $owner = "Docker Desktop WSL backend" }
                    elseif ($v.FullName -match "\\Packages\\") { $owner = "WSL distro package" }
                    $envData.DockerWsl.Caches += @{ Path = $v.FullName; Size = $v.Length; Owner = $owner }
                }
            } catch {}
        }
    }
}
$envData.DockerWsl.Caches = @($envData.DockerWsl.Caches | Sort-Object Path -Unique)
$dockerSettingPaths = @(
    (Join-Path $appdataRoaming "Docker\settings-store.json"),
    (Join-Path $appdataRoaming "Docker\settings.json"),
    (Join-Path $appdataRoaming "Docker Desktop\settings.json")
)
$envData.DockerWsl.DockerSettings = @()
foreach ($p in $dockerSettingPaths) {
    if (Test-Path -LiteralPath $p -PathType Leaf) {
        $f = Get-Item -LiteralPath $p -ErrorAction SilentlyContinue
        if ($f) { $envData.DockerWsl.DockerSettings += @{ Path = $f.FullName; Size = $f.Length } }
    }
}

# 7. AI Agents / IDE / MCP
Write-Host "Auditing Agent & IDE configurations..." -ForegroundColor Cyan
$agentPaths = @(
    (Join-Path $userProfile ".claude"),
    (Join-Path $userProfile ".codex"),
    (Join-Path $userProfile ".gemini"),
    (Join-Path $userProfile ".cursor"),
    (Join-Path $userProfile ".continue"),
    (Join-Path $userProfile ".cache"),
    (Join-Path $userProfile ".vscode"),
    (Join-Path $appdataRoaming "Codex"),
    (Join-Path $appdataLocal "Codex"),
    (Join-Path $appdataLocal "OpenAI"),
    (Join-Path $appdataRoaming "ai.opencode.desktop"),
    (Join-Path $appdataLocal "hermes"),
    (Join-Path $appdataLocal "AnthropicClaude"),
    (Join-Path $appdataRoaming "Code")
)
$envData.AgentsIde.Paths = @()
foreach ($p in $agentPaths) {
    if (Test-Path -LiteralPath $p) {
        $size = Get-DirSize $p
        $envData.AgentsIde.Paths += @{ Path = $p; Size = $size }
    }
}

# 8. AI Model Caches
Write-Host "Auditing AI Model Caches..." -ForegroundColor Cyan
$modelEnvPaths = @()
if ($env:HF_HOME) { $modelEnvPaths += $env:HF_HOME }
if ($env:TRANSFORMERS_CACHE) { $modelEnvPaths += $env:TRANSFORMERS_CACHE }
if ($env:HUGGINGFACE_HUB_CACHE) { $modelEnvPaths += $env:HUGGINGFACE_HUB_CACHE }
if ($env:OLLAMA_MODELS) { $modelEnvPaths += $env:OLLAMA_MODELS }
if ($env:TORCH_HOME) { $modelEnvPaths += $env:TORCH_HOME }

$defaultModelPaths = @(
    (Join-Path $userProfile ".cache\huggingface"),
    (Join-Path $userProfile ".ollama"),
    (Join-Path $userProfile ".cache\torch"),
    (Join-Path $userProfile ".lmstudio"),
    (Join-Path $userProfile ".cache\lm-studio")
)
$envData.ModelCaches.Paths = @()
foreach ($p in ($modelEnvPaths + $defaultModelPaths | Select-Object -Unique)) {
    if (Test-Path -LiteralPath $p) {
        $size = Get-DirSize $p
        $envData.ModelCaches.Paths += @{ Path = $p; Size = $size }
    }
}

# 9. Playwright / Puppeteer
Write-Host "Auditing Playwright/Puppeteer browser cache..." -ForegroundColor Cyan
$browserPaths = @(
    (Join-Path $appdataLocal "ms-playwright"),
    (Join-Path $userProfile ".cache\puppeteer")
)
if ($env:PLAYWRIGHT_BROWSERS_PATH) { $browserPaths += $env:PLAYWRIGHT_BROWSERS_PATH }

$envData.Playwright.Caches = @()
foreach ($p in ($browserPaths | Select-Object -Unique)) {
    if (Test-Path -LiteralPath $p) {
        $size = Get-DirSize $p
        $envData.Playwright.Caches += @{ Path = $p; Size = $size }
    }
}

# 10. Known path-like environment variables
$pathEnvNames = @(
    "NPM_CONFIG_CACHE",
    "PNPM_HOME",
    "YARN_CACHE_FOLDER",
    "PIP_CACHE_DIR",
    "UV_CACHE_DIR",
    "UV_TOOL_DIR",
    "UV_PYTHON_INSTALL_DIR",
    "GOPATH",
    "GOMODCACHE",
    "GOCACHE",
    "CARGO_HOME",
    "RUSTUP_HOME",
    "DOCKER_CONFIG",
    "HF_HOME",
    "TRANSFORMERS_CACHE",
    "HUGGINGFACE_HUB_CACHE",
    "OLLAMA_MODELS",
    "TORCH_HOME",
    "PLAYWRIGHT_BROWSERS_PATH"
)
$envData.PackageEnv.Paths = @()
foreach ($name in $pathEnvNames) {
    $value = [Environment]::GetEnvironmentVariable($name, "Process")
    if (-not $value) { $value = [Environment]::GetEnvironmentVariable($name, "User") }
    if ($value) {
        $exists = Test-Path -LiteralPath $value
        $size = 0
        if ($exists -and (Test-Path -LiteralPath $value -PathType Container)) { $size = Get-DirSize $value }
        elseif ($exists -and (Test-Path -LiteralPath $value -PathType Leaf)) { $size = (Get-Item -LiteralPath $value).Length }
        $envData.PackageEnv.Paths += @{ Name = $name; Path = $value; Exists = $exists; Size = $size }
    }
}

# ---- Search in Roots (node_modules, target, .venv) ----
$projectCaches = [System.Collections.ArrayList]@()
if ($resolvedRoots.Count -gt 0) {
    Write-Host "Searching Roots for project-level cache folders (node_modules, target, .venv)..." -ForegroundColor Cyan
    foreach ($root in $resolvedRoots) {
        try {
            $dirs = Get-ChildItem -LiteralPath $root -Directory -Recurse -Depth $MaxDepth -ErrorAction SilentlyContinue
            foreach ($d in $dirs) {
                if ($d.Name -eq 'node_modules' -or $d.Name -eq 'target' -or $d.Name -eq '.venv' -or $d.Name -eq 'venv') {
                    $size = Get-DirSize $d.FullName
                    [void]$projectCaches.Add(@{ Path = $d.FullName; Name = $d.Name; Size = $size })
                }
            }
        } catch {}
    }
}

# ---- Scoring & Analytics ----

$totalCdriveCache = [long]0
$totalNonCdriveCache = [long]0

$allScannedCaches = $envData.Node.Caches + $envData.Python.Caches + $envData.Go.Caches + $envData.Rust.Caches + $envData.Java.Caches + $envData.DockerWsl.Caches + $envData.AgentsIde.Paths + $envData.ModelCaches.Paths + $envData.Playwright.Caches + $projectCaches

foreach ($c in $allScannedCaches) {
    if ($c.Path -match "^[Cc]:") {
        $totalCdriveCache += $c.Size
    } else {
        $totalNonCdriveCache += $c.Size
    }
}

# Scoring model
$scoreCdrive = 20
if ($totalCdriveCache -ge 50GB) { $scoreCdrive = 0 }
elseif ($totalCdriveCache -ge 20GB) { $scoreCdrive = 5 }
elseif ($totalCdriveCache -ge 10GB) { $scoreCdrive = 10 }
elseif ($totalCdriveCache -ge 5GB) { $scoreCdrive = 15 }

$redundantRuntimesCount = 0
if ($envData.Node.Version -match 'v') { $redundantRuntimesCount++ }
if ($envData.Python.Version -match '3\.') { $redundantRuntimesCount++ }
if ($envData.Go.Version -match 'go') { $redundantRuntimesCount++ }
if ($envData.Rust.Version -match 'rustc') { $redundantRuntimesCount++ }

$scoreRuntimes = 20
# Simple deduction if runtimes are duplicate or sprawl (mock calculation)
if ($redundantRuntimesCount -gt 4) { $scoreRuntimes = 10 }

$scoreIsolation = 20
$isolationFailures = 0
foreach ($m in $envData.ModelCaches.Paths) {
    if ($m.Path -match "^[Cc]:" -and $m.Size -gt 10GB) { $isolationFailures++ }
}
if ($isolationFailures -gt 0) { $scoreIsolation = 10 }

$scoreAgentState = 20
$totalAgentStateSize = [long]0
foreach ($a in $envData.AgentsIde.Paths) {
    $totalAgentStateSize += $a.Size
}
if ($totalAgentStateSize -gt 5GB) { $scoreAgentState = 10 }

$scoreVirtualization = 20
$totalVhdSize = [long]0
foreach ($v in $envData.DockerWsl.Caches) {
    $totalVhdSize += $v.Size
}
if ($totalVhdSize -gt 50GB) { $scoreVirtualization = 5 }
elseif ($totalVhdSize -gt 20GB) { $scoreVirtualization = 12 }

$totalModelCache = [long]0
$modelCdriveSize = [long]0
foreach ($m in $envData.ModelCaches.Paths) {
    $totalModelCache += $m.Size
    if ($m.Path -match "^[Cc]:") { $modelCdriveSize += $m.Size }
}

$totalBrowserCache = [long]0
foreach ($p in $envData.Playwright.Caches) { $totalBrowserCache += $p.Size }

$totalProjectCache = [long]0
foreach ($p in $projectCaches) { $totalProjectCache += $p.Size }

$totalScore = $scoreCdrive + $scoreRuntimes + $scoreIsolation + $scoreAgentState + $scoreVirtualization
$totalScore = [Math]::Min(100, [Math]::Max(0, $totalScore))

if ($totalScore -ge 90) { $rating = "Highly controlled"; $ratingDetail = "highly controlled" }
elseif ($totalScore -ge 70) { $rating = "Mostly controlled"; $ratingDetail = "mostly controlled" }
elseif ($totalScore -ge 50) { $rating = "Pollution risk"; $ratingDetail = "pollution risk" }
else { $rating = "Environment sprawl"; $ratingDetail = "environment sprawl" }

$scoreRisk = if ($totalScore -ge 90) { "Controlled" } elseif ($totalScore -ge 70) { "Watch" } elseif ($totalScore -ge 50) { "Review" } else { "High" }
$cDriveRisk = if ($totalCdriveCache -ge 20GB) { "High" } elseif ($totalCdriveCache -ge 5GB) { "Watch" } else { "Controlled" }
$wslDockerRisk = if ($totalVhdSize -ge 50GB) { "High" } elseif ($totalVhdSize -ge 20GB) { "Watch" } elseif ($envData.DockerWsl.Distros.Count -gt 0 -or $envData.DockerWsl.Caches.Count -gt 0) { "Mapped" } else { "Controlled" }
$modelRisk = if ($modelCdriveSize -ge 10GB) { "High" } elseif ($totalModelCache -ge 5GB) { "Watch" } else { "Controlled" }

$findings = [System.Collections.ArrayList]@()
$safeSuggestions = [System.Collections.ArrayList]@()
$manualOperations = [System.Collections.ArrayList]@()
$optimizationItems = [System.Collections.ArrayList]@()

[void]$findings.Add("C-drive development footprint: $(Format-Size $totalCdriveCache).")
[void]$findings.Add("Non-C-drive development footprint: $(Format-Size $totalNonCdriveCache).")
if ($envData.DockerWsl.Distros.Count -gt 0) {
    [void]$findings.Add("WSL distros detected: $($envData.DockerWsl.Distros.Count).")
}
if ($envData.DockerWsl.WslConfig.Exists) {
    [void]$findings.Add(".wslconfig found at $($envData.DockerWsl.WslConfig.Path).")
} else {
    [void]$findings.Add(".wslconfig not found in the user profile.")
}
if ($envData.DockerWsl.Caches.Count -gt 0) {
    [void]$findings.Add("WSL/Docker VHDX files detected: $($envData.DockerWsl.Caches.Count), total $(Format-Size $totalVhdSize).")
}
if ($envData.ModelCaches.Paths.Count -gt 0) {
    [void]$findings.Add("AI model cache locations detected: $($envData.ModelCaches.Paths.Count).")
}

[void]$safeSuggestions.Add("Keep cleanup in DryRun mode first and review paths before deletion.")
[void]$safeSuggestions.Add("Prefer moving future reports to .agent_reports/ and temporary files to .agent_tmp/.")
if (-not $envData.DockerWsl.WslConfig.Exists) {
    [void]$safeSuggestions.Add("Consider reviewing whether a .wslconfig file is useful for WSL2 memory/swap/process limits.")
}
if ($envData.PackageEnv.Paths.Count -gt 0) {
    [void]$safeSuggestions.Add("Review path-like cache environment variables before moving cache folders.")
}
if ($totalCdriveCache -gt 10GB) {
    [void]$safeSuggestions.Add("Prioritize C-drive cache owners before deleting anything.")
}

if ($totalCdriveCache -gt 5GB) {
    Add-OptimizationItem -Items $optimizationItems -Area "C-drive footprint" -Why "Development caches on the system drive can create slow, confusing disk pressure." -CanTouch "Review only" -NextStep "Sort the cache owners below by size and handle package caches before touching tool state." -Size $totalCdriveCache -Priority 100
}

foreach ($v in $envData.DockerWsl.Caches) {
    if ($v.Size -gt 20GB) {
        [void]$manualOperations.Add("Large VHDX requires manual review: $($v.Path) ($(Format-Size $v.Size)).")
        Add-OptimizationItem -Items $optimizationItems -Area "WSL/Docker VHDX" -Why "Virtual disks can grow even after data is deleted inside WSL or Docker." -CanTouch "Manual" -NextStep "Use documented WSL/Docker maintenance steps; do not delete or move the VHDX file directly." -Size $v.Size -Priority 95
    }
}
foreach ($m in $envData.ModelCaches.Paths) {
    if ($m.Path -match "^[Cc]:" -and $m.Size -gt 10GB) {
        [void]$manualOperations.Add("Model cache relocation is manual: $($m.Path) ($(Format-Size $m.Size)).")
        Add-OptimizationItem -Items $optimizationItems -Area "Model cache" -Why "Large model files on C drive are high-impact but tool-owned." -CanTouch "Manual" -NextStep "Use tool-supported settings such as HF_HOME or OLLAMA_MODELS before moving future models." -Size $m.Size -Priority 90
    }
}
[void]$manualOperations.Add("WSL export/import, VHDX compaction, Docker data relocation, and .wslconfig edits are never automatic.")

if ($totalBrowserCache -gt 5GB) {
    Add-OptimizationItem -Items $optimizationItems -Area "Browser runtimes" -Why "Playwright/Puppeteer browser binaries are often rebuildable but can be shared by tests." -CanTouch "Safe to review" -NextStep "Check active projects first, then use the browser tool's supported reinstall/cleanup flow." -Size $totalBrowserCache -Priority 80
}
if ($totalProjectCache -gt 1GB) {
    Add-OptimizationItem -Items $optimizationItems -Area "Project build caches" -Why "Project-local dependency and build folders are usually rebuildable but may be expensive to restore." -CanTouch "Review project first" -NextStep "Clean only from the owning project after confirming tests/builds can recreate them." -Size $totalProjectCache -Priority 75
}
if ($envData.PackageEnv.Paths.Count -gt 0) {
    Add-OptimizationItem -Items $optimizationItems -Area "Cache environment variables" -Why "Path-like cache variables decide where future package/model data lands." -CanTouch "Review only" -NextStep "Audit current values before changing shell profiles or user environment variables." -Size 0 -Priority 70
}
if (-not $envData.DockerWsl.WslConfig.Exists -and $envData.DockerWsl.Distros.Count -gt 0) {
    Add-OptimizationItem -Items $optimizationItems -Area "WSL resource policy" -Why "A missing .wslconfig can leave WSL memory/swap behavior implicit." -CanTouch "Manual" -NextStep "Review whether memory, swap, processors, or sparseVhd settings are appropriate before editing config." -Size 0 -Priority 65
}
if ($totalAgentStateSize -gt 5GB) {
    Add-OptimizationItem -Items $optimizationItems -Area "Agent/IDE state" -Why "Agent and IDE state can be large but may contain settings, history, indexes, or sessions." -CanTouch "Do not clean automatically" -NextStep "Use the owning app's cleanup UI or documented cache reset path." -Size $totalAgentStateSize -Priority 60
}

$largeCaches = @($allScannedCaches | Where-Object { $_.Size -gt 1GB } | Sort-Object Size -Descending | Select-Object -First 5)
foreach ($c in $largeCaches) {
    Add-OptimizationItem -Items $optimizationItems -Area "Large cache owner" -Why "$($c.Path) is one of the largest detected local footprints ($(Format-Size $c.Size))." -CanTouch (Get-PathTouchClass $c.Path) -NextStep (Get-PathNextStep $c.Path) -Size $c.Size -Priority 50
}
$optimizationItems = @($optimizationItems | Sort-Object Priority, Size -Descending | Select-Object -First 10)

# ---- Generate Report ----

$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
if (-not $ReportPath) {
    if ($resolvedRoots.Count -gt 0) {
        $rptDir = Join-Path -Path $resolvedRoots[0] -ChildPath ".agent_reports"
        if (-not (Test-Path $rptDir)) { New-Item -ItemType Directory -Path $rptDir -Force | Out-Null }
        $ReportPath = Join-Path $rptDir "dev_environment_hygiene_$timestamp.md"
    } else {
        $ReportPath = ".\dev_environment_hygiene_$timestamp.md"
    }
}

$lines = [System.Collections.ArrayList]@()
[void]$lines.Add("# tidy-skill - Dev Environment Hygiene Audit")
[void]$lines.Add("")
[void]$lines.Add("**Average Control Score:** $totalScore / 100 - **$rating** ($ratingDetail)")
[void]$lines.Add("**Scan Time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$lines.Add("**Scan Roots:** $(if($resolvedRoots.Count -gt 0){$resolvedRoots -join ', '}else{'_None specified (local files only)_'})")
[void]$lines.Add("**Known Cache Paths Scanned:** Yes")
[void]$lines.Add("**User Profile Deep Scan:** $(if($IncludeUserProfile){'Yes'}else{'No'})")
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")
[void]$lines.Add("## Overview Cards")
[void]$lines.Add("")
[void]$lines.Add("| Card | Status | Evidence | Next step |")
[void]$lines.Add("|---|---|---|---|")
[void]$lines.Add("| Environment hygiene | $scoreRisk | $totalScore / 100 - $rating | Review the Top 10 optimization plan before changing anything. |")
[void]$lines.Add("| C-drive risk | $cDriveRisk | $(Format-Size $totalCdriveCache) detected on C drive | Prioritize package and model cache owners before touching tool state. |")
[void]$lines.Add("| WSL/Docker risk | $wslDockerRisk | $($envData.DockerWsl.Distros.Count) distros, $(Format-Size $totalVhdSize) VHDX footprint | Treat migration, compaction, and Docker data moves as manual operations. |")
[void]$lines.Add("| Model cache risk | $modelRisk | $(Format-Size $totalModelCache) total, $(Format-Size $modelCdriveSize) on C drive | Move future models only through tool-supported settings. |")
[void]$lines.Add("")
[void]$lines.Add("## Top 10 Optimization Plan")
[void]$lines.Add("")
if ($optimizationItems.Count -gt 0) {
    [void]$lines.Add("| # | Area | Size | Why it matters | Can touch? | Next step |")
    [void]$lines.Add("|---:|---|---:|---|---|---|")
    $rank = 1
    foreach ($item in $optimizationItems) {
        $why = ($item.Why -replace '\|', '/')
        $next = ($item.NextStep -replace '\|', '/')
        [void]$lines.Add("| $rank | $($item.Area) | $(Format-Size $item.Size) | $why | $($item.CanTouch) | $next |")
        $rank++
    }
} else {
    [void]$lines.Add("_No high-impact optimization items found._")
}
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")
[void]$lines.Add("## Control Score Breakdown")
[void]$lines.Add("")
[void]$lines.Add("| Dimension | Score | Max | Notes |")
[void]$lines.Add("|---|---|---|---|")
[void]$lines.Add("| C-Drive Footprint | $scoreCdrive | 20 | Total C-Drive environment cache: $(Format-Size $totalCdriveCache) |")
[void]$lines.Add("| Active Runtimes | $scoreRuntimes | 20 | Detected toolchains: Go, Python, Node, Rust |")
[void]$lines.Add("| Cache Isolation | $scoreIsolation | 20 | Model caches stored in system drive |")
[void]$lines.Add("| Agent State Cleanliness | $scoreAgentState | 20 | Total IDE & Agent configuration size: $(Format-Size $totalAgentStateSize) |")
[void]$lines.Add("| Virtualization Footprint | $scoreVirtualization | 20 | WSL and Docker vhdx sizes: $(Format-Size $totalVhdSize) |")
[void]$lines.Add("| **Total** | **$totalScore** | **100** | **$rating ($ratingDetail)** |")
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")
[void]$lines.Add("## Findings")
[void]$lines.Add("")
foreach ($item in $findings) { [void]$lines.Add("- $item") }
[void]$lines.Add("")
[void]$lines.Add("## Safe Suggestions")
[void]$lines.Add("")
[void]$lines.Add("These are low-risk review steps. They do not move, delete, compact, or reconfigure system-owned data.")
[void]$lines.Add("")
foreach ($item in $safeSuggestions) { [void]$lines.Add("- $item") }
[void]$lines.Add("")
[void]$lines.Add("## Manual / Risky Operations")
[void]$lines.Add("")
[void]$lines.Add("These require separate confirmation and tool-specific documentation. This report never performs them automatically.")
[void]$lines.Add("")
foreach ($item in $manualOperations) { [void]$lines.Add("- $item") }
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")
[void]$lines.Add("## Environment Mapping Details")
[void]$lines.Add("")

# Node
[void]$lines.Add("### Node / NPM Environment")
[void]$lines.Add("- **Node Version:** $($envData.Node.Version)")
[void]$lines.Add("- **NPM Version:** $($envData.Node.NpmVersion)")
[void]$lines.Add("- **NPM Prefix:** $($envData.Node.Prefix)")
[void]$lines.Add("- **NPM Cache:** $($envData.Node.Cache)")
if ($envData.Node.Caches.Count -gt 0) {
    [void]$lines.Add("- **Caches & Storage:**")
    foreach ($c in $envData.Node.Caches) {
        [void]$lines.Add( ("  - '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
}
[void]$lines.Add("")

# Python
[void]$lines.Add("### Python Environment")
[void]$lines.Add("- **Python Version:** $($envData.Python.Version)")
[void]$lines.Add("- **Uv Version:** $($envData.Python.UvVersion)")
[void]$lines.Add("- **Pip Cache Dir:** $($envData.Python.PipCacheDir)")
if ($envData.Python.Caches.Count -gt 0) {
    [void]$lines.Add("- **Caches & Storage:**")
    foreach ($c in $envData.Python.Caches) {
        [void]$lines.Add( ("  - '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
}
[void]$lines.Add("")

# Go
[void]$lines.Add("### Go Environment")
[void]$lines.Add("- **Go Version:** $($envData.Go.Version)")
[void]$lines.Add("- **GOROOT:** $($envData.Go.Goroot)")
[void]$lines.Add("- **GOPATH:** $($envData.Go.Gopath)")
[void]$lines.Add("- **GOCACHE:** $($envData.Go.Gocache)")
[void]$lines.Add("- **GOMODCACHE:** $($envData.Go.Gomodcache)")
if ($envData.Go.Caches.Count -gt 0) {
    [void]$lines.Add("- **Caches & Storage:**")
    foreach ($c in $envData.Go.Caches) {
        [void]$lines.Add( ("  - '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
}
[void]$lines.Add("")

# Rust
[void]$lines.Add("### Rust Environment")
[void]$lines.Add("- **Rustc Version:** $($envData.Rust.Version)")
[void]$lines.Add("- **Cargo Version:** $($envData.Rust.CargoVersion)")
if ($envData.Rust.Caches.Count -gt 0) {
    [void]$lines.Add("- **Caches & Storage:**")
    foreach ($c in $envData.Rust.Caches) {
        [void]$lines.Add( ("  - '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
}
[void]$lines.Add("")

# Java
[void]$lines.Add("### Java Environment")
[void]$lines.Add("- **JAVA_HOME:** $($envData.Java.JavaHome)")
if ($envData.Java.Caches.Count -gt 0) {
    [void]$lines.Add("- **Caches & Storage:**")
    foreach ($c in $envData.Java.Caches) {
        [void]$lines.Add( ("  - '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
}
[void]$lines.Add("")

# Docker / WSL
[void]$lines.Add("### Docker & WSL Environment")
[void]$lines.Add("- **Docker Version:** $($envData.DockerWsl.DockerVersion)")
[void]$lines.Add("- **WSL Status:**")
if ($envData.DockerWsl.WslStatusReadable -and $envData.DockerWsl.WslStatus -ne "Not Installed") {
    [void]$lines.Add('```text' + "`n" + $envData.DockerWsl.WslStatus + "`n" + '```')
} else {
    [void]$lines.Add("  - Raw status output unavailable or not safely decodable; use parsed distro table below.")
}
[void]$lines.Add("- **WSL Distros:**")
if ($envData.DockerWsl.WslList -and $envData.DockerWsl.WslList -ne "Not Installed") {
    [void]$lines.Add('```text' + "`n" + $envData.DockerWsl.WslList + "`n" + '```')
} else {
    [void]$lines.Add("  - Not Installed or Stopped")
}
if ($envData.DockerWsl.Distros.Count -gt 0) {
    [void]$lines.Add("- **Parsed WSL Distro Table:**")
    [void]$lines.Add("")
    [void]$lines.Add("  | Distro | State | Version |")
    [void]$lines.Add("  |---|---|---|")
    foreach ($d in $envData.DockerWsl.Distros) {
        [void]$lines.Add("  | $($d.Name) | $($d.State) | $($d.Version) |")
    }
}
[void]$lines.Add("- **.wslconfig:** $(if($envData.DockerWsl.WslConfig.Exists){$envData.DockerWsl.WslConfig.Path}else{'not found'})")
if ($envData.DockerWsl.WslConfig.Exists) {
    [void]$lines.Add("  - memory: $(if($envData.DockerWsl.WslConfig.Memory){$envData.DockerWsl.WslConfig.Memory}else{'not set'})")
    [void]$lines.Add("  - swap: $(if($envData.DockerWsl.WslConfig.Swap){$envData.DockerWsl.WslConfig.Swap}else{'not set'})")
    [void]$lines.Add("  - processors: $(if($envData.DockerWsl.WslConfig.Processors){$envData.DockerWsl.WslConfig.Processors}else{'not set'})")
    [void]$lines.Add("  - defaultVhdSize: $(if($envData.DockerWsl.WslConfig.DefaultVhdSize){$envData.DockerWsl.WslConfig.DefaultVhdSize}else{'not set'})")
    [void]$lines.Add("  - autoMemoryReclaim: $(if($envData.DockerWsl.WslConfig.AutoMemoryReclaim){$envData.DockerWsl.WslConfig.AutoMemoryReclaim}else{'not set'})")
    [void]$lines.Add("  - sparseVhd: $(if($envData.DockerWsl.WslConfig.SparseVhd){$envData.DockerWsl.WslConfig.SparseVhd}else{'not set'})")
}
if ($envData.DockerWsl.Caches.Count -gt 0) {
    [void]$lines.Add("- **VHDX File Storage:**")
    foreach ($c in $envData.DockerWsl.Caches) {
        [void]$lines.Add( ("  - [{0}] '{1}' ({2})" -f $c.Owner, $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
}
if ($envData.DockerWsl.DockerSettings.Count -gt 0) {
    [void]$lines.Add("- **Docker Desktop Settings Hints:**")
    foreach ($s in $envData.DockerWsl.DockerSettings) {
        [void]$lines.Add( ("  - '{0}' ({1})" -f $s.Path, (Format-Size $s.Size)).Replace("'", '`') )
    }
}
[void]$lines.Add("")

# Agents / IDE
[void]$lines.Add("### AI Agent & IDE Configurations")
if ($envData.AgentsIde.Paths.Count -gt 0) {
    foreach ($c in $envData.AgentsIde.Paths) {
        [void]$lines.Add( ("- '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
} else {
    [void]$lines.Add("- _No default configuration paths found._")
}
[void]$lines.Add("")

# Model Caches
[void]$lines.Add("### AI Model Caches")
if ($envData.ModelCaches.Paths.Count -gt 0) {
    foreach ($c in $envData.ModelCaches.Paths) {
        [void]$lines.Add( ("- '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
} else {
    [void]$lines.Add("- _No model cache paths found._")
}
[void]$lines.Add("")

# Playwright
[void]$lines.Add("### Playwright / Puppeteer Browser Cache")
if ($envData.Playwright.Caches.Count -gt 0) {
    foreach ($c in $envData.Playwright.Caches) {
        [void]$lines.Add( ("- '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
} else {
    [void]$lines.Add("- _No browser runtime caches found._")
}
[void]$lines.Add("")

# Path-like environment variables
[void]$lines.Add("### Path-like Cache Environment Variables")
if ($envData.PackageEnv.Paths.Count -gt 0) {
    [void]$lines.Add("| Name | Path | Exists | Size |")
    [void]$lines.Add("|---|---|---|---|")
    foreach ($e in $envData.PackageEnv.Paths) {
        [void]$lines.Add( ("| {0} | '{1}' | {2} | {3} |" -f $e.Name, $e.Path, $e.Exists, (Format-Size $e.Size)).Replace("'", '`') )
    }
} else {
    [void]$lines.Add("- _No known path-like cache environment variables found._")
}
[void]$lines.Add("")

# Project level
if ($projectCaches.Count -gt 0) {
    [void]$lines.Add("### Project-level Build & Cache Folders (`node_modules`, `target`, `venv`)")
    foreach ($pc in $projectCaches) {
        [void]$lines.Add( ("- '{0}' ({1})" -f $pc.Path, (Format-Size $pc.Size)).Replace("'", '`') )
    }
    [void]$lines.Add("")
}

# Additional notes
[void]$lines.Add("## Additional Notes")
[void]$lines.Add("")
if ($totalCdriveCache -gt 20GB) {
    [void]$lines.Add("- **C-Drive Risk:** Cache footprint on system C-Drive is substantial ($(Format-Size $totalCdriveCache)). Review owners before relocating or deleting anything.")
}
foreach ($m in $envData.ModelCaches.Paths) {
    if ($m.Path -match "^[Cc]:" -and $m.Size -gt 10GB) {
        [void]$lines.Add( ("- **Model cache:** AI models in '{0}' ({1}) are taking up system space. Relocation is manual and should use tool-supported settings such as OLLAMA_MODELS or HF_HOME." -f $m.Path, (Format-Size $m.Size)).Replace("'", '`') )
    }
}
if ($envData.Playwright.Caches.Count -gt 0) {
    $pwSize = 0
    foreach ($p in $envData.Playwright.Caches) { $pwSize += $p.Size }
    if ($pwSize -gt 5GB) {
        [void]$lines.Add("- **Browser Runtimes:** Playwright/Puppeteer browser cache is large ($(Format-Size $pwSize)). Review project needs before cleanup; browser runtimes can usually be rebuilt.")
    }
}
[void]$lines.Add("- **Safe Cleanup:** Run `.\clean-agent-artifacts.ps1 -Root . -DryRun` to preview project-level cleanup without touching system config.")
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")
[void]$lines.Add("*Report generated by tidy-skill. Local-first, read-only.*")

($lines -join "`n") | Out-File -FilePath $ReportPath -Encoding utf8

# Console output
Write-Host ""
Write-Host "Hygiene score: $totalScore / 100 - $rating ($ratingDetail)" -ForegroundColor $(if ($totalScore -ge 70) { 'Green' } elseif ($totalScore -ge 50) { 'Yellow' } else { 'Red' })
Write-Host "C-Drive Footprint: $(Format-Size $totalCdriveCache)"
Write-Host "Non-C Drive Footprint: $(Format-Size $totalNonCdriveCache)"
Write-Host "Report Path: $ReportPath" -ForegroundColor Cyan
Write-Host ""

return @{
    Score = $totalScore
    Rating = $rating
    ReportPath = $ReportPath
    CdriveSize = $totalCdriveCache
    NonCdriveSize = $totalNonCdriveCache
}
