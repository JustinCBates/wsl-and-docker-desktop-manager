"""Placeholder for src/status/docker/Get-DockerStatus.ps1"""
from step_result import StepResult

def get_docker_status(dry_run: bool = True):
    if dry_run:
        return StepResult.now(name="get_docker_status", status="Skipped", message="Dry-run: docker status")
    return StepResult.now(name="get_docker_status", status="Success", message="MOCK: docker not running")
