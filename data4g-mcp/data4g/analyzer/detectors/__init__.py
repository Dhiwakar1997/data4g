from .base import RiskDetector
from .unbounded_fetch import UnboundedFetchDetector

DETECTORS: list[RiskDetector] = [UnboundedFetchDetector()]

__all__ = ["DETECTORS", "RiskDetector", "UnboundedFetchDetector"]
