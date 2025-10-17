#!/usr/bin/env python3
"""Wrapper to tools/acl/prevent_root_dirs.py"""
import os, sys, subprocess
script = os.path.join(os.path.dirname(__file__), '..', 'acl', 'prevent_root_dirs.py')
sys.exit(subprocess.call([sys.executable, script] + sys.argv[1:]))
