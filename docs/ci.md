<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# CI & shared tooling

Workflow templates are in
[`templates/.github/workflows/`](../templates/.github/workflows/).

## Required checks before merge

A PR can't merge into `develop` until its required checks are green — enforced by
**branch protection** (required status checks on `develop`), so the squash button
stays disabled until CI passes.

**Every repo (code *and* docs):**
- **`reuse`** — `reuse lint` (REUSE/SPDX compliance). [`reuse.yml`]
- **`version guard`** — the PR didn't change the version source-of-truth; bumps
  happen at release on `main`, not in feature work. [`version-guard.yml`]

**Code repos add** (all in `test.yml`):
- `ruff check` (lint) + `ruff format --check` (formatting)
- `ty check` (types — `ty` must be a dev dependency)
- `pytest -m "not network and not docling"` (the fast test tier)
- **`license-check`** (pip-licenses copyleft block) **where the repo's license
  requires it** [`license-check.yml`]

(A docs repo like this handbook has no code, so it runs only `reuse` + `version
guard`.)

**Enforcement.** Add these as **required status checks** on `develop` (Settings →
Branches, or `gh api`), and **let admins bypass** — the release flow's back-merge
(`main→develop`) and promotion (`develop→main`) are direct pushes, not PRs, so they
must not be blocked by these PR checks. The release's own gate
(see [`releases.md`](releases.md)) covers the promotion.

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

## `reuse.yml` — REUSE/SPDX (every repo)

Triggers on `pull_request`/`push` to `main` and `develop`; runs
`uvx --from "reuse[charset-normalizer]" reuse lint`. Universal — code and docs
repos alike (it's the handbook's main gate, since the handbook has no `test.yml`).

## `version-guard.yml` — version SoT unchanged (every repo)

