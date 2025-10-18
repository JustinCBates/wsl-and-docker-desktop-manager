Release checklist — token-free GitHub Releases

This checklist documents a manual, token-free release flow using GitHub Releases. It assumes CI builds wheels as artifacts on PRs and on `build` branch pushes.

1. Build verification (CI)
   - Open a PR from `develop` → `build` and ensure the `Build` job produces a wheel artifact.
   - Download the artifact from the successful workflow run and verify it installs locally:
     ```powershell
     python -m pip install path\to\artifact\wsl_and_docker_desktop_manager-0.1.0-py3-none-any.whl
     ```

2. Tag the release locally
   - Pick the commit you want to release (for example the `build` branch HEAD) and create an annotated tag:
     ```powershell
     git checkout build
     git pull --ff-only
     git tag -a v0.1.0 -m "Release v0.1.0"
     git push origin v0.1.0
     ```

3. Create a GitHub Release and attach the wheel (manual)
   - In the GitHub UI go to: Releases → Draft a new release.
   - Choose the tag you pushed (v0.1.0). Add release notes and upload the wheel you downloaded from CI as an asset.
   - Publish the release.

4. Consumer install (token-free)
   - Document the install URL in README (example):
     ```powershell
     python -m pip install https://github.com/JustinCBates/wsl-and-docker-desktop-manager/releases/download/v0.1.0/wsl_and_docker_desktop_manager-0.1.0-py3-none-any.whl
     ```

Notes and caveats
- Ensure `project.dependencies` in `pyproject.toml` lists all runtime dependencies. When pip installs the wheel it will read dependency metadata and fetch transitive dependencies from public PyPI.
- If the package has private dependencies, consumers must configure an index or pre-install those dependencies (this requires tokens on the consumer side).
- For pure-Python code produce a universal wheel (`py3-none-any.whl`) so a single wheel works across platforms.
- If you prefer partial automation, CI can upload artifacts and create a draft release via API, but attaching assets via the API requires a token. The manual flow above requires no secrets in CI.
