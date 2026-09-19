<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# CI & shared tooling

Workflow templates are in [`templates/.github/workflows/`](../templates/.github/workflows/).

## Required checks before merge

A PR can't merge into `develop` until its required checks are green — enforced by **branch protection** (required status checks on `develop`), so the squash button stays disabled until CI passes.

**Every repo (code *and* docs):**
- **`reuse`** — `reuse lint` (REUSE/SPDX compliance). [`reuse.yml`]
- **`version guard`** — the PR didn't change the version source-of-truth; bumps happen at release on `main`, not in feature work. [`version-guard.yml`]

**Code repos add** (all in `test.yml`):
- `ruff check` (lint) + `ruff format --check` (formatting)
- `ty check` (types — `ty` must be a dev dependency)
- `pytest -m "not network and not docling"` (the fast test tier)
- **`license-check`** (pip-licenses copyleft block) **where the repo's license requires it** [`license-check.yml`]

(A docs repo like this handbook has no code, so it runs only `reuse` + `version guard` on PRs, and its release workflow, the documents target's, on a `v*` tag push; see below.)

**Enforcement.** Add these as **required status checks** on `develop` (Settings → Branches, or `gh api`), and **let admins bypass** — the release flow's back-merge (`main→develop`) and promotion (`develop→main`) are direct pushes, not PRs, so they must not be blocked by these PR checks. The release's own gate (see [`releases.md`](releases.md)) covers the promotion.

## Repo merge settings

Configure every repo so the merge **method can't be picked wrong** — make it **squash-only**:

```bash
gh repo edit <owner>/<repo> \
  --enable-squash-merge=true \
  --enable-merge-commit=false \
  --enable-rebase-merge=false \
  --delete-branch-on-merge=true
# squash commit subject = the PR title, so the changelog lists the PR under its
# Conventional Commit type even on a single-commit PR:
gh api -X PATCH repos/<owner>/<repo> \
  -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=COMMIT_MESSAGES
```

- **Squash-only** means a PR's merge button can only squash — no one can pick the wrong method for a feature PR into `develop` (see [`branching.md`](branching.md)).
- **`squash_merge_commit_title=PR_TITLE` decides the title the changelog lists.** The GitHub default (`COMMIT_OR_PR_TITLE`) uses the *commit* subject on a single-commit PR, which may miss the `feat:`/`fix:` prefix and file the entry under Other changes ([`commits-and-changelogs.md`](commits-and-changelogs.md)).
- **`delete_branch_on_merge`** auto-removes the branch after merge.
- Because the repo is squash-only, `develop → main` (which needs a merge commit) is done **from the CLI during a release** — `git merge --no-ff develop` on `main`, not the PR button. That needs `main` to accept direct pushes; don't add a PR-required ruleset to `main` without rethinking this (you'd have to re-enable merge commits for that path). See [`releases.md`](releases.md).
- **`main` is protected against force pushes and deletions, nothing more.** No required checks, reviews, or restrictions on `main`: the release flow (and the `changelog` job, where the release has one) push to it directly, and the release gate covers the promotion. The two blocks bind admins as well, which is the point: `main` is the release ledger and is never rewritten. `develop`'s rule already blocks both. Apply it with the call below; `required_linear_history` must stay `false` (the promotion is a merge commit), and adding a required check to `main` later would block the release push (see the previous point).

