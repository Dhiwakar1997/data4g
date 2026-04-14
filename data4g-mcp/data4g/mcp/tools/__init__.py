"""Tool registration. Grouped by concern; each sub-module attaches its
tools to the shared `FastMCP` instance.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from .analyzer import register as register_analyzer_tools
from .register import register as register_write_tools
from .session import register as register_session_tools

if TYPE_CHECKING:
    from mcp.server.fastmcp import FastMCP

    from ..server import ServerContext


def register_all_tools(mcp: "FastMCP", context: "ServerContext") -> None:
    register_session_tools(mcp, context)
    register_write_tools(mcp, context)
    register_analyzer_tools(mcp, context)
