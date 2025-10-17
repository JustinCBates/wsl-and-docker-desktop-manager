# MVP Specification and Architecture

## Overview
This document describes the Minimum Viable Product (MVP) for the "WSL and Docker Desktop Manager" project. The MVP will focus on two primary capabilities and do them well:

1. Completely uninstall Docker Desktop/engine and related artifacts from a Windows host.
2. Uninstall WSL distributions and related artifacts, and provide a reliable install path to enable WSL2 and install Docker Desktop configured for developer best practices.

Per direction, the MVP will not include any backup features — backups are listed in the backlog.

## Scope and constraints
- Target platform: Windows 10/11 with administrative privileges available.
- Operations may require elevation and often require reboots when enabling Windows features.
- The orchestrator will be implemented in PowerShell (Option A), reusing the existing script set.
- All destructive operations require an explicit `-Yes` flag; otherwise the orchestrator will abort with a summary of actions.
- The orchestrator supports `-DryRun` and `-LogPath <path>` for structured logging.

## Contract (inputs / outputs / success)
- Inputs:
  - CLI flags: `-DryRun`, `-Yes`, `-LogPath <path>`, `-WslVersion <1|2>` (default 2), `-InstallDesktop` (bool, default true).
- Outputs:
  - Exit codes: `0` = success, non-zero = error.
  - A JSON structured log written to `-LogPath` when provided (contains step-level results and timestamps).
- Success criteria:
  - Uninstall path: Docker Desktop and engine are removed and no Docker services/processes remain; WSL distros that the user allowed to be removed are unregistered and WSL state is cleaned.
  - Install path: WSL default version set to 2; Docker Desktop installed; docker client and server respond to `docker version`.

## Repository architecture (directory & file layout)
Below is the repository structure relevant to the orchestrator and MVP (trimmed to important files/folders):

- README.md
- docs/
  - spec.md  <-- this file
- scripts/
  - Install-Orchestrator.ps1
  - Uninstall-Orchestrator.ps1
  - Install-Orchestrator.ps1
  - Uninstall-Orchestrator.ps1
  - Install-Orchestrator.ps1
  - docker/
    - Install-Docker.ps1
    - Uninstall-Docker.ps1
  - wsl/
    - Install-WSL.ps1
    - Uninstall-WSL.ps1
  - status/
    - Get-WSLStatus.ps1
    - Get-DockerStatus.ps1
    - Get-SystemStatus.ps1
  - master/
    - MASTER-REINSTALL-v2.ps1
  - backup/
    - Backup-Data.ps1
    - Restore-Data.ps1
  - Uninstall-Orchestrator.ps1
- tests/
  - unit/
    - *.Tests.ps1 (Pester unit tests for many components)
  - integration/
    - SystemIntegration.Tests.ps1
- tools/
  - run_tests_pwsh.ps1
  - run_pssa.ps1
- docker_manager.py
- WSL-TUI-Wizard.py
- requirements.txt

Notes:
- Only the scripts under `scripts/status/` currently contain working implementations. Other scripts in the repository are scaffolds or placeholders. For the MVP we will first wire the implemented `status` scripts into the root orchestrator and expose them to the UI so navigation and runtime flows can be validated.
- The repository contains Python files and a virtual environment, but initial MVP work will be PowerShell-focused and centered in the `src/` directory. The existing Python TUI will be treated as a consumer of the `src/` mocks and/or orchestrator APIs; no Python code will be modified for the MVP without your explicit approval.

## Runtime execution flow
The orchestrator is a thin sequencer that parses CLI flags and runs a series of ordered steps (each step is a small, testable unit). Steps are executed via a StepRunner library that provides:
- Dry-run mode: record the steps that *would* be executed.
- Structured logging: produce JSON per-step records.
- Error handling: on step failure, abort or continue depending on the severity and flags.

Typical flows:

Uninstall flow (high-level):
1. Parse flags (DryRun, Yes, LogPath, WslVersion)
2. Validate preconditions (Windows version checks, current WSL state)
3. Stop Docker processes and services
4. Call `scripts/docker/Uninstall-Docker.ps1` to uninstall Docker Desktop/engine
5. Remove Docker data directories (only if `-Yes` provided)
6. Call `scripts/wsl/Uninstall-WSL.ps1` to unregister selected WSL distributions and remove WSL artifacts (only with `-Yes`)
7. Clean up WSL/registry/service entries where safe
8. Emit final structured log and return exit code

