"""Placeholder for src/status/wsl/Get-WSLStatus.ps1"""
from step_result import StepResult

def get_wsl_status(dry_run: bool = True):
    if dry_run:
        return StepResult.now(name="get_wsl_status", status="Skipped", message="Dry-run: wsl status")
    return StepResult.now(name="get_wsl_status", status="Success", message="MOCK: no distros installed")
