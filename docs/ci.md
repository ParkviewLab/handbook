<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# CI & shared tooling

Each repo has up to three GitHub Actions workflows. Templates are in
[`templates/.github/workflows/`](../templates/.github/workflows/).

## Repo merge settings

Configure every repo so the merge **method can't be picked wrong** — make it
**squash-only**:

```bash
gh repo edit <owner>/<repo> \
  --enable-squash-merge=true \
  --enable-merge-commit=false \
  --enable-rebase-merge=false \
  --delete-branch-on-merge=true
# squash commit subject = the PR title, so git-cliff parses the Conventional
# Commit prefix even on a single-commit PR:
gh api -X PATCH repos/<owner>/<repo> \
  -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=COMMIT_MESSAGES
```

- **Squash-only** means a PR's merge button can only squash — no one can pick the
  wrong method for a feature PR into `develop` (see [`branching.md`](branching.md)).
- **`squash_merge_commit_title=PR_TITLE` is load-bearing.** The GitHub default
  (`COMMIT_OR_PR_TITLE`) uses the *commit* subject on a single-commit PR, which may
  miss the `feat:`/`fix:` prefix and silently drop the entry from the changelog.
- **`delete_branch_on_merge`** auto-removes the branch after merge.
- Because the repo is squash-only, `develop → main` (which needs a merge commit) is
  done **from the CLI during a release** — `git merge --no-ff develop` on `main`,
  not the PR button. That needs `main` to accept direct pushes; don't add a
  PR-required ruleset to `main` without rethinking this (you'd have to re-enable
  merge commits for that path). See [`releases.md`](releases.md).

## `test.yml` — on every PR/push

Triggers on `pull_request` and `push` to `main` and `develop`. Steps:

```yaml
- uses: actions/checkout@v6
- uses: astral-sh/setup-uv@v8.1.0      # pin exactly — not floating @v8
- run: uv sync
- run: uv run ruff check src tests
- run: uv run pytest -m "not network and not docling" -q
```

The test subset excludes the slow/networked tiers (see [`testing.md`](testing.md)).

## `release.yml` — on `v*` tag push

The tag-driven publish pipeline: `gate` → `docker` + `pypi`/npm → `changelog`.
Fully described in [`releases.md`](releases.md). Notes that belong to CI:

- **Pin action versions exactly** (`astral-sh/setup-uv@v8.1.0`, not `@v8`).
- **GHCR Docker tags always include `latest`:**

  ```yaml
  tags: |
    type=semver,pattern={{version}}
    type=semver,pattern={{major}}.{{minor}}
    type=raw,value=latest
  ```
- **Trusted publishing (OIDC), no long-lived secrets** — PyPI
  (`pypa/gh-action-pypi-publish`, `environment: pypi`) and npm.
- The `changelog` job needs `contents: write` (scoped to that job) and the
  org-level `ANTHROPIC_API_KEY`. It pulls the anthropic SDK just-in-time with
  `uv run --with anthropic …` so the workflow snippet stays identical in every
  repo that adopts it, regardless of whether `anthropic` is a project dep.

## Version checks

Two guards keep versioning honest (see [`releases.md`](releases.md#version-rules)):

- **Feature PRs into `develop` must not change the version.** A `test.yml` step
  fails the PR if the version source-of-truth (`pyproject.toml` `[project].version`
  / `package.json` `version` / a `VERSION.txt` file) differs from `origin/develop` —
  bumps belong at release, on `main`, not in feature work.
- **The release gate enforces a monotonic increase.** On top of the existing gate
  checks (tag == SoT version, tag reachable from `origin/main`), it rejects a tag
  whose version is not **strictly greater** than the previous tag — catching a
  forgotten or backwards bump before anything publishes.

## `license-check.yml` — copyleft guard

Some repos run `pip-licenses` to block copyleft transitive dependencies
(GPL/AGPL/LGPL) from sneaking into a permissively-licensed package. Include it
where the repo's own license requires keeping deps non-copyleft.

## Org-level secrets

`ANTHROPIC_API_KEY` is set at the **ParkviewLab org** level and inherited by every
repo (used by the changelog job's Highlights call). A missing key degrades
gracefully — the changelog gets a placeholder and the release still ships.

## Dependency management

- **`uv.lock` is committed** — the reproducible-build source of truth.
- Updates land via PR (a `build-` branch).
- **No dependabot today.** Dependency-update automation is a deferred in-flight
  idea (see `deco-assaying/docs/dependency-update-automation.md`); add it
  per-repo if/when it's worth the moving parts.

## Shared dev scripts: `dev-tools`

Cross-project scripts that encode an org convention live in
**[`ParkviewLab/dev-tools`](https://github.com/ParkviewLab/dev-tools)**, not in
each repo. `dev-tools/install.sh` **symlinks** `scripts/*` into `~/.local/bin/`,
so a `git pull` in `dev-tools` propagates updates to every dev with no re-run. Git
auto-discovers `git-<verb>` binaries on `PATH`, which is how `git bump` /
`git release` work (see [`releases.md`](releases.md)).

The test for what belongs in `dev-tools` vs a repo's own `scripts/`: *if I changed
this, would it need changing in other repos too?* Yes → `dev-tools`. No → the
repo's `scripts/`.