Install flow (high-level):
1. Parse flags
2. Enable Windows features for WSL (WSL, VirtualMachinePlatform) — may prompt or return a signal to require reboot
3. Ensure WSL kernel package is present and run `wsl --set-default-version 2`
4. Call `scripts/wsl/Install-WSL.ps1` to prepare distributions if needed
5. Call `scripts/docker/Install-Docker.ps1` to install Docker Desktop silently, with CLI options that enable WSL2 backend
6. Validate `wsl -l -v` and `docker version`
7. Apply recommended developer defaults (light, documented changes — avoid forcing resource limits)
8. Emit final structured log and exit

## Step runner contract
Each step will return a simple object with properties:
- Name (string)
- Status (Success|Failed|Skipped)
- Message (string)
- Error (object|null)
- Timestamp

The StepRunner provides functions:
- Invoke-Step -Name -ScriptPath -DryRun -Args -> standardized result object
- Write-Log -Path -Object -> append structured JSON lines

## Error handling & safety
- Default mode is non-destructive: the orchestrator will not remove user data unless `-Yes` is supplied.
- On step failure the orchestrator returns a non-zero exit code and writes an error detail to the structured log.
- The orchestrator documents the exact registry keys and filesystem paths it will touch; only documented keys/paths will be modified.

## Tests and validation
- Unit tests for StepRunner dry-run behavior and for parsing/flags (test framework TBD).
- Unit tests for wrappers around `Install-Docker.ps1` and `Uninstall-Docker.ps1` using mocking (test framework TBD).
- Integration tests: a non-destructive dry-run verification and a targeted install/uninstall on a disposable VM (manual or CI runner with Windows image).

## Implementation plan (detailed tasks)
The implementation is split into small, reviewable tasks. Each task indicates affected files, acceptance criteria, and test coverage.

Task 1 — Create `scripts/orchestrator/lib/StepRunner.ps1` (ETA: 1 day)
- Add a small library implementing `Invoke-Step`, `Write-Log`, and `Format-Result`.
- The library handles DryRun and returns the standardized result object.
- Tests: Pester unit tests for DryRun and a mocked failing step.
- Acceptance: StepRunner unit tests pass locally.

Task 2 — Refactor `scripts/Install-Orchestrator.ps1` and `scripts/Uninstall-Orchestrator.ps1` to use StepRunner (ETA: 1 day)
- Convert those scripts to orchestrator entrypoints that sequence steps using the StepRunner.
- Add CLI parameter parsing for `-DryRun`, `-Yes`, `-LogPath`, `-WslVersion`, `-InstallDesktop`.
- Tests: unit tests for CLI parsing; integration dry-run verifying steps are listed.
- Acceptance: Orchestrator dry-run produces a valid JSON log with expected steps.

Task 3 — Harden step scripts to return standardized results (ETA: 2 days)
- Update `scripts/docker/Install-Docker.ps1`, `Uninstall-Docker.ps1`, `scripts/wsl/Install-WSL.ps1`, `Uninstall-WSL.ps1` to return the standardized object rather than just writing to console.
- Where needed, break large scripts into function exports that StepRunner can call.
- Tests: unit tests for each script function using mocks for system calls.
- Acceptance: Each script function returns the result object and StepRunner aggregates them.

Task 4 — Add structured logging & CLI options to orchestrators (ETA: 0.5 day)
- Implement `-LogPath` handling and JSON-lines log writing.
- Ensure logs capture timestamps and full step outputs.

Task 5 — Add unit tests & CI wiring (ETA: 1 day)
- Add tests to `tests/unit` for the new StepRunner and updated orchestrators (test framework TBD).
- Optionally add a CI workflow for running tests on push (deferred if not required for MVP).

Task 6 — Update `README.md` and `docs/spec.md` with usage examples and acceptance criteria (ETA: 0.5 day)
- Document CLI usage and safety flags.

