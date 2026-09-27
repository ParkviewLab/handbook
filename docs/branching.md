<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Branching & worktrees

ParkviewLab uses a two-trunk model — `develop` for integration, `main` for releases — with short-lived, **prefixed** working branches in ephemeral worktrees.

Why the two trunks, why pull requests are merged with merge commits rather than squashed, and why the release comes back to `develop` through a pull request: [`branching-why.md`](branching-why.md) holds the alternatives set aside, the evidence and the dated rulings.

## The two permanent branches

- **`develop`** — the integration trunk. Every working branch PRs into it, and in the flow nothing reaches it any other way: the release's back-merge and the dev cycle it opens arrive by a pull request too, so nothing the flow writes to `develop` bypasses the checks `develop` requires (see [`ci.md`](ci.md#required-checks-before-merge) and [`releases.md`](releases.md#the-releases-last-step-the-back-merge-pull-request)). Two kinds of write lie outside the flow: an emergency write, such as the repair of a version-line conflict or the direct back-merge that is the exception where `git back-merge` refuses and neither repair of the history applies, pushed directly with administrators unbound for it where they are bound; and, in a repo that has not switched, the release's direct pushes ([`releases.md`](releases.md#until-a-repository-has-switched)). It is what `main` is promoted from.
- **`main`** — the release-only surface. Tags live here, and only a release's own commits land on `main`: the promotion's merge commit, the release bump that is tagged, the CI changelog auto-commit where the release writes one, and, for a hotfix, a merged pull request picked onto it whole. See [`releases.md`](releases.md).

PRs target `develop`; releases are cut from `main`. `develop` is every repo's GitHub *default* branch, so a PR targets integration by default; a website's default branch is `staging` ([`website.md`](website.md)).

> **Consume `main`, not `develop`.** Because `main` only advances at a release, its tip is always the latest **released** state — so that's what to depend on: the published artifact (a package, an image or an installer) or a `vX.Y.Z` tag, and `main` (or a tag) for read-consumed repos like this handbook. `develop` is integration and may be ahead of the last release / mid-change. Pin a `vX.Y.Z` tag when you need an exact, immutable reference.

## Branch prefixes (canonical set)

Working branches are named `<prefix>-<short-description>`, **hyphen not slash**. The prefix signals the *kind* of change. The prefixes mirror the Conventional Commit types so the branch's intent and the changelog category line up.

| Branch prefix | Conventional Commit type (PR title) | Changelog section |
|---|---|---|
| `feature-` | `feat:` | Features (user-visible) |
| `bug-` / `fix-` | `fix:` | Bug fixes (user-visible) |
| `doc-` | `docs:` | Docs |
| `test-` | `test:` | Tests |
| `ops-` | `chore:` / `ci:` | Maintenance |
| `ci-` | `ci:` | Maintenance |
| `build-` | `build:` | Maintenance |
| `release-` | the `release vX.Y.Z` bump commit | _(left out by content where it is made on the trunk; a bump merged by pull request is listed under Other changes)_ |
| `back-merge-` | `chore(release):` | _(left out: the changelog job's notes leave out a pull request by its `back-merge-vX.Y.Z` head branch, and a documents repo's generated notes by its `release-bookkeeping` label)_ |

The **everyday four** are `feature-`, `bug-`, `doc-`, `ops-`. The rest exist for when a change is purely tests, CI, build plumbing, or a release bump.

`back-merge-` is not a prefix to type: the branch is `back-merge-<tag>` (`back-merge-v1.2.3`), and only `git back-merge` creates it, at the end of a release, with the pull request titled `chore(release): back-merge main into develop after <tag>` (see [`releases.md`](releases.md#the-releases-last-step-the-back-merge-pull-request)). The hyphen is the table's rule, and it keeps the worktree a sibling directory rather than a nested one.

> **Key rule: the PR title carries the changelog prefix, not the branch.** A PR is merged with a merge commit titled `<PR title> (#N)`, so the *PR title* becomes the commit subject from which the changelog takes the title. A branch named `feature-foo` still needs a PR titled `feat: …` for it to be listed under Features. A title without a recognised prefix is listed whole under Other changes, which says nothing about what kind of change it is. See [`commits-and-changelogs.md`](commits-and-changelogs.md).

## Working-branch lifecycle (ephemeral worktree)

```bash
# from the develop worktree, branch off develop into a new sibling worktree:
cd <repo>/<repo>-develop
git worktree add ../<repo>-feature-foo -b feature-foo develop
git push -u origin feature-foo    # the branch exists on the remote before any work is done on it
cd ../<repo>-feature-foo
uv sync                       # each worktree gets its own deps (or: npm ci)

# …work, committing as you go and pushing after each commit (see ai-collaboration.md)…

# open a PR into develop. The USER merges it (see "Who merges").
# Then sync the trunk worktree and clean up — see "After the merge" below.
```

- Working branches merge into `develop` **with a merge commit**: GitHub makes it with `--no-ff` and titles it `<PR title> (#N)` (with the `feat:`/`fix:`/… prefix by which the changelog groups it), and its message is the PR's description, so both are kept in the repo and not only on GitHub. That one dated commit on `develop`'s first-parent line is the record of *when the feature landed*, and the branch's own commits stay in the repo on the second-parent side.
- Promotion `develop → main` is part of a **release**, not a reviewed PR: run from the CLI on `main` with `git merge --no-ff develop` (a merge commit → a dated per-release ledger via `git log --first-parent main`), then bump + tag + push. See [`releases.md`](releases.md).
- Pulls are **`git pull --ff-only`** — never an implicit merge on pull.

## Tracking when a feature was added

The merges above yield a dated history at three granularities:

- **Per feature** — `git log --first-parent develop` is one line per pull request, its merge commit titled `<PR title> (#N)`, plus one per release, the merge of that release's back-merge pull request, each with its date. The chain holds because GitHub merges every pull request, the back-merge's included, with a merge commit whose first parent is `develop`'s tip, so `main`'s release ledger stays on the second-parent side. The back-merge branch's own `git merge --no-ff` has another reason: without it, where no PR merged during the release, the branch would fast-forward onto `main`'s tip, the `[skip ci]` changelog commit where the release writes one, and so lack the merge commit of its own that `back-merge-check` requires (see [`releases.md`](releases.md#the-releases-last-step-the-back-merge-pull-request)). In this handbook the back-merge fast-forwarded from v0.8.5 to v0.14.0, so the chain below v0.14.0 is `main`'s release ledger; the per-feature ledger resumes at v0.15.0.
- **Per release** — `git log --first-parent main` is one line per release merge commit, the promotion, with that release's `release vX.Y.Z` bump and, where the release writes one, its `docs(changelog):` commit on the same chain. A hotfix has no promotion: the commit of the pull request picked onto `main` stands on the chain in its place ([`releases.md`](releases.md#picking-a-merged-pull-request-onto-the-release-line)).
- **Per release, with contents** — annotated, dated tags (`git tag --list 'v*'`) and the dated sections of `CHANGELOG.md`, which group each release's features.

A branch's own commits are in the history too, on the second-parent side of its merge, and so are the merges of `develop` into it that the up-to-date rule forces before it can be merged ([`ci.md`](ci.md#required-checks-before-merge)). Three consequences:

- **Bisect on the first-parent line.** `git bisect start --first-parent <bad> <good>` keeps the search to the pull-request merges, so it tests one pull request at a time and never stops on a working commit that never built. A plain `git log`, `git bisect` or `git blame` walks the branch commits, which is what makes blame attribute a line to the commit that wrote it rather than to a whole pull request.
- **Reverting a merged PR is `git revert -m 1 <merge>`**, which undoes the whole pull request against its first parent. The same branch cannot then simply be merged again — git sees it as already merged — so its changes return only by reverting the revert. The release that brings them back lists them as the pull request that reverted the revert, or under Direct commits where a direct commit re-applies them (`git cherry-pick -x` included), never as the original pull request again (see [`commits-and-changelogs.md`](commits-and-changelogs.md#how-a-releases-list-is-built)).
- **Tidying a branch is allowed and not required.** Rebase it, squash or reword its commits before its PR merges if that leaves a clearer history; a branch that was committed as the work went is fine as it is. A tidy is a force push of the working branch, which needs its own go-ahead ([`ai-collaboration.md`](ai-collaboration.md#shared-state-writes-need-explicit-authorization)).

## Who merges

The repo is configured **merge-commit only** (squash and rebase merges are disabled), so a PR's merge button can only make a merge commit — there's no wrong option to pick. Set new repos up the same way; see [`ci.md`](ci.md#repo-merge-settings).

- **Feature PR → `develop`:** opened by anyone (including AI devs); a **human reviews and merges** it (the merge button, or `gh pr merge <n> --merge`) once the **required checks are green** — branch protection keeps the button disabled until they pass (see [`ci.md`](ci.md#required-checks-before-merge)). Merged branches auto-delete. A broad directive ("fix all that", "finish it") authorises the *work*, not the merge.
- **The back-merge PR → `develop`:** merged by whoever runs the release, under that release's authorisation, because it is the release's last step and not a feature PR. `git back-merge` opens it, waits for `develop`'s required checks on its head, and merges it with `gh pr merge <n> --merge --match-head-commit <sha>`, never with `--admin`, so the commit that lands is the one the checks examined; where `develop` moves meanwhile and the repo requires branches to be up to date, it rebuilds the branch instead of merging a head that has fallen behind. The version guard's back-merge mode is what reviews it: it admits the released state of `main` and, in a code repo, the open-cycle bump, and nothing else (see [`ci.md`](ci.md#version-guardyml--version-sot-unchanged-every-repo) and [`releases.md`](releases.md#the-releases-last-step-the-back-merge-pull-request)).
- **`develop → main`:** done from the CLI as part of a **release**, not a reviewed PR. A single release authorisation ("do the release") covers the whole flow — including the `git merge --no-ff develop` promotion and the back-merge PR's merge — with no second approval. See [`ai-collaboration.md`](ai-collaboration.md) and [`releases.md`](releases.md).

## After the merge

Two steps follow a merge, and they have different owners. The **sync** belongs to whoever performed the merge — a feature PR's merge, the back-merge PR's (which `git back-merge` performs and syncs itself), and the release promotion, which alone has no PR author at all. The **cleanup** belongs to whoever opened the pull request (in parallel work, the coordinator — see [`parallel-work.md`](parallel-work.md)). Do each as soon as the merge is confirmed, alongside the release prompt ([`ai-collaboration.md`](ai-collaboration.md#shared-state-writes-need-explicit-authorization)).

### Sync the trunk worktree

**After any merge into a trunk, fast-forward that trunk's worktree:**

```bash
cd <repo>/<repo>-develop
git pull --ff-only
```

Whoever next opens the machine, with a session running or not, should find the trunk already prepared. Nothing is committed in a trunk worktree ([`repo-layout.md`](repo-layout.md#never-commit-in-repo-main--repo-develop)), so the fast-forward-only pull (above) can fail only if someone committed there anyway or the trunk was rewritten — both of which you want to hear about at once.

The release flow already syncs both trunks before promoting: a stale local `develop` promotes and tags a commit that omits the merged work (see [`releases.md`](releases.md#cutting-a-release)). This rule generalises the habit beyond release time; it doesn't replace that step.

### Remove the worktree and delete the branch

Do this when no further work on that branch is expected; **keep the worktree when it is**. Leaving one isn't free: each worktree carries its own installed dependencies (`uv sync` / `npm ci`), hundreds of megabytes routinely — 241 MB of `node_modules` in the case that prompted this rule.

> **The ancestry test answers the question.** A merge commit keeps both parents, so once the PR has merged the branch tip is an ancestor of `develop`, and `git merge-base --is-ancestor` answers exactly what is asked: did this branch's work land? The exception is a branch whose PR was **squash-merged before its repo's switch** to merge commits ([`releases.md`](releases.md#until-a-repository-has-switched)): the squash is a *fresh* commit, so that tip is never an ancestor of the trunk, and neither the ancestry test nor `git branch -d` says whether the work landed. **Verify such a branch from its pull request** (`gh pr view <n> --json state,mergedAt` — "MERGED" with a date).

```bash
# from the develop worktree, with the trunk already synced:
git fetch --prune origin                                # drops origin/<branch>, deleted at the merge
git merge-base --is-ancestor <branch> origin/develop    # exit 0 — the work landed
git worktree remove ../<repo>-<branch>
git branch -d <branch>
git push origin --delete <branch>      # only if the remote ref still exists
```

- **The prune comes first, and then `-d` asks the right question.** `git branch -d` tests the branch against its configured upstream where it has one, so while `origin/<branch>` still exists it succeeds whatever `develop` holds; after the prune it falls back to `HEAD`, which in the `develop` worktree is the synced trunk, and its verdict is the ancestry test's. Keep the explicit `git merge-base --is-ancestor` all the same: it names the branch it compares against, and it is the form a script or an agent can read the exit status of.
- **`git worktree remove` refuses while the worktree holds modified or untracked, non-ignored files** (a gitignored `node_modules`/`.venv` doesn't block it); `--force` removes it anyway, so look at what those files are first. `git worktree prune` isn't needed after a successful removal — it's the repair for a worktree directory deleted by hand, whose administrative entry it clears.
- The last line is usually unnecessary: the remote branch is already gone, and the local `origin/<branch>` left behind is merely stale, which `git fetch --prune` clears.

## AI devs

AI devs follow the exact same flow — an ephemeral prefixed-branch worktree, PR into `develop`. There is **no special `claude/` branch or worktree** in the new layout.
