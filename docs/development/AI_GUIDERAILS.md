<!-- Canonical development guiderails file (development-branch only). Use the ALL-CAPS filename to make the development-only status obvious. -->

# Development guide rails

These are repository-level constraints and rules to guide development for the MVP. They are intentionally strict to keep changes focused and reviewable. This file is for development branches only and must not be merged to `main` unless the repository owner explicitly approves.

Key rules

- Documentation-only policy: non-code documentation produced by the assistant must be placed under `docs/`. The assistant may also edit the root `README.md` and `README.md` files inside `src/`, `tools/`, and `tests/`.
- No code outside `src/`, `tests/`, or `tools/`: the assistant must not create or modify source files outside those directories unless the repo owner explicitly approves and provides a reason.
- Tests framework deferred: references to test frameworks (Pester, pytest, etc.) and CI wiring are backlog items and will be addressed after core UI flows are validated with mocks.
- Single root orchestrator: there should be one canonical orchestrator entrypoint at the repository root (for example `orchestrator.ps1` or `orchestrator.sh`). A bootstrap script for initializing the Python environment (for example `init-python.sh`) may also exist at repo root.
- Mocks-first approach: initial implementations for UI testing must use mocks inside `src/` only. Mocks must be inert and clearly labeled.
- Ask before global or structural changes: any change that adds files outside `src/`, `tests/`, or `tools/` requires explicit permission and a short rationale from the repository owner.

Placement of new code

- Do not create new top-level directories without explicit approval. If a shared library or helper is required for the orchestrator, place it under `src/` by default.
- Any proposed structural change (for example adding `src/wsl_docker_manager/` or moving files) must include a short rationale and a list of all files and directories that will be created, moved, or deleted. Present that list and obtain approval before making the change.
- The assistant may create small, temporary helper files under `tools/` or `src/` only when explicitly requested and after showing the proposed filenames.

Directory creation and structural changes

- The repository owner defines the canonical `src/` directory structure. The assistant MUST NOT create new top-level directories or add new high-level packages under `src/` without explicit, pre-approved permission.
- Any proposed structural change must include a complete file/dir manifest and rationale and await approval.

Notes

- This file is intended to remain in `docs/development/` and should not be referenced directly from `main`.
- If a case-only rename is needed on a case-insensitive file system (for example to change `AI_Guiderails.md` -> `AI_GUIDERAILS.md`), perform the rename by creating the new file and deleting the old one to ensure Git records the change reliably on Windows.

Explicit prohibition

- Creating new top-level packages under `src/` is forbidden unless the repository owner provides explicit written approval listing the exact files and directories to be created. This includes names like `src/wsl_docker_manager/`, `src/my_new_pkg/`, or any other new top-level package/directory. The assistant must NOT introduce such packages.


<!-- End of development guiderails -->
<!-- Canonical development guiderails file with uppercase name -->

# Development guide rails

These are repository-level constraints and rules to guide development for the MVP. They are intentionally strict to keep changes focused and reviewable.

- Documentation-only policy: any non-code documentation created by the assistant must be placed in the `docs/` directory. The assistant may also edit the root `README.md`, and `README.md` files located in the `src/`, `tools/`, and `tests/` directories.
- No code outside `src/`, `tests/`, or `tools/`: the assistant must not create or modify source code files outside the `src/`, `tests/`, and `tools/` directories unless you (the repo owner) explicitly approve and provide a reason.
- Tests framework deferred: references to Pester or other test frameworks are considered backlog items. Test framework selection and CI wiring will be addressed after core UI flows are validated with mocks.
- Single root orchestrator: there should be one canonical orchestrator entrypoint located at the repository root (for example `orchestrator.ps1` or `orchestrator.sh`). This orchestrator coordinates high-level tasks. A bootstrap script for initializing the Python environment and dependencies (for example `init-python.sh`) may also exist at the repo root.
- Mocks-first approach: initial implementations for UI testing will use mock functions inside `src/` only. These mocks must be inert and clearly labeled.
- Ask before global changes: if any change requires adding files outside `src/`, `tests/`, or `tools/`, the assistant must request explicit permission and provide a justification.

### Placement of new code

