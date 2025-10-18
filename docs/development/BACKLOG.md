````markdown
# Development Backlog

This file captures backlog items that are intentionally deferred from the MVP and development guidance. These items live under `docs/development/` and should not be merged to `main`.

## Development Backlog (reference)

This document records deferred items, design notes, and improvement ideas that are intentionally postponed from the MVP. It is a reference for maintainers. Entries are written as headings and paragraphs rather than checklist items so they are not picked up by editor todo parsers.

## Repo protection and ACL backlog

Require explicit -AllowPrincipal for lock_repo_acl.ps1

Rationale: make the lock operation require an explicit principal argument so a maintainer cannot accidentally grant the current user FullControl when locking repository ACLs. Implementation work is deferred until an approved admin flow is documented.

Git-level protections (pre-commit and CI)

Rationale: add defense-in-depth by implementing a pre-commit hook and a GitHub Action that detect and block new top-level directories or files being added to the repository root.

Document Deny-ACE plan and emergency restore steps

Rationale: document the risks and an emergency recovery plan (including `icacls /restore` usage and recommended recovery account(s)) so maintainers know exact recovery steps.

## Dependency & migration backlog

Move dependency manifests into `dependencies/`

Rationale: centralize generated `requirements*.in` and pinned `requirements*.txt` under `dependencies/` and update CI/scripts/docs to reference that location.

Draft Python-only `src/` migration plan

Rationale: prepare a careful, reviewable migration plan for converting `src/` to Python-only. The plan should list exact file operations, compatibility checks, and a rollback strategy.

## Misc backlog

StepRunner / StepResult conversion

Rationale: convert placeholder modules to return structured `StepResult` objects and wire `StepRunner` to improve testing and observability of orchestration steps.

Cherry-pick recovered commits onto `build`

Rationale: ensure recovered documentation edits are preserved on the `build` branch and validated before any publish steps.

