<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Commits & changelogs

ParkviewLab generates each release's section of `CHANGELOG.md` and its GitHub Release notes automatically, with one script: `generate-changelog` in [`ParkviewLab/dev-tools`](https://github.com/ParkviewLab/dev-tools), which the changelog job of every release workflow runs from a checkout of dev-tools pinned to a release. The notes are a Highlights paragraph written by a model, then the list of what the release holds: every pull request merged into it, under the group that the [Conventional Commits](https://www.conventionalcommits.org/) type of its title names, and every commit that reached it without a pull request. The prefixes on PR titles therefore decide how the list reads. (A `VERSION.txt` repo, such as this handbook or `dev-tools`, has no changelog job; its Release notes are GitHub's generated notes, the titles of the pull requests merged since the previous tag, so the prefix on the PR title matters there too. See [`releases.md`](releases.md#what-the-release-workflow-does).)

A repo not yet switched still carries `cliff.toml` and `scripts/generate_changelog.py` and runs them, as it did before: the switch is one pull request per repo, and paper-boxing is the first. Everything below describes a repo once it has switched.

This page states the rules and the reasons needed to apply them. Its sibling [`commits-and-changelogs-why.md`](commits-and-changelogs-why.md) records what is needed only to reopen one of them: the measurement the rule rests on, the alternatives set aside, and the dated rulings.

## Conventional Commit prefixes

A title of the form `type(scope)!: description` is grouped by its type. The scope and the `!` are optional, the type is matched without regard to case, and a blank follows the colon.

| Title | Group in the notes | Notes |
|---|---|---|
| any type with `!` after it (`feat!:`), or a breaking-change footer | Breaking changes | listed there once, whatever its type |
| `feat:` | Features | user-visible |
| `fix:` | Bug fixes | user-visible |
| `perf:` | Performance | user-visible |
| `refactor:` | Refactor | |
| `docs:` | Docs | |
| `test:` | Tests | |
| `revert:` | Reverts | GitHub's Revert button titles a PR `Revert "…"`, which has no type |
| `build:` / `chore:` / `ci:` / `style:` | Maintenance | |
| any other title | Other changes | the whole title |
| a commit with no pull request | Direct commits | its subject and short hash |

The groups appear in this order, and a group with nothing in it is left out; a release with nothing to list reads `_No changes._`. A breaking-change footer is a line beginning `BREAKING CHANGE:` or `BREAKING-CHANGE:`, in the pull request's description or in the message of any of its commits. The types map to the branch prefixes in [`branching.md`](branching.md).

> The PR title is what matters. PRs are squash-merged, so the PR title becomes the subject of the commit GitHub makes, and the list takes the title from that commit. A title without a recognised type is not dropped: it is listed whole under Other changes, where its place in the list says nothing about what kind of change it is. So: prefix your PR titles. No check enforces the prefix, and retitling a PR after its merge does not change the commit, so correct a title before merging.

## How a release's list is built

The rule is implemented once, in the script, and the docstring at the head of [`scripts/generate-changelog`](https://github.com/ParkviewLab/dev-tools/blob/main/scripts/generate-changelog) states it in full: seven rules, R1 to R7, and the eighteen points they decide, D1 to D18. In outline:

- A release covers the commits reachable from its tag and not from the previous release's tag, which is the highest `vX.Y.Z` tag below it by its three numbers. A first release covers the whole history.
- A pull request is found by the commit GitHub made for it: its squash commit (committed by `noreply@github.com`, its subject ending in `(#N)`), or its merge commit where it was merged for real. A copy of such a commit made with `git cherry-pick`, with or without the `-x` trailer, belongs to the same pull request, so a fix picked onto the release line is listed in the release that ships it. A commit that re-applies a change reverted since is no copy, and is listed in the release that brings the change back. A commit whose subject ends in `(#N)` but which GitHub did not make is not believed: it is a direct commit, and the job summary warns of it.
- A pull request is listed once, in the first release that holds its commit or a copy of it, and not again when a later release brings the original.
- A pull request from the repo itself whose head branch is `develop`, `main` or `back-merge-vX.Y.Z` carries work recorded elsewhere, a release promotion or a back-merge, and is not listed; the commits it brings are judged one by one.
- Bookkeeping is left out of the list and reported in the job summary. It is recognised by what a commit changes, never by its title: a commit that changes only the project's own version (in its version file at the repo root and that file's lockfile, with or without `CHANGELOG.md`); a commit that changes only the root `CHANGELOG.md`, as the release job's own commit does; a merge that belongs to no listed pull request and whose tree equals the automatic merge of its two parents, as a release promotion or a back-merge does when it brings nothing of its own; and a commit that changes nothing.
- Every other commit in the range is a direct commit, listed under its own heading. Among them is any merge that belongs to no listed pull request and whose tree differs from the automatic merge of its parents: it carries a change of its own, and is listed with a warning that names the difference.

The script reads one thing from GitHub: the repo's merged pull requests, with each one's number, title, description, branches and merge commit, through `gh`. It uses them to recognise the pull requests that carry other work, by their head branch and the repository they come from; to title a pull request merged at GitHub's default title (`Merge pull request #N from …`), which takes the title GitHub records for it; and to find a breaking-change footer in a description. It also warns where a commit it gives to #N is not the merge commit GitHub records for #N. Everything else comes from git. The changelog job therefore holds `pull-requests: read` beside `contents: write`. If the read fails, the job fails and names the cause: a list built without it would be wrong without saying so, and whereas a missing list is restored by re-running the job, a wrong one would stay published.

## `CHANGELOG.md` format

Each release section is:

```markdown
## [vX.Y.Z] - YYYY-MM-DD

### Highlights

<two to four sentences of plain prose on what is user-visible, written by a model>

### Features

- Thing one (#12)

### Bug fixes

- Thing two (#15)

### Direct commits

- fix a typo in the README (abc1234)
```

- The date is the tagged commit's.
- The Highlights paragraph is written by a model at release time from the entries of the list: plain, factual prose about what is user-visible, with no bullets, no marketing language, and nothing the entries do not contain.
- The list below it is mechanical. A pull request's line is its title's description with the first letter capitalised, then its number; under Other changes the line is the whole title. A direct commit's line is its subject, then its short hash.
- Sections are ordered most recent first, below an `## [Unreleased]` marker (Keep-a-Changelog style).
- Notes already published stay as published. The script accepts an earlier release's tag, for a dry run for instance, but a section it generates for that release is not used to change the release's section of `CHANGELOG.md` or its GitHub Release: the published notes are the record of what was released.

## `generate-changelog`: two phases

The script is `scripts/generate-changelog` in dev-tools, and its [README](https://github.com/ParkviewLab/dev-tools/blob/main/README.md#generate-changelog--a-releases-changelog-section) documents the command. It serves every repo, whatever its language: the project's name and description come from `pyproject.toml`, `package.json` or `Cargo.toml`, else from the repo's name. A repo carries no changelog script or configuration of its own; the copied `scripts/generate_changelog.py` and `cliff.toml` are retired. The script reports on the repository at `--repo DIR`, by default the current directory, which must be the root of its git checkout, and never reads the dev-tools checkout it runs from. It runs in two phases, so that the one model call is made against the tag and its result can still be committed onto a `main` that moved while CI ran:

- `--mode=generate` reads the history at the tag and the repo's merged pull requests, asks the model for the Highlights paragraph, and writes the complete section to `release-body.md` at the repository root. With `--reuse-committed`, which the release workflow passes, it first looks for the tag's section in `CHANGELOG.md` on `origin/main`; when the section is there, it writes it to `release-body.md` unchanged and makes no call, so a re-run of a job that failed after the section was committed creates the Release from the committed text.
- `--mode=insert` puts `release-body.md` into `CHANGELOG.md` below `## [Unreleased]`, creating the file where it is absent. It uses no network, and it does nothing when `CHANGELOG.md` already holds the tag's section, so a re-run never adds a second one.

The tag comes from `GITHUB_REF` on a tag push, and otherwise from `--tag vX.Y.Z`; with neither, the script refuses in every mode. `--tag` serves every run outside a tag push: a local run, a dry run, and the repair of a release whose changelog job failed ([`releases.md`](releases.md#repairing-a-release-whose-changelog-job-failed)). The changelog job checks dev-tools out at the commit of a pinned release, and a local run takes the script from a dev-tools worktree at the same commit; [`ci.md`](ci.md#shared-dev-scripts-dev-tools) states how the pin is locked and when it moves.

Behaviour worth knowing:

- The Highlights call uses the org-level `ANTHROPIC_API_KEY` secret. If the key is missing, or the call fails, is refused, returns nothing or stops at its output limit, the script writes a marked placeholder, gives the cause in the job summary, and the release still ships: changelog prose never blocks a release.
- The model is pinned in the script (`HIGHLIGHTS_MODEL`), one value for every repo. Moving it is a dev-tools release, which reaches a repo when that repo's pin moves.
- The model's input is capped (`MAX_INPUT_CHARS`). Every entry's title or subject goes in first and is never shortened, and the descriptions share what remains, each shortened as needed, so that no entry is lost to the cap.
- The job summary gives the dev-tools version the release ran, the range, every listed pull request with the route by which it was recognised, the pull requests left out as carrying other work or as already shipped, the bookkeeping commits with their reasons, and every warning, among them one for a release that raises the major version but lists no breaking change. Warnings never enter the notes and never fail the job.

How CI wires the two phases (generate against the tag, then switch to a fresh `origin/main`, insert, and commit) is in [`releases.md`](releases.md) and [`ci.md`](ci.md).
