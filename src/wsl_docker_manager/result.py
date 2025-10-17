from dataclasses import dataclass
from typing import Optional, Any

@dataclass
class StepResult:
    name: str
    status: str  # Success|Failed|Skipped
    message: str
    error: Optional[Any] = None
    timestamp: float = 0.0

    def to_dict(self):
        return {
            "name": self.name,
            "status": self.status,
            "message": self.message,
            "error": None if self.error is None else str(self.error),
            "timestamp": self.timestamp,
        }
