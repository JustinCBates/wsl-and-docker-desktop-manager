"""Placeholder for src/uninstall/docker/Uninstall-Docker.ps1"""

def uninstall_docker(yes: bool = False):
    if not yes:
        return {"name": "uninstall_docker", "status": "Skipped", "message": "Requires -Yes"}
    return {"name": "uninstall_docker", "status": "Success", "message": "MOCK: uninstalled Docker (no-op)"}
