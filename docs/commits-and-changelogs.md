<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Commits & changelogs

ParkviewLab generates `CHANGELOG.md` and the GitHub Release notes
**automatically** from commit history, using [Conventional
Commits](https://www.conventionalcommits.org/) + [git-cliff](https://git-cliff.org/)
+ a one-paragraph LLM "Highlights" summary. This only works if commits/PR titles
carry the right prefixes.

## Conventional Commit prefixes

| Prefix | Section in CHANGELOG | Notes |
|---|---|---|
| `feat:` | Features | user-visible |
| `fix:` | Bug fixes | user-visible |
| `perf:` | Performance | user-visible |
| `refactor:` | Refactor | |
| `docs:` | Docs | |
| `test:` | Tests | |
| `chore:` / `ci:` / `build:` / `style:` | _(dropped)_ | stay in git history, not surfaced |
| `Merge` / `Revert` | dropped / Reverts | |

These map to the branch prefixes in [`branching.md`](branching.md).

> **The PR title is what matters.** PRs are **squash-merged**, so the PR title
> becomes the commit subject `git-cliff` parses. A commit/PR without a recognised
> prefix is **silently dropped** from `CHANGELOG.md` (it remains in git history).
> So: prefix your PR titles.

## `cliff.toml` — the canonical template, copied verbatim

The categorization rules live in [`cliff.toml`](../templates/cliff.toml). It is
the single source of truth; a repo that generates changelogs copies it
**verbatim** — don't customise per-repo. (Rolling out across the family; today
deco-assaying is the reference implementation.) Key settings:

- `conventional_commits = true`, `filter_unconventional = true` (drop
  non-conforming commits), `filter_commits = true` (honour per-parser `skip`).
- `commit_parsers` map each prefix to a group; `chore`/`ci`/`build`/`style`/`Merge`
  are `skip = true`.
- The body template emits **only** the categorized groups — no `## [version]`
  header. The header (and the `### Highlights` paragraph above it) is added by
  `generate_changelog.py`, so the two compose cleanly.

## `CHANGELOG.md` format

Each release section is:

```markdown
## [vX.Y.Z] - YYYY-MM-DD

### Highlights

<2–3 sentence LLM-written prose summary of what's user-visible>

### Features
- feat thing one (abc1234)
### Bug fixes
- fix thing two (def5678)
```

- The **Highlights** paragraph is LLM-generated at release time (plain factual
  prose, no marketing language, no bullets).
- The categorized list below it is mechanical (git-cliff).
- Ordering is most-recent-first, below an `## [Unreleased]` marker
  (Keep-a-Changelog style).

## `generate_changelog.py` — two-phase

The canonical script is [`generate_changelog.py`](../templates/generate_changelog.py)
(copied into a repo's `scripts/` when it adopts the changelog flow). It runs in
two phases so the single LLM call survives the changelog being committed onto a
`main` that moved during CI:

- **`--mode=generate`** — reads git history at the tagged commit, runs git-cliff
  for the categorized section, calls the Anthropic API once for the Highlights
  paragraph, and writes `release-body.md` (the complete section).
- **`--mode=insert`** — prepends `release-body.md` into `CHANGELOG.md` (below
  `## [Unreleased]`). No network, no LLM; idempotent.

Behaviour worth knowing:

- The Highlights call uses the **org-level `ANTHROPIC_API_KEY`** secret. If it's
  missing or the call fails, the script writes a marked placeholder and **the
  release still ships** — never let changelog prose block a release.
- The Anthropic model is **pinned** in the script (`HIGHLIGHTS_MODEL`); bump it
  deliberately, in one place, so behaviour stays stable across repos.
- The commit-log slice fed to the LLM is capped (`MAX_LOG_CHARS`) and truncated
  with a marker rather than failing on an unusually large release.

How CI wires the two phases (generate against the tag, then switch to fresh
`origin/main` and insert + commit) is in [`releases.md`](releases.md) and
[`ci.md`](ci.md).
