from dataclasses import dataclass
from typing import Optional, Any, Dict
import time

@dataclass
class StepResult:
    name: str
    status: str  # Success | Failed | Skipped
    message: str
    error: Optional[str] = None
    timestamp: float = 0.0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "status": self.status,
            "message": self.message,
            "error": self.error,
            "timestamp": self.timestamp,
        }

    @classmethod
    def now(cls, name: str, status: str, message: str, error: Optional[Any] = None):
        ts = time.time()
        return cls(name=name, status=status, message=message, error=None if error is None else str(error), timestamp=ts)
