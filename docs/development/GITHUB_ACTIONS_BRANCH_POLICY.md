# GitHub Actions Branch & PR Policy

This document describes the intended GitHub Actions behavior for branch merges in this repository.

Goals
- Prevent accidental merges of development-only docs into `main`.
- Allow day-to-day feature PRs to `develop` to run fast tests only.
- Run full lint/build/test on integration branches (`build`) and when preparing `main` releases.
- Avoid workflows added in feature branches from running and blocking PRs targeting non-main branches.

Branch roles
- feature/* → develop
  - Short-lived feature branches. PRs to `develop` should run a lightweight test job (unit tests) and nothing that enforces `main`-only policies.
- develop → build
  - Integration branch used for preparing releases or further integration. PRs to `build` should run the full CI (lint, test, build) to validate artifacts before promoting to `main`.
- build → main
  - `build` merges into `main` should be gated. PRs to `main` should run full CI and enforcement checks (no development docs under `docs/development/`, no unexpected top-level directories added).

How workflows are structured in this repo
- Lightweight PR tests (`ci-tests-on-pr.yml`) are configured to run for PRs targeting `develop`, `build`, and `main`.
- Full CI (`ci-build-and-publish-package.yml`) runs for PRs and pushes to `build`.
- Blocking workflows (`block-root-additions.yml`, `block-dev-docs-on-main.yml`, `ci-docs-enforce.yml`) are intended to run only when PRs target or pushes reach `main`.

Defensive job-level guards
- Workflows that enforce repository policy should include a job-level `if:` guard so they don't run when added in a head branch. Example:

```yaml
jobs:
  enforce-policy:
    runs-on: ubuntu-latest
    if: >-
      startsWith(github.ref, 'refs/heads/main') ||
      (github.event_name == 'pull_request' && github.event.pull_request.base.ref == 'main')
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/check_policy.sh
```

This ensures the job executes only when the workflow is actually targeting `main`.

Root-level additions policy (override allowed)
------------------------------------------------
- The repository will block PRs that introduce new unexpected top-level directories (for example, adding a new top-level folder `foo/`) by default on all PRs.
- Override mechanism for PRs:
  - Add label `allow-root-additions` or `allow-root` to the PR, OR
  - Include the token `ALLOW_ROOT_ADDITIONS` (case-insensitive) in the PR body.
  - Note: pushes directly to `main` are blocked and do NOT permit overrides.

Development docs exclusion for build→main
----------------------------------------
- Files under `docs/development/` are considered development-only documentation. They should NOT be merged into `main`.
- For PRs from `build` to `main`, changes under `docs/development/` are excluded from enforcement — i.e., the PR will not be allowed to move `docs/development/` into `main`. If something in `docs/development/` truly needs to reach `main`, move it to `docs/production/` or open a separate PR that authors the change for `main`.

Main as pip-install source
---------------------------
- The `main` branch is the canonical source for published package artifacts and should be the branch referenced by external consumers who pip install from a GitHub-hosted wheel or source URL. In other words, the `main` branch should be the point of the URL consumers use when installing directly from repository artifacts.

Recommended workflow mapping (summary)
- Feature PR (feature/* → develop)
  - `ci-tests-on-pr.yml` runs lightweight tests only.
  - No blockers for docs/root should run.
- Integration PR (develop → build)
  - `ci-tests-on-pr.yml` runs (lightweight); `ci-build-and-publish-package.yml` runs full CI for `build` PRs.
- Release PR (build → main)
  - `ci-tests-on-pr.yml` runs, full CI should have been run on `build`, and blockers (`block-root-additions`, docs enforcement) run for `main`.

PR behavior: develop → build
-----------------------------
- Intended use: PRs from `develop` to `build` are integration gates. They validate that the cumulative changes on `develop` are ready to be promoted for a release candidate.
- Expected workflows to run:
  - `ci-tests-on-pr.yml` — lightweight PR checks (pytest quick run).
  - `ci-build-and-publish-package.yml` — full CI (pinned deps check, lint, tests, build). This workflow is configured to run for PRs targeting `build`.
- Blockers that should NOT run for this PR path:
  - `block-root-additions.yml` and `ci-docs-enforce.yml` are intended for `main` and should not stop develop→build PRs.

Example: top-level snippet for `ci-build-and-publish-package.yml` (already in repo):

```yaml
on:
  pull_request:
    branches: [ build ]
  push:
    branches: [ build ]
```

PR behavior: feature/* → develop
--------------------------------
- Intended use: day-to-day development. Feature branches target `develop` for iterative work and review.
- Expected workflows to run:
  - `ci-tests-on-pr.yml` — lightweight tests only. It is fast and covers unit/smoke tests.
  - Path-based automations (e.g., auto-update requirements) may run if they match; these are intentionally limited by path.
- Blockers that should NOT run for this PR path:
  - Any enforcement workflow that gates merges into `main` (e.g., docs enforcement, root additions) should not run when the PR base is `develop`. Job-level guards prevent them from executing.

Example: top-of-file for `ci-tests-on-pr.yml` (already in repo):

```yaml
on:
  pull_request:
    branches: [ develop, build, main ]
```

Operational checklist for reviewers
- For `feature/* -> develop` PRs: ensure tests pass; docs in `docs/development/` are OK here.
- For `develop -> build` PRs: ensure full CI passes; keep docs in `docs/development/` unless they must be promoted to `main`.
- For `build -> main` PRs: ensure blockers pass (no development-only docs, no unexpected root additions); if a blocker flags something that must land on `main`, create a separate PR that moves files appropriately.

Notes and operational guidance
- If you need to change which branches trigger which workflows, update the `on:` block at the top of the corresponding workflow and keep job-level guards for enforcement workflows.
- For path-specific automations (e.g., update pinned requirements when `pyproject.toml` changes), path filters are acceptable but consider whether they should be limited to `develop` or `main`.
- Keep enforcement messages actionable: tell contributors how to correct (move docs to `docs/production/`, open a separate PR against `main`, etc.).

Appendix: example job-level guard for PRs

```yaml
if: >-
  github.event_name == 'pull_request' && github.event.pull_request.base.ref == 'main'
```

This is sufficient for most enforcement jobs that should only run for PRs to `main`.

---
Document created automatically by repo maintainer tooling on behalf of the team.
