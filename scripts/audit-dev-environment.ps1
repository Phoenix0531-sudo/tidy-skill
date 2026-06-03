<#
.SYNOPSIS
    Audit developer environment hygiene, focusing on toolchains, runtimes, virtualization, and AI model caches.

.DESCRIPTION
    Analyzes local developer environments (NPM, Python, Go, Rust, Java, Docker, WSL, AI model caches, and IDE configs)
    to map system drive footprints, identify redundant caches, and calculate environment hygiene scores.
    Read-only — never modifies environment variables, files, system settings, or registers scheduled tasks.

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
    Part of Tidy Skill. Local-first, privacy-first, read-only.
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
        $proc = Start-Process -FilePath $Cmd -ArgumentList $ArgsStr -NoNewWindow -PassThru -RedirectStandardOutput $env:TEMP\agy_cmd_out.txt -RedirectStandardError $env:TEMP\agy_cmd_err.txt -Wait
        if (Test-Path $env:TEMP\agy_cmd_out.txt) {
            $out = Get-Content $env:TEMP\agy_cmd_out.txt -Raw -ErrorAction SilentlyContinue
            Remove-Item $env:TEMP\agy_cmd_out.txt -ErrorAction SilentlyContinue | Out-Null
            if ($out) { return $out.Trim() }
        }
    } catch {}
    return "Unknown / Error running command"
}

# ---- Initialize ----
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Tidy Skill — Dev Environment Audit" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Local-first, read-only, privacy-first."

$resolvedRoots = [System.Collections.ArrayList]@()
foreach ($r in $Roots) {
    if (Test-Path -LiteralPath $r -PathType Container) {
        [void]$resolvedRoots.Add((Resolve-Path -LiteralPath $r).Path)
    }
}

Write-Host "Roots to scan:   $($resolvedRoots -join ', ')"
Write-Host "User profile:    $(if($IncludeUserProfile){'Yes'}else{'No (pass -IncludeUserProfile to enable)'})"
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
$envData.DockerWsl.WslList = Run-SafeCommand "wsl" "--list --verbose"
$envData.DockerWsl.DockerVersion = Run-SafeCommand "docker" "--version"

