"""Tests for the unlock_repo_acl.ps1 helper.

These tests avoid executing PowerShell. Instead they perform a lightweight
static check that the script contains the expected safety checks and the
icacls restore invocation. That gives quick coverage without requiring
administrative privileges or touching ACLs.
"""
from pathlib import Path


def test_unlock_script_exists():
    script = Path("tools/acl/unlock_repo_acl.ps1")
    assert script.exists(), "unlock_repo_acl.ps1 should exist under tools/acl"


def test_unlock_script_has_checks_and_restore():
    script = Path("tools/acl/unlock_repo_acl.ps1")
    content = script.read_text(encoding="utf-8")

    # Ensure the script validates inputs
    assert (
        "Test-Path $RepoPath" in content
        or "if (-not (Test-Path $RepoPath))" in content
    ), "Script should check that the repo path exists"

    assert (
        "Test-Path $BackupFile" in content
        or "if (-not (Test-Path $BackupFile))" in content
    ), "Script should check that the backup file exists before restoring"

    # Ensure the script restores ACLs using icacls
    assert (
        'icacls "$RepoPath" /restore "$BackupFile"' in content
    ), "Script should call icacls ... /restore to restore backed-up ACLs"

    # Default backup filename present
    assert 'acl-backup.acl' in content, "Default backup filename should be 'acl-backup.acl'"
