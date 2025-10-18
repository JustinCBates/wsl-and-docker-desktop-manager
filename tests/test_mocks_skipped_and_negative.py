import sys
import os

repo_root = os.path.normpath(os.path.join(os.path.dirname(__file__), '..'))
src_root = os.path.join(repo_root, 'src')
if src_root not in sys.path:
    sys.path.insert(0, src_root)

from step_result import StepResult
from src.status.status_orchestrator import get_system_status
from src.status.wsl.get_wsl_status import get_wsl_status
from src.status.docker.get_docker_status import get_docker_status
from src.uninstall.wsl.uninstall_wsl import unregister_wsl
from src.uninstall.docker.uninstall_docker import uninstall_docker
from src.install.install_orchestrator import main as install_orchestrator_main
from src.step_runner import StepRunner


def test_skipped_dry_run_paths():
    assert get_system_status(dry_run=True).status == "Skipped"
    assert get_wsl_status(dry_run=True).status == "Skipped"
    assert get_docker_status(dry_run=True).status == "Skipped"
    assert unregister_wsl(yes=False).status == "Skipped"
    assert uninstall_docker(yes=False).status == "Skipped"
    assert install_orchestrator_main(dry_run=True).status == "Skipped"


def test_step_runner_failure_path():
    runner = StepRunner(dry_run=False)

    def raises():
        raise RuntimeError("boom")

    res = runner.invoke("test_raises", func=raises)
    assert isinstance(res, StepResult)
    assert res.status == "Failed" or res.status == "Error"
