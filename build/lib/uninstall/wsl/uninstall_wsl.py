"""Placeholder for src/uninstall/wsl/Uninstall-WSL.ps1"""
from step_result import StepResult

def unregister_wsl(yes: bool = False):
    if not yes:
        return StepResult.now(name="unregister_wsl", status="Skipped", message="Requires -Yes")
    return StepResult.now(name="unregister_wsl", status="Success", message="MOCK: unregistered WSL distros (no-op)")
