````markdown
# Development Backlog

This file captures backlog items that are intentionally deferred from the MVP and development guidance. These items live under `docs/development/` and should not be merged to `main`.

## Repo protection and ACL backlog

- Require explicit `-AllowPrincipal` for `tools/acl/lock_repo_acl.ps1` so the lock operation cannot accidentally grant the current user full control. (Backlog)
- Add Git-level protections (pre-commit hook and/or GitHub Action) that block adding new top-level directories or files to the repository root as a defense-in-depth measure. (Backlog)
- Document admin/service account flow and recovery plan for ACL locking, including secure storage guidance for ACL backup files. (Backlog)
- Document Deny-ACE plan and emergency restore steps (icacls /restore) and recommended recovery account(s). (Backlog)

## Dependency & migration backlog

- Move dependency manifests (generated `requirements*.in` and pinned `requirements*.txt`) into the `dependencies/` directory and update scripts/CI/docs to use that path. (Backlog)
- Draft a detailed plan for migrating `src/` to Python-only, including file moves, compatibility concerns, and a rollback strategy. (Backlog)

## Misc backlog

- Convert placeholder modules to return `StepResult` and wire `StepRunner` for step orchestration where appropriate. (Backlog)
- Cherry-pick recovered commits onto `build` and validate documentation changes before publishing. (Backlog)

````
