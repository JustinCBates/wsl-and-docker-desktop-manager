<#
Builds generated .in files from pyproject.toml and compiles pinned requirements into dependencies/.
Usage: ./scripts/update-requirements.ps1
#>

Write-Host "Syncing requirements.in from pyproject.toml..."
python .\scripts\sync_reqs_from_pyproject.py
if ($LASTEXITCODE -ne 0) { throw "sync script failed" }

Write-Host "Installing pip-tools and compiling pinned requirements..."
python -m pip install --upgrade pip pip-tools
python -m piptools compile --output-file=dependencies/requirements.txt dependencies/requirements.in
python -m piptools compile --output-file=dependencies/requirements-dev.txt dependencies/requirements-dev.in

Write-Host "Done. Commit the updated dependencies/requirements*.txt files."