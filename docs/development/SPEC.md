<!-- Development-only copy of the project MVP spec. This file lives under docs/development/ and should not be merged into `main`. -->

# MVP Specification and Architecture (development)

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
  - development/  <-- this file lives here on development branches
  - production/   <-- docs safe for `main`
- src/
  - ... (see repo)

Notes:
- Only the scripts under `src/status/` currently contain working implementations. Other scripts in the repository are scaffolds or placeholders. For the MVP we will first wire the implemented `status` scripts into the root orchestrator and expose them to the UI so navigation and runtime flows can be validated.
- The repository contains Python files and a virtual environment, but initial MVP work will be PowerShell-focused and centered in the `src/` directory. The existing Python TUI will be treated as a consumer of the `src/` mocks and/or orchestrator APIs; no Python code will be modified for the MVP without your explicit approval.

## Runtime execution flow
The orchestrator is a thin sequencer that parses CLI flags and runs a series of ordered steps (each step is a small, testable unit). Steps are executed via a StepRunner library that provides:
- Dry-run mode: record the steps that *would* be executed.
- Structured logging: produce JSON per-step records.
- Error handling: on step failure, abort or continue depending on the severity and flags.

... (development spec continues — moved from docs/spec.md)
