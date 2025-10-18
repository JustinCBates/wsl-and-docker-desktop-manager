#!/usr/bin/env python3
"""Simple smoke runner that imports a module from src by dotted name and calls a known entrypoint.

Usage: python tools/dev/run_smoke.py uninstall.uninstall_orchestrator --dry_run True --yes False
"""
import sys
import importlib

def main(argv):
    if not argv:
        print("Usage: run_smoke.py <module> [args]")
        return 2
    module_name = argv[0]
    sys.path.insert(0, 'src')
    mod = importlib.import_module(module_name)
    # call a known function if present
    if hasattr(mod, 'uninstall_sequence'):
        print(mod.uninstall_sequence(dry_run=True, yes=False))
        return 0
    if hasattr(mod, 'main'):
        mod.main()
        return 0
    print('No known entrypoint in module', module_name)
    return 1

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
#!/usr/bin/env python3
import os, sys, subprocess
script = os.path.join(os.path.dirname(__file__), '..', 'run_smoke.py')
sys.exit(subprocess.call([sys.executable, script] + sys.argv[1:]))
