<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# MCP server conventions

Most ParkviewLab repos are **Python MCP servers** (deco-assaying, smalt-mcp, flint-slating, ebony-enriching) and they share one architecture. This documents it so a new server starts from the same shape. It builds on [`python-tooling.md`](python-tooling.md).

## Stack

`mcp[cli]>=1.27` + **FastAPI** + **uvicorn** + **starlette** + **pydantic**. The MCP protocol is served over **Streamable-HTTP** (a FastAPI app), with an optional stdio transport for local clients.

## Module layout (`src/<pkg>/`)

| Module | Responsibility |
|---|---|
| `config.py` | **Pure leaf** module — no internal imports. Reads env vars via `os.environ.get(...)` with defaults; exposes a frozen dataclass / module constants. `VERSION` via `importlib.metadata` with a `"0.0.0+local"` fallback (see [`releases.md`](releases.md)). |
| `__main__.py` | CLI entry (`python -m <pkg>`). Parses `--transport {http,stdio}`; `uvicorn.run("<pkg>.server:app", …)` for http, `anyio.run(_run_stdio)` for stdio. `logging.basicConfig(level=INFO)`. |
| `server.py` (or `app.py` + `routes.py`) | FastAPI app construction + MCP `Server` wiring + lifespan. Defines the module-level `app`. |
| `tools.py` | Tool definitions + dispatch. |
| `schema.py` | pydantic models for tool/route boundaries. |

`config.py` being a pure leaf matters: it's imported everywhere and must not create import cycles. The `App`/server object is often constructed at module import (with lazy heavy resources) so both the MCP handlers and the FastAPI routes share one instance.

## Transports