Task 7 — Manual integration verification (ETA: 1 day)
- On a disposable Windows VM, run full install and uninstall sequences to validate behavior and record any required reboot steps.

### Implementation TODOs

Below are the active implementation-level todos tracked for the MVP. They are duplicated here so the team can review progress directly in the spec document.

- [x] Gather high-level requirements — Clarify goals, constraints, platforms, and acceptance criteria before design.
- [x] Review repository and current state — Scan the repo for architecture, existing components, and areas impacted by planned changes.
- [x] Propose 2–3 design options — Provide tradeoffs, diagrams, data shapes, and a recommended approach with rationale.
- [-] Agree on a concrete design/spec — Finalize interfaces, file layout, major functions, and tests to implement. (in-progress)
- [ ] Sign-off to begin coding — Get confirmation and schedule the initial coding tasks; create implementation todo list.
- [-] Create mock implementations in `src` — Generate mock functions for each file in `src/` that return descriptive strings for UI testing. (in-progress)
- [ ] Wire UI to use mocks — Point the UI to use the new mock functions so navigation and flows can be tested end-to-end without side effects.
- [ ] Run UI navigation tests — Execute manual/automated UI navigation tests to validate flows; update design as needed.

## Backlog (non-MVP items)
- Backup/export of Docker images/volumes and WSL data before destructive operations (feature request).
- Advanced configuration UI (TUI) and/or Python wrapper for richer UX and cross-platform support.
- Offline installers and corporate proxy support automation.

- Pester-specific test suite and Pester CI wiring (moved to backlog per design constraints).

## Development guide rails

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

## Development guide rails

See `docs/AI_Guiderails.md` for the full development guide rails and placement rules.

## Design mode — current decisions and confirmed `src/` layout

This section captures the current, agreed-upon design decisions made during the design phase. It documents the confirmed `src/` directory layout, the order of work (what will be wired first), and the hard constraints the team agreed to during design mode.

Confirmed `src/` layout (current):

- `src/`
  - `README.md` (docs for source folder)
  - `main-orchetrator.py` (TUI/orchestrator consumer; existing)
  - `install/`
    - `Install-Orchestrator.ps1` (entry for install sequencing)
    - `docker/` (install helpers)
      - `Install-Docker.ps1`
    - `wsl/` (install helpers)
      - `Install-WSL.ps1`
  - `uninstall/`
    - `Uninstall-Orchestrator.ps1` (entry for uninstall sequencing)
    - `docker/`
      - `Uninstall-Docker.ps1`
    - `wsl/`
      - `Uninstall-WSL.ps1`
  - `status/`
    - `Get-SystemStatus.ps1`
    - `docker/`
      - `Get-DockerStatus.ps1`
    - `wsl/`
      - `Get-WSLStatus.ps1`
  - `backup/` (present but out-of-scope for MVP)
    - `Backup-orchestrator.ps1`
    - `docker/`
      - `Backup-Data.ps1`
      - `Restore-Data.ps1`

Key design decisions agreed in design mode:

- Status-first wiring: only the `src/status/` scripts currently contain working implementations. These status scripts will be the first to be wired into the orchestrator and the UI for navigation and runtime validation.
- Mocks-first for behavior: all other `src/` modules will use mock implementations initially (under `src/`) that return plain descriptive strings. This allows the UI to be exercised end-to-end without side effects.
- No new top-level directories: the assistant will not create new top-level directories (e.g., `scripts/orchestrator/`) without explicit approval. Any shared helper libraries (for example, StepRunner) should be placed under `src/` by default (for example `src/orchestrator/StepRunner.ps1`) unless you approve an alternative.
- No Python modifications without approval: The existing Python TUI(s) are treated as consumers of `src/` and will not be modified for MVP unless you explicitly approve changes.
- Backlog items: backups, logging, and test framework selection (Pester or otherwise) are explicitly moved to the backlog and will not be implemented during mocks-first MVP.

Confirmed next actions (design-only, not yet implemented):

