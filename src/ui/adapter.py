"""Non-invasive UI adapter that maps flows to orchestrator entrypoints.

This module does not change orchestrators; it only imports and calls them.
"""
from typing import Any, Dict, List, Optional, Union


def _module_for_flow(flow_name: str) -> str:
    mapping = {
        "install": "src.install.install_orchestrator",
        "uninstall": "src.uninstall.uninstall_orchestrator",
        "status": "src.status.get_system_status",
    }
    return mapping.get(flow_name, "src.status.get_system_status")


def _call_module(module_path: str, dry_run: bool, yes: bool, log_path: Optional[str], targets: Optional[List[str]], progress_cb=None):
    import importlib

    mod = importlib.import_module(module_path)
    # prefer `main` entrypoint if available
    if hasattr(mod, "main"):
        # pass progress_cb if supported (orchestrators should accept it optionally)
        try:
            return mod.main(dry_run=dry_run, yes=yes, log_path=log_path, targets=targets, progress_cb=progress_cb)
        except TypeError:
            return mod.main(dry_run=dry_run, yes=yes, log_path=log_path, targets=targets)
    # fallback: try calling with positional args
    if hasattr(mod, "main"):
        return mod.main(dry_run)
    # last resort: try a call without args
    if hasattr(mod, "run"):
        return mod.run()
    raise RuntimeError(f"Orchestrator entrypoint not found in {module_path}")


def run_flow(flow_name: str, dry_run: bool = True, yes: bool = False, log_path: Optional[str] = None, targets: Optional[List[str]] = None, progress_cb=None) -> Union[Dict, List[Dict]]:
    """Run the orchestrator for a flow and normalize results.

    Returns either a StepResult-like dict or a list of such dicts.
    """
    module_path = _module_for_flow(flow_name)
    res = _call_module(module_path, dry_run, yes, log_path, targets, progress_cb=progress_cb)
    # normalize
    if res is None:
        return []
    if isinstance(res, list):
        return res
    return [res]
