# Build & release workflow (development)

This document describes how to build wheels locally, the CI artifact flow, and the token-free release process used by maintainers.

Local build (developer)

1. Create or activate a virtual environment.
2. Build a wheel locally:

```powershell
python -m pip install --upgrade pip build
python -m build --wheel --no-isolation
```

3. The wheel will be created in `dist/` (for example `dist/wsl_and_docker_desktop_manager-0.1.0-py3-none-any.whl`).

Helper script
- `scripts/release.ps1` is a convenience script that builds the wheel and optionally opens the GitHub Releases "New release" page so a maintainer can attach the wheel manually (token-free). Usage:

```powershell
./scripts/release.ps1 -OpenRelease
```

CI flow (what the CI does)
- The `ci-build-and-publish-package.yml` workflow runs on PRs and pushes to the `build` branch and will:
  - run a pinned-requirements check
  - run lints and tests
  - build a wheel and upload it as a workflow artifact
  - optionally publish to PyPI if `PYPI_API_TOKEN` is provided (disabled for token-free releases)

Token-free release (recommended)
1. Create a tag for the release (`git tag -a vX.Y.Z -m "Release vX.Y.Z"`) and push it.
2. Trigger CI by pushing to `build` branch or via a workflow dispatch; download the wheel artifact from the CI run.
3. Draft a new GitHub Release and attach the downloaded wheel. Publish the release.
4. Consumers can install directly from the release asset URL.

Notes
- Keep `dist/` and build artifacts out of version control (we ignore them via `.gitignore`).
- If you want fully-automated publishing to PyPI, add `PYPI_API_TOKEN` to repository secrets and enable the publish job; the token is required for API uploads.
