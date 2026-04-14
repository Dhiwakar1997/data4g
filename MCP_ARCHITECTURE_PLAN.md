# Per-Project API Keys & MCP-Driven Scanner

## Context

The Data4G backend already ingests static-analysis data into a "live" topology per project via [backend/dataforge/route/mcp_route.py](backend/dataforge/route/mcp_route.py), but today:

1. **Auth is wrong.** Ingestion requires a user's JWT. Machines can't hold human tokens safely; no automated agent can authenticate to Data4G without impersonating a user.
2. **The scanner isn't distributable.** The analyzer under [backend/mcp_server/](backend/mcp_server/) only runs inside this monorepo.
3. **The scanner doesn't actually leverage AI.** Static analysis alone misses intent, semantics, and business-level risk that an AI agent with full codebase context can surface.

**Intended outcome:** The user installs a small Data4G package, points their AI coding agent (Claude Code, Cursor, Codex, or any MCP-capable client) at it, and says *"sync this repo to Data4G."* The agent:

- Reads the codebase using its own tools and models (its tokens, not ours).
- Calls our MCP server's fine-grained tools (`start_sync`, `register_endpoint`, `register_entity`, `register_risk`, `finalize_sync`, etc.) to structure and enrich what it finds.
- Data lands in the backend via authenticated POSTs using a project-scoped API key.

No human JWT involved in ingestion. Agent does semantic work a static analyzer can't. Static analyzer becomes *one optional tool* the agent can invoke.

---

## Decisions (locked with PM)

