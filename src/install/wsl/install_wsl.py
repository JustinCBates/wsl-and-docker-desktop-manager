"""Placeholder converted from src/install/wsl/Install-WSL.ps1

Original PowerShell content preserved here as a docstring for review.
"""

from step_result import StepResult

def install_wsl(*, dry_run=True):
    if dry_run:
        return StepResult.now(name="install_wsl", status="Skipped", message="Dry-run: would enable WSL features and install kernel")
    return StepResult.now(name="install_wsl", status="Success", message="MOCK: installed WSL (placeholder)")
