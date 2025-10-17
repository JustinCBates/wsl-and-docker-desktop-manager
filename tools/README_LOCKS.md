Repository local warnings and optional hooks
=========================================

This folder contains optional, local tooling to warn developers when new top-level
directories are created in the repository. These are advisory tools (they warn but
do not prevent operations) and are intended for local developer use only.

Files
- watch_repo_root.ps1 — long-running FileSystemWatcher that warns when a new top-level directory is created. Run with:

  powershell -File .\tools\watch_repo_root.ps1

  Pass `-Toast` to enable Windows desktop toasts (requires BurntToast module).

- precommit_warning.ps1 — non-blocking pre-commit hook script that warns if a staged commit would add a new top-level directory. Install with:

  powershell -File .\tools\install_precommit_warning.ps1

- prevent_root_dirs.py — optional blocking checker (intended for a pre-commit hook that fails). Use this if you want hard blocking locally.

Notes
- These tools are advisory. For hard enforcement, consider the NTFS ACL scripts (`lock_repo_acl.ps1`/`unlock_repo_acl.ps1`) which must be run with care.
- Because the repository is under OneDrive, you may see extra filesystem noise; adjust the allowlist accordingly.
