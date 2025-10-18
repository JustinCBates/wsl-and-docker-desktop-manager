"""Integration contract for UI ↔ orchestrator interactions.

Defines the minimal function signatures the UI will call on orchestrators.
Keep this file small and importable by UI code and tests.
"""
from typing import Any, Callable, Dict, List, Optional, Union


class StepResultShape(Dict):
    """A minimal typing alias for StepResult-like dicts for tests and adapters."""


def run_orchestrator(flow_name: str,
                     dry_run: bool = True,
                     yes: bool = False,
                     log_path: Optional[str] = None,
                     targets: Optional[List[str]] = None,
                     progress_cb: Optional[Callable[[Any, str], None]] = None
                     ) -> Union[Dict, List[Dict]]:
    """Abstract contract: call the named orchestrator and return StepResult or list.

    The real orchestrator entrypoints live under `src/` and should accept these
    named args. UI adapters can import and call them directly.
    """
    raise NotImplementedError()