- **Streamable-HTTP (default)** — the MCP `Server` is wrapped in a `StreamableHTTPSessionManager` and mounted at **`/mcp`** on the FastAPI app, as a raw ASGI3 route accepting **`POST`**, with `security_settings` passed (see [Transport security](#transport-security)). Started via the FastAPI **lifespan**.
- **stdio (optional)** — `--transport stdio` runs `mcp.server.stdio.stdio_server` under `anyio.run`, for local desktop clients.

```python
# __main__.py (shape)
if args.transport == "stdio":
    anyio.run(_run_stdio)
else:
    uvicorn.run("<pkg>.server:app", host=HOST, port=PORT)
```

> The `StreamableHTTPSessionManager` **hard-errors if `run()` is called twice** — this shapes the test fixtures (see [`testing.md`](testing.md)).

### The path is `/mcp`, not `/sse`

Three sources agree. The specification's example MCP endpoint is `https://example.com/mcp`; the SDK's own default is `streamable_http_path = "/mcp"` (`mcp/server/fastmcp/server.py`); and `/sse` is the path of the **HTTP+SSE transport from protocol revision 2024-11-05**, deprecated since `2025-03-26` and eligible for removal in a future revision.

Serving Streamable-HTTP at `/sse` is not merely a misnomer. A client that reads the path and speaks the legacy transport connects, receives a valid `text/event-stream` response, and then waits indefinitely for the `endpoint` event that transport expects as its first message: it hangs rather than failing. A person configuring the server meets the same trap from the other side, choosing `--transport sse` because the URL says so.

A server that previously served `/sse` renames as a per-repo breaking release and says so in the release notes. Do **not** keep a `/sse` alias pointing at the same handler; the alias preserves exactly the hang described above. Where a transition period is wanted, have `/sse` answer `GET` with `405` and a body naming `/mcp`.

### Methods on the MCP endpoint

A **stateless** server (`stateless=True`, the house default) accepts `POST` only:

- `POST` carries every JSON-RPC message. Required.
- `GET` would open a standalone server-to-client stream. A stateless server has nothing to send on one, and the specification explicitly permits answering `405 Method Not Allowed` to signal that the endpoint offers no such stream.
- `DELETE` terminates a session. A stateless server has none, and the SDK already answers `405 Method Not Allowed: Session termination not supported`, so listing the verb advertises a capability that does not exist.

Restricting the route to `POST` is also forward-compatible: revision `2026-07-28` removes the standalone GET stream and protocol-level sessions outright and tells servers to answer `405` to both verbs. A stateful server that genuinely streams server-initiated messages adds `GET`, and `DELETE` for session termination.

It also removes the hang described above at the server end: a legacy client that issues `GET` gets a clean `405` instead of an SSE stream that never speaks.

### Transport security

Pass `security_settings` explicitly. The SDK leaves DNS-rebinding protection **off** when the argument is omitted, so omitting it means no `Host` or `Origin` validation at all:

```python
session_manager = StreamableHTTPSessionManager(
    app=mcp,
    stateless=True,
    security_settings=TransportSecuritySettings(
        enable_dns_rebinding_protection=ENABLE_TRANSPORT_SECURITY,
        allowed_hosts=ALLOWED_HOSTS,
        allowed_origins=ALLOWED_ORIGINS,
    ),
)
```

The specification requires a server to validate the `Origin` header and answer `403` when one is present and invalid, recommends binding `127.0.0.1` rather than `0.0.0.0` when running locally, and recommends authenticating every connection. Without those, any page in a browser that can reach the server can drive it.

Reference implementation: `ebony-enriching/.../server.py` and its `config.py` — the `EBONY_ENABLE_TRANSPORT_SECURITY`, `EBONY_ALLOWED_HOSTS`, and `EBONY_ALLOWED_ORIGINS` knobs, defaulting on with a localhost allowlist.

## Admin / health endpoints

Standard across servers:

- `GET /health` — liveness: `{ok, version, uptime_seconds}` (version is the runtime `VERSION`).
- `GET /admin/version` — server identity (name, version, configured scope/paths).
- `GET /admin/health` — detailed observability where a server has it.
- `GET /docs` — FastAPI's OpenAPI UI.

## Permission scopes

Servers gate their tools behind a **scope** set at startup from an env var, as an `Enum`, e.g. `READ_ONLY` → `READ_WRITE` → `REMOVE_DESTRUCTIVE` (smalt-mcp's `SMALT_SCOPE`, default `read_write`). Destructive tools are opt-in to expose.

## Auth model

Be honest about what the shared token is: a **pre-OAuth, localhost-only placeholder**, not an authentication system. It is one static secret compared for equality, with no rotation, no per-client identity, no expiry, and no audience binding.

That is adequate for a server bound to `127.0.0.1` on a single-user machine. It is **not** adequate for anything reachable from a network the operator does not control. Do not expose one of these servers publicly without a real OAuth 2.1 resource server in front of it, per the specification's authorization requirements.

- **Default the bind to `127.0.0.1`.** `HOST` stays env-driven, since a container must bind `0.0.0.0` to be reachable, but the default someone gets without thinking about it should be the safe one.
- **Decide, per server, what an unconfigured token means.** smalt-mcp treats an unset token as full access (single-user dev mode); bronze-scribing is adopting the opposite, serving its read-only surface but refusing writes, deletes, and admin mutations. The family has not converged on one answer, so state the choice in the server's README Configuration table rather than leaving it implicit.

## Middleware & misc

- `CORSMiddleware` scoped to the **same origin allowlist as the MCP transport** — not `*` — plus `GZipMiddleware(minimum_size=256)` on the FastAPI app. A wildcard lets any page the operator happens to visit read every response cross-origin, which matters precisely because these servers have no browser-grade auth (see [Auth model](#auth-model)).
- Tunable thread pool via a namespaced env var where relevant (e.g. `SMALT_THREAD_POOL_WORKERS`).
- Tool results are wrapped as `list[mcp.types.TextContent]` carrying JSON.
- **Config is plain dataclasses + `os.environ.get`** — no `pydantic-settings`. Env var names are namespaced per server (`SMALT_*`, `OUTPUT_ROOT`, …) plus the generic `HOST`/`PORT`/`PUBLIC_BASE_URL`.

Source: `smalt-mcp/.../{__main__,server,config,permissions}.py`, `deco-assaying/.../{config,routes}.py`. Deployment (Docker, "five ways to run it") is in [`packaging-and-deployment.md`](packaging-and-deployment.md).
