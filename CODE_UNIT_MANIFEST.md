# Code Unit Manifest

All entries below are tagged: Status: in-progress

This manifest lists the repository's main code units, a short purpose, exported symbols/functions, tests that exercise them (if any), and brief notes.

---

1) File: `scripts/Install-Orchestrator.ps1`
     - Status: in-progress
     - Purpose: Small orchestrator that runs installer scripts for WSL and Docker; supports ShouldProcess and structured phase logging.
     - Exported symbols / functions: Write-Phase, Invoke-InstallScript (guarded), main orchestration logic handling Target values.
     - Tests: `tests/unit/Install-Orchestrator.Tests.ps1`
     - Notes: `Invoke-InstallScript` is defined only if not present so tests can mock/override; unit tests use a mixture of child-process invocation and local mocks — verify same-session behavior when editing tests.
     - Test findings (from running `tests/unit/Install-Orchestrator.Tests.ps1`):
         - Failure A: "Should call both installation scripts in order"
             - Observed: `$callOrder[0]` was an empty object ({}), the test expected the first recorded call to match "Install-WSL.ps1".
             - Likely cause: the mocked `Invoke-InstallScript` didn't record script path into the test's `$callOrder` array in this test run (mock visibility / call recording issue).
         - Failure B: "Should throw when script not found"
             - Observed: test expected an exception with message matching `*not found*`, but no exception was raised when `Test-Path` returned false.
             - Likely cause: the orchestrator's behavior in the missing-script case returned normally (or suppressed the thrown error) instead of throwing a detectable exception in the child/invoked context used by the test.
         - Recommendation: ensure `Invoke-InstallScript` throws when `Test-Path` is false (or surface an error), and verify the test's mock of `Invoke-InstallScript` is visible to the orchestrator in the same session; alternatively adjust the test to run the orchestrator in the same session (dot-sourcing) so mock captures occur.