```bash
gh api --method PUT repos/<owner>/<repo>/branches/main/protection --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

## `reuse.yml` — REUSE/SPDX (every repo)

Triggers on `pull_request`/`push` to `main` and `develop`; runs `uvx --from "reuse[charset-normalizer]" reuse lint`. Universal — code and docs repos alike (it's the handbook's PR gate, since the handbook has no `test.yml`).

## `version-guard.yml` — version SoT unchanged (every repo)

On `pull_request` to `develop`, fails if the version source-of-truth (`pyproject.toml` `[project].version` / `package.json` `version` / `VERSION.txt`) differs from the base — bumps belong at release on `main`. See [Version checks](#version-checks).

Because the check is *unchanged-vs-base* (not a format check), it's fine for a code repo's `develop` to sit at a `X.Y.Z.dev0` between releases (the post-release open-cycle — see [`releases.md`](releases.md#development-versioning)); feature PRs that don't touch it still pass. A branch cut *before* the open-cycle fails this check until it merges `develop` — sync up.

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

**Node repos** use [`test-node.yml`](../templates/.github/workflows/test-node.yml) instead — a `node-version` matrix running `npm ci` · `npm run typecheck`/`lint`/`test`. See [`node-tooling.md`](node-tooling.md).

**Electron apps** use [`test-electron.yml`](../templates/.github/workflows/test-electron.yml) — `npm ci` · `npm run lint` · `npm run build` (the electron-vite build as a smoke test). See [`electron-tooling.md`](electron-tooling.md).

## `release.yml` — on `v*` tag push

Every repo's release workflow is `.github/workflows/release.yml`, whatever the repo publishes, and it is assembled from the parts in [`templates/.github/workflows/release/`](../templates/.github/workflows/release/): the gate, the job of each of the product's publish targets, and the job that creates the GitHub Release. Which jobs those are is decided by the targets, never by the language; [`releases.md`](releases.md#what-a-release-publishes) is the rule and the table of targets, and describes what each job publishes.

| Part | Job | What it carries |
|---|---|---|
| `head.yml` | none | the workflow name, the `v*` tag trigger, `permissions: contents: read` |
| `gate.yml` | `gate` | the three checks: the tag equals the version in the repo's version file and that version carries no dev marker, the tagged commit is reachable from `origin/main`, the version is strictly greater than the previous tag |
| `docker.yml` | `docker` | the multi-arch image on GHCR |
| `pypi.yml` | `pypi` | the PyPI publish |
| `npm.yml` | `npm` | the npm publish, with the optional scoped alias |
| `installers.yml` | `installers` | the macOS / Windows / Linux installer build |
| `changelog.yml` | `changelog` | the CHANGELOG commit back to `main` and the GitHub Release |
| `documents.yml` | `release` | the GitHub Release with GitHub's generated notes |

The assembly is a concatenation: `head.yml`, `gate.yml`, the part of each target in the order `docker`, `pypi`, `npm`, `installers`, and then `changelog.yml`; for the documents target, `documents.yml` after the gate and nothing else. Then, in the `changelog` job, replace `TARGET_JOBS` in `needs:` with the target jobs, and delete the "Download all built installers" step unless the repo has the installers target. Add the SPDX header the repo's REUSE layout asks for. An image-only service, for instance:

```bash
cd <handbook>/templates/.github/workflows/release
cat head.yml gate.yml docker.yml changelog.yml > <repo>/.github/workflows/release.yml
# then in that file: needs: [gate, docker], and no installers download step
```

Left in place, `TARGET_JOBS` fails `actionlint` and GitHub's own validation, so the workflow does not run at all: an unfinished assembly cannot half-publish. Run `actionlint` on the result before committing it.

A difference from a part is judged, not forbidden. State every difference in the repo's pull request with its reason. A need of that repo alone is documented in the repo as its slot, in a comment at the job or in its `docs/decisions.md`: paper-boxing's three-image matrix and jonobones's scoped alias are the cases today. A difference that improves the part goes back into the handbook's part by a handbook pull request, and the other repos take it at their next re-assembly where it improves them. Only a mistaken or unexplained difference is corrected. `convention-auditor` reports each undocumented difference for that judgement rather than as a defect. A repo not yet re-assembled is a separate case: it still carries a copy of one of the templates the parts replaced (`release-node.yml`, `release-electron.yml`, `release-txt.yml`, `dev-release-electron.yml`, or a trimmed `release.yml` or `dev-release.yml`), under whatever name, and the auditor reports that as not yet re-assembled rather than as drift.

Notes that belong to CI:

- **Pin action versions exactly** (`astral-sh/setup-uv@v8.1.0`, not `@v8`).
- **Keep actions on the Node 24 runtime.** GitHub removed Node 20 from its runners (force-upgraded to node24 on 2026-06-16; removed ~2026-09-16). Several actions only switched to node24 *several majors* up, so a naïve "one major up" can still land on node20. Verified node24 floors (lowest node24 version): `actions/checkout@v6` · `astral-sh/setup-uv@v8.1.0` (≥v7) · `docker/setup-qemu-action@v4` · `docker/setup-buildx-action@v4` · `docker/login-action@v4` · `docker/metadata-action@v6` · `docker/build-push-action@v7` (**skip v6 — still node20**) · `actions/upload-artifact@v6` (skip v5) · `actions/download-artifact@v7` (skip v5/v6) · `actions/upload-pages-artifact@v5` (skip v4 — bundles a node20 upload-artifact) · `actions/deploy-pages@v5` · `actions/configure-pages@v6` · `actions/setup-python@v6` · `actions/cache@v5`. (All node24 majors need Actions Runner ≥ 2.327.1; GitHub-hosted runners satisfy this.)
- **GHCR Docker tags always include `latest`:**

  ```yaml
  tags: |
    type=semver,pattern={{version}}
    type=semver,pattern={{major}}.{{minor}}
    type=raw,value=latest
  ```
- **Trusted publishing (OIDC), no long-lived secrets** — PyPI (`pypa/gh-action-pypi-publish`, `environment: pypi`) and npm. Register the publisher at the **org** level so the package is born org-owned — see [Org-owned trusted publishers](#org-owned-trusted-publishers) below.
- The `changelog` job needs `contents: write` and `pull-requests: read`, scoped to that job (a job's `permissions:` block sets every scope it does not name to none), the org-level `ANTHROPIC_API_KEY`, and `GH_TOKEN` for reading the merged pull requests. It checks `dev-tools` out into `dev-tools/` at the pinned release ([below](#shared-dev-scripts-dev-tools)) and runs `uv run --script dev-tools/scripts/generate-changelog`, which installs the exact anthropic SDK version the script declares for that run alone, whatever the repo's own dependencies.

## The documents assembly: `VERSION.txt` repos, on a `v*` tag push

A repo whose version lives in `VERSION.txt` (docs repos like this handbook, and `dev-tools`) publishes documents, and its `release.yml` is `head.yml` + `gate.yml` + `documents.yml`: the same three-check gate, then a `release` job that creates the GitHub Release with `gh release create --verify-tag --generate-notes` (`contents: write` scoped to that job). Nothing else. There is no artifact to build or publish, and no `changelog` job: a documents repo keeps no `CHANGELOG.md` to generate and commit back to `main`, and GitHub's generated notes are its release record, listing every pull request merged since the previous tag with its link, which is why the PR-title prefix still matters here. The job is idempotent: a re-run, or a Release already created by hand, finds it and exits 0. To add hand-written notes, edit the Release after the workflow has created it (`gh release edit v<new> --notes-file …`). The handbook's own `.github/workflows/release.yml` is that assembly byte for byte.

## `dev-release.yml` — on-demand dev build

A dev build is for local testing, and it is optional: a repo has one or it has none. Where it has one, `.github/workflows/dev-release.yml` is assembled the same way from the parts in [`templates/.github/workflows/dev-release/`](../templates/.github/workflows/dev-release/): `head.yml`, `gate.yml`, and then the dev part of each of the repo's targets that has one, in the order `docker.yml`, `testpypi.yml`, `installers.yml`. npm has no dev part, as documents have none ([`releases.md`](releases.md#what-a-release-publishes)).

It is **manually triggered** (`workflow_dispatch`) and run from `develop` (`gh workflow run dev-release.yml --ref develop`, or via `git dev-release`). The dev gate requires a dev marker on the version (`X.Y.Z.devN` or `X.Y.Z-devN`), refuses any ref but `develop`, and hands the version to the dev jobs. It creates **no `v*` tag**, so it never trips the `release.yml` gate, and it runs no changelog job. What each dev job publishes is its target's dev counterpart: the image tagged `dev`, with the dev version and `sha-<commit>` (never `latest`), the dev version on TestPyPI, or unsigned installers kept seven days as workflow artifacts.

TestPyPI belongs to the PyPI target. A repo that publishes to PyPI and has dev builds needs its **own TestPyPI trusted publisher**, which differs from the PyPI one in two fields: it authorizes the workflow **`dev-release.yml`** (not `release.yml`) and the environment **`testpypi`** (not `pypi`). **TestPyPI is a separate instance from pypi.org** — its own account and login, and an org must be requested there independently; until that org is approved the publisher is a plain **individual-account** pending publisher, which is fine for a throwaway sandbox. Create a matching `testpypi` GitHub environment (no protection rules). A repo that does not publish to PyPI needs none of this. See [`releases.md`](releases.md#development-versioning).

## Version checks

Two guards keep versioning honest (see [`releases.md`](releases.md#version-rules)):

- **Feature PRs into `develop` must not change the version.** `version-guard.yml` fails the PR if the version source-of-truth (`pyproject.toml` `[project].version` / `package.json` `version` / a `VERSION.txt` file) differs from the base — bumps belong at release, on `main`, not in feature work. (The release back-merge to `develop` is a direct push, not a PR, so it isn't subject to this.)
- **The release gate enforces a monotonic increase.** On top of the existing gate checks (tag == SoT version, tag reachable from `origin/main`), it rejects a tag whose version is not **strictly greater** than the previous tag — catching a forgotten or backwards bump before anything publishes. Implemented as the third step of the gate part. A repo has the check once its workflows are assembled from the parts; until then its gate is whatever its older workflow carried: the tag-equality and reachability checks in every repo but jonobones, which has no gate at all, and the monotonic check in paper-boxing and dev-tools alone.
- **The release gate refuses a dev version.** The first gate step fails a tag whose version still carries a `.devN` or `-devN` marker. Like the monotonic check, it reaches a repo with its re-assembly: no repo carries it yet. The promotion brings `develop`'s placeholder onto `main`, so a tag cut before `git bump release` would otherwise publish a dev version to every target, `latest` among the image's tags.

## `license-check.yml` — copyleft guard

Some repos run `pip-licenses` to block copyleft transitive dependencies (GPL/AGPL/LGPL) from sneaking into a permissively-licensed package. Include it where the repo's own license requires keeping deps non-copyleft.

## Org-level secrets

`ANTHROPIC_API_KEY` is set at the **ParkviewLab org** level and inherited by every repo (used by the changelog job's Highlights call). A missing key degrades gracefully — the changelog gets a placeholder and the release still ships.

## Org-owned trusted publishers

A package should be owned by the **ParkviewLab PyPI org**, not by whoever's account happened to run the first publish. How you get there depends on whether the package exists yet:

- **New package (not yet published) →** register a **pending** trusted publisher at the **org** level before the first release: *ParkviewLab → Publishing* on PyPI, with owner `ParkviewLab`, the repo name, workflow `release.yml`, and environment `pypi`. The first publish then creates the project **born org-owned**, with no personal-account step to undo. (Org-level pending publishers are a PyPI feature, added 2025-11.)
- **Existing package (already published under a personal account) →** move it in from the **org Projects page → "Transfer existing project"** (the drop-down of your personal projects at the bottom of the org's Projects page). Do **not** confuse this with the project-settings **"Transfer project"** control, which is org→org and makes you type the project name. You must act as an org **Owner** for the transfer to take.

**Trusted publishers survive the transfer — leave them untouched.** OIDC is attached to the *project* record and checks only the GitHub token claims (`repository_owner`, repo, `release.yml`, `environment`); it consults no PyPI account or org identity. Because every ParkviewLab repo already lives at `github.com/ParkviewLab/<repo>`, the org move changes no claim and releases keep working. Recreating an overlapping publisher is what causes a race — don't.

## Dependency management

- **`uv.lock` is committed** — the reproducible-build source of truth.
- Updates land via PR (a `build-` branch).
- **No dependabot today.** Dependency-update automation is a deferred in-flight idea (see `deco-assaying/docs/dependency-update-automation.md`); add it per-repo if/when it's worth the moving parts.

## Shared dev scripts: `dev-tools`

Cross-project scripts that encode an org convention live in **[`ParkviewLab/dev-tools`](https://github.com/ParkviewLab/dev-tools)**, not in each repo. `dev-tools/install.sh` **symlinks** `scripts/*` into `~/.local/bin/`, so a `git pull` in `dev-tools` propagates updates to every dev with no re-run. Git auto-discovers `git-<verb>` binaries on `PATH`, which is how `git bump` / `git release` work (see [`releases.md`](releases.md)).

The test for what belongs in `dev-tools` vs a repo's own `scripts/`: *if I changed this, would it need changing in other repos too?* Yes → `dev-tools`. No → the repo's `scripts/`.

A `dev-tools` script may also run inside a repo's workflow, from a checkout of `dev-tools` at an exact release into `dev-tools/`, a subfolder of the checkout. Two do: `build-pages-site`, which builds the documentation site ([`docs-site.md`](docs-site.md#the-build-script)), and `generate-changelog`, which writes the release notes in the `changelog` job ([`commits-and-changelogs.md`](commits-and-changelogs.md)). The pin is what makes each a locked dependency rather than one on `dev-tools`' state, and a workflow never checks `dev-tools` out at a branch. It holds only while what the pin names cannot change, and the two pins meet that condition in different ways:

- The `changelog` job pins the release's full commit SHA, with its tag in a comment on the same line (`ref: <sha> # vX.Y.Z`, the SHA from `git rev-parse vX.Y.Z^{commit}`). The job commits to `main` and creates the Release, and a SHA names one commit by construction: nothing done in `dev-tools` can redirect it, and a re-run of a past release job runs exactly what the original ran.
- The documentation site's pin in `pages-docs.yml` is the tag itself, and a tag names its commit only while nothing moves it. `dev-tools` carries a ruleset on `refs/tags/v*` that refuses the update, the force push and the deletion of a release tag and names no bypass actor, so no one, an administrator included, can move a release tag while it is active. An administrator can still disable or delete the ruleset, which makes it a guard rather than a lock, and it is to be kept: it holds the site's pin in place, and it keeps the tag in each SHA pin's comment true. Its cost is that a `dev-tools` release cut in error cannot be re-tagged; the next patch release corrects it.

Every workflow pin of a `dev-tools` script, the documentation site's excepted, follows one policy, each pin with its own script:

- A pin names a `dev-tools` release whose own release run passed and which is at or after the pin's floor: the newest such release that changed the pinned script. A `dev-tools` release that leaves the script unchanged raises no floor, so it makes no pin lag and costs no repo a pull request. Only a release whose run passed counts: that run's gate checks the tag after the tag exists, so a tag that fails it stays under the ruleset, and it is passed over.
- A pin below its floor is moved during the next piece of work done in the repo. Preparing a release counts as such a piece of work, so a pin below the floor is moved by a pull request before the promotion: a release is when the script writes the notes, and notes once published stay as published. A pin that is moved, or set for the first time, takes the newest `dev-tools` release whose run passed.
- No pin pull requests are opened across the repos when `dev-tools` releases. The pin in the handbook's release parts catches up with the next handbook change.
- The floor is computed from `dev-tools`' release tags whose release runs passed: the newest of them whose range from the previous tag touched the script's file (`git log <previous tag>..<tag> -- scripts/<script>`, or `gh api repos/ParkviewLab/dev-tools/compare/<previous tag>...<tag>`). `convention-auditor` and the release preflight report a pin below its floor, and a pin whose SHA is not its tag's commit; the job summary names the `dev-tools` version each release ran.
- A local run, such as a dry run or the repair of a failed changelog job, takes the script from a `dev-tools` worktree at the pin, not from the clone `install.sh` links, which runs whatever branch that clone has checked out.

The documentation site's pin moves on its own occasions, when a repo needs a newer `build-pages-site`; bumping it is a one-line change in that repo.