1. Create mock implementations under `src/status/` for any status scripts that require a mock replacement for UI testing (though many status scripts are already implemented and will be wired directly).
2. Create mock implementations under `src/install/` and `src/uninstall/` for callers the UI will exercise (returning plain descriptive strings). No destructive operations or external calls.
3. Wire the UI (the TUI/orchestrator consumer) to call `src/status/` implementations first so navigation and status flows can be validated.
4. After UI navigation is validated, proceed to iterate on the orchestrator implementation inside `src/` and replace mocks with real logic in small, reviewed steps.

If you'd like any of these items re-ordered or want the orchestrator entrypoint placed at the repository root instead of under `src/`, confirm and I will update the spec and the todo list accordingly.

## Defensive programming strategy

This section records the defensive programming practices and concrete protections we will follow when implementing the orchestrator and its steps. It is written to be implementation-agnostic (PowerShell-first for MVP) and to keep destructive operations explicit and auditable.

Principles
- Fail fast, fail safe: detect invalid input and missing preconditions early and abort without side effects.
- Non-destructive by default: destructive actions require an explicit `-Yes` flag. By default the orchestrator uses `-DryRun` semantics.
- Idempotency: steps should be safe to run multiple times where feasible and should not leave partial state that prevents re-try.
- Small, testable steps: break flows into small steps with clear inputs/outputs and no hidden global side effects.
- Explicit permissions: check for elevation/administrative rights at start and exit with a clear error if not available.

Step-level protections
- Preconditions: each step validates preconditions (OS version, existing services/processes, required binaries). If preconditions fail, the step returns a standardized Failed result and does not proceed.
- Dry-run support: every step honors `-DryRun` and returns what it would do without performing actions.
- Confirm destructive operations: any step that deletes or unregisters user data must check `-Yes` and explicitly enumerate what will be removed. If data is present and `-Yes` is not provided, the step must return Skipped and a message.
- Safe ordering: steps that stop services or unmount resources will be ordered before destructive file ops to avoid partial removal while processes still hold handles.

## PowerShell inventory and Python mapping

A quick inventory of the repository's PowerShell scripts (approx. 58 files found) and the suggested one-to-one mapping to the initial Python package layout for the migration plan. This inventory will be used to create inert mocks under `src/` and to prioritize migration.

Key PowerShell scripts discovered:
- `src/status/Get-SystemStatus.ps1`
- `src/status/wsl/Get-WSLStatus.ps1`
- `src/status/docker/Get-DockerStatus.ps1`
- `src/uninstall/Uninstall-Orchestrator.ps1`
- `src/uninstall/docker/Uninstall-Docker.ps1`
- `src/uninstall/wsl/Uninstall-WSL.ps1`
- `src/install/Install-Orchestrator.ps1`
- `src/install/docker/Install-Docker.ps1`
- `src/install/wsl/Install-WSL.ps1`
- `src/backup/Backup-Data.ps1` (and related restore scripts)

Suggested initial Python mapping (placed under `src/` only):
- `src/wsl_docker_manager/orchestrator.py` -> orchestrator entrypoint that sequences steps and exposes a programmatic API.
- `src/wsl_docker_manager/step_runner.py` -> StepRunner contract and result dataclass.
- `src/wsl_docker_manager/platform/mock_provider.py` -> mocks for UI/testing that return descriptive strings.
- `src/wsl_docker_manager/platform/windows_provider.py` -> Windows-specific implementations (real logic, added later).
- `src/wsl_docker_manager/status/*.py` -> mappings for status scripts (Get-SystemStatus, Get-WSLStatus, Get-DockerStatus).

Notes:
- Per the project guide rails, these Python files will only be added under `src/` and will start as inert mocks that return descriptive strings. Real implementations will replace mocks in small, reviewed commits.
- If you'd like, I can now (A) commit the small removal of `Export-ModuleMember` from the mock so dot-sourcing is clean, and (B) create the Python skeleton files as draft mocks under `src/` for your review. Tell me which one to do next.

Input validation and parameter handling
- Strict parameter validation: required parameters are validated at entry and reject obviously invalid values (null, out-of-range, unsupported OS build).
- Sanitize inputs: treat paths and user-supplied names as untrusted; canonicalize and validate before use.
- Feature gates: require explicit flags for risky features (for example `-InstallDesktop` default true, but modifying machine-wide resource settings must require an additional flag).

