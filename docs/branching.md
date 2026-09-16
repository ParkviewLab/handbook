<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Branching & worktrees

ParkviewLab uses a two-trunk model — `develop` for integration, `main` for releases — with short-lived, **prefixed** working branches in ephemeral worktrees.

## The two permanent branches

- **`develop`** — the integration trunk. Every working branch PRs into it. It is what `main` is promoted from.
- **`main`** — the release-only surface. Tags live here; the only commits that land directly on `main` are the release bump+tag (and the CI changelog auto-commit). See [`releases.md`](releases.md).

PRs target `develop`; releases are cut from `main`. (jonobones makes `develop` its GitHub *default* branch so PRs target integration by default; some older Python repos still default to `main` — the flow is the same either way.)

> **Consume `main`, not `develop`.** Because `main` only advances at a release, its tip is always the latest **released** state — so that's what to depend on: the published artifact (PyPI/npm) or a `vX.Y.Z` tag for code repos, and `main` (or a tag) for read-consumed repos like this handbook. `develop` is integration and may be ahead of the last release / mid-change. Pin a `vX.Y.Z` tag when you need an exact, immutable reference.

## Branch prefixes (canonical set)

Working branches are named `<prefix>-<short-description>`, **hyphen not slash**. The prefix signals the *kind* of change. The prefixes mirror the Conventional Commit types so the branch's intent and the changelog category line up.

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

The **everyday four** are `feature-`, `bug-`, `doc-`, `ops-`. The rest exist for when a change is purely tests, CI, build plumbing, or a release bump.

> **Key rule: the PR title carries the changelog prefix, not the branch.** Branches are **squash-merged**, so the *PR title* becomes the commit subject that `git-cliff` parses. A branch named `feature-foo` still needs a PR titled `feat: …` for it to land in the changelog. Commits without a recognised prefix are silently dropped from `CHANGELOG.md` (they stay in git history). See [`commits-and-changelogs.md`](commits-and-changelogs.md).

## Working-branch lifecycle (ephemeral worktree)

```bash
# from the develop worktree, branch off develop into a new sibling worktree:
cd repo_name/repo_name-develop
git worktree add ../repo_name-feature-foo -b feature-foo develop
git push -u origin feature-foo    # the branch exists on the remote before any work is done on it
cd ../repo_name-feature-foo
uv sync                       # each worktree gets its own deps (or: npm ci)

# …work, committing as you go and pushing after each commit (see ai-collaboration.md)…

# open a PR into develop. The USER merges it (see "Who merges").
# Then sync the trunk worktree and clean up — see "After the merge" below.
```

- Working branches **squash-merge** into `develop`: each PR collapses to a single commit whose subject is the PR title (the `feat:`/`fix:`/… prefix `git-cliff` parses). That one dated commit is the record of *when the feature landed*; the branch's individual commits stay viewable on the PR. (A squash always creates a fresh commit, so `--no-ff` doesn't apply here.)
- Promotion `develop → main` is part of a **release**, not a reviewed PR: run from the CLI on `main` with `git merge --no-ff develop` (a merge commit → a dated per-release ledger via `git log --first-parent main`), then bump + tag + push. See [`releases.md`](releases.md).
- Pulls are **`git pull --ff-only`** — never an implicit merge on pull.

## Tracking when a feature was added

The two merge strategies above yield a dated history at three granularities:

- **Per feature** — `git log --first-parent develop` is one line per squash commit (one per feature) plus one back-merge commit per release, each with its date. This holds because the cascade merges `main` into `develop` with `--no-ff` (see [`releases.md`](releases.md#after-the-release-the-back-merge-cascade-mandatory)); a fast-forward would replace the chain with `main`'s. In this handbook the cascade fast-forwarded from v0.8.5 to v0.14.0, so the chain below v0.14.0 is `main`'s release ledger; the per-feature ledger resumes at v0.15.0.
- **Per release** — `git log --first-parent main` is one line per release merge commit.
- **Per release, with contents** — annotated, dated tags (`git tag --list 'v*'`) and the dated sections of `CHANGELOG.md`, which group each release's features.

## Who merges

The repo is configured **squash-only** (merge-commit and rebase merges are disabled), so a PR's merge button can only squash — there's no wrong option to pick. Set new repos up the same way; see [`ci.md`](ci.md#repo-merge-settings).

- **Feature PR → `develop`:** opened by anyone (including AI devs); a **human reviews and squash-merges** it (the merge button, or `gh pr merge <n> --squash`) once the **required checks are green** — branch protection keeps the button disabled until they pass (see [`ci.md`](ci.md#required-checks-before-merge)). Merged branches auto-delete. A broad directive ("fix all that", "finish it") authorises the *work*, not the merge.
- **`develop → main`:** done from the CLI as part of a **release**, not a reviewed PR. A single release authorisation ("do the release") covers the whole flow — including the `git merge --no-ff develop` promotion — with no second approval. See [`ai-collaboration.md`](ai-collaboration.md) and [`releases.md`](releases.md).

## After the merge

The merge is the user's; the two steps that close the lifecycle belong to whoever opened the PR — in parallel work, the coordinator ([`parallel-work.md`](parallel-work.md)). Do them as soon as the merge is confirmed, alongside the release prompt ([`ai-collaboration.md`](ai-collaboration.md)).

### Sync the trunk worktree

**After any merge into a trunk, fast-forward that trunk's worktree** — from the container dir:

```bash
git -C <repo>-develop pull --ff-only
```

There is no reason for a trunk worktree to sit out of sync when it can be kept in sync: whoever next opens the machine, with a session running or not, should find it already prepared. Pulls are fast-forward only (above), so this either applies cleanly or tells you something is wrong.

The release flow already syncs both trunks before promoting, for a sharper reason — a stale local `develop` promotes and tags a commit that omits the merged work (see [`releases.md`](releases.md#cutting-a-release)). This rule generalises the habit beyond release time; it doesn't replace that step.

### Remove the worktree and delete the branch

Do this when no further work on that branch is expected; **keep the worktree when it is**. Leaving one isn't free: each worktree carries its own installed dependencies (`uv sync` / `npm ci`) — the pensa-grex worktree that prompted this rule held 241 MB of `node_modules`.

> **A squash merge defeats the obvious test.** The squash is a *fresh* commit, so the branch tip is never an ancestor of the trunk: `git branch -d` refuses, and any "is it merged?" ancestry check reads false even though the work has landed. **Verify by tree, not by ancestry** — identical trees mean the work is in.

```bash
# from the container dir, after the merge:
git -C <repo>.git diff --stat origin/develop origin/<prefix>-<topic>   # no output = trees identical = the work landed
git -C <repo>.git worktree remove ../<repo>-<prefix>-<topic>
git -C <repo>.git worktree prune
git -C <repo>.git branch -D <prefix>-<topic>
git -C <repo>.git push origin --delete <prefix>-<topic>                # only if the remote ref still exists
```

- **`-D`, not `-d`**, for the reason above: `-d`'s merged-check can't see a squash.
- Repos are configured to **delete the branch on merge** ([`ci.md`](ci.md#repo-merge-settings)), so the last line is usually a no-op: the remote ref is already gone and the local `origin/<prefix>-<topic>` is merely stale — `git fetch --prune` clears it. Run the tree check *before* pruning, since prune removes the ref it compares against.

## AI devs

AI devs follow the exact same flow — an ephemeral prefixed-branch worktree, PR into `develop`. There is **no special `claude/` branch or worktree** in the new layout.
