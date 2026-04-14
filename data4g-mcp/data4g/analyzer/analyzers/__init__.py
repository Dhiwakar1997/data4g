from .base import LanguageAnalyzer
from .node_analyzer import NodeJSAnalyzer
from .python_analyzer import PythonAnalyzer

ANALYZERS: list[LanguageAnalyzer] = [PythonAnalyzer(), NodeJSAnalyzer()]

__all__ = ["ANALYZERS", "LanguageAnalyzer", "NodeJSAnalyzer", "PythonAnalyzer"]
