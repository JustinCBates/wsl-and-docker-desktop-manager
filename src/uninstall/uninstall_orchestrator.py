"""Uninstall orchestrator using StepRunner and StepResult (mocks-first).

This orchestrator composes small provider functions and returns a list of StepResult objects.
"""
from step_runner import StepRunner
from step_result import StepResult
from .docker.uninstall_docker import uninstall_docker
from .wsl.uninstall_wsl import unregister_wsl
import subprocess
import sys
import os


def _run_elevated_script(script_path: str, args=None) -> StepResult:
    """Run a script with UAC elevation using the repository helper and return a StepResult."""
    args = args or []
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    helper = os.path.join(repo_root, 'tools', 'elevate', 'run_elevated.py')
    if not os.path.exists(helper):
        return StepResult(name=os.path.basename(script_path), status='Error', message='elevate helper missing', error='helper not found')
    cmd = [sys.executable, helper, script_path] + args
    try:
        proc = subprocess.run(cmd, check=False)
        if proc.returncode == 0:
            return StepResult(name=os.path.basename(script_path), status='Ok', message='elevated action completed')
        return StepResult(name=os.path.basename(script_path), status='Failed', message='elevated action failed', error=f'exit {proc.returncode}')
    except Exception as e:
        return StepResult(name=os.path.basename(script_path), status='Error', message='exception during elevation', error=str(e))

def uninstall_sequence(yes: bool = False, dry_run: bool = True):
    runner = StepRunner(dry_run=dry_run)
    results = []

    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

    # stop_docker: no-op placeholder
    results.append(runner.invoke("stop_docker", None))

    # uninstall_docker: requires explicit yes
    if dry_run:
        results.append(runner.invoke("uninstall_docker", uninstall_docker, yes_required=True, yes=yes))
    else:
        # call elevated PowerShell uninstall script (mock placeholder)
        script = os.path.join(repo_root, 'tools', 'protect', 'uninstall_docker.ps1')
        results.append(runner.invoke("uninstall_docker", lambda: _run_elevated_script(script), yes_required=True, yes=yes))

    # unregister_wsl: requires explicit yes
    if dry_run:
        results.append(runner.invoke("unregister_wsl", unregister_wsl, yes_required=True, yes=yes))
    else:
        script = os.path.join(repo_root, 'tools', 'protect', 'unregister_wsl.ps1')
        results.append(runner.invoke("unregister_wsl", lambda: _run_elevated_script(script), yes_required=True, yes=yes))

    return results
