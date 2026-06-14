<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Testing

Python projects test with **pytest**. Config lives in
`[tool.pytest.ini_options]` (see [`python-tooling.md`](python-tooling.md)):

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"          # async tests run without per-test decorators
markers = [
  "network: tests that require outbound network access (e.g. git clone of a public repo)",
  "docling: tests that download/run the Docling ML model (slow, first-run download)",
  "integration: end-to-end tests against a running server",
]
```

Test files are `tests/test_<module>.py`.

## Marker tiers — fast CI, full local

Slow or networked tests are marked so CI can skip them. CI runs the fast subset;
run the full suite locally before a release.

```bash
uv run pytest -m "not network and not docling" -q   # CI
uv run pytest                                         # everything (local)
```

Use `network` for anything hitting the internet, `docling` for the ML-model
download path, `integration` for end-to-end server tests.

## conftest patterns (MCP servers)

The MCP `/sse` transport's `StreamableHTTPSessionManager` **hard-errors if
`run()` is called twice**, and the FastAPI lifespan calls `run()`. So:

- **One session-scoped `mcp_client` `TestClient`** lives in `conftest.py`; every
  test module that touches `/sse` reuses it (don't open a second `with
  TestClient(app)` per module).
- **Set env vars before importing the server module.** `server.py` constructs its
  `App()`/config at import time, so the fixture sets `SMALT_DIR`,
  `EMBEDDING_PROVIDER=fake`, scope, etc. *before* `from <pkg>.server import app`.
- **Reload if already imported** (smalt-mcp's pattern). If another module already
  loaded `server`, its session-manager singleton won't accept a second `run()`:

  ```python
  if "<pkg>.server" in sys.modules:
      importlib.reload(sys.modules["<pkg>.server"])
  from <pkg>.server import app
  with TestClient(app) as c:
      yield c
  ```
- **Generate test data in-memory / in `tmp_path`** — no committed binary
  fixtures. smalt-mcp seeds a tiny deterministic store (a handful of pages
  covering each type) and uses a `fake` embedder to avoid a model download.

Source: `smalt-mcp/.../tests/conftest.py` (the reload guard + seeded store);
`deco-assaying/.../tests/conftest.py` (the single session-scoped client).

## Node (jonobones) test tiers

jonobones runs tiered CI: unit/lint/typecheck, an **interop** tier (round-trips
against the official Joplin CLI), a docker image-boot check, and an **e2e** tier
that boots a real Joplin Server in Docker. Locally, e2e needs Docker + the joplin
CLI (`JOPLIN_CLI_BIN`). See jonobones's `docs/testing.md`.

## Visual / front-end verification

For apps with a UI (conception-space, the static sites), verify by **running the
app and looking** — not by asserting alone. Start the dev server and drive it via
the Claude Preview MCP tools: `preview_start`, `preview_screenshot` after each
visual change, `preview_click`/`preview_eval` to exercise interactions,
`preview_console_logs` for warnings. Don't claim a visual change works without a
screenshot. (Source: conception-space's "running and seeing" workflow.)
