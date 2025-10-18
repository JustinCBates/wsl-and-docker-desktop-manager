wsl-and-docker-desktop-manager
================================

Install (public PyPI)
---------------------

When published to PyPI consumers can install without any tokens:

```powershell
python -m pip install --upgrade pip
python -m pip install wsl-and-docker-desktop-manager
```

Importing in code:

```python
import wsl_and_docker_desktop_manager
```

Install from a GitHub Release (token-free)
-----------------------------------------

If you publish wheels as GitHub Release assets, consumers can install the wheel directly from the release URL. This is token-free and suitable for public repositories:

```powershell
python -m pip install https://github.com/JustinCBates/wsl-and-docker-desktop-manager/releases/download/v0.1.0/wsl_and_docker_desktop_manager-0.1.0-py3-none-any.whl
```

PEP 508 example (declare a release URL in pyproject dependencies):

```toml
[project]
dependencies = [
	"wsl-and-docker-desktop-manager @ https://github.com/JustinCBates/wsl-and-docker-desktop-manager/releases/download/v0.1.0/wsl_and_docker_desktop_manager-0.1.0-py3-none-any.whl"
]
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
```