- Do not create new top-level directories (for example `scripts/orchestrator/`) without explicit approval. If a shared library or helper is required for the orchestrator, place it under `src/` by default. For example, the StepRunner library should live at `src/orchestrator/StepRunner.ps1` (or a similar path under `src/`) unless you approve an alternative location and provide a rationale.

Additions that deviate from these placement rules require your sign-off.
 
## Directory creation and structural changes

- The repository owner (you) defines the canonical `src/` directory structure. The assistant MUST NOT create new top-level directories or add new high-level packages under `src/` without explicit, pre-approved permission.
- Any proposed structural change (for example adding `src/wsl_docker_manager/` or moving files) must include a short rationale and a list of *all* files and directories that will be created, moved, or deleted. The assistant must present this list and obtain your approval before making the change.
- The assistant may create small, temporary helper files under `tools/` or `src/` only when explicitly requested and after showing the proposed filenames.

These rules ensure the repository layout remains under your control and avoids surprises during design or migration work.
# Development guide rails

These are repository-level constraints and rules to guide development for the MVP. They are intentionally strict to keep changes focused and reviewable.

- Documentation-only policy: any non-code documentation created by the assistant must be placed in the `docs/` directory. The assistant may also edit the root `README.md`, and `README.md` files located in the `src/`, `tools/`, and `tests/` directories.
- No code outside `src/`, `tests/`, or `tools/`: the assistant must not create or modify source code files outside the `src/`, `tests/`, and `tools/` directories unless you (the repo owner) explicitly approve and provide a reason.
- Tests framework deferred: references to Pester or other test frameworks are considered backlog items. Test framework selection and CI wiring will be addressed after core UI flows are validated with mocks.
- Single root orchestrator: there should be one canonical orchestrator entrypoint located at the repository root (for example `orchestrator.ps1` or `orchestrator.sh`). This orchestrator coordinates high-level tasks. A bootstrap script for initializing the Python environment and dependencies (for example `init-python.sh`) may also exist at the repo root.
- Mocks-first approach: initial implementations for UI testing will use mock functions inside `src/` only. These mocks must be inert and clearly labeled.
- Ask before global changes: if any change requires adding files outside `src/`, `tests/`, or `tools/`, the assistant must request explicit permission and provide a justification.

### Placement of new code

- Do not create new top-level directories (for example `scripts/orchestrator/`) without explicit approval. If a shared library or helper is required for the orchestrator, place it under `src/` by default. For example, the StepRunner library should live at `src/orchestrator/StepRunner.ps1` (or a similar path under `src/`) unless you approve an alternative location and provide a rationale.

Additions that deviate from these placement rules require your sign-off.
<!-- Development-only guiderails. This file should remain in development branches only. -->

# Development guide rails

These are repository-level constraints and rules to guide development for the MVP. They are intentionally strict to keep changes focused and reviewable.

- Documentation-only policy: any non-code documentation created by the assistant must be placed in the `docs/` directory. The assistant may also edit the root `README.md`, and `README.md` files located in the `src/`, `tools/`, and `tests/` directories.
- No code outside `src/`, `tests/`, or `tools/`: the assistant must not create or modify source code files outside the `src/`, `tests/`, and `tools/` directories unless you (the repo owner) explicitly approve and provide a reason.
- Tests framework deferred: references to Pester or other test frameworks are considered backlog items. Test framework selection and CI wiring will be addressed after core UI flows are validated with mocks.
- Single root orchestrator: there should be one canonical orchestrator entrypoint located at the repository root (for example `orchestrator.ps1` or `orchestrator.sh`). This orchestrator coordinates high-level tasks. A bootstrap script for initializing the Python environment and dependencies (for example `init-python.sh`) may also exist at the repo root.
- Mocks-first approach: initial implementations for UI testing will use mock functions inside `src/` only. These mocks must be inert and clearly labeled.
- Ask before global changes: if any change requires adding files outside `src/`, `tests/`, or `tools/`, the assistant must request explicit permission and provide a justification.

### Placement of new code

- Do not create new top-level directories (for example `scripts/orchestrator/`) without explicit approval. If a shared library or helper is required for the orchestrator, place it under `src/` by default. For example, the StepRunner library should live at `src/orchestrator/StepRunner.ps1` (or a similar path under `src/`) unless you approve an alternative location and provide a rationale.

Additions that deviate from these placement rules require your sign-off.
