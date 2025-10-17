#!/usr/bin/env python3
"""Run a PowerShell script with elevation (UAC) and wait for completion.

This helper launches PowerShell to Start-Process the requested script with the
runas verb (UAC). It redirects stdout/stderr to temporary files and prints them
after completion. Use this from your manager when you need a one-click elevation
for install/uninstall actions.

Usage:
  python tools/elevate/run_elevated.py "C:\path\to\script.ps1" arg1 arg2

The script will prompt Windows UAC; the user must confirm.
"""
import os
import sys
import tempfile
import shlex
import subprocess


def build_ps_command(script_path, script_args, out_file, err_file):
    # Build a PowerShell command string that runs pwsh (or powershell) to execute
    # the script and redirect output to files. Use Start-Process -Verb RunAs -Wait
    # and pass-through the exit code.
    # Use pwsh if available, otherwise powershell.
    pwsh = 'pwsh'
    # Quote paths
    script_path_q = script_path.replace("'", "''")
    args_quoted = ' '.join([shlex.quote(a) for a in script_args])
    # Construct inner argument list for pwsh: -NoProfile -ExecutionPolicy Bypass -File 'script' args
    inner = f"-NoProfile -ExecutionPolicy Bypass -File '{script_path_q}' {args_quoted}"

    # Use Start-Process to elevate and wait; redirect output within the elevated pwsh
    # We'll wrap the inner command in quotes and use Out-File for output redirection
    # Build the argument string passed to Start-Process as a single string
    inner_escaped = inner.replace("'", "''")
    # The elevated process will run pwsh with the inner args and redirect output to files
    elevated_args = f"-NoProfile -Command \"& {{ & {pwsh} {inner_escaped} *> '{out_file}' 2> '{err_file}' }}\""

    # Build the command that calls Start-Process to run pwsh elevated
    # We call powershell.exe (present on Windows) to invoke Start-Process
    ps_command = (
        "Start-Process -FilePath 'pwsh' -ArgumentList @(' -NoProfile -Command ', \"& { & 'pwsh' -NoProfile -ExecutionPolicy Bypass -File '" + script_path_q + "' '" + "' '.join(script_args) + "' ) -Verb RunAs -Wait -PassThru | Select-Object -ExpandProperty ExitCode"
    )
    # The above is complex to compose robustly; instead, we'll build a simpler command
    # that uses Start-Process with a single string argument and lets pwsh handle redirection.
    ps_command = (
        "$arg = '-NoProfile -ExecutionPolicy Bypass -File \"" + script_path_q + "\" ' + ' '.join(@('""') ) ; "
        "Start-Process -FilePath 'pwsh' -ArgumentList \"-NoProfile -ExecutionPolicy Bypass -File '" + script_path_q + "' " + ' '.join([shlex.quote(a) for a in script_args]) + "\" -Verb RunAs -Wait -NoNewWindow"
    )
    # The above attempts to start elevated and wait — we'll instead use a slightly different approach
    # Compose a powershell command that calls Start-Process with -Verb RunAs and -Wait and that
    # launches pwsh which runs the script and redirects inside it.

    # Final approach: build a one-liner that Start-Process runs pwsh -Command "& { & 'script' args *> out 2>err }"
    inner_cmd = f"& {{ & '{script_path_q}' {args_quoted} *> '{out_file}' 2> '{err_file}' }}"
    inner_cmd_escaped = inner_cmd.replace("'", "''")
    ps_command = f"Start-Process -FilePath 'pwsh' -ArgumentList '-NoProfile','-Command','{inner_cmd_escaped}' -Verb RunAs -Wait -PassThru | Select-Object -ExpandProperty ExitCode"

    return ps_command


def run_elevated(script_path, script_args):
    script_path = os.path.abspath(script_path)
    if not os.path.exists(script_path):
        print(f"Script not found: {script_path}")
        return 2

    out_fd, out_path = tempfile.mkstemp(prefix='elev_out_', suffix='.log')
    err_fd, err_path = tempfile.mkstemp(prefix='elev_err_', suffix='.log')
    os.close(out_fd)
    os.close(err_fd)

    ps_command = build_ps_command(script_path, script_args, out_path, err_path)

    # Invoke powershell to run Start-Process (which will prompt UAC)
    cmd = [
        'powershell',
        '-NoProfile',
        '-Command',
        ps_command
    ]

    print('Requesting elevation (UAC). Please accept the UAC prompt to continue...')
    proc = subprocess.run(cmd)
    exit_code = proc.returncode

    print('\n--- elevated stdout (tail) ---')
    try:
        with open(out_path, 'r', encoding='utf-8', errors='replace') as f:
            print(f.read())
    except Exception:
        print('(no stdout)')

    print('\n--- elevated stderr (tail) ---')
    try:
        with open(err_path, 'r', encoding='utf-8', errors='replace') as f:
            print(f.read())
    except Exception:
        print('(no stderr)')

    # Cleanup temp files
    try:
        os.remove(out_path)
        os.remove(err_path)
    except Exception:
        pass

    return exit_code


def main(argv):
    if not argv:
        print('Usage: run_elevated.py <script.ps1> [args...]')
        return 2
    script = argv[0]
    args = argv[1:]
    return run_elevated(script, args)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
