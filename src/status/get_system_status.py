"""Placeholder for src/status/Get-SystemStatus.ps1"""
from step_result import StepResult

def get_system_status(dry_run: bool = True):
    if dry_run:
        return StepResult.now(name="get_system_status", status="Skipped", message="Dry-run: system status")
    return StepResult.now(name="get_system_status", status="Success", message="MOCK: system status OK")
