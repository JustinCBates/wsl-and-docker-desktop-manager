Elevate helper
==============

This helper runs a PowerShell script elevated (prompts UAC) and returns when it completes.

Usage:

  python tools/elevate/run_elevated.py "C:\path\to\script.ps1" arg1 arg2

It captures stdout/stderr to temporary files and prints them after the elevated process finishes.

Recommended use:
- The manager calls this helper when the user clicks a button to perform an install/uninstall action.
- The user accepts the UAC prompt once; the elevated script performs the privileged actions.
