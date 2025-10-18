# Dependency workflow (development)

This document describes the dependency management workflow used during development. It is intended for contributors working on development branches and should not be merged to `main` if it contains work-in-progress guidance.

Key tools
- pip-tools (pip-compile / pip-sync) — used to keep a human-editable `requirements.in` (or other inputs) and a fully pinned `requirements.txt` for reproducible builds.
- `pyproject.toml` — authoritative project metadata and declared runtime dependencies under `[project].dependencies`.


Typical day-to-day workflow

1. Edit `requirements.in` to add or remove top-level runtime dependencies (or edit `pyproject.toml` for project metadata/runtime deps). Note: in this repository the generated `requirements.in` and `requirements-dev.in` files are produced into `dependencies/` by `scripts/sync_reqs_from_pyproject.py` and are ignored in Git. Developers should normally edit `pyproject.toml` (the canonical source) and run the sync script locally when needed.
2. Run pip-compile locally to regenerate a pinned `requirements.txt`:

```powershell
python -m pip install --upgrade pip pip-tools
python -m piptools compile --output-file=dependencies/requirements.txt dependencies/requirements.in
```

3. Commit the regenerated `dependencies/requirements.txt` (pinned) to the branch. Do NOT commit the generated `dependencies/requirements.in` files — they are ignored and will be created by CI from `pyproject.toml`.

CI enforcement
- The repository CI runs a pinned-check job which executes:

```bash
pip-compile --output-file=requirements.txt --check requirements.in
```

If the check fails, update `requirements.txt` locally and push the regenerated file.

Notes
- For dev-only tooling (linters, formatters) use `requirements-dev.in` and `requirements-dev.txt`.
- If you prefer editing `pyproject.toml` for runtime deps, keep `pyproject.toml` and `requirements.in` synchronized and update both as needed. The CI expects `requirements.in` to be the input for the pinned-check step.
