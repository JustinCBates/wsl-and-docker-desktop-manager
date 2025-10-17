"""Simple helper to run single-unit smoke tests from the repo root.

Usage examples:
  python tools/run_smoke.py uninstall.uninstall_orchestrator --yes False --dry_run True
  python tools/run_smoke.py status.get_system_status --dry_run True

This script imports the target module from `src/` (so run it from the repo root).
"""
import sys
import importlib
import argparse

sys.path.insert(0, 'src')

parser = argparse.ArgumentParser()
parser.add_argument('module', help='Module path under src to import, e.g. uninstall.uninstall_orchestrator')
parser.add_argument('--yes', type=lambda s: s.lower() == 'true', default=False)
parser.add_argument('--dry_run', type=lambda s: s.lower() == 'true', default=True)
args = parser.parse_args()

mod = importlib.import_module(args.module)
if hasattr(mod, 'uninstall_sequence'):
    res = mod.uninstall_sequence(yes=args.yes, dry_run=args.dry_run)
    for r in res:
        print(r.to_dict())
elif hasattr(mod, 'get_system_status'):
    r = mod.get_system_status(dry_run=args.dry_run)
    print(r.to_dict())
else:
    print('Module loaded but no known entrypoint found; introspect functions manually.')
