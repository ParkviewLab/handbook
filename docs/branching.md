<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Branching & worktrees

ParkviewLab uses a two-trunk model — `develop` for integration, `main` for
releases — with short-lived, **prefixed** working branches in ephemeral
worktrees.

## The two permanent branches

- **`develop`** — the integration trunk. Every working branch PRs into it. It is
  what `main` is promoted from.
- **`main`** — the release-only surface. Tags live here; the only commits that
  land directly on `main` are the release bump+tag (and the CI changelog
  auto-commit). See [`releases.md`](releases.md).

PRs target `develop`; releases are cut from `main`. (jonobones makes `develop`
its GitHub *default* branch so PRs target integration by default; some older
Python repos still default to `main` — the flow is the same either way.)

## Branch prefixes (canonical set)

Working branches are named `<prefix>-<short-description>`, **hyphen not slash**.
The prefix signals the *kind* of change. The prefixes mirror the Conventional
Commit types so the branch's intent and the changelog category line up.

| Branch prefix | Conventional Commit type (PR title) | Changelog section |
|---|---|---|
| `feature-` | `feat:` | Features (user-visible) |
| `bug-` / `fix-` | `fix:` | Bug fixes (user-visible) |
| `doc-` | `docs:` | Docs |
| `test-` | `test:` | Tests |
| `ops-` | `chore:` / `ci:` | _(dropped from changelog — operational/infra)_ |
| `ci-` | `ci:` | _(dropped)_ |
| `build-` | `build:` | _(dropped)_ |
| `release-` | the `release vX.Y.Z` bump commit | _(dropped — version-bump branches)_ |

The **everyday four** are `feature-`, `bug-`, `doc-`, `ops-`. The rest exist for
when a change is purely tests, CI, build plumbing, or a release bump.

> **Key rule: the PR title carries the changelog prefix, not the branch.**
> Branches are **squash-merged**, so the *PR title* becomes the commit subject
> that `git-cliff` parses. A branch named `feature-foo` still needs a PR titled
> `feat: …` for it to land in the changelog. Commits without a recognised prefix
> are silently dropped from `CHANGELOG.md` (they stay in git history). See
> [`commits-and-changelogs.md`](commits-and-changelogs.md).

## Working-branch lifecycle (ephemeral worktree)

```bash
# from the repo root (repo_name/), branch off develop into a sibling worktree:
git worktree add -b feature-foo feature-foo develop
cd feature-foo
uv sync                       # each worktree gets its own deps (or: npm ci)

# …work, committing as you go; push after each commit (see ai-collaboration.md)…
git push -u origin feature-foo

# open a PR into develop. The USER merges it (see below). Then clean up:
cd ..
git worktree remove feature-foo
git branch -d feature-foo
```

- Branches merge into `develop` with **`--no-ff`** (an explicit merge commit per
  branch keeps the integration history legible). Promotion `develop → main` uses
  `gh pr merge --merge`.
- Pulls are **`git pull --ff-only`** — never an implicit merge on pull.

## Who merges

Opening a PR is fair game for anyone, including AI devs. **Merging a PR into
`develop` or `main` is the user's action** — it writes to a shared trunk. A
broad directive ("fix all that", "finish it") authorises the *work*, not the
merge. See [`ai-collaboration.md`](ai-collaboration.md).

## AI devs

AI devs follow the exact same flow — an ephemeral prefixed-branch worktree, PR
into `develop`. There is **no special `claude/` branch or worktree** in the new
layout.
