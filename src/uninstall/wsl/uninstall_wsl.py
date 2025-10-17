"""Placeholder for src/uninstall/wsl/Uninstall-WSL.ps1"""

def unregister_wsl(yes: bool = False):
    if not yes:
        return {"name": "unregister_wsl", "status": "Skipped", "message": "Requires -Yes"}
    return {"name": "unregister_wsl", "status": "Success", "message": "MOCK: unregistered WSL distros (no-op)"}