2) File: `scripts/status/Get-WSLStatus.ps1`
     - Status: in-progress
     - Purpose: Query WSL install state, feature enablement, distributions, and version info.
     - Exported symbols / functions: Test-WSLInstalled, Test-WSLFeatureEnabled, Test-VirtualMachinePlatformEnabled, Get-WSLDistribution, Get-WSLRunningDistribution, Get-WSLVersion, Get-WSLStatus.
     - Tests: `tests/unit/Get-WSLStatus.Tests.ps1`
     - Notes: Designed to be dot-sourced by tests; avoid bare literal here-strings that emit text at import time.
     - Test findings (from running `tests/unit/Get-WSLStatus.Tests.ps1` locally under PowerShell 5 / Pester 3):
         - Summary: Passed 0, Failed 4 (Total 4)
         - Issue 1 — Docstring emission at dot-source time
             - Symptom: `Test-WSLInstalled` returned a multi-line string (the module's docstring) instead of a Boolean value in tests.
             - Cause: Bare triple-quoted literal strings present in the module are written to output when the file is dot-sourced.
             - Fix: Replace bare string docblocks with block comments (`<# ... #>`) or remove them so functions return proper values when dot-sourced.
         - Issue 2 — Version parsing assertion too strict
             - Symptom: `Get-WSLVersion` test expected an exact version '2.0.9.0' but received a multiline version info containing another version (e.g., 'WSL version: 2.6.1.0 ...').
             - Cause: Test asserts equality with a fixed string while actual output is multiline and may vary.
             - Fix: Relax the test to match a semantic version regex (e.g., `'\d+\.\d+\.\d+'`) or extract the numeric version from the output before asserting.
         - Issue 3 — Test file contains merged/duplicated content / Pester assertion errors
             - Symptom: `ParameterBindingException` referencing a missing `-Encoding` parameter inside Pester's `Contain` assertion, and errors indicating `Should` used outside a Describe block.
             - Cause: The test file appears to have duplicated/merged sections or stray content from earlier edits, causing invalid Pester usage and parameter mismatches (PowerShell v5 differences in `-Encoding`).
             - Fix: Clean `tests/unit/Get-WSLStatus.Tests.ps1`: remove duplicate/merged blocks, ensure all `It`/`Context`/`Describe` blocks are valid, and place module dot-sourcing inside `BeforeAll`/`Context` *after* mocks are defined (Pester v3 pattern).
         - Recommended next actions:
             1. Update `scripts/status/Get-WSLStatus.ps1` to convert all triple-quoted literal docstrings to block comments.
             2. Clean and normalize `tests/unit/Get-WSLStatus.Tests.ps1` (remove duplicated sections, confirm dot-sourcing order, and avoid Pester v5-only assertions when running under v3).
             3. Relax version assertions to regex-based checks.
             4. Re-run the unit test file and iterate until green.

3) File: `scripts/status/Get-DockerStatus.ps1`
   - Status: in-progress
   - Purpose: Detect Docker presence, running state, client/server version, and container/image/volume details.
   - Exported symbols / functions: Test-DockerInstalled, Test-DockerRunning, Test-DockerDesktopInstalled, Test-DockerWorking, Get-DockerVersion, Get-DockerContainer, Get-DockerImage, Get-DockerVolume, Get-DockerStatus.
   - Tests: `tests/unit/Get-DockerStatus.Tests.ps1`, `tests/unit/Get-DockerStatus.Tests.clean.ps1`
   - Notes: Tests mock `Get-Command` and `docker` before dot-sourcing; version parsing assertions were relaxed to reduce environment-specific failures.
     - Test findings (from running `tests/unit/Get-DockerStatus.Tests.ps1`):
         - Summary: Passed 9, Failed 1 (Total 10)
         - Failure: "Should return not running when docker command fails"
             - Symptom: The test expected `$result.Running` to be `$false` when the mocked `docker` command fails, but the function returned `$true`.
             - Likely cause: `Test-DockerRunning` or `Get-DockerStatus` uses `$LASTEXITCODE` incorrectly or the mocking did not simulate a non-zero exit code for the `docker` invocation; the module may be checking presence differently (e.g., checking `Get-Command` or presence of `docker.exe` rather than the actual command execution result).
             - Fixes to try:
                 1. Ensure the test's mock sets `$global:LASTEXITCODE` appropriately when simulating failure, or change the module to inspect command output/stream instead of only `$LASTEXITCODE` which may not be set under mocked calls.
                 2. In `Test-DockerRunning`, capture the command execution result and handle errors (e.g., `try/catch` with `$false` on exception) instead of assuming `$LASTEXITCODE` reflects the mocked state in Pester v3.
         - Recommendation: Update `Test-DockerRunning` to be robust to mocked `docker` behavior (use try/catch and test returned output), adjust tests to set `$global:LASTEXITCODE` if relying on it, then re-run the unit file.

4) File: `BACKUP-DOCKER-DATA.ps1`
    - Status: removed
    - Purpose: Previously provided backup functionality for containers, images, volumes and produced a restoration script. This unit has been deleted per request.
    - Notes: All backup functionality and high-level orchestration were removed. See repo changes: deleted files `BACKUP-DOCKER-DATA.ps1`, `scripts/backup/Backup-Data.ps1`, and `tests/unit/Backup-DOCKER-DATA.Tests.ps1`.

5) File: `scripts/backup/Backup-Data.ps1`
    - Status: removed
    - Purpose: High-level backup orchestration (deleted along with backup unit).
    - Notes: Deleted; any orchestration responsibilities should be replaced by higher-level workflows if backup is reintroduced in the future.

6) File: `scripts/backup/Restore-Data.ps1`
    - Status: removed
    - Purpose: Restore functionality associated with backup unit — removed along with backup unit.
    - Notes: If restoration features are needed later, implement them in a separate, focused module with clear tests and avoid coupling to the main installer orchestration.

