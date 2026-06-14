<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# MCP server conventions

Most ParkviewLab repos are **Python MCP servers** (deco-assaying, smalt-mcp,
flint-slating, ebony-enriching) and they share one architecture.
This documents it so a new server starts from the same shape. It builds on
[`python-tooling.md`](python-tooling.md).

## Stack

`mcp[cli]>=1.27` + **FastAPI** + **uvicorn** + **starlette** + **pydantic**. The
MCP protocol is served over **Streamable-HTTP** (a FastAPI app), with an optional
stdio transport for local clients.

## Module layout (`src/<pkg>/`)

| Module | Responsibility |
|---|---|
| `config.py` | **Pure leaf** module — no internal imports. Reads env vars via `os.environ.get(...)` with defaults; exposes a frozen dataclass / module constants. `VERSION` via `importlib.metadata` with a `"0.0.0+local"` fallback (see [`releases.md`](releases.md)). |
| `__main__.py` | CLI entry (`python -m <pkg>`). Parses `--transport {http,stdio}`; `uvicorn.run("<pkg>.server:app", …)` for http, `anyio.run(_run_stdio)` for stdio. `logging.basicConfig(level=INFO)`. |
| `server.py` (or `app.py` + `routes.py`) | FastAPI app construction + MCP `Server` wiring + lifespan. Defines the module-level `app`. |
| `tools.py` | Tool definitions + dispatch. |
| `schema.py` | pydantic models for tool/route boundaries. |

`config.py` being a pure leaf matters: it's imported everywhere and must not
create import cycles. The `App`/server object is often constructed at module
import (with lazy heavy resources) so both the MCP handlers and the FastAPI
routes share one instance.

## Transports

- **Streamable-HTTP (default)** — the MCP `Server` is wrapped in a
  `StreamableHTTPSessionManager` and mounted at **`/sse`** (the route accepts
  `GET`/`POST`/`DELETE`) on the FastAPI app. Started via the FastAPI **lifespan**.
- **stdio (optional)** — `--transport stdio` runs `mcp.server.stdio.stdio_server`
  under `anyio.run`, for local desktop clients.

```python
# __main__.py (shape)
if args.transport == "stdio":
    anyio.run(_run_stdio)
else:
    uvicorn.run("<pkg>.server:app", host=HOST, port=PORT)
```

> The `StreamableHTTPSessionManager` **hard-errors if `run()` is called twice** —
> this shapes the test fixtures (see [`testing.md`](testing.md)).

## Admin / health endpoints

Standard across servers:

- `GET /health` — liveness: `{ok, version, uptime_seconds}` (version is the
  runtime `VERSION`).
- `GET /admin/version` — server identity (name, version, configured scope/paths).
- `GET /admin/health` — detailed observability where a server has it.
- `GET /docs` — FastAPI's OpenAPI UI.

## Permission scopes

Servers gate their tools behind a **scope** set at startup from an env var, as an
`Enum`, e.g. `READ_ONLY` → `READ_WRITE` → `REMOVE_DESTRUCTIVE` (smalt-mcp's
`SMALT_SCOPE`, default `read_write`). Destructive tools are opt-in to expose.

## Middleware & misc

- `CORSMiddleware` (allow `*`) and `GZipMiddleware(minimum_size=256)` on the
  FastAPI app.
- Tunable thread pool via a namespaced env var where relevant (e.g. `SMALT_THREAD_POOL_WORKERS`).
- Tool results are wrapped as `list[mcp.types.TextContent]` carrying JSON.
- **Config is plain dataclasses + `os.environ.get`** — no `pydantic-settings`.
  Env var names are namespaced per server (`SMALT_*`, `OUTPUT_ROOT`, …) plus the
  generic `HOST`/`PORT`/`PUBLIC_BASE_URL`.

Source: `smalt-mcp/.../{__main__,server,config,permissions}.py`,
`deco-assaying/.../{config,routes}.py`. Deployment (Docker, "five ways to run
it") is in [`packaging-and-deployment.md`](packaging-and-deployment.md).
