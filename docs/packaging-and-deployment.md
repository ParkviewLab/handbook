<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Packaging & deployment

ParkviewLab servers ship as a PyPI package **and** a multi-arch container image,
and each README documents **five ways to run it**. Publishing is covered in
[`releases.md`](releases.md)/[`ci.md`](ci.md); this page is the artifact shapes.

## Dockerfile

Base on the **uv image** so uv + Python are present; resolve deps first for layer
caching; copy `README.md` before the project install (pyproject reads it as
package metadata).

```dockerfile
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim
WORKDIR /app

# Only if the server needs it at runtime (e.g. git for clones):
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Resolve deps first so they cache across source changes.
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-dev --no-install-project

# README.md is part of package metadata (pyproject -> readme); needed by the
# second sync that installs the project itself.
COPY README.md ./
COPY src/ src/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-dev

ENV PYTHONUNBUFFERED=1 \
    OUTPUT_ROOT=/data \
    PORT=35832 \
    HOST=0.0.0.0
EXPOSE 35832
VOLUME ["/data"]
CMD ["uv", "run", "python", "-m", "deco_assaying"]
```

Conventions: `PYTHONUNBUFFERED=1`; persistent state under `VOLUME ["/data"]`;
`EXPOSE` the server's port; `CMD ["uv","run","python","-m","<pkg>"]`. Node images
base on `node:24-slim` (multi-stage) and set OCI `org.opencontainers.image.*`
labels. Source: `deco-assaying/.../Dockerfile`, `jonobones/main/Dockerfile`.

## docker-compose.yml

A copy-and-edit example stack:

- image `ghcr.io/<org>/<repo>:latest`, `container_name`, `restart: unless-stopped`;
- explicit host port mapping (`"35832:35832"`);
- env block with `CHANGE-ME` placeholders for operator config (e.g.
  `PUBLIC_BASE_URL`, tokens);
- a **named volume** for `/data` by default, with a commented bind-mount
  alternative;
- `extra_hosts: ["host.docker.internal:host-gateway"]` so a consumer on the
  Docker host can reach the server on Linux;
- header comment with the up / upgrade / down lifecycle.

Source: `deco-assaying/.../docker-compose.yml`.

## "Five ways to run it" (README)

Every server's README has a run table covering the same five modes, fastest to
most persistent:

| # | Mode | For |
|---|---|---|
| 1 | `uvx <pkg>` | one-off, no install |
| 2 | `uv tool install <pkg>` | a pinned daemon on `PATH` |
| 3 | macOS **LaunchAgent** | persistent daemon on a Mac |
| 4 | Linux **systemd** user unit | persistent daemon on Linux |
| 5 | **Docker** / docker-compose | container |

Plus a prereqs note (uv; Python 3.13 comes via uv), a sanity check
(`curl http://127.0.0.1:<PORT>/health`), and an env-var **Configuration** table
(name, default, purpose) matching the server's `config.py`.

## Configuration via env vars

Config is environment variables read in `config.py` (no `pydantic-settings`; see
[`mcp-server-conventions.md`](mcp-server-conventions.md)). Generic ones —
`HOST`, `PORT`, `PUBLIC_BASE_URL` — plus per-server namespaced ones
(`OUTPUT_ROOT`, `SMALT_*`, …). Document every one in the README's Configuration
table.
