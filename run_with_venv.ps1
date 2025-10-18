<#
.\run_with_venv.ps1

Create (if missing) and activate a local virtualenv at .venv, install runtime
requirements from dependencies\requirements.txt (if present), then run
docker_manager.py in the activated environment.

Usage:
  .\run_with_venv.ps1            # create venv, install deps, run manager
  .\run_with_venv.ps1 -NoInstall # create+activate but skip pip installs

Notes:
 - Run this script from the repository root (the folder that contains docker_manager.py).
 - To run from an elevated PowerShell prompt (recommended for actions that need Admin), open PowerShell As Administrator first.
#>

param(
    [switch]$NoInstall,
    [switch]$Dev,
    [switch]$DevOnly,
    [switch]$NoRun,
    [bool]$Quiet = $false
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Get-Location).Path
$venvPath = Join-Path -Path $repoRoot -ChildPath '.venv'

if (-not (Test-Path $venvPath)) {
    if (-not $Quiet) { Write-Host "Creating virtual environment at $venvPath..." }
    python -m venv $venvPath
}

$activate = Join-Path $venvPath 'Scripts\Activate.ps1'
if (-not (Test-Path $activate)) {
    Write-Error "Activation script not found at $activate"
    exit 1
}

if (-not $Quiet) { Write-Host "Activating virtual environment..." }
. $activate

if (-not $Quiet) { Write-Host "Upgrading pip..." }
# Use pip's quiet flag when running in quiet mode
if ($Quiet) {
    python -m pip install --upgrade pip -q
} else {
    python -m pip install --upgrade pip
}

if (-not $NoInstall) {
    $req = Join-Path $repoRoot 'dependencies\requirements.txt'
    if (Test-Path $req) {
        if (-not $Quiet) { Write-Host "Installing runtime requirements from $req..." }
        if ($Quiet) {
            python -m pip install -r $req -q
        } else {
            python -m pip install -r $req
        }
    } else {
        if (-not $Quiet) { Write-Host "No requirements file found at $req. Skipping pip install." }
    }
} else {
    if (-not $Quiet) { Write-Host "-NoInstall specified: skipping pip installs." }
}

if ($Dev -and -not $NoInstall) {
    $devReq = Join-Path $repoRoot 'dependencies\requirements-dev.txt'
    if (Test-Path $devReq) {
        if (-not $Quiet) { Write-Host "Installing development requirements from $devReq..." }
        if ($Quiet) {
            python -m pip install -r $devReq -q
        } else {
            python -m pip install -r $devReq
        }
    } else {
        if (-not $Quiet) { Write-Host "No dev requirements file found at $devReq. Skipping dev installs." }
    }
}

# If DevOnly was requested, exit after installing dev dependencies (or skipping installs if NoInstall).
if ($DevOnly) {
    if ($NoInstall) {
        if (-not $Quiet) { Write-Host "-DevOnly specified but -NoInstall set: no installs performed. Exiting." }
    } else {
        if (-not $Quiet) { Write-Host "-DevOnly specified: development dependencies installed (if present). Exiting before running manager." }
    }
    exit 0
}

if (-not $Quiet) { Write-Host "`nStarting docker_manager.py (press Ctrl+C to exit)...`n" }
# Always run the interactive manager in the foreground so the TUI/menu is visible.
# Quiet mode only affects pip output, not the interactive program.
python .\docker_manager.py
