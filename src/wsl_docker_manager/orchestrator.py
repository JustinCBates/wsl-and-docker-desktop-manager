"""Thin orchestrator entrypoint that uses the mock provider by default."""
from .platform.mock_provider import MockProvider
from .step_runner import StepRunner

class Orchestrator:
    def __init__(self, provider=None, dry_run: bool = True):
        self.provider = provider if provider is not None else MockProvider()
        self.step_runner = StepRunner(dry_run=dry_run)

    def uninstall(self, yes: bool = False):
        results = []
        results.append(self.step_runner.invoke_step("stop_docker", self.provider.stop_docker))
        results.append(self.step_runner.invoke_step("uninstall_docker", self.provider.uninstall_docker, yes))
        results.append(self.step_runner.invoke_step("unregister_wsl", self.provider.unregister_wsl, yes))
        return results

# tiny convenience function for the UI to call
def uninstall_sequence(yes: bool = False, dry_run: bool = True):
    orch = Orchestrator(dry_run=dry_run)
    return orch.uninstall(yes=yes)
