"""Regex-based Node.js analyzer covering Express + Fastify route registration."""

from __future__ import annotations

import re
from pathlib import Path

from ...schemas import ScanRegisterEndpoint, ScanRegisterEntity
from .base import LanguageAnalyzer

_EXPRESS_ROUTE = re.compile(
    r"\b(?P<var>\w+)\.(?P<method>get|post|put|patch|delete|options|head)\s*\(\s*"
    r"(['\"`])(?P<path>[^'\"`]+)\3",
    re.IGNORECASE,
)
_FASTIFY_ROUTE = re.compile(
    r"\.route\s*\(\s*\{\s*method\s*:\s*(['\"])(?P<method>[A-Z]+)\1\s*,\s*"
    r"url\s*:\s*(['\"])(?P<path>[^'\"]+)\3",
    re.IGNORECASE,
)


class NodeJSAnalyzer(LanguageAnalyzer):
    extensions = (".js", ".ts", ".mjs", ".cjs")

    def analyze_file(
        self, path: Path, source: str
    ) -> tuple[list[ScanRegisterEndpoint], list[ScanRegisterEntity]]:
        endpoints: list[ScanRegisterEndpoint] = []

        for match in _EXPRESS_ROUTE.finditer(source):
            var = match.group("var")
            # Filter obvious false positives (e.g. console.log, res.get).
            if var.lower() in {"res", "req", "console", "logger", "axios"}:
                continue
            endpoints.append(self._build(path, source, match.start(),
                                         match.group("method"), match.group("path"),
                                         "express"))

        for match in _FASTIFY_ROUTE.finditer(source):
            endpoints.append(self._build(path, source, match.start(),
                                         match.group("method"), match.group("path"),
                                         "fastify"))

        return endpoints, []

    def _build(
        self,
        path: Path,
        source: str,
        start: int,
        method: str,
        url_path: str,
        framework: str,
    ) -> ScanRegisterEndpoint:
        line_no = source.count("\n", 0, start) + 1
        return ScanRegisterEndpoint(
            method=method.upper(),
            path=url_path,
            handler_file=str(path),
            handler_line=line_no,
            framework=framework,
            semantic_description="",
        )
