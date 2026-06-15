<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# ParkviewLab handbook

The engineering handbook for the **[ParkviewLab](https://github.com/ParkviewLab)**
GitHub org — the conventions, procedures, and methods we use when building
software here. It is written for **human and AI developers alike**.

> 📌 **Use the released conventions on [`main`](https://github.com/ParkviewLab/handbook/tree/main)** (or a [`vX.Y.Z`](https://github.com/ParkviewLab/handbook/tags) tag). This default view is **`develop`** — the integration branch, which may be ahead of the last release. Current version: [`VERSION.txt`](VERSION.txt).

Start with **[`docs/northstar.md`](docs/northstar.md)** (or the designed
[`docs/northstar.html`](docs/northstar.html)) — *why* we build the way we do.
Everything else is downstream of it.

## The docs

| Doc | What it covers |
|---|---|
| [northstar.md](docs/northstar.md) · [.html](docs/northstar.html) | Methodology intents + axioms |
| [repo-layout.md](docs/repo-layout.md) | Contained, repo-prefixed worktree layout, required contents, repo naming |
| [branching.md](docs/branching.md) | Two-trunk model, branch prefixes, ephemeral worktrees, merge flow |
| [commits-and-changelogs.md](docs/commits-and-changelogs.md) | Conventional Commits, `cliff.toml`, the LLM-Highlights changelog |
| [releases.md](docs/releases.md) | Version single-source-of-truth, `git bump`/`git release`, the gate, back-merge cascade |
| [python-tooling.md](docs/python-tooling.md) | uv + ruff + ty + hatchling, the `pyproject.toml` shape |
| [mcp-server-conventions.md](docs/mcp-server-conventions.md) | The shared Python MCP server architecture |
| [website.md](docs/website.md) | Website repos: `live`/`staging`, Pages-via-Actions deploy, page footers — the lighter profile |
| [testing.md](docs/testing.md) | pytest markers/tiers, conftest patterns, visual verification |
| [packaging-and-deployment.md](docs/packaging-and-deployment.md) | Dockerfile, compose, the "five ways to run it" README |
| [licensing.md](docs/licensing.md) | REUSE/SPDX, per-bucket licensing, `LICENSING.md` |
| [documentation.md](docs/documentation.md) | `docs/` convention, northstar structure, README shape, dual-track HTML |
| [md-to-html.md](docs/md-to-html.md) | How to **author** (not convert) designed HTML from Markdown |
| [brand.md](docs/brand.md) | Palette, fonts, logos, voice |
| [ci.md](docs/ci.md) | The three workflows, org secrets, action pinning, `dev-tools` |
| [ai-collaboration.md](docs/ai-collaboration.md) | The behavioural contract for AI devs |
| [new-repo-checklist.md](docs/new-repo-checklist.md) | The master bootstrap checklist |

## Templates & tooling

- **[`templates/`](templates/)** — copy-paste sources kept identical across repos:
  `cliff.toml`, `pyproject.toml.template`, `CONTRIBUTING.md`, the
  `.github/workflows/`, `generate_changelog.py`, the `LICENSING.md`/`REUSE.toml`
  templates, the `AGENTS.md`/`CLAUDE.md` pointer templates, and the
  [`md-to-html/`](templates/md-to-html/) default HTML scaffold.
- **[`brand/`](brand/)** — canonical logos (all rights reserved) + the Michroma
  font (`OFL-1.1`); see [licensing.md](docs/licensing.md).
- **[`scripts/sync-agent-files.sh`](scripts/sync-agent-files.sh)** — writes the
  `AGENTS.md` + `CLAUDE.md` pointer files into every repo from the templates:

  ```bash
  scripts/sync-agent-files.sh --dry-run   # preview
  scripts/sync-agent-files.sh             # apply across the org
  ```

## How to use this handbook

- **Starting a repo?** Follow [new-repo-checklist.md](docs/new-repo-checklist.md).
- **An AI dev?** Read [ai-collaboration.md](docs/ai-collaboration.md) and the
  repo's `docs/northstar.md`.
- **Changing a convention?** Change it here first, then propagate (re-run the sync
  script; re-copy the affected template). This handbook is the single source of
  truth; if a repo disagrees with it, the handbook wins until updated.

## License

Per-bucket (REUSE-compliant): docs are `CC-BY-4.0`, scripts/templates are
`AGPL-3.0-or-later`, brand logos are all rights reserved, and the bundled font
is `OFL-1.1`. See [docs/licensing.md](docs/licensing.md) and
[`LICENSING.md`](LICENSING.md).

---
<sub>© 2026 Gary Frattarola · Licensed under [CC-BY-4.0](LICENSES/CC-BY-4.0.txt) · part of the ParkviewLab handbook</sub>
