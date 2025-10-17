ACL tools
=========

This directory will contain scripts to lock/unlock NTFS ACLs for the repo root. These scripts will be powerful and require admin privileges. Use with caution.

Files added by the agent:
- lock_repo_acl.ps1 — backup ACLs and lock the repo root so only specified accounts can create top-level directories.
- unlock_repo_acl.ps1 — restore the saved ACL backup.

Read the scripts before running. Test on a non-critical folder first (for example a temporary copy outside OneDrive).