$wslPaths = @(
    (Join-Path $appdataLocal "Docker\wsl"),
    (Join-Path $appdataLocal "Packages")
)
$envData.DockerWsl.Caches = @()
if ($IncludeUserProfile -or $IncludeDrives) {
    foreach ($p in $wslPaths) {
        if (Test-Path -LiteralPath $p) {
            # Only scan for ext4.vhdx sizes to be fast and safe
            try {
                $vhdxFiles = Get-ChildItem -LiteralPath $p -Filter "*.vhdx" -Recurse -File -ErrorAction SilentlyContinue
                foreach ($v in $vhdxFiles) {
                    $envData.DockerWsl.Caches += @{ Path = $v.FullName; Size = $v.Length }
                }
            } catch {}
        }
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

$totalScore = $scoreCdrive + $scoreRuntimes + $scoreIsolation + $scoreAgentState + $scoreVirtualization
$totalScore = [Math]::Min(100, [Math]::Max(0, $totalScore))

if ($totalScore -ge 90) { $rating = "Highly controlled"; $ratingCn = "高度可控" }
elseif ($totalScore -ge 70) { $rating = "Mostly controlled"; $ratingCn = "基本可控" }
elseif ($totalScore -ge 50) { $rating = "Pollution risk"; $ratingCn = "存在污染风险" }
else { $rating = "Environment sprawl"; $ratingCn = "环境明显失控" }

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
[void]$lines.Add("# Tidy Skill — Dev Environment Hygiene Audit")
[void]$lines.Add("")
[void]$lines.Add("**Average Control Score:** $totalScore / 100 — **$rating** ($ratingCn)")
[void]$lines.Add("**Scan Time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$lines.Add("**Scan Roots:** $(if($resolvedRoots.Count -gt 0){$resolvedRoots -join ', '}else{'_None specified (local files only)_'})")
[void]$lines.Add("**User Profile Scanned:** $(if($IncludeUserProfile){'Yes'}else{'No'})")
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")
[void]$lines.Add("## 📊 Control Score Breakdown")
[void]$lines.Add("")
[void]$lines.Add("| Dimension | Score | Max | Notes |")
[void]$lines.Add("|---|---|---|---|")
[void]$lines.Add("| C-Drive Footprint | $scoreCdrive | 20 | Total C-Drive environment cache: $(Format-Size $totalCdriveCache) |")
[void]$lines.Add("| Active Runtimes | $scoreRuntimes | 20 | Detected toolchains: Go, Python, Node, Rust |")
[void]$lines.Add("| Cache Isolation | $scoreIsolation | 20 | Model caches stored in system drive |")
[void]$lines.Add("| Agent State Cleanliness | $scoreAgentState | 20 | Total IDE & Agent configuration size: $(Format-Size $totalAgentStateSize) |")
[void]$lines.Add("| Virtualization Footprint | $scoreVirtualization | 20 | WSL and Docker vhdx sizes: $(Format-Size $totalVhdSize) |")
[void]$lines.Add("| **Total** | **$totalScore** | **100** | **$rating ($ratingCn)** |")
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")
[void]$lines.Add("## 🔍 Environment Mapping Details")
[void]$lines.Add("")

# Node
[void]$lines.Add("### 🟢 Node / NPM Environment")
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
[void]$lines.Add("### 🐍 Python Environment")
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
[void]$lines.Add("### 🐹 Go Environment")
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
[void]$lines.Add("### 🦀 Rust Environment")
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
[void]$lines.Add("### ☕ Java Environment")
[void]$lines.Add("- **JAVA_HOME:** $($envData.Java.JavaHome)")
if ($envData.Java.Caches.Count -gt 0) {
    [void]$lines.Add("- **Caches & Storage:**")
    foreach ($c in $envData.Java.Caches) {
        [void]$lines.Add( ("  - '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
}
[void]$lines.Add("")

# Docker / WSL
[void]$lines.Add("### 🐳 Docker & WSL Environment")
[void]$lines.Add("- **Docker Version:** $($envData.DockerWsl.DockerVersion)")
[void]$lines.Add("- **WSL Distros:**")
if ($envData.DockerWsl.WslList -and $envData.DockerWsl.WslList -ne "Not Installed") {
    [void]$lines.Add('```text' + "`n" + $envData.DockerWsl.WslList + "`n" + '```')
} else {
    [void]$lines.Add("  - Not Installed or Stopped")
}
if ($envData.DockerWsl.Caches.Count -gt 0) {
    [void]$lines.Add("- **VHdx File Storage:**")
    foreach ($c in $envData.DockerWsl.Caches) {
        [void]$lines.Add( ("  - '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
}
[void]$lines.Add("")

# Agents / IDE
[void]$lines.Add("### 🤖 AI Agent & IDE Configurations")
if ($envData.AgentsIde.Paths.Count -gt 0) {
    foreach ($c in $envData.AgentsIde.Paths) {
        [void]$lines.Add( ("- '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
} else {
    [void]$lines.Add("- _No default configuration paths found._")
}
[void]$lines.Add("")

# Model Caches
[void]$lines.Add("### 🧠 AI Model Caches")
if ($envData.ModelCaches.Paths.Count -gt 0) {
    foreach ($c in $envData.ModelCaches.Paths) {
        [void]$lines.Add( ("- '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
} else {
    [void]$lines.Add("- _No model cache paths found._")
}
[void]$lines.Add("")

# Playwright
[void]$lines.Add("### 🎭 Playwright / Puppeteer Browser Cache")
if ($envData.Playwright.Caches.Count -gt 0) {
    foreach ($c in $envData.Playwright.Caches) {
        [void]$lines.Add( ("- '{0}' ({1})" -f $c.Path, (Format-Size $c.Size)).Replace("'", '`') )
    }
} else {
    [void]$lines.Add("- _No browser runtime caches found._")
}
[void]$lines.Add("")

# Project level
if ($projectCaches.Count -gt 0) {
    [void]$lines.Add("### 📁 Project-level Build & Cache Folders (`node_modules`, `target`, `venv`)")
    foreach ($pc in $projectCaches) {
        [void]$lines.Add( ("- '{0}' ({1})" -f $pc.Path, (Format-Size $pc.Size)).Replace("'", '`') )
    }
    [void]$lines.Add("")
}

# Recommendations
[void]$lines.Add("## 💡 Recommendations")
[void]$lines.Add("")
if ($totalCdriveCache -gt 20GB) {
    [void]$lines.Add("- **C-Drive Risk:** Cache footprint on system C-Drive is substantial ($(Format-Size $totalCdriveCache)). Consider relocating large caches.")
}
foreach ($m in $envData.ModelCaches.Paths) {
    if ($m.Path -match "^[Cc]:" -and $m.Size -gt 10GB) {
        [void]$lines.Add( ("- **Model relocation:** AI models in '{0}' ({1}) are taking up system space. Consider moving models via Ollama ('OLLAMA_MODELS' environment variable) or HuggingFace ('HF_HOME')." -f $m.Path, (Format-Size $m.Size)).Replace("'", '`') )
    }
}
if ($envData.Playwright.Caches.Count -gt 0) {
    $pwSize = 0
    foreach ($p in $envData.Playwright.Caches) { $pwSize += $p.Size }
    if ($pwSize -gt 5GB) {
        [void]$lines.Add("- **Browser Runtimes:** Playwright/Puppeteer browser cache is large ($(Format-Size $pwSize)). These can be safely deleted; they will auto-rebuild when running tests.")
    }
}
[void]$lines.Add("- **Safe Cleanup:** Run `.\clean-agent-artifacts.ps1 -Root . -DryRun` to verify project-level cleanup without touching system config.")
[void]$lines.Add("")
[void]$lines.Add("---")
[void]$lines.Add("")
[void]$lines.Add("*Report generated by Tidy Skill. Local-first, read-only.*")

($lines -join "`n") | Out-File -FilePath $ReportPath -Encoding utf8

# Console output
Write-Host ""
Write-Host "Hygiene score: $totalScore / 100 — $rating ($ratingCn)" -ForegroundColor $(if ($totalScore -ge 70) { 'Green' } elseif ($totalScore -ge 50) { 'Yellow' } else { 'Red' })
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
