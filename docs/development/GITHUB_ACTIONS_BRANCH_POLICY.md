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

Recommended workflow mapping (summary)
- Feature PR (feature/* → develop)
  - `ci-tests-on-pr.yml` runs lightweight tests only.
  - No blockers for docs/root should run.
- Integration PR (develop → build)
  - `ci-tests-on-pr.yml` runs (lightweight); `ci-build-and-publish-package.yml` runs full CI for `build` PRs.
- Release PR (build → main)
  - `ci-tests-on-pr.yml` runs, full CI should have been run on `build`, and blockers (`block-root-additions`, docs enforcement) run for `main`.

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
