# Architecture and Workflow

Last updated: 2025-10-17

This document describes the high-level workflow of the WSL & Docker Manager repository, the responsibilities of each major component, and notes about tests, CI, and common entry points. It's intended as a developer-facing map so you can understand how pieces interact and where to make targeted changes.

## Table of contents
- Project summary
- High-level workflows (backup, uninstall, install, restore, verify)
- Components and interactions
- Per-file / per-module inventory (purpose, key functions, inputs/outputs)
- Tests and how to run them locally / CI
- Known issues and notes

---

## Project summary

This repository provides PowerShell-based automation to manage Docker Desktop and WSL on Windows (Windows 11 primary target). It includes scripts to backup Docker data, uninstall and reinstall WSL and Docker, and verification helpers. The repo also includes a test harness (Pester) and helper scripts for running Pester under PowerShell 7 in CI.

Target audiences:
- Power users who want to automate WSL/Docker reinstall and storage reconfiguration
- Developers maintaining scripts and tests

Design goals:
- Safe, idempotent orchestration with ShouldProcess support
- Test coverage with Pester (local compatibility for Pester v3 and CI Pester v5)
- PSScriptAnalyzer-friendly scripts (replacing Write-Host, adding [CmdletBinding])

---

## High-level workflows

1) Backup
-- Script: `BACKUP-DOCKER-DATA.ps1` — REMOVED (backup functionality no longer in repo).
- Typical user flow: run backup before uninstall or moving Docker data.

2) Uninstall
- Scripts: `UNINSTALL-DOCKER-DESKTOP.ps1`, `UNINSTALL-WSL.ps1` — remove apps, distributions, and optionally clean data.

3) Install / Reinstall
- `INSTALL-WSL2-DYNAMIC.ps1` — install WSL 2 with dynamic VHDX sizing, configure `.wslconfig`, and set performance options.
- `INSTALL-DOCKER-DESKTOP.ps1` — install Docker Desktop configured to use WSL 2.
- `MASTER-REINSTALL.ps1` / `MASTER-REINSTALL-v2.ps1` — orchestrate the full flow in phases (backup → uninstall → install → restore).

4) Restore and Verify
- After reinstallation, restore from the backup (scripts in `backup/`), and run verification commands: `wsl --status`, `docker info`, `docker run --rm hello-world`.

5) Orchestration helper
- `scripts/Install-Orchestrator.ps1` is a smaller orchestrator that calls individual installer scripts (WSL and Docker) using `Invoke-InstallScript` helper. It supports `-WhatIf`/`-Confirm` via `[CmdletBinding(SupportsShouldProcess=$true)]`.

---

## Components and interactions

- Root scripts: top-level PowerShell scripts are entry points (MASTER-REINSTALL, BACKUP, INSTALL-WSL2, INSTALL-DOCKER, UNINSTALL-*). They usually call into the `scripts/` directory or `scripts/*/` helper scripts.
- `scripts/` holds domain-specific helpers and orchestrators:
  - `scripts/status/` collects system and Docker/WSL status (`Get-WSLStatus.ps1`, `Get-DockerStatus.ps1`, `Get-SystemStatus.ps1`). These are designed to be dot-sourced by tests.
  - `scripts/wsl/`, `scripts/docker/` contain installers for each subsystem.
  - `scripts/Install-Orchestrator.ps1` provides an entrypoint for combined installs.
- `tests/` holds Pester unit and integration tests. The repo supports a PWSh-based CI path (Pester 5) and local compatibility for PowerShell 5 / Pester 3 where feasible.
- `tools/` contains helper scripts for running the PSScriptAnalyzer wrapper and a pwsh test runner used in CI.
- `.github/workflows/pwsh-tests.yml` runs tests and script analyzer under PowerShell 7 + Pester 5 on Windows runners.

---

## Per-file / per-module inventory

The list below focuses on files you are most likely to edit or consult. For each file I include:
- Purpose (1–2 lines)
- Key functions / exported names
- Inputs / outputs
- Tests that cover it (if any)
- Notes / known test or linter issues

NOTE: Paths are given relative to the repo root.

### Root-level scripts

- `README.md`
  - Purpose: user-facing guide and quick-start; comprehensive doc describing capabilities and examples.
  - Key content: quick start commands, script list, suggested workflow.
  - Tests: none.
  - Notes: Very detailed; keep in sync with real script options and names.

