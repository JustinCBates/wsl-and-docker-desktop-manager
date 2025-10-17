#!/usr/bin/env python3
"""Prevent commits that add new top-level directories (blocking version)."""
import os, subprocess, sys
ALLOW = os.environ.get("ALLOWED_TOP_LEVEL", "src docs tools tests .github .vscode").split()
def get_staged_added_files():
    try:
        out = subprocess.check_output(["git","diff","--cached","--name-status","--diff-filter=A"]) 
    except subprocess.CalledProcessError:
        return []
    lines = out.decode().splitlines()
    files = [line.split('\t',1)[1] if '\t' in line else line.split(None,1)[1] for line in lines if line]
    return files
def main():
    cwd = os.getcwd()
    existing = {name for name in os.listdir(cwd) if os.path.isdir(os.path.join(cwd,name))}
    staged = get_staged_added_files()
    new = set()
    for f in staged:
        if '/' in f or '\\\\' in f:
            top = f.replace('\\','/').split('/',1)[0]
            if top not in existing and top not in ALLOW:
                new.add(top)
    if new:
        sys.stderr.write("ERROR: Commit would add new top-level dirs: %s\n" % ','.join(sorted(new)))
        return 1
    return 0
if __name__ == '__main__':
    sys.exit(main())
