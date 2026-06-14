<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Repository layout

Every ParkviewLab repo uses a **`.bare` clone + worktrees** layout on disk, with
two permanent worktrees (`main`, `develop`) and ephemeral worktrees for the
working branches. This is the standard git-worktree layout — the same shape the
rest of the world uses — with `main`/`develop` always checked out so you never
switch branches in place.

## Canonical on-disk layout

```
repo_name/
├── .bare/                ← the bare clone (the actual git database)
├── .git                  ← one-line gitdir pointer: "gitdir: ./.bare"
├── main/                 ← permanent worktree — release surface (tags cut here)
├── develop/              ← permanent worktree — integration trunk (PRs target here)
└── <working-branch>/     ← ephemeral worktree(s), direct siblings:
                            feature-foo/, bug-bar/, doc-baz/, …
```

- `.bare/` holds the repository; `.git` is a one-line `gitdir: ./.bare` pointer
  so plain `git` commands work from `repo_name/`.
- `main/` and `develop/` are **permanent** worktrees and are never worked in
  directly (only the release bump+tag commit lands on `main`; everything else
  arrives in `develop` via merge).
- Each working branch gets its **own ephemeral worktree** as a direct sibling of
  `main/`/`develop/`, named after the branch — see [`branching.md`](branching.md).
- **Each worktree is independent for dependencies.** A fresh worktree needs its
  own `uv sync` (Python) or `npm ci` (Node) — the virtualenv / `node_modules`
  are not shared.

### Creating the layout

```bash
mkdir repo_name && cd repo_name
git clone --bare git@github.com:ParkviewLab/repo_name.git .bare
echo "gitdir: ./.bare" > .git
git worktree add main main
git worktree add develop develop
```

> **Current state / migration note.** The older Python repos use a *different*,
> now-deprecated layout: `repo_name/worktrees/{main,develop,claude}`, where each
> is an independent clone (not a real `git worktree`) nested under `worktrees/`,
> plus a **permanent `claude/`** worktree. The new canonical layout above drops
> the `worktrees/` nesting and the permanent `claude/`. **jonobones already uses
> the new layout** and is the on-disk reference. Migrating the older repos is a
> separate task, not covered here. There is no permanent `claude/` worktree any
> more — AI devs use ordinary ephemeral working-branch worktrees like everyone
> else.

## Required contents of a repo

Inside each worktree (i.e. in the repo root), these conventions hold:

- **`README.md`** in the root — the standard entry point (see
  [`documentation.md`](documentation.md) for its shape).
- **`docs/`** — all substantive documentation, including `northstar.md`
  (+ its designed HTML) and `in-flight_ideas.md`. See
  [`documentation.md`](documentation.md).
- **`scripts/`** — project-specific scripts. Cross-project scripts live in
  `dev-tools` instead (see [`ci.md`](ci.md) and [`releases.md`](releases.md)).
- **`AGENTS.md` + `CLAUDE.md`** — thin pointers to this handbook, synced by
  `scripts/sync-agent-files.sh` (see [`ai-collaboration.md`](ai-collaboration.md)).
- Language scaffolding per [`python-tooling.md`](python-tooling.md) /
  [`mcp-server-conventions.md`](mcp-server-conventions.md).

## Repo naming

The house style is **mineral/pigment + gerund**:

- `cobalt-grinding`, `deco-assaying`, `ebony-enriching`, `flint-slating`,
  `aqua-roaming`, `bronze-scribing`.
- Pigment-named MCP servers may take a `-mcp` suffix instead of a gerund:
  `smalt-mcp`.
- Infrastructure/meta repos are plain: `dev-tools`, `handbook`.

It's a house style, lightly held — evocative over literal, but don't contort a
name to fit the pattern.
