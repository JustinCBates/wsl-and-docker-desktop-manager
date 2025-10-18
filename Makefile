# Makefile helpers for dependency management
.PHONY: update-requirements

update-requirements:
	python scripts/sync_reqs_from_pyproject.py
	python -m pip install --upgrade pip pip-tools
	python -m piptools compile --output-file=dependencies/requirements.txt dependencies/requirements.in
	python -m piptools compile --output-file=dependencies/requirements-dev.txt dependencies/requirements-dev.in
