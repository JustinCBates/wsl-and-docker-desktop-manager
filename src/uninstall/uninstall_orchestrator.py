"""Placeholder for src/uninstall/Uninstall-Orchestrator.ps1"""

def uninstall_sequence(yes: bool = False, dry_run: bool = True):
    steps = []
    steps.append({"name": "stop_docker", "status": "Skipped" if dry_run else "Success", "message": "MOCK: stop Docker"})
    steps.append({"name": "uninstall_docker", "status": "Skipped" if not yes else "Success", "message": "MOCK: uninstall Docker (no-op)"})
    steps.append({"name": "unregister_wsl", "status": "Skipped" if not yes else "Success", "message": "MOCK: unregister WSL (no-op)"})
    return steps
