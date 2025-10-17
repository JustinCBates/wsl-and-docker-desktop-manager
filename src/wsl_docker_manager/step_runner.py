"""Inert StepRunner for mocks-first UI testing."""
from .result import StepResult
import time
from typing import Dict, Any

class StepRunner:
    def __init__(self, dry_run: bool = True):
        self.dry_run = dry_run

    def invoke_step(self, name: str, func=None, *args, **kwargs) -> StepResult:
        ts = time.time()
        if self.dry_run:
            return StepResult(name=name, status="Skipped", message=f"Dry-run: would invoke {name}", timestamp=ts)
        try:
            if func:
                res = func(*args, **kwargs)
                return StepResult(name=name, status="Success", message=str(res), timestamp=ts)
            else:
                return StepResult(name=name, status="Success", message=f"No-op {name}", timestamp=ts)
        except Exception as e:
            return StepResult(name=name, status="Failed", message="Exception during step", error=e, timestamp=ts)
