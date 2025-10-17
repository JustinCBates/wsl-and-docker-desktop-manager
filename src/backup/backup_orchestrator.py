"""Placeholder for src/backup/Backup-orchestrator.ps1"""
from step_result import StepResult

def backup_sequence(dry_run=True):
    if dry_run:
        return [StepResult.now(name="backup_data", status="Skipped", message="Dry-run: backup")]
    return [StepResult.now(name="backup_data", status="Success", message="MOCK: backup data")]
