"""Flag `.all()` / `SELECT *` style fetches without obvious pagination.

This is the cheapest high-value detector: unbounded reads are the single
most common production footgun and trivial to spot lexically.
"""

from __future__ import annotations

import re
from pathlib import Path

from ...schemas import ScanRegisterRisk
from .base import RiskDetector

_UNBOUNDED_PATTERNS = [
    re.compile(r"\.all\s*\(\s*\)"),
    re.compile(r"SELECT\s+\*\s+FROM", re.IGNORECASE),
    re.compile(r"\.find\s*\(\s*\{\s*\}\s*\)"),
]
_PAGINATION_HINT = re.compile(r"\blimit\b|\.limit\s*\(|\boffset\b|\bpaginate\b", re.IGNORECASE)


class UnboundedFetchDetector(RiskDetector):
    def inspect(self, path: Path, source: str) -> list[ScanRegisterRisk]:
        if _PAGINATION_HINT.search(source):
            return []

        findings: list[ScanRegisterRisk] = []
        for pattern in _UNBOUNDED_PATTERNS:
            for match in pattern.finditer(source):
                line_no = source.count("\n", 0, match.start()) + 1
                findings.append(ScanRegisterRisk(
                    type="unbounded_fetch",
                    severity="medium",
                    location=f"{path}:{line_no}",
                    description=(
                        "Unbounded fetch detected. No limit/offset/pagination "
                        "hint found in the surrounding file."
                    ),
                    suggested_fix="Add explicit pagination or a row cap.",
                    confidence=0.6,
                ))
                break  # one finding per pattern per file is enough
        return findings