| Area | Decision |
|---|---|
| Agent role | Semantic enrichment. MCP server exposes fine-grained tools; agent drives analysis. |
| Transport | stdio. MCP server runs as a local subprocess spawned by the agent. |
| Sync CLI | **Removed.** No `data4g sync`. Sync only happens through an AI agent. |
| Setup CLI | Kept, but only for bootstrap: `data4g init` writes MCP config for detected IDEs; `data4g doctor` diagnoses. **No `data4g login`** — API key is supplied via `DATA4G_API_KEY` env var (see Key Handling below). |
| Agents supported | Any MCP-capable client; first-class setup docs + `data4g init` for Claude Code, Cursor, Codex. Multiple agents in parallel is supported (same MCP server config, each spawns its own instance). |
| Key scope | Ingest + read, scoped to one project. No cross-project access. |
| URL shape | Keep `project_id` in the path. Key must be bound to that project; mismatch = 403. |
| Key rotation | Up to 2 active keys per project. Manual rotation by owner. |
| Naming | Backend ingestion layer → `scan_*` (it's not MCP). Client-side package → `data4g-mcp` (it *is* MCP). Existing `backend/mcp_server/` analyzer code moves into the client package. |

---

## Architecture Overview

```
┌─────────────────────┐         ┌────────────────────────┐         ┌───────────────────┐
│ AI Agent            │  stdio  │ data4g-mcp (local)     │  HTTPS  │ Data4G Backend    │
│ (Claude Code, etc.) │ ──────▶│ MCP server              │ ──────▶│ /api/v1/projects  │
│  - uses its tokens  │         │  - fine-grained tools  │ X-Api-   │  /{id}/scan/...   │
│  - reads user code  │         │  - local analyzer opt. │  Key     │                   │
└─────────────────────┘         └────────────────────────┘         └───────────────────┘
         ▲                                  ▲
         │ user installs via                │ reads DATA4G_API_KEY from env
         │ `data4g init` (one-time)         │ (inherited from agent's parent shell)
```

Three components:
1. **`data4g-mcp`** — stdio MCP server; installed locally via `pip install data4g`; spawned by the agent.
2. **`data4g` CLI** — setup only (`init`, `doctor`, `--version`). Same pip package, second entry point.
3. **Backend** — renamed ingestion routes, new API-key auth, new session-based ingest API.

---

## MCP Server Design

### Session model (why this matters)

Nothing commits to the live topology until the agent calls `finalize_sync`. This is the single biggest defence against non-deterministic agent behaviour — partial uploads, crashed agents, hallucinated data. The session is a staging area.

### Tool surface

All tools require `sync_id` except `start_sync` and read-only tools. Backend binds `sync_id` to the API key's `project_id`; cross-project writes are rejected.

**Session:**
- `start_sync(project_id: str, note: str) → { sync_id }`
- `finalize_sync(sync_id: str) → { endpoints_added, entities_added, risks_added, topology_url }`
- `abort_sync(sync_id: str) → { discarded: true }`

**Optional local analyzer (saves agent tokens):**
- `run_static_analysis(path: str) → { endpoints[], entities[], services[], risks[] }` — runs the deterministic analyzer on the local filesystem. Agent can accept, override, or enrich the output before registering. This is not required; the agent can skip it entirely and register everything itself.

**Registration (the semantic-enrichment layer):**
- `register_endpoint(sync_id, { method, path, handler_file, handler_line, framework?, auth_required?, is_hot_path?, semantic_description, notes? })`
- `register_entity(sync_id, { name, file, fields[], semantic_description, pii_fields? })`
- `register_service(sync_id, { name, type, depends_on[], semantic_description })`
- `register_risk(sync_id, { type, severity, location, description, suggested_fix, confidence })`
- `add_semantic_note(sync_id, target_type, target_ref, note)` — attach free-form reasoning.

**Read (context for the agent):**
- `get_project_info(project_id) → { name, cloud_provider, last_synced_at, endpoint_count }`
- `list_previous_endpoints(project_id) → [ { method, path, last_seen } ]` — lets the agent reconcile against the previous sync and detect removals.

### Design rules enforced server-side

- `start_sync` returns a short-lived `sync_id` (TTL 2h); expired IDs reject writes.
- Each `register_*` call validates against Pydantic schema; malformed calls return structured errors the agent can recover from.
- `register_endpoint` is idempotent on `(method, path)` within a session — re-registering updates.
- Every tool call logs the API key ID to audit which agent sessions did what.
- `finalize_sync` is atomic: all session data commits or nothing does.

### Package layout

```
data4g/                                 # single pip package
├── pyproject.toml                      # name = "data4g"
│                                       # entry_points:
│                                       #   data4g      = data4g.cli:main
│                                       #   data4g-mcp  = data4g.mcp.server:main
├── data4g/
│   ├── cli/
│   │   ├── main.py                     # Typer: init, doctor, --version
│   │   ├── init.py                     # writes MCP config for each detected IDE
│   │   └── doctor.py                   # validates env, MCP configs, backend connectivity
│   ├── mcp/
│   │   ├── server.py                   # FastMCP stdio server, registers all tools
│   │   ├── tools/                      # one file per tool group (session, register, read, analyzer)
│   │   ├── client.py                   # HTTP client → backend; adds X-Api-Key header
│   │   └── config.py                   # reads DATA4G_API_KEY + DATA4G_PROJECT_ID from env
│   ├── analyzer/                       # MOVED from backend/mcp_server/
│   │   ├── analyzers/                  # python, node, go, java (unchanged)
│   │   └── detectors/                  # risk detectors (unchanged)
│   └── schemas.py                      # Pydantic models; shared with backend via `data4g-schemas` (see below)
└── Dockerfile                          # fallback for non-Python shops
```

### Setup CLI (`data4g` binary)

`data4g init` behaviour:
1. Prompts user for project ID (or reads from `DATA4G_PROJECT_ID`).
2. Detects installed agents by probing config paths:
   - Claude Code → `.mcp.json` in repo OR `~/.claude.json`
   - Cursor → `.cursor/mcp.json` in repo OR `~/.cursor/mcp.json`
   - Codex → `~/.codex/config.toml`
   - Offers a "print generic MCP config" option for unlisted clients.
3. For each detected agent, writes an MCP server entry — with **no literal key**, relying on shell env inheritance:
   ```json
   {
     "mcpServers": {
       "data4g": {
         "command": "data4g-mcp",
         "env": {
           "DATA4G_PROJECT_ID": "proj_abc"
         }
       }
     }
   }
   ```
   `DATA4G_API_KEY` is inherited from the parent shell environment when the agent spawns the MCP server — it's never written to any config file.
4. Appends `.env` / `.env.local` patterns to `.gitignore` if they're not already present (defence-in-depth for users who still choose the `.env` path).
5. Prints next steps: *"Export `DATA4G_API_KEY=d4g_…` in your shell profile, `.envrc`, or per-session. Then restart your AI agent."*

`data4g doctor`:
- Confirms `DATA4G_API_KEY` and `DATA4G_PROJECT_ID` are readable from the current env.
- Hits `POST /keys/verify` with the key to confirm it's valid and not revoked.
- Checks MCP configs are present and well-formed for each detected agent.
- Checks no tracked file contains the key value (git-aware grep).
- Prints a single-line summary per check: ✓ / ✗ / ⚠.

### API key handling (MCP server runtime)

- **Single source of truth:** `DATA4G_API_KEY` environment variable.
- Supplied by the user via shell profile (`.zshrc`/`.bashrc`), `direnv` / `.envrc` per project, or `.env` loaded by the user's preferred method.
- MCP server reads it once at startup. If missing, it exits with a structured MCP error the agent surfaces: *"`DATA4G_API_KEY` is not set. See https://data4g.io/docs/setup."*
- **Git-leak guard:** on startup, the MCP server runs `git ls-files` against the current working directory and refuses to run if the API key value appears in any tracked file. Cheap, catches the #1 foot-gun.
- `data4g init` writes MCP configs that do **not** embed the key literally, so agent config files (often committed) stay clean.

---

## Backend Changes

### Rename (ingestion side — not MCP-related)

| Old | New |
|---|---|
| `backend/dataforge/route/mcp_route.py` | `backend/dataforge/route/scan_route.py` |
| `backend/dataforge/service/mcp_ingestion_service.py` | `backend/dataforge/service/scan_ingestion_service.py` |
| `backend/dataforge/schemas/mcp.py` | `backend/dataforge/schemas/scan.py` |
| `MCPSyncPayload`, `MCPSyncResult`, `MCPSyncLog` | `ScanSyncPayload`, `ScanSyncResult`, `ScanSyncLog` |
| `MCP_SERVER_ENABLED` env | `SCANNER_ENABLED` |
| Route prefix `/mcp/...` | `/scan/...` |

### Delete

- `backend/mcp_server/` — moved to the `data4g` pip package's `analyzer/` submodule. Backend no longer runs analyzers.

### New: session-based ingest API

The old bulk `POST /scan/sync` (formerly `/mcp/sync`) is replaced by a session model matching the MCP tool surface:

- `POST /api/v1/projects/{project_id}/scan/sessions` → `{ sync_id }`
- `POST /api/v1/projects/{project_id}/scan/sessions/{sync_id}/endpoints`
- `POST /api/v1/projects/{project_id}/scan/sessions/{sync_id}/entities`
- `POST /api/v1/projects/{project_id}/scan/sessions/{sync_id}/services`
- `POST /api/v1/projects/{project_id}/scan/sessions/{sync_id}/risks`
- `POST /api/v1/projects/{project_id}/scan/sessions/{sync_id}/notes`
- `POST /api/v1/projects/{project_id}/scan/sessions/{sync_id}/finalize` → commits; updates live topology; returns diff summary.
- `POST /api/v1/projects/{project_id}/scan/sessions/{sync_id}/abort` → discards.
- `GET /api/v1/projects/{project_id}/scan/sessions/{sync_id}` → session state (for agent read-after-write).

All guarded by `require_project_api_key` (see below). No JWT accepted on these routes.

### New Beanie documents

Add to [backend/dataforge/data/model.py](backend/dataforge/data/model.py):

```python
class ProjectApiKey(Document):
    project_id: str              # indexed
    key_hash: str                # SHA-256 hex, unique indexed
    last_four: str
    label: str                   # e.g. "Claude Code - Dhiwakar's Mac"
    created_by: str              # user_id
    created_at: datetime
    last_used_at: datetime | None
    revoked_at: datetime | None  # soft delete

class ScanSession(Document):
    sync_id: str                 # unique indexed
    project_id: str              # indexed; must match api_key.project_id
    api_key_id: str              # who started the session
    started_at: datetime
    expires_at: datetime         # start + 2h
    state: Literal["active", "finalized", "aborted", "expired"]
    note: str | None
    # staged data
    endpoints: list[dict]
    entities: list[dict]
    services: list[dict]
    risks: list[dict]
    notes: list[dict]
```

Also: add `api_key_id: str` to `ScanSyncLog` so audits trace every finalized sync to its key.

### New auth dependency

Add to [backend/core/access_control.py](backend/core/access_control.py):

```python
async def require_project_api_key(
    project_id: str,
    x_api_key: str = Header(..., alias="X-Api-Key"),
) -> ProjectApiKey:
    # 1. SHA-256 hash the incoming key
    # 2. Look up ProjectApiKey by hash (401 if missing, 403 if revoked)
    # 3. Verify key.project_id == project_id from URL (403 on mismatch)
    # 4. Fire-and-forget update to last_used_at
    # 5. Return key record
```

Replaces JWT auth **only** on `/scan/...` routes. User-facing routes are untouched.

### New key-management routes (user JWT, owner-only)

Add [backend/dataforge/route/api_key_route.py](backend/dataforge/route/api_key_route.py):

- `POST /api/v1/projects/{project_id}/keys` → returns `{ key_id, plaintext_key, last_four }` **once**. Rejects if project already has 2 active keys.
- `GET  /api/v1/projects/{project_id}/keys` → lists non-revoked keys (no plaintext).
- `DELETE /api/v1/projects/{project_id}/keys/{key_id}` → sets `revoked_at`.
- `POST /api/v1/projects/{project_id}/keys/verify` → tiny endpoint `data4g doctor` uses to validate a key. Accepts the key in the `X-Api-Key` header, returns 200 or 401. Rate-limited by IP + key prefix.

All except `verify` guarded by `require_project_owner`. `verify` is guarded by `require_project_api_key` itself (so it doubles as a ping).

### Key format & hashing

- Format: `d4g_` + 40 random base62 chars (256 bits entropy).
- Shown plaintext to user exactly once at creation.
- Stored as SHA-256 hash (sufficient for high-entropy secrets; bcrypt would be overkill and slow).
- Display post-creation: `d4g_…<last 4>` + label.

---

## Shared Schemas

Wire format between `data4g-mcp` and backend lives in a tiny third package: **`data4g-schemas`** (Pydantic models). Both backend and agent pin a version. Keeps the backend from depending on the agent and vice versa.

Alternative if you want less ceremony: keep schemas in `data4g` package, backend imports it as a lib. Faster to ship, creates a backend→agent direction dep. I recommend the three-package split at launch; it pays for itself by the second breaking-change release.

---

## Files to Create / Modify

**Create:**
- `data4g/` (new top-level pip package; or separate repo). Contains `cli/`, `mcp/`, `analyzer/`.
- `backend/dataforge/route/api_key_route.py` — key management.
- `backend/dataforge/route/scan_session_route.py` — session-based ingest API (replaces old `/mcp/sync`).
- Migration script for any `mcp_*` MongoDB collections and env-var renames.

**Modify:**
- [backend/dataforge/data/model.py](backend/dataforge/data/model.py) — add `ProjectApiKey`, `ScanSession`; add `api_key_id` to `ScanSyncLog`.
- [backend/core/access_control.py](backend/core/access_control.py) — add `require_project_api_key`.
- [backend/dataforge/route/mcp_route.py](backend/dataforge/route/mcp_route.py) → rename to `scan_route.py`; replace with thin router that delegates to session routes (or delete outright).
- [backend/dataforge/service/mcp_ingestion_service.py](backend/dataforge/service/mcp_ingestion_service.py) → rename; finalize logic runs here.
- [backend/dataforge/schemas/mcp.py](backend/dataforge/schemas/mcp.py) → rename + class renames; import from `data4g-schemas` where possible.
- [backend/main.py](backend/main.py) — register new routers.
- [backend/core/config.py](backend/core/config.py) — rename `MCP_SERVER_*` env vars.

**Delete:**
- `backend/mcp_server/` — moved to the `data4g` package's `analyzer/` submodule.

---

## Risks & Open Questions

1. **Agent non-determinism.** Agents may skip `finalize_sync`, call tools out of order, or partially register data. Mitigation: session TTL (2h auto-expire), atomic finalize, idempotent `register_endpoint`, structured errors that prompt the agent to retry correctly. Still, expect "why didn't my topology update?" support tickets — dashboards must surface session state ("Last session aborted / expired").
2. **Token cost on the user side.** Reading a 100k-LOC repo with an agent can burn significant tokens. `run_static_analysis` tool exists partly to mitigate this — the agent can run it first, then selectively enrich rather than read every file.
3. **Key storage is env-var-only.** Simpler than keyring; works identically on macOS, Linux, WSL, Docker, headless. Risk: users putting the key in a committed `.env`. Mitigations in place: `data4g init` updates `.gitignore`, MCP server startup refuses to run if key is in any tracked file, backend logs never include plaintext.
4. **Verify endpoint abuse.** `POST /keys/verify` is a key-probing endpoint; rate-limit by IP + by key prefix to prevent brute-force (even at 256 bits it's moot, but cheap defence).
5. **No CI story.** Deliberate for v1. If customers ask for CI sync, we revisit with either a headless-agent or resurrecting a minimal CLI sync — but not before validating that AI-agent-driven sync actually works.
6. **"Live topology" branding.** Sync happens only when a developer asks an agent to do it. UI must show `last_synced_at` prominently and label truly live data (if any) distinctly. Frontend tweak in [frontend/lib/features/topology/](frontend/lib/features/topology/) — out of scope here but tracked.
7. **Schemas three-package split.** If this slows shipping, collapse into two packages (`data4g` + `backend`). Revisit if the first breaking-change release is painful.

---

## Verification

1. **Backend unit tests (`backend/tests/`):**
   - `ProjectApiKey.create` rejects a 3rd active key.
   - `require_project_api_key` returns 401 on missing/unknown, 403 on project mismatch, 403 on revoked.
   - Session flow: start → register → finalize writes to topology; abort discards; expired session rejects writes.
   - `finalize_sync` is atomic (simulate mid-commit failure → nothing persists).
   - Rotation: key 1 + key 2 both work; revoke key 1 → key 1 fails, key 2 succeeds.
2. **MCP server tests (`data4g/tests/`):**
   - Each tool's Pydantic contract is exercised against the backend via a local test double.
   - `run_static_analysis` returns the same shape as the old analyzer on fixture repos.
3. **End-to-end with Claude Code:**
   - `pip install data4g`, export `DATA4G_API_KEY`, run `data4g init`, then `data4g doctor` (all green).
   - In a sample Python repo, open Claude Code, say *"sync this to Data4G"*.
   - Agent calls `start_sync`, optionally `run_static_analysis`, several `register_*`, then `finalize_sync`.
   - Topology visible in frontend with enriched `semantic_description` fields.
4. **End-to-end with Cursor and Codex:** same flow, each agent's config generated by `data4g init`.
5. **Multi-agent parallel:** Claude Code and Cursor both running against same repo → each gets its own `sync_id`; neither clobbers the other; last finalize wins (documented).
6. **Rename regression:** all routes under `/scan/...` respond; `/mcp/...` returns 404; `grep -r "mcp" backend/` returns only commit messages / migration files, no live code.
7. **Security checks:**
   - `data4g init` does not write the API key into any config file; generated MCP configs rely on shell env inheritance.
   - MCP server refuses to start if `DATA4G_API_KEY` value appears in any git-tracked file in the CWD.
   - Backend logs contain `key_id` and `last_four` only — never plaintext.
   - Expired or aborted sessions leave zero topology impact.
