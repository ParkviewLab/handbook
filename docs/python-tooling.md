<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Python tooling

The ParkviewLab Python stack is **uv + ruff + ty + hatchling**, on **Python
3.13**, with a `src/` layout. Every Python repo's `pyproject.toml` is nearly
identical — start from the template
([`pyproject.toml.template`](../templates/pyproject.toml.template)) and change
only the name/description/deps.

## The stack

- **[uv](https://docs.astral.sh/uv/)** — package manager and runner. `uv.lock`
  is **committed** (reproducible builds; see [`ci.md`](ci.md)). `uv sync`
  installs; `uv run <cmd>` runs in the project env. Each worktree has its own env
  (run `uv sync` per worktree).
- **[ruff](https://docs.astral.sh/ruff/)** — linter + formatter.
- **[ty](https://github.com/astral-sh/ty)** — type checker.
- **[hatchling](https://hatch.pypa.io/)** — build backend, `src/`-layout wheels.
- **pytest** — tests (see [`testing.md`](testing.md)).
- **`.python-version`** pins `3.13`; `requires-python = ">=3.13"`.

## Canonical `pyproject.toml` shape

```toml
[project]
name = "deco-assaying"
version = "0.2.1"                         # single source of truth — see releases.md
description = "…"
readme = "README.md"
requires-python = ">=3.13"
license = "MIT"                           # per-repo choice — see licensing.md
license-files = ["LICENSE"]
authors = [{ name = "Gary", email = "garycoding@gmail.com" }]
dependencies = [ … ]

[project.scripts]
deco-assaying = "deco_assaying.__main__:main"

[dependency-groups]
dev = ["pytest", "pytest-asyncio", "httpx"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/deco_assaying"]          # src-layout

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
markers = [ "network: …" ]                # see testing.md

[tool.ruff]
line-length = 110
target-version = "py313"
src = ["src", "tests"]

[tool.ruff.lint]
select = ["E", "F", "W", "I", "B", "UP", "SIM", "C4", "RUF"]
ignore = ["E501"]                         # line length is the formatter's job

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["B011"]

[tool.ty.src]
include = ["src"]

[tool.ty.environment]
python-version = "3.13"
```

Source: deco-assaying's `pyproject.toml`.

### The settings that are fixed across repos

- **ruff:** `line-length = 110`, `target-version = "py313"`,
  `select = ["E","F","W","I","B","UP","SIM","C4","RUF"]`, `ignore = ["E501"]`
  (the formatter handles wrapping), and `tests/**` ignores `B011`
  (`assert False` in tests).
- **ty:** `[tool.ty.src] include = ["src"]`, `[tool.ty.environment]
  python-version = "3.13"` (this exact shape in deco-assaying/smalt-mcp/ebony-enriching;
  a few repos vary or omit `[tool.ty]` — bring new repos to this shape).
- **hatch:** `packages = ["src/<pkg>"]` — always `src/` layout.

## Everyday commands

```bash
uv sync                                   # install deps into this worktree's env
uv run ruff check src tests               # lint (CI runs this)
uv run ruff format src tests              # format
uv run ty check                           # type-check
uv run pytest -m "not network and not docling" -q   # the CI test subset
```

The `version`/release commands (`git bump`, `git release`) are in
[`releases.md`](releases.md). Most repos are MCP servers — their structure is in
[`mcp-server-conventions.md`](mcp-server-conventions.md).
