import sys
import os

# Ensure project src is importable from tests
repo_root = os.path.normpath(os.path.join(os.path.dirname(__file__), '..'))
src_root = os.path.join(repo_root, 'src')
if src_root not in sys.path:
    sys.path.insert(0, src_root)

from step_result import StepResult

from src.status.status_orchestrator import get_system_status
from src.status.wsl.get_wsl_status import get_wsl_status
from src.status.docker.get_docker_status import get_docker_status

from src.uninstall.wsl.uninstall_wsl import unregister_wsl as _unregister_wsl
from src.uninstall.docker.uninstall_docker import uninstall_docker

from src.backup.docker.backup_data import backup_data
from src.backup.docker.restore_data import restore_data
from src.backup.backup_orchestrator import backup_sequence

import importlib.util
import importlib.machinery
import os

# Install-Orchestrator.py filename contains a hyphen; load it by path to avoid import name issues
install_path = os.path.join(os.path.dirname(__file__), '..', 'src', 'install', 'Install-Orchestrator.py')
install_path = os.path.normpath(install_path)
spec = importlib.util.spec_from_file_location('install_orchestrator', install_path)
install_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(install_module)
install_orchestrator_main = install_module.main


def assert_step_result_ok(res):
    assert isinstance(res, StepResult)
    assert res.status == "Success"


def test_status_mocks():
    assert_step_result_ok(get_system_status(dry_run=False))
    assert_step_result_ok(get_wsl_status(dry_run=False))
    assert_step_result_ok(get_docker_status(dry_run=False))


def test_uninstall_mocks():
    # yes flag required for happy paths
    assert_step_result_ok(_unregister_wsl(yes=True))
    assert_step_result_ok(uninstall_docker(yes=True))


def test_backup_mocks():
    res = backup_data(dry_run=False)
    assert_step_result_ok(res)
    res = restore_data(dry_run=False)
    assert_step_result_ok(res)
    seq = backup_sequence(dry_run=False)
    assert isinstance(seq, list) and len(seq) > 0
    assert_step_result_ok(seq[0])


def test_install_orchestrator_placeholder():
    res = install_orchestrator_main(dry_run=False)
    assert isinstance(res, StepResult)
    assert res.status == "Success"
