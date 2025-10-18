# Proposal: Python-only `src/` migration (draft)

This document is a draft proposal describing a minimal, reviewable migration of the repository `src/` area to a Python-first layout. It is intentionally conservative: no deletions will be performed until you (the repository owner) approve the exact list of file moves/creates/deletes.

Goals

- Provide a single, consistent Python package root under `src/` for all runtime code.
- Preserve the mocks-first approach: initial implementations are inert and return `StepResult` objects.
- Make imports stable for running from the repository root (no fragile relative imports that fail when `src` is added to `sys.path`).
- Minimize churn: list all changes before making them; perform one small migration at a time with tests.

High-level plan

1. Create a top-level package `src/wsl_and_docker_manager/` (or similar; this doc will use `wsl_docker_manager` as the name) with `__init__.py` and public entrypoints.
2. Move existing `src/*` modules into the package under appropriate subpackages (install, uninstall, status, backup, step_runner, step_result).
3. Update imports to absolute package imports (for example `from wsl_docker_manager.step_result import StepResult`).
4. Add small unit tests per orchestrator under `tests/` that run the orchestrator in dry-run mode.
5. Run linters (ruff) and unit tests. Keep changes small and reviewed.

Proposed package layout (file/dir manifest)

NOTE: This is a proposal only. Do NOT execute until you approve.

Create:

- src/wsl_docker_manager/__init__.py (exports top-level helpers and orchestrators)
- src/wsl_docker_manager/step_result.py (already present) -> moved
- src/wsl_docker_manager/step_runner.py (already present) -> moved

Create directories (move existing files under these):

- src/wsl_docker_manager/install/
  - __init__.py
  - orchestrator.py (formerly `src/install/Install-Orchestrator.py`)
  - docker.py (formerly `src/install/docker/install_docker.py`)
  - wsl.py (formerly `src/install/wsl/install_wsl.py`)

- src/wsl_docker_manager/uninstall/
  - __init__.py
  - orchestrator.py (formerly `src/uninstall/uninstall_orchestrator.py`)
  - docker.py (formerly `src/uninstall/docker/uninstall_docker.py`)
  - wsl.py (formerly `src/uninstall/wsl/uninstall_wsl.py`)

- src/wsl_docker_manager/status/
  - __init__.py
  - system.py (formerly `src/status/get_system_status.py`)
  - docker.py (formerly `src/status/docker/get_docker_status.py`)
  - wsl.py (formerly `src/status/wsl/get_wsl_status.py`)

- src/wsl_docker_manager/backup/
  - __init__.py
  - orchestrator.py (formerly `src/backup/backup_orchestrator.py`)
  - docker/
    - backup_data.py (formerly `src/backup/docker/backup_data.py`)
    - restore_data.py (formerly `src/backup/docker/restore_data.py`)

Keep (no move):

- tools/ (smoke runners and helpers)
- tests/ (tests live here and can be updated to import from the package)

Rationale and trade-offs

- Using a single package (`wsl_docker_manager`) avoids ambiguous top-level modules when importing from the repository root.
- Absolute imports are portable and work with `python -m` execution patterns.
- Moving files is low-risk if done incrementally and with tests after each unit.

Assumptions

- You approve the package name `wsl_docker_manager`. If you prefer another name, state it and I'll update the manifest.
- We'll perform changes one orchestrator at a time (you previously asked for single-unit conversions).

Acceptance criteria for each small migration step

- A unit test is added/updated and passes (dry-run acceptable for mocks-first).
- Linter/pyproject checks pass (ruff configured in `src/pyproject.toml`).
- No change to repository-wide licenses or root README without explicit approval.

Next steps after your approval

1. I will present a concrete patch for moving one small set of files (for example the `uninstall` orchestrator) that includes the exact file renames/moves and updated imports.
2. You will review the patch; once approved I'll apply it, run tests, and commit.
3. Repeat for the next orchestrator.

If you approve this proposal, tell me which orchestrator to migrate first (I recommend `uninstall`, which is already converted to StepRunner/StepResult and has tests). If you want me to use a different package name, say so and I'll update the draft.

<!-- End of draft migration proposal -->
