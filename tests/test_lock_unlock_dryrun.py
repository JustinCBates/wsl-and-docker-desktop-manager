"""Run lock/unlock PowerShell scripts with -DryRun and assert they don't change ACLs.

These tests execute PowerShell in a subprocess and capture output. They are
skipped on non-Windows systems.
"""
import sys
import subprocess
from pathlib import Path

import pytest
import os


def is_windows():
    return sys.platform.startswith("win")


@pytest.mark.skipif(not is_windows(), reason="PowerShell tests only on Windows")
def test_lock_dryrun_outputs_expected_text(tmp_path):
    script = Path("tools/acl/lock_repo_acl.ps1")
    assert script.exists()

    # Run PowerShell with DryRun and capture output
    allow_principal = f"{os.environ.get('USERDOMAIN','')}\\{os.environ.get('USERNAME','')}"

    completed = subprocess.run(
        [
            "powershell",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(script),
            "-RepoPath",
            str(tmp_path),
            "-BackupFile",
            str(tmp_path / "acl-backup.acl"),
            "-AllowPrincipal",
            allow_principal,
            "-DryRun",
        ],
        capture_output=True,
        text=True,
        check=False,
    )

    out = completed.stdout + completed.stderr
    assert completed.returncode == 0, f"Lock script failed: {out}"
    assert "DRYRUN: icacls" in out


@pytest.mark.skipif(not is_windows(), reason="PowerShell tests only on Windows")
def test_unlock_dryrun_outputs_expected_text(tmp_path):
    script = Path("tools/acl/unlock_repo_acl.ps1")
    assert script.exists()

    # Create a fake backup file so the script passes the Test-Path checks
    backup = tmp_path / "acl-backup.acl"
    backup.write_text("fake-acl")

    completed = subprocess.run(
        [
            "powershell",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(script),
            "-RepoPath",
            str(tmp_path),
            "-BackupFile",
            str(backup),
            "-DryRun",
        ],
        capture_output=True,
        text=True,
        check=False,
    )

    out = completed.stdout + completed.stderr
    assert "DRYRUN: icacls" in out