Idempotency and state checks
- Query current state before performing actions; if the target state is already achieved, steps should return Skipped with a clear message.
- Use safe rename/move instead of immediate deletion where practical (e.g., move data to a clearly named `.deleted-by-orchestrator` directory) — only when `-Yes` is provided.
- Clean failure behavior: steps must leave the system in a consistent state and report exactly what changed.

Error handling, reporting, and exit codes
- Standardized step result object (returned to the calling orchestrator):

  - Name: string
  - Status: Success | Failed | Skipped
  - Message: string
  - Error: string|null (short error text)
  - Timestamp: ISO 8601 string

- Orchestrator behavior on step failure: by default abort on first Failed step and return a non-zero exit code. A `-ContinueOnError` flag may be added later for non-fatal cleanup steps.
- Exit codes: `0` success; `1` general failure; `2` precondition/elevation failure; `3` user-aborted/missing-Yes.
- Avoid persistent logs for MVP (per design that logging is in backlog). However, the orchestrator will return the structured result objects to the caller (for TUI display) so the UI can show step-level detail without the orchestrator writing logs to disk.

Reboots, elevation, and long-running operations
- Detect when a Windows feature enable requires reboot. In that case, the orchestrator must return a special Skipped/RequiresReboot result and a clear action message instead of attempting an automatic reboot.
- Check for administrative privileges at start and refuse to continue with an explanatory message if not elevated.
- For long-running operations, return intermediate progress where possible and allow the UI to show activity. Implement reasonable timeouts and retries for transient operations (for example, waits for services to stop), with a capped retry count.

Security and integrity checks
- Verify installer artifacts when possible (checksum or digital signature) before executing an installer.
- Prefer official, signed installers and documented silent-install arguments.
- Avoid hardcoding secrets or credentials in code; prompt the user or read from secure store only when required (and document this flow separately).

Testing and mocks
- Mocks-first: use inert mocks in `src/` for UI navigation and for unit testing command flows. Mocks must declare themselves clearly as MOCK and should return deterministic descriptive strings or the standardized step result shape.
- Unit tests and integration tests are in the backlog per guide rails; however the code will be structured to be easily testable (small functions, pure input/output where possible).

Backlog (deferred defensive features)
- Persistent structured logging to disk (moved to backlog per design rails).
- Full automated rollback/transactional rollback for multi-step destructive changes (deferred — will be scoped later if needed).
- Automatic retries with exponential backoff for network/installer downloads (deferred).

Acceptance criteria for defensive programming
- Every step validates preconditions and honors `-DryRun` and `-Yes` flags.
- The orchestrator never performs destructive changes without `-Yes` and an explicit list of targets.
- Steps return the standardized result object and the orchestrator returns non-zero codes for failures.

If this defensive strategy looks correct I will fold it into the final spec and we can sign off; if you want any specific additional protections (for example, mandatory checksum verification for installers, or a stricter exit code mapping) tell me and I'll include them in the document.

Additions to the backlog or deviations from these guide rails require your sign-off.

## Platform/runtime decision

Decision: adopt a Python-first core and manage developer environments with pyenv.

Notes:
- The project will favor Python for new core code to maximize cross-platform support (Linux + Windows). PowerShell artifacts will remain where they exist but will not be expanded as part of the Python-first work.
- Platform-specific provider adapters (Windows WSL, Docker Desktop, Linux package managers) are deferred to the backlog as a feature request. For the MVP these behaviors will be mocked or return NotApplicable on unsupported platforms.
- Any repo-root packaging or pyenv bootstrap scripts require explicit approval before creation; I will propose exact file paths and contents for review when you ask.


## Acceptance criteria (concrete)
- Dry-run uninstaller prints the exact steps and writes a success JSON log without modifying system.
- Running uninstaller with `-Yes` removes Docker Desktop and engine artifacts and unregisters WSL distributions as agreed; orchestrator exits 0 on success.
- Running installer results in WSL default version 2 and a working Docker Desktop with `docker version` returning client+server.
- Pester suite covers StepRunner behaviors and flag parsing.

## Next steps
- Confirm the spec and directory structure above.
- I will implement Task 1 (StepRunner) and wire the orchestrators to use it. After Task 1 completes I'll run unit tests and report results.

