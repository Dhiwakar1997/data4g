"""Risk-detector contract.

A detector runs over the full text of a source file and returns zero or more
``ScanRegisterRisk`` candidates. Keep detectors cheap and conservative —
false positives degrade agent trust fast.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from pathlib import Path

from ...schemas import ScanRegisterRisk


class RiskDetector(ABC):
    @abstractmethod
    def inspect(self, path: Path, source: str) -> list[ScanRegisterRisk]:
        """Return candidate risks for this file."""
