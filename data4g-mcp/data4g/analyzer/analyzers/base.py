"""Language-analyzer contract.

Each concrete analyzer scans files for one language/framework family and
emits ``ScanRegisterEndpoint`` / ``ScanRegisterEntity`` candidates.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from pathlib import Path

from ...schemas import ScanRegisterEndpoint, ScanRegisterEntity


class LanguageAnalyzer(ABC):
    """Extend this per language + framework combo."""

    #: File extensions this analyzer cares about (lower-case, incl. dot).
    extensions: tuple[str, ...] = ()

    @abstractmethod
    def analyze_file(
        self, path: Path, source: str
    ) -> tuple[list[ScanRegisterEndpoint], list[ScanRegisterEntity]]:
        """Return candidate endpoints + entities for a single file."""

    def wants(self, path: Path) -> bool:
        return path.suffix.lower() in self.extensions
