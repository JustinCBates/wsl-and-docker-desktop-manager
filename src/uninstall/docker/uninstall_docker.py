"""Placeholder for src/uninstall/docker/Uninstall-Docker.ps1"""
from step_result import StepResult

def uninstall_docker(yes: bool = False):
    if not yes:
        return StepResult.now(name="uninstall_docker", status="Skipped", message="Requires -Yes")
    return StepResult.now(name="uninstall_docker", status="Success", message="MOCK: uninstalled Docker (no-op)")
