#!/usr/bin/env python3
import os, sys, subprocess
script = os.path.join(os.path.dirname(__file__), '..', 'run_smoke.py')
sys.exit(subprocess.call([sys.executable, script] + sys.argv[1:]))
