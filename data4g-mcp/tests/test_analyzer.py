"""Smoke tests for the static analyzer."""

from __future__ import annotations

from pathlib import Path

from data4g.analyzer import run_static_analysis


def test_python_fastapi_endpoint_detected(tmp_path: Path) -> None:
    (tmp_path / "app.py").write_text(
        '''
from fastapi import FastAPI

app = FastAPI()

@app.get("/users/{user_id}")
async def get_user(user_id: str):
    return {"id": user_id}
'''
    )
    result = run_static_analysis(tmp_path)
    assert len(result.endpoints) == 1
    ep = result.endpoints[0]
    assert ep.method == "GET"
    assert ep.path == "/users/{user_id}"
    assert ep.framework == "fastapi"


def test_node_express_endpoint_detected(tmp_path: Path) -> None:
    (tmp_path / "server.js").write_text(
        '''
const app = require("express")();
app.post("/login", (req, res) => res.json({ ok: true }));
'''
    )
    result = run_static_analysis(tmp_path)
    assert any(ep.method == "POST" and ep.path == "/login" for ep in result.endpoints)


def test_unbounded_fetch_flagged(tmp_path: Path) -> None:
    (tmp_path / "query.py").write_text(
        '''
def all_users(session):
    return session.query(User).all()
'''
    )
    result = run_static_analysis(tmp_path)
    assert any(r.type == "unbounded_fetch" for r in result.risks)


def test_pagination_suppresses_unbounded_fetch(tmp_path: Path) -> None:
    (tmp_path / "query.py").write_text(
        '''
def paged(session, page=0):
    return session.query(User).limit(50).offset(page * 50).all()
'''
    )
    result = run_static_analysis(tmp_path)
    assert all(r.type != "unbounded_fetch" for r in result.risks)


def test_skip_dirs(tmp_path: Path) -> None:
    vendored = tmp_path / "node_modules" / "pkg"
    vendored.mkdir(parents=True)
    (vendored / "index.js").write_text('app.get("/ignored", () => {});')
    (tmp_path / "app.js").write_text('app.get("/kept", () => {});')
    result = run_static_analysis(tmp_path)
    paths = {ep.path for ep in result.endpoints}
    assert "/kept" in paths
    assert "/ignored" not in paths
