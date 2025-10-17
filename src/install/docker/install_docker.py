"""Placeholder converted from src/install/docker/Install-Docker.ps1"""
from step_result import StepResult

def install_docker(*, dry_run=True):
    """Mock placeholder for installing Docker Desktop."""
    if dry_run:
        return StepResult.now(name="install_docker", status="Skipped", message="Dry-run: would install Docker Desktop")
    return StepResult.now(name="install_docker", status="Success", message="MOCK: installed Docker Desktop")