7) File: `INSTALL-WSL2-DYNAMIC.ps1`
   - Status: in-progress
   - Purpose: Reinstall WSL 2 with dynamic disk settings, kernel updates, `.wslconfig`, optional custom distro installation, and disk utilities.
   - Exported symbols / functions: Test-WindowsFeature, Wait-ForFeatureInstallation, plus installation utilities and disk compact/optimize script creators.
   - Tests: none unit-specific (manual/integration).
   - Notes: Requires Administrator and may require restart; tests should mock feature checks and wsl commands.
    - Test findings:
        - No unit tests found under `tests/unit/`; treat as integration/manual script.
        - Recommendation: Add unit tests for helper functions (Test-WindowsFeature, Wait-ForFeatureInstallation) using Pester with mocks for `Get-WindowsOptionalFeature` and file ops; keep full install flows as integration tests.

8) File: `INSTALL-DOCKER-DESKTOP.ps1`
   - Status: in-progress
   - Purpose: Install Docker Desktop with WSL 2 backend, configure daemon and desktop JSON settings, perform verification checks and create utility scripts.
   - Exported symbols / functions: Test-WSL2Ready, verification helpers, utility generator.
   - Tests: integration-level; unit tests mock `docker` and `wsl` interactions.
   - Notes: Writes to user/app data; verify file paths when running tests.
    - Test findings:
        - No dedicated unit tests found under `tests/unit/` for the installer script; integration scenarios exist but are environment-dependent.
        - Recommendation: Unit-test the small helper functions (Test-WSL2Ready, verification helper blocks) by mocking wsl/docker outputs. Keep the full installer as integration or manual test.

9) File: `UNINSTALL-WSL.ps1` and `scripts/wsl/Uninstall-WSL.ps1`
   - Status: in-progress
   - Purpose: Remove WSL distributions and features; part of the full reinstallation workflow.
   - Exported symbols: uninstall helpers.
   - Tests: none unit-specific.
   - Notes: Destructive operations — always mock in unit tests.
    - Test findings:
        - No unit tests found under `tests/unit/` for uninstallers.
        - Recommendation: Add unit tests that mock dangerous operations (Remove-Item, wsl --unregister, Enable/Disable Windows features) to verify confirmation logic and error handling.

10) File: `UNINSTALL-DOCKER-DESKTOP.ps1` and `scripts/docker/Uninstall-Docker.ps1`
    - Status: in-progress
    - Purpose: Remove Docker Desktop and related artifacts.
    - Exported symbols: uninstall helpers.
    - Tests: none unit-specific.
    - Notes: Use -Force semantics and mock in tests.
        - Test findings:
            - No unit tests found under `tests/unit/` for uninstallers.
            - Recommendation: Add unit tests that mock stop/uninstall commands and ensure -Force semantics behave as expected.

11) File: `MASTER-REINSTALL.ps1` and `MASTER-REINSTALL-v2.ps1`
    - Status: in-progress
    - Purpose: High-level orchestrator for backup → uninstall → install → restore flows; handles restarts and user confirmations.
    - Exported symbols / functions: Invoke-ScriptPhase, Test-SystemState, Show-SystemState, main phase switch.
    - Tests: limited; some orchestrator behavior covered by `tests/unit/Install-Orchestrator.Tests.ps1`.
    - Notes: Interactive by default; support `-AutoConfirm` for CI automation.
        - Test findings:
            - No dedicated unit test file exists for the full master reinstaller under `tests/unit/`.
            - Recommendation: Add unit tests for `Invoke-ScriptPhase` and `Test-SystemState` by mocking system calls and script presence; treat full `-Phase=all` runs as integration tests.

12) File: `scripts/status/Get-SystemStatus.ps1`
    - Status: in-progress
    - Purpose: Provide high-level diagnostics (OS, virtualization status, memory, CPU) used by verification flows.
    - Exported symbols: Get-SystemStatus (or similar).
    - Tests: none unit-specific.
    - Notes: Useful for pre-flight checks.
        - Test findings:
            - No unit tests found under `tests/unit/` for system status helper.
            - Recommendation: Add small unit tests that mock system calls (Get-CimInstance, Get-ComputerInfo) and verify formatting and error handling.

