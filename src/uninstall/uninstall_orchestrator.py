"""Uninstall orchestrator using StepRunner and StepResult (mocks-first).

This orchestrator composes small provider functions and returns a list of StepResult objects.
"""
from step_runner import StepRunner
from step_result import StepResult
from .docker.uninstall_docker import uninstall_docker
from .wsl.uninstall_wsl import unregister_wsl

def uninstall_sequence(yes: bool = False, dry_run: bool = True):
    runner = StepRunner(dry_run=dry_run)
    results = []

    # stop_docker: no-op placeholder
    results.append(runner.invoke("stop_docker", None))

    # uninstall_docker: requires explicit yes
    results.append(runner.invoke("uninstall_docker", uninstall_docker, yes_required=True, yes=yes))

    # unregister_wsl: requires explicit yes
    results.append(runner.invoke("unregister_wsl", unregister_wsl, yes_required=True, yes=yes))

    return results
