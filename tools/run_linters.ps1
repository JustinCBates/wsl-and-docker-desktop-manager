<#
tools/run_linters.ps1
Helper to run Python linters (ruff) across `src/`.
Usage:
  .\tools\run_linters.ps1            # run checks
  .\tools\run_linters.ps1 -Fix      # run fixes where ruff supports them

This script installs ruff into the active Python environment if it's missing.
#>
param(
    [switch]$Fix
)

function Write-Log($msg) {
    Write-Host "[run_linters] $msg"
}

# Find python
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Log "Python not found in PATH. Activate your virtualenv or install Python."
    exit 0
}
$python = $pythonCmd.Path

# Check if ruff is installed
$check = & $python -m pip show ruff 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Log "ruff not found. Installing ruff into the active Python environment..."
    & $python -m pip install ruff
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install ruff. Please install it manually: python -m pip install ruff"
        exit 1
    }
}

# Build the ruff command
if ($Fix) {
    Write-Log "Running ruff with --fix on src/"
    & $python -m ruff check src --fix
} else {
    Write-Log "Running ruff check on src/"
    & $python -m ruff check src
}

exit $LASTEXITCODE
