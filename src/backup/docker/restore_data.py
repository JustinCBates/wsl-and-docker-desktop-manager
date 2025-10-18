"""Placeholder for src/backup/docker/Restore-Data.ps1"""
from step_result import StepResult

def restore_data(dry_run=True):
    if dry_run:
        return StepResult.now(name="restore_data", status="Skipped", message="Dry-run: restore data")
    return StepResult.now(name="restore_data", status="Success", message="MOCK: restore data (no-op)")