On `pull_request` to `develop`, fails if the version source-of-truth
(`pyproject.toml` `[project].version` / `package.json` `version` / `VERSION.txt`)
differs from the base — bumps belong at release on `main`. See
[Version checks](#version-checks).

Because the check is *unchanged-vs-base* (not a format check), it's fine for `develop` to sit at a
`X.Y.Z.dev0` between releases (the post-release open-cycle — see
[`releases.md`](releases.md#development-versioning)); feature PRs that don't touch it still pass. A
branch cut *before* the open-cycle fails this check until it merges `develop` — sync up.

## `test.yml` — code repos, on every PR/push

Triggers on `pull_request` and `push` to `main` and `develop`. Steps:

```yaml
- uses: actions/checkout@v6
- uses: astral-sh/setup-uv@v8.1.0      # pin exactly — not floating @v8
- run: uv sync
- run: uv run ruff check src tests
- run: uv run ruff format --check src tests
- run: uv run ty check                 # ty must be a dev dependency
- run: uv run pytest -m "not network and not docling" -q
```

The test subset excludes the slow/networked tiers (see [`testing.md`](testing.md)).

**Node repos** use [`test-node.yml`](../templates/.github/workflows/test-node.yml) instead — a
`node-version` matrix running `npm ci` · `npm run typecheck`/`lint`/`test`. See
[`node-tooling.md`](node-tooling.md).

**Electron apps** use [`test-electron.yml`](../templates/.github/workflows/test-electron.yml) — `npm ci` ·
`npm run lint` · `npm run build` (the electron-vite build as a smoke test). See
[`electron-tooling.md`](electron-tooling.md).

## `release.yml` — on `v*` tag push

The tag-driven publish pipeline: `gate` → `docker` + `pypi`/npm → `changelog`.
Fully described in [`releases.md`](releases.md). Notes that belong to CI:

- **Pin action versions exactly** (`astral-sh/setup-uv@v8.1.0`, not `@v8`).
- **Keep actions on the Node 24 runtime.** GitHub removed Node 20 from its runners (force-upgraded to node24 on 2026-06-16; removed ~2026-09-16). Several actions only switched to node24 *several majors* up, so a naïve "one major up" can still land on node20. Verified node24 floors (lowest node24 version):
  `actions/checkout@v6` · `astral-sh/setup-uv@v8.1.0` (≥v7) · `docker/setup-qemu-action@v4` · `docker/setup-buildx-action@v4` · `docker/login-action@v4` · `docker/metadata-action@v6` · `docker/build-push-action@v7` (**skip v6 — still node20**) · `actions/upload-artifact@v6` (skip v5) · `actions/download-artifact@v7` (skip v5/v6) · `actions/upload-pages-artifact@v5` (skip v4 — bundles a node20 upload-artifact) · `actions/deploy-pages@v5` · `actions/configure-pages@v6` · `actions/setup-python@v6` · `actions/cache@v5`. (All node24 majors need Actions Runner ≥ 2.327.1; GitHub-hosted runners satisfy this.)
- **GHCR Docker tags always include `latest`:**

  ```yaml
  tags: |
    type=semver,pattern={{version}}
    type=semver,pattern={{major}}.{{minor}}
    type=raw,value=latest
  ```
- **Trusted publishing (OIDC), no long-lived secrets** — PyPI
  (`pypa/gh-action-pypi-publish`, `environment: pypi`) and npm. Register the publisher at
  the **org** level so the package is born org-owned — see
  [Org-owned trusted publishers](#org-owned-trusted-publishers) below.
- The `changelog` job needs `contents: write` (scoped to that job) and the
  org-level `ANTHROPIC_API_KEY`. It pulls the anthropic SDK just-in-time with
  `uv run --with anthropic …` so the workflow snippet stays identical in every
  repo that adopts it, regardless of whether `anthropic` is a project dep.
- **Node repos** use [`release-node.yml`](../templates/.github/workflows/release-node.yml) — the
  same `gate` → image + **npm** (OIDC) → `changelog` shape, with an optional scoped-alias publish.
  See [`node-tooling.md`](node-tooling.md).
- **Electron apps** use [`release-electron.yml`](../templates/.github/workflows/release-electron.yml) — the
  same `gate` + `changelog` shape, but the middle is a **macOS/Windows/Linux build matrix** (electron-builder)
  whose installers the `changelog` job attaches to the GitHub Release. **No GHCR image.** See
  [`electron-tooling.md`](electron-tooling.md).
- **Pure CLI/library packages** (no container image, e.g. `cogrind-workshop`) drop the
  `docker` job from `release.yml` — and from `dev-release.yml` if present — leaving
  `gate` → `pypi`/npm → `changelog`. Trim the job from the template; no separate template.

## `dev-release.yml` — on-demand dev build (optional, code repos)

A **manually-triggered** (`workflow_dispatch`) pre-release publish, for exercising a candidate before
the real release — run from `develop` (`gh workflow run dev-release.yml --ref develop`, or via
`git dev-release`). It builds and publishes a **pre-release** — a GHCR **`:dev`** image (+
`:X.Y.Z.devN`) and `X.Y.Z.devN` to **TestPyPI** — and creates **no `v*` tag**, so it never trips the
`release.yml` gate; no changelog/CHANGELOG-commit. Needs its **own TestPyPI trusted
publisher**, which differs from the PyPI one in two fields: it authorizes the workflow
**`dev-release.yml`** (not `release.yml`) and the environment **`testpypi`** (not `pypi`).
**TestPyPI is a separate instance from pypi.org** — its own account and login, and an org
must be requested there independently; until that org is approved the publisher is a plain
**individual-account** pending publisher, which is fine for a throwaway sandbox. Create a
matching `testpypi` GitHub environment (no protection rules). See
[`releases.md`](releases.md#development-versioning).

**Electron apps** use [`dev-release-electron.yml`](../templates/.github/workflows/dev-release-electron.yml) —
`workflow_dispatch` from `develop` builds the macOS/Windows/Linux installers as 7-day **workflow artifacts** (no
registry, no `v*` tag, no dev-version requirement). See [`electron-tooling.md`](electron-tooling.md).

## Version checks

Two guards keep versioning honest (see [`releases.md`](releases.md#version-rules)):

- **Feature PRs into `develop` must not change the version.** `version-guard.yml`
  fails the PR if the version source-of-truth (`pyproject.toml` `[project].version`
  / `package.json` `version` / a `VERSION.txt` file) differs from the base —
  bumps belong at release, on `main`, not in feature work. (The release back-merge
  to `develop` is a direct push, not a PR, so it isn't subject to this.)
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

## Org-owned trusted publishers

A package should be owned by the **ParkviewLab PyPI org**, not by whoever's account
happened to run the first publish. How you get there depends on whether the package
exists yet:

- **New package (not yet published) →** register a **pending** trusted publisher at the
  **org** level before the first release: *ParkviewLab → Publishing* on PyPI, with owner
  `ParkviewLab`, the repo name, workflow `release.yml`, and environment `pypi`. The first
  publish then creates the project **born org-owned**, with no personal-account step to
  undo. (Org-level pending publishers are a PyPI feature, added 2025-11.)
- **Existing package (already published under a personal account) →** move it in from the
  **org Projects page → "Transfer existing project"** (the drop-down of your personal
  projects at the bottom of the org's Projects page). Do **not** confuse this with the
  project-settings **"Transfer project"** control, which is org→org and makes you type the
  project name. You must act as an org **Owner** for the transfer to take.

**Trusted publishers survive the transfer — leave them untouched.** OIDC is attached to the
*project* record and checks only the GitHub token claims (`repository_owner`, repo,
`release.yml`, `environment`); it consults no PyPI account or org identity. Because every
ParkviewLab repo already lives at `github.com/ParkviewLab/<repo>`, the org move changes no
claim and releases keep working. Recreating an overlapping publisher is what causes a race —
don't.

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
