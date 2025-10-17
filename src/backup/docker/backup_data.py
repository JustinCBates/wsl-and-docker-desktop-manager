"""Placeholder for src/backup/docker/Backup-Data.ps1"""
from step_result import StepResult

def backup_data(dry_run=True):
    if dry_run:
        return StepResult.now(name="backup_data", status="Skipped", message="Dry-run: backup data")
    return StepResult.now(name="backup_data", status="Success", message="MOCK: backup data (no-op)")
