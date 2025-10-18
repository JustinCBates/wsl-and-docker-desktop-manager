"""
scripts/sync_reqs_from_pyproject.py
Generate requirements.in and requirements-dev.in from root pyproject.toml and optionally compile pinned requirements.txt files.

Usage:
  python scripts/sync_reqs_from_pyproject.py [--write-txt]

If --write-txt is provided the script will run pip-compile to create pinned requirements.
"""

import tomllib
import argparse
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--write-txt", action="store_true", help="Also run pip-compile to generate pinned requirements.txt")
parser.add_argument("--pyproject", default="pyproject.toml")
parser.add_argument("--out-in", default="requirements.in")
parser.add_argument("--out-dev-in", default="requirements-dev.in")
args = parser.parse_args()

pyproject_path = Path(args.pyproject)
if not pyproject_path.exists():
    raise SystemExit(f"pyproject.toml not found at {pyproject_path}")

data = tomllib.loads(pyproject_path.read_text(encoding="utf8"))
proj = data.get("project", {})

def normalize_entry(e):
    if isinstance(e, str):
        return e
    # For complex table forms, just stringify - rare in typical projects
    return str(e)

# Gather runtime dependencies
deps = proj.get("dependencies", []) or []
opt = proj.get("optional-dependencies", {}) or {}
dev_deps = opt.get("dev", []) or []

Path(args.out_in).write_text("\n".join(normalize_entry(d).strip() for d in deps) + ("\n" if deps else ""), encoding="utf8")
Path(args.out_dev_in).write_text("\n".join(normalize_entry(d).strip() for d in dev_deps) + ("\n" if dev_deps else ""), encoding="utf8")

print(f"Wrote {args.out_in} and {args.out_dev_in} from {args.pyproject}")

if args.write_txt:
    subprocess.check_call(["python", "-m", "pip", "install", "--upgrade", "pip", "pip-tools"])
    subprocess.check_call(["python", "-m", "piptools", "compile", "--output-file=requirements.txt", args.out_in])
    subprocess.check_call(["python", "-m", "piptools", "compile", "--output-file=requirements-dev.txt", args.out_dev_in])
    print("Generated requirements.txt and requirements-dev.txt")
