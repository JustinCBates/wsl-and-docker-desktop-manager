"""Placeholder for src/backup/Backup-orchestrator.ps1"""

def backup_sequence(dry_run=True):
    return [{"name": "backup_data", "status": "Skipped" if dry_run else "Success", "message": "MOCK: backup data"}]
