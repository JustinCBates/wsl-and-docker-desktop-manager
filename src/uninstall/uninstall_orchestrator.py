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

def uninstall_sequence(yes: bool = False, dry_run: bool = True, progress_cb=None):
    """Run uninstall sequence. Optional progress_cb(event_dict, event_type) will be called if provided."""
    runner = StepRunner(dry_run=dry_run)
    results = []

    def _emit(event: dict, event_type: str):
        if not progress_cb:
            return
        try:
            progress_cb(event, event_type)
        except Exception:
            # never let UI callback failures abort the orchestrator
            pass

    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

    # stop_docker: no-op placeholder
    _emit({"step_id": "stop_docker", "name": "stop_docker"}, "step-start")
    res = runner.invoke("stop_docker", None)
    _emit({"step_id": "stop_docker", "status": getattr(res, 'status', 'Unknown')}, "step-end")
    results.append(res)

    # uninstall_docker: requires explicit yes
    if dry_run:
        _emit({"step_id": "uninstall_docker", "name": "uninstall_docker"}, "step-start")
        res = runner.invoke("uninstall_docker", uninstall_docker, yes_required=True, yes=yes)
        _emit({"step_id": "uninstall_docker", "status": getattr(res, 'status', 'Unknown')}, "step-end")
        results.append(res)
    else:
        # call elevated PowerShell uninstall script (mock placeholder)
        script = os.path.join(repo_root, 'tools', 'protect', 'uninstall_docker.ps1')
        _emit({"step_id": "uninstall_docker", "name": "uninstall_docker"}, "step-start")
        res = runner.invoke("uninstall_docker", lambda: _run_elevated_script(script), yes_required=True, yes=yes)
        _emit({"step_id": "uninstall_docker", "status": getattr(res, 'status', 'Unknown')}, "step-end")
        results.append(res)

    # unregister_wsl: requires explicit yes
    if dry_run:
        _emit({"step_id": "unregister_wsl", "name": "unregister_wsl"}, "step-start")
        res = runner.invoke("unregister_wsl", unregister_wsl, yes_required=True, yes=yes)
        _emit({"step_id": "unregister_wsl", "status": getattr(res, 'status', 'Unknown')}, "step-end")
        results.append(res)
    else:
        script = os.path.join(repo_root, 'tools', 'protect', 'unregister_wsl.ps1')
        _emit({"step_id": "unregister_wsl", "name": "unregister_wsl"}, "step-start")
        res = runner.invoke("unregister_wsl", lambda: _run_elevated_script(script), yes_required=True, yes=yes)
        _emit({"step_id": "unregister_wsl", "status": getattr(res, 'status', 'Unknown')}, "step-end")
        results.append(res)

    return results


def main(dry_run: bool = True, yes: bool = False, log_path: str = None, targets=None, progress_cb=None, interactive: bool = False):
    """Top-level entrypoint for the uninstall orchestrator.

    If interactive=True and `questionary` is available, prompt the user for
    dry-run/yes options. Otherwise use provided args. Returns the list of
    StepResult objects produced by uninstall_sequence.
    """
    if interactive:
        try:
            import questionary  # type: ignore
            # ask dry-run and yes
            dr = questionary.confirm("Dry-run (no changes)?", default=True).ask()
            yn = questionary.confirm("Run with -Yes (allow destructive actions)?", default=False).ask()
            dry_run = bool(dr)
            yes = bool(yn)
        except Exception:
            # fallback to provided args
            pass

    return uninstall_sequence(yes=yes, dry_run=dry_run, progress_cb=progress_cb)