- `BACKUP-DOCKER-DATA.ps1`
  - Purpose: Back up Docker images, containers, and volumes to a local archive.
  - Key behavior: exports containers/images, compresses volumes, stores metadata.
  - Inputs: target backup path (optional), credentials (if needed).
  - Outputs: archive files and a manifest.
  - Tests: integration tests under `tests/integration` may exercise backup/restore flows.

- `UNINSTALL-DOCKER-DESKTOP.ps1`, `UNINSTALL-WSL.ps1`
  - Purpose: Remove Docker Desktop and/or WSL distributions and associated data.
  - Notes: Must be run elevated; destructive — tests typically mock operations.

- `MASTER-REINSTALL.ps1`, `MASTER-REINSTALL-v2.ps1`
  - Purpose: High level orchestrators that string together backup → uninstall → install → restore.
  - Key behaviors: parse phases, prompt for confirmation, call the underlying installers.

### scripts/

- `scripts/Install-Orchestrator.ps1`
  - Purpose: Smaller orchestrator used by tests and some workflows to install WSL, Docker, or both.
  - Key functions/behaviors:
    - `Invoke-InstallScript` (guarded definition so tests can mock/override it) — runs a single install script and returns exit status. Throws when script not found or fails.
    - Uses `[CmdletBinding(SupportsShouldProcess=$true)]` and `$PSCmdlet.ShouldProcess` to implement `-WhatIf`/`-Confirm` semantics.
    - `Write-Phase` helper (structured output to replace Write-Host)
  - Inputs: `-Target` (ValidateSet: `wsl-only`, `docker-only`, `both`), `-Force`, `-BackupPath`.
  - Outputs: exit codes (`0` success, `1` failure) and structured output lines.
  - Tests: `tests/unit/Install-Orchestrator.Tests.ps1` (mocks `Invoke-InstallScript` and checks call order and error propagation). Known failing assertions: call order can fail if the script redefines `Invoke-InstallScript` or if the test's stubbing isn't visible to the executed script (tests run the script as an external invocation in some cases; prefer running in the same session or ensuring the script doesn't re-declare the function).

- `scripts/Uninstall-Orchestrator.ps1`
  - Purpose: Complement Install-Orchestrator for removal flows.

- `scripts/status/Get-WSLStatus.ps1`
  - Purpose: Collect WSL installation and distribution info (Test-WSLInstalled, Get-WSLVersion, Get-WSLDistribution, Get-WSLRunningDistribution, Test-WSLFeatureEnabled).
  - Key functions: `Test-WSLInstalled`, `Get-WSLVersion`, `Get-WSLDistribution`, `Get-WSLRunningDistribution`, `Get-WSLStatus` (composite hashtable).
  - Inputs: none (reads system commands like `wsl` or Windows feature state).
  - Outputs: hashtables or arrays describing installations.
  - Tests: `tests/unit/Get-WSLStatus.Tests.ps1` — this file had parsing problems earlier and was replaced with a Pester v3–compatible suite where tests mock `wsl` and dot-source the module inside each Context.
  - Notes: Be careful with here-string formatting and ensure docstrings are not literal outputs (use comments instead of bare triple-quoted strings) — previously caused tests to see unexpected output.

- `scripts/status/Get-DockerStatus.ps1`
  - Purpose: Collect Docker Desktop install/running/working status, container/image/volume counts, and Docker client version.
  - Key functions: `Test-DockerInstalled`, `Test-DockerRunning`, `Get-DockerVersion`, `Get-DockerContainer`, `Get-DockerImage`, `Get-DockerVolume`, `Get-DockerStatus` (composite hashtable).
  - Inputs: runs `docker` commands and uses `Get-Command`/`Test-Path` to detect executables.
  - Outputs: hashtable with nested hashtables for Version, Containers, Images, Volumes.
  - Tests: `tests/unit/Get-DockerStatus.Tests.ps1` — tests must mock `Get-Command`/`docker` before dot-sourcing the module in Pester v3. Some tests failed initially because the module or tests emitted strings during dot-sourcing (converted docstrings to comments to fix that). Version matching was relaxed to accept any semantic version in tests to avoid host-specific failures.

- `scripts/status/Get-SystemStatus.ps1`
  - Purpose: Higher-level system diagnostics (OS, memory, virtualization support). Used by higher-level verification.

### scripts/docker/ and scripts/wsl/

- Purpose: contain the actual installer scripts for WSL and Docker (e.g., `Install-WSL.ps1`, `Install-Docker.ps1`) used by the orchestrator and by the master reinstaller. These are destructive/privileged operations; unit tests mock them.

### tests/

- `tests/unit` — unit tests using Pester (v3 locally, v5 in CI). Files of interest:
  - `Get-DockerStatus.Tests.ps1` — mocked docker/Get-Command and dot-sourced `Get-DockerStatus.ps1`
  - `Get-WSLStatus.Tests.ps1` — mocked wsl and dot-sourced `Get-WSLStatus.ps1`
  - `Install-Orchestrator.Tests.ps1` — mocks `Invoke-InstallScript` and verifies call order and error cases; some failing assertions existed because of how the orchestrator defined `Invoke-InstallScript` (guard function) and how tests execute the orchestrator (external vs same-session execution differences).

- `tests/integration` — contains higher-level integration tests (shelling out; may be disabled without pwsh/pester5 environment). Use `tests/Run-Tests.ps1` or `tools/run_tests_pwsh.ps1` to run everything under pwsh.

### tools/

- `tools/run_pssa.ps1` — wrapper to run `Invoke-ScriptAnalyzer` (the wrapper originally focused on reporting PSAvoidUsingWriteHost) and print findings in a table.
- `tools/run_tests_pwsh.ps1` — helper to run tests under pwsh (installs Pester if missing, runs `Invoke-Pester`). This is useful locally and matches the CI flow.
- `tools/README-tests.md` — local instructions for running tests under pwsh / Pester 5.

### CI

- `.github/workflows/pwsh-tests.yml` — GitHub Actions workflow that:
  - sets up PowerShell 7 on windows-latest
  - installs Pester (v5) and runs `Invoke-Pester -Script tests`
  - runs PSScriptAnalyzer across the repo and outputs findings

---

## Tests: how to run locally and in CI

- CI (recommended): GitHub Actions will run `.github/workflows/pwsh-tests.yml` using PowerShell 7 + Pester 5. It runs both tests and PSScriptAnalyzer.
- Local (fast): use a PowerShell 7 (pwsh) install and helper script:

  pwsh -File tools\run_tests_pwsh.ps1

  Or:

  pwsh -NoProfile -Command "Install-Module -Name Pester -Scope CurrentUser -Force; Import-Module Pester -Force; Invoke-Pester -Script 'tests'"

- For quick unit-only runs under Windows PowerShell 5 (legacy local environment), tests were adapted in places to work with Pester 3, but full compatibility is not guaranteed. The repo includes `tests/unit/*` designed to be Pester v3–compatible in many cases by dot-sourcing modules after mocks.

---

## Notes, known issues, and guidance

- Test mocking order: For Pester v3, mocks must be defined before dot-sourcing the module under test (so `Mock` can intercept commands the module uses at import time). Many prior failures were caused by dot-sourcing happening too early or tests that executed scripts in a child process where mocks are not visible.
- Docstrings vs comments: Avoid triple-quoted bare strings at top of function bodies. They produce output when a module is dot-sourced and break tests; use block comments `<# ... #>` instead.
- `Write-Host` replacements: The repo favors structured outputs (Write-Output/Write-Information/Write-Error) and a helper `Write-Phase` for orchestration logging. This makes testing and script analysis easier.
- Pester version differences: The codebase contains a mix of Pester v3-compatible tests and CI-focused Pester v5 workflows. When adding tests, prefer Pester v5 features for new code; if maintaining v3 compatibility, ensure mocks/dot-sourcing ordering is correct.
- Linting: Use `tools/run_pssa.ps1` or CI to run `Invoke-ScriptAnalyzer`. The repo has been updated to address many common findings but a final run is recommended once tests pass.

---

## Quick reference: commands

- Run unit tests (PowerShell 5 with Pester 3 compatibility may be partial):

  powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-Location '<repo>'; Invoke-Pester -Script 'tests/unit' -PassThru"

- Run full tests locally with pwsh:

  pwsh -File tools\run_tests_pwsh.ps1

- Run script analyzer (tools wrapper):

  pwsh -File tools\run_pssa.ps1

---

If you want, I can:

- Add missing per-file TODOs in `TODO.md` linking to failing tests and analyzer rules.
- Run the full test suite and iterate until green (I can continue fixing tests and code now).
- Generate a short onboarding README for contributors showing how to add tests and run the analyzer.

I will pause now — tell me which of the follow-ups you'd like next:
1) Run/finish making unit tests green (I will continue editing the tests or code). 
2) Update `TODO.md` with remaining analyzer/test items and link to failing tests. 
3) Add `ARCHITECTURE_AND_WORKFLOW.md` to the repo (I created it here). 
4) Anything else you want me to do next.
