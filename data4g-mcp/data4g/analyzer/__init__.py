"""Local deterministic analyzer.

Exists so the agent can avoid reading every file in a large repo. Output is
a *first-pass* the agent can accept, override, or enrich before calling
`register_*`. Keep the analyzer intentionally conservative — false positives
here cost the user trust; missed detections the agent can still catch.
"""

from .runner import run_static_analysis  # noqa: F401
