"""Regex-based Python analyzer covering FastAPI + Flask decorators.

Deliberately shallow; the agent is expected to enrich with semantic detail.
We mark every emitted record with an empty ``semantic_description`` so the
agent knows this is raw output.
"""

from __future__ import annotations

import re
from pathlib import Path

from ...schemas import ScanRegisterEndpoint, ScanRegisterEntity
from .base import LanguageAnalyzer

_FASTAPI_DECORATOR = re.compile(
    r"@(?P<var>\w+)\.(?P<method>get|post|put|patch|delete|options|head)\s*\(\s*"
    r"(['\"])(?P<path>[^'\"]+)\3",
    re.IGNORECASE,
)
_FLASK_ROUTE = re.compile(
    r"@(?P<var>\w+)\.route\s*\(\s*(['\"])(?P<path>[^'\"]+)\2"
    r"(?:\s*,\s*methods\s*=\s*\[(?P<methods>[^\]]+)\])?",
    re.IGNORECASE,
)
_HANDLER_DEF = re.compile(r"^\s*(?:async\s+)?def\s+(?P<name>\w+)\s*\(", re.MULTILINE)


class PythonAnalyzer(LanguageAnalyzer):
    extensions = (".py",)

    def analyze_file(
        self, path: Path, source: str
    ) -> tuple[list[ScanRegisterEndpoint], list[ScanRegisterEntity]]:
        endpoints: list[ScanRegisterEndpoint] = []

        for match in _FASTAPI_DECORATOR.finditer(source):
            endpoints.append(self._build_endpoint(
                path=path,
                source=source,
                match_start=match.start(),
                method=match.group("method"),
                url_path=match.group("path"),
                framework="fastapi",
            ))

        for match in _FLASK_ROUTE.finditer(source):
            raw_methods = match.group("methods")
            methods = (
                [m.strip().strip("'\"").upper() for m in raw_methods.split(",")]
                if raw_methods else ["GET"]
            )
            for method in methods:
                endpoints.append(self._build_endpoint(
                    path=path,
                    source=source,
                    match_start=match.start(),
                    method=method,
                    url_path=match.group("path"),
                    framework="flask",
                ))

        # Entity extraction (SQLAlchemy / Pydantic) is intentionally omitted
        # from v1 — the agent can still register entities directly.
        return endpoints, []

    def _build_endpoint(
        self,
        *,
        path: Path,
        source: str,
        match_start: int,
        method: str,
        url_path: str,
        framework: str,
    ) -> ScanRegisterEndpoint:
        line_no = source.count("\n", 0, match_start) + 1
        return ScanRegisterEndpoint(
            method=method.upper(),
            path=url_path,
            handler_file=str(path),
            handler_line=line_no,
            framework=framework,
            semantic_description="",  # agent to fill in
        )
