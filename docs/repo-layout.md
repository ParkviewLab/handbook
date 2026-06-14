<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Repository layout

Every ParkviewLab repo uses a **bare clone + worktrees** layout on disk, contained in
one `repo_name/` directory: a bare clone plus two permanent worktrees (`main`,
`develop`) and ephemeral worktrees for the working branches. Every working directory is
named **`<repo>-<branch>`**, so it is *self-identifying* in editor tabs, terminal
titles, and recent-folder lists — no two repos show an indistinguishable `main`/`develop`.
`main`/`develop` stay checked out, so you never switch branches in place.

## Canonical on-disk layout

```
ParkviewLab/                          ← org root: one container dir per repo
└── repo_name/                        ← the repo container (a plain dir — no .git of its own)
    ├── repo_name.git/                ← the bare clone (the git database; never opened in an editor)
    ├── repo_name-main/               ← permanent worktree — release surface (tags cut here)
    ├── repo_name-develop/            ← permanent worktree — integration trunk (PRs target here)
    └── repo_name-<branch>/           ← ephemeral worktree(s):
                                        repo_name-feature-foo/, repo_name-bug-bar/, …
```

- The container `repo_name/` is a **plain directory** — it holds the bare repo and the
  worktrees but has no `.git` of its own. The bare `repo_name.git/` is a **sibling** of
  the worktrees, not their parent, so git resolves each worktree's `.git` pointer directly
  and never walks up into the container. (This is why it does *not* trip the "never nest a
  worktree inside another worktree" rule.)
- `repo_name-main/` and `repo_name-develop/` are **permanent** worktrees, never worked in
  directly — only the release bump+tag commit lands on `main`; everything else arrives in
  `develop` via merge.
- Each working branch gets its **own ephemeral worktree**, a sibling of the permanent
  ones, named `<repo>-<branch>` (the branch keeps its prefix: `feature-foo` →
  `repo_name-feature-foo`) — see [`branching.md`](branching.md).
- **Why repo-prefixed names?** The directory name is what an editor tab, terminal title,
  and recent-folders list show. `repo_name-develop` is unambiguous across the org; a bare
  `develop` is not. The cost — the repo segment appears twice in a full path
  (`repo_name/repo_name-develop`) — is hidden by tab-completion and editor tabs.
- **Each worktree is independent for dependencies.** A fresh worktree needs its own
  `uv sync` (Python) or `npm ci` (Node) — the virtualenv / `node_modules` are not shared.

### Creating the layout

```bash
mkdir repo_name && cd repo_name
git clone --bare git@github.com:ParkviewLab/repo_name.git repo_name.git
git -C repo_name.git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git -C repo_name.git fetch origin
git -C repo_name.git worktree add ../repo_name-main main
git -C repo_name.git worktree add ../repo_name-develop develop
```

The **fetch-refspec line is required**: `git clone --bare` does not configure
remote-tracking, so without it a worktree's `git status` won't show ahead/behind and
`git pull` won't track `origin`.

> **Current state / migration note.** Two earlier layouts are now deprecated:
>
> 1. `repo_name/worktrees/{main,develop,claude}` — independent clones (not real
>    `git worktree`s) nested under `worktrees/`, plus a permanent `claude/`.
> 2. `repo_name/{.bare, .git, main, develop}` — a bare clone with *branch-named* children
>    (an earlier take on this convention; tidy, but a worktree reads as a bare
>    `main`/`develop` in window titles).
>
> The canonical layout above replaces both — a contained, repo-prefixed `<repo>.git` +
> `<repo>-<branch>` worktrees — and drops the permanent `claude/`: AI devs use ordinary
> ephemeral working-branch worktrees like everyone else. **deco-assaying is the first
> repo on the new layout** (jonobones and handbook follow as the on-disk reference); the
> remaining older repos migrate to it as they're next touched.

## Required contents of a repo

Inside each worktree (the working root, e.g. `repo_name-develop/`), these conventions
hold:

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
