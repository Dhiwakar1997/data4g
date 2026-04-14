# data4g

Local MCP server + CLI that lets an AI coding agent (Claude Code, Cursor,
Codex, or any MCP-capable client) sync a repository's topology, endpoints,
entities, and risks to the [Data4G](https://data4g.io) backend.

- **No user JWT is ever used for ingestion.** Writes are authenticated with
  a project-scoped API key (`DATA4G_API_KEY`) stored only in the local shell
  environment.
- **The agent does the semantic work.** The MCP server exposes fine-grained
  tools (`start_sync`, `register_endpoint`, `register_risk`, `finalize_sync`,
  …). Static analysis is just one optional tool the agent may invoke.
- **Atomic sync.** Nothing commits to the live topology until `finalize_sync`;
  crashed or partial agent runs fail cleanly.

## Install

```bash
pip install data4g
```

Two commands are registered:

| Command      | Purpose                                         |
|--------------|-------------------------------------------------|
| `data4g`     | Setup CLI: `init`, `doctor`, `--version`        |
| `data4g-mcp` | stdio MCP server (spawned by your AI agent)     |

## Setup (one-time per repo)

1. **Create an API key** in the Data4G web UI (Settings → Scan Integration).
   Plaintext is shown exactly once — copy it immediately.

2. **Export it in the shell that launches your agent.** Add to `~/.zshrc`,
   `~/.bashrc`, or a per-project `.envrc` with direnv:

   ```bash
   export DATA4G_API_KEY="d4g_..."
   export DATA4G_PROJECT_ID="proj_abc"
   export DATA4G_API_BASE="http://localhost:8000/api/v1"  # optional
   ```

3. **Wire up your AI agent:**

   ```bash
   cd path/to/your/repo
   data4g init       # writes MCP configs for detected IDEs
   data4g doctor     # confirms env, configs, and backend reachability
   ```

4. **Restart your AI agent** (Claude Code / Cursor / Codex). Then say:

   > "Sync this repo to Data4G."

   The agent will call `start_sync`, optionally `run_static_analysis`, a
   batch of `register_*` tools, and `finalize_sync`. Your live topology
   updates atomically on finalize.

## Configuration model

The key lives in `DATA4G_API_KEY` only. `data4g init` writes MCP configs
that inherit env from the shell — the literal key is **never** written to
any config file, `.env`, or committed artefact. On startup the MCP server
also runs a `git ls-files` leak guard and refuses to run if your key
appears in any tracked file.

## Multi-agent

Claude Code, Cursor, and Codex can run against the same repo in parallel;
each agent spawns its own MCP subprocess and starts its own `sync_id`.
Last `finalize_sync` wins for live-topology state; earlier sessions
persist in the audit log.

## Docker

A `Dockerfile` is included for non-Python shops. Mount the repo and pass
the API key + project via env:

```bash
docker run --rm -i \
  -e DATA4G_API_KEY -e DATA4G_PROJECT_ID \
  -v "$PWD:/workspace" -w /workspace \
  data4g/mcp:latest
```

## Local development

```bash
git clone <this repo>
cd data4g-mcp
pip install -e ".[dev]"
pytest
```

See [MCP_ARCHITECTURE_PLAN.md](../MCP_ARCHITECTURE_PLAN.md) in the parent
repo for the full design context.