13) File: `tools/run_tests_pwsh.ps1`
    - Status: in-progress
    - Purpose: Helper to run Pester tests under PowerShell 7 (install/import Pester if missing and run `Invoke-Pester`).
    - Exported symbols: none (script wrapper).
    - Tests: n/a
    - Notes: Used from CI; recommended for locally matching CI behavior.
        - Test findings:
            - No unit tests; script is a runner used in CI.
            - Recommendation: Validate behavior in CI runs and document pwsh requirements in README.

14) File: `tools/run_pssa.ps1`
    - Status: in-progress
    - Purpose: Wrapper for `Invoke-ScriptAnalyzer` focused on common rules (e.g., PSAvoidUsingWriteHost).
    - Exported symbols: none (script wrapper).
    - Tests: n/a
    - Notes: Use after test runs to search and fix analyzer findings.
        - Test findings:
            - No unit tests; this is a developer tool.
            - Recommendation: Add a simple smoke test or script check that runs PSScriptAnalyzer on a small sample to ensure the wrapper works in the environment.

15) File: `tests/unit/Get-DockerStatus.Tests.ps1`
    - Status: in-progress
    - Purpose: Unit tests for Docker status helpers; Pester v3-compatible by mocking `docker` and `Get-Command` before dot-sourcing the module.
    - Tests target: Get-DockerStatus, Get-DockerContainer, Get-DockerImage, Get-DockerVolume.
    - Notes: A clean copy exists at `tests/unit/Get-DockerStatus.Tests.clean.ps1` for iterative development.

16) File: `tests/unit/Get-WSLStatus.Tests.ps1`
    - Status: in-progress
    - Purpose: Unit tests for WSL status helpers; mocks `wsl` command and verifies parsing and status outputs.
    - Tests target: Test-WSLInstalled, Get-WSLVersion, Get-WSLDistribution.
    - Notes: Ensure dot-sourcing happens after mocks to allow Pester v3 Mock interception.

17) File: `tests/unit/Install-Orchestrator.Tests.ps1`
    - Status: in-progress
    - Purpose: Unit tests verifying parameter validation, script calls, ordering, and error propagation for `Install-Orchestrator.ps1`.
    - Tests target: orchestrator behavior and calls to Invoke-InstallScript.
    - Notes: Tests use both local mocks and child-process runs — mismatches can cause flaky assertions (call-order vs stub visibility).

18) File: `tests/integration/SystemIntegration.Tests.ps1`
    - Status: in-progress
    - Purpose: Integration tests that exercise larger flows; requires environment with Docker/WSL and is intended for CI or manual runs.
    - Notes: Prefer running in pwsh with Pester 5 for CI compatibility.
        - Test findings:
            - Integration tests exist; they are environment-dependent and are run via `tools/run_tests_pwsh.ps1` or CI workflows.
            - Recommendation: Keep integration tests gated behind a CI flag or environment variable to avoid accidental local execution.

19) File: `tests/Run-Tests.ps1`
    - Status: in-progress
    - Purpose: Convenience runner to execute unit and integration tests (may call `Invoke-Pester` directly).
    - Notes: Prefer `tools/run_tests_pwsh.ps1` for CI parity.
        - Test findings:
            - No unit tests for the runner itself; use as a convenience script.
            - Recommendation: Document usage and expected prerequisites (pwsh, Pester version).

20) File: `.github/workflows/pwsh-tests.yml`
    - Status: in-progress
    - Purpose: GitHub Actions workflow to run tests and PSScriptAnalyzer under PowerShell 7 + Pester 5 on Windows.
    - Notes: Ensures CI runs match local `pwsh` test runner.
        - Test findings:
            - CI workflow exists; ensure secrets and artifacts are handled properly.
            - Recommendation: Validate the workflow in a feature branch and ensure it triggers expected matrix runs for pwsh and Pester versions.

---

If you'd like this file updated to mark specific items as completed (for example, once tests for a file are green), tell me which files to toggle to "Status: done" and I'll update `CODE_UNIT_MANIFEST.md` accordingly and close the related todo.
