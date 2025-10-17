"""Simple StepRunner to invoke steps and return StepResult objects."""
from step_result import StepResult
import time
from typing import Callable, Any

class StepRunner:
    def __init__(self, dry_run: bool = True):
        self.dry_run = dry_run

    def invoke(self, name: str, func: Callable[..., Any] = None, *args, yes_required: bool = False, **kwargs) -> StepResult:
        if self.dry_run:
            return StepResult.now(name=name, status="Skipped", message=f"Dry-run: would invoke {name}")

        if yes_required and not kwargs.get("yes", False):
            return StepResult.now(name=name, status="Skipped", message=f"Requires -Yes to run {name}")

        try:
            if func:
                res = func(*args, **kwargs)
                return StepResult.now(name=name, status="Success", message=str(res))
            return StepResult.now(name=name, status="Success", message=f"No-op {name}")
        except Exception as e:
            return StepResult.now(name=name, status="Failed", message="Exception during step", error=e)
