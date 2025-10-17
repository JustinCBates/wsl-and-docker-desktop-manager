"""Mock platform provider used by the UI during mocks-first development."""
from ..result import StepResult
import time

class MockProvider:
    def stop_docker(self):
        ts = time.time()
        return StepResult(name="stop_docker", status="Success", message="MOCK: stop Docker (no-op)", timestamp=ts)

    def uninstall_docker(self, yes: bool = False):
        ts = time.time()
        msg = "MOCK: uninstall Docker Desktop (requires -Yes)"
        if not yes:
            return StepResult(name="uninstall_docker", status="Skipped", message=msg, timestamp=ts)
        return StepResult(name="uninstall_docker", status="Success", message="MOCK: uninstalled Docker Desktop", timestamp=ts)

    def unregister_wsl(self, yes: bool = False):
        ts = time.time()
        msg = "MOCK: unregister WSL distros (requires -Yes)"
        if not yes:
            return StepResult(name="unregister_wsl", status="Skipped", message=msg, timestamp=ts)
        return StepResult(name="unregister_wsl", status="Success", message="MOCK: unregistered WSL distros", timestamp=ts)
