wsl-and-docker-desktop-manager
================================

Install (public PyPI)
---------------------

When published to PyPI consumers can install without any tokens:

```powershell
python -m pip install --upgrade pip
python -m pip install wsl-and-docker-desktop-manager
```

Importing in code (during development):

```python
# When running from the repository root, import the package modules directly:
from src.install import install_orchestrator
from src.uninstall import uninstall_orchestrator
from src.status import get_system_status
```

Install from a GitHub Release (token-free)
-----------------------------------------

If you publish wheels as GitHub Release assets, consumers can install the wheel directly from the release URL. This is token-free and suitable for public repositories:

```powershell
# Releases produce wheels under `dist/` (example):
# python -m pip install dist\wsl_and_docker_desktop_manager-0.1.0-py3-none-any.whl
```

PEP 508 example (declare a release URL in pyproject dependencies):

```toml
[project]
# If you publish a wheel, consumers can reference it by direct URL or host it on PyPI.
dependencies = []
```

Developer install (from git)
----------------------------

For development or testing you can install directly from the repository:

```powershell
python -m pip install --upgrade pip
python -m pip install git+https://github.com/JustinCBates/wsl-and-docker-desktop-manager.git@main
```

Notes
-----
- If you want consumers to `pip install` the package with zero tokens, use PyPI or public GitHub Releases. GitHub Packages requires auth for consumers.
- Ensure `project.dependencies` in `pyproject.toml` lists any runtime dependencies so the wheel's METADATA includes Requires-Dist entries — that enables pip to install transitive dependencies automatically.

Dependency workflow
-------------------

We track runtime and development dependencies separately.

- Runtime deps: declared in `pyproject.toml` under `[project].dependencies` and listed in `requirements.in`.
- Development deps: declared in `[project.optional-dependencies].dev` and listed in `requirements-dev.in`.

To generate fully pinned `requirements.txt` and `requirements-dev.txt` use pip-tools locally:

```powershell
python -m pip install --user pip-tools
python -m piptools compile requirements.in --output-file=requirements.txt
python -m piptools compile requirements-dev.in --output-file=requirements-dev.txt
```

Install:

```powershell
python -m pip install -r requirements.txt         # production
python -m pip install -r requirements-dev.txt     # development (linters, test tools)

Quick dev workflow (recommended)
-------------------------------

There's a small helper PowerShell script at `run_with_venv.ps1` that creates/activates a `.venv`,
installs runtime requirements and (optionally) development requirements, then runs the interactive
manager. The `-Dev` flag installs development dependencies listed in `dependencies/requirements-dev.txt`.

Examples:

```powershell
# Create/activate venv, install runtime deps and dev deps, then run manager
.\run_with_venv.ps1 -Dev

# Same but silence pip output
.\run_with_venv.ps1 -Dev -Quiet

# Create/activate venv but skip any pip installs
.\run_with_venv.ps1 -NoInstall
```

Notes:
- The `-Dev` flag will install tools like `pytest`, `pylint`, `ruff`, and `yamllint` into the venv.
- If you prefer to manage dev deps manually, add or remove packages in `dependencies/requirements-dev.in`
	and regenerate the pinned file with `pip-compile`.
```
