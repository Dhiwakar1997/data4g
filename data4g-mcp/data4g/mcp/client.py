"""Thin async HTTP client wrapping the Data4G scan + key-verify endpoints.

All calls carry the `X-Api-Key` header — never a JWT. The client is
deliberately mechanical; schema validation happens at the tool boundary.
"""

from __future__ import annotations

from typing import Any

import httpx

from .config import Config


class BackendError(RuntimeError):
    """Structured HTTP failure the MCP layer re-raises as an MCP error."""

    def __init__(self, status_code: int, detail: str):
        super().__init__(f"[{status_code}] {detail}")
        self.status_code = status_code
        self.detail = detail


class Data4gClient:
    """Async HTTP client for the backend scan API.

    Construct via `Data4gClient(config)`; use as an async context manager
    so the underlying `httpx.AsyncClient` is torn down cleanly.
    """

    def __init__(self, config: Config):
        self._config = config
        self._client: httpx.AsyncClient | None = None

    async def __aenter__(self) -> Data4gClient:
        self._client = httpx.AsyncClient(
            base_url=self._config.api_base,
            timeout=self._config.http_timeout,
            headers={
                "X-Api-Key": self._config.api_key,
                "User-Agent": "data4g-mcp/0.1",
            },
        )
        return self

    async def __aexit__(self, *exc_info: Any) -> None:
        if self._client:
            await self._client.aclose()
            self._client = None

    # ── Helpers ──────────────────────────────────────────────

    def _project_url(self, suffix: str) -> str:
        return f"/projects/{self._config.project_id}/{suffix.lstrip('/')}"

    async def _request(
        self,
        method: str,
        url: str,
        json: dict[str, Any] | None = None,
    ) -> dict[str, Any] | list[dict[str, Any]]:
        assert self._client is not None, "use Data4gClient as an async context manager"
        response = await self._client.request(method, url, json=json)
        if response.status_code >= 400:
            detail: str
            try:
                body = response.json()
                detail = body.get("detail") if isinstance(body, dict) else str(body)
            except ValueError:
                detail = response.text or response.reason_phrase
            raise BackendError(response.status_code, detail or "unknown error")
        if response.status_code == 204 or not response.content:
            return {}
        return response.json()

    # ── Public API (one method per backend route) ────────────

    async def verify_key(self) -> dict[str, Any]:
        return await self._request("POST", self._project_url("keys/verify"))  # type: ignore[return-value]

    async def start_session(self, note: str | None) -> dict[str, Any]:
        return await self._request(
            "POST",
            self._project_url("scan/sessions"),
            json={"note": note},
        )  # type: ignore[return-value]

    async def get_session(self, sync_id: str) -> dict[str, Any]:
        return await self._request(
            "GET",
            self._project_url(f"scan/sessions/{sync_id}"),
        )  # type: ignore[return-value]

    async def register_endpoint(self, sync_id: str, payload: dict) -> dict[str, Any]:
        return await self._request(
            "POST",
            self._project_url(f"scan/sessions/{sync_id}/endpoints"),
            json=payload,
        )  # type: ignore[return-value]

    async def register_entity(self, sync_id: str, payload: dict) -> dict[str, Any]:
        return await self._request(
            "POST",
            self._project_url(f"scan/sessions/{sync_id}/entities"),
            json=payload,
        )  # type: ignore[return-value]

    async def register_service(self, sync_id: str, payload: dict) -> dict[str, Any]:
        return await self._request(
            "POST",
            self._project_url(f"scan/sessions/{sync_id}/services"),
            json=payload,
        )  # type: ignore[return-value]

    async def register_risk(self, sync_id: str, payload: dict) -> dict[str, Any]:
        return await self._request(
            "POST",
            self._project_url(f"scan/sessions/{sync_id}/risks"),
            json=payload,
        )  # type: ignore[return-value]

    async def add_note(self, sync_id: str, payload: dict) -> dict[str, Any]:
        return await self._request(
            "POST",
            self._project_url(f"scan/sessions/{sync_id}/notes"),
            json=payload,
        )  # type: ignore[return-value]

    async def finalize_session(self, sync_id: str) -> dict[str, Any]:
        return await self._request(
            "POST",
            self._project_url(f"scan/sessions/{sync_id}/finalize"),
        )  # type: ignore[return-value]

    async def abort_session(self, sync_id: str) -> dict[str, Any]:
        return await self._request(
            "POST",
            self._project_url(f"scan/sessions/{sync_id}/abort"),
        )  # type: ignore[return-value]
