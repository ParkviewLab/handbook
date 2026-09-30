<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# CI & shared tooling

Workflow templates are in [`templates/.github/workflows/`](../templates/.github/workflows/).

The reasoning behind these rules, with the alternatives set aside and the dated rulings, is in two records: [`releases-why.md`](releases-why.md) for the release and dev-release workflows, and [`branching-why.md`](branching-why.md) for the merge settings, the version guard's back-merge mode and the binding of administrators.

## Required checks before merge

A PR can't merge into `develop` until its required checks are green, enforced by branch protection (required status checks on `develop`), so the merge button stays disabled until CI passes.

**Every repo (code *and* docs):**
- **`reuse`**: `reuse lint` (REUSE/SPDX compliance). [`reuse.yml`]
- **`version guard`**: one required context, `no-version-change`, with two modes: for a feature PR, that it didn't change the version source-of-truth, bumps happening at release on `main`; for the release's back-merge PR, that it brings the released state of `main` and, in a code repo, the open-cycle bump, and nothing else. [`version-guard.yml`]

**Code repos add** (all in `test.yml`):
- `ruff check` (lint) + `ruff format --check` (formatting)
- `ty check` (types; `ty` must be a dev dependency)
- `pytest -m "not network and not integration"` (the fast test tier)
- **`license-check`** (pip-licenses copyleft block) where the repo's license requires it [`license-check.yml`]

(A docs repo like this handbook has no code, so it runs only `reuse` + `version guard` on PRs, and its release workflow, the documents target's, on a `v*` tag push; see below.)

**Enforcement.** Add these as required status checks on `develop`, strict, so that a pull request merges only when its branch is up to date with `develop` and its checks ran on what will land (Settings → Branches, or `gh api`). The release does not need a way round them: the promotion pushes `main`, which carries no required checks, and the back-merge and the dev cycle it opens reach `develop` by a pull request that passes them ([`releases.md`](releases.md#the-releases-last-step-the-back-merge-pull-request)). So nothing in the flow writes to `develop` outside its protection, and administrators are bound on `develop` in every repo whose `develop` is protected, a new repo as soon as its protection is set, and on a website's `staging` alike, at `branches/staging/…` ([`website.md`](website.md#ci)):

```bash
gh api -X POST repos/<owner>/<repo>/branches/develop/protection/enforce_admins     # bind
gh api -X DELETE repos/<owner>/<repo>/branches/develop/protection/enforce_admins   # unbind, only where releases.md prescribes it
```

GitHub's rule is that a protection rule's restrictions do not apply to administrators by default, and that this setting applies them too. Binding changes nothing in the flow; it makes `develop`'s checks the gate for every write, including a mistaken one. A write in an emergency then needs the setting switched off and on again, which is an explicit change to the repo's settings rather than a routine consequence of the flow. [`releases.md`](releases.md#the-releases-last-step-the-back-merge-pull-request) prescribes two: the repair of a version-line conflict, and the exception's direct back-merge, whose one push carries, in a code repo, the open-cycle commit that `git dev-release --open --direct` makes after the merge. Until a repo has switched, its release writes `develop` directly, with the setting switched off for those pushes and on again after them, as [`releases.md`](releases.md#until-a-repository-has-switched) gives it.

## Repo merge settings

Configure every repo so the merge method can't be picked wrong; make it merge-commit only:

```bash
gh repo edit <owner>/<repo> \
  --enable-merge-commit=true \
  --enable-squash-merge=false \
  --enable-rebase-merge=false \
  --delete-branch-on-merge=true
# the merge commit's title = "<PR title> (#N)", so the changelog lists the PR
# under its Conventional Commit type, and its message = the PR's description:
gh api -X PATCH repos/<owner>/<repo> \
  -f merge_commit_title=PR_TITLE \
  -f merge_commit_message=PR_BODY
```

- **Merge-commit only** means a PR's merge button can only make a merge commit: no one can pick the wrong method for any PR into `develop`, the release's back-merge PR included (see [`branching.md`](branching.md#who-merges)). GitHub sets the allowed methods for the whole repo, or by a ruleset for the branches merged *into*, never by a PR's head branch, so leaving squash enabled beside merge commits would offer the squash button on the back-merge PR, where a squash severs `develop` from the release, leaving the tag outside `develop`'s ancestry and, in a code repo, the next promotion in conflict on the version line.
- **`merge_commit_title=PR_TITLE` decides the title the changelog lists.** GitHub's default, `MERGE_MESSAGE`, titles every merge `Merge pull request #N from <branch>`, which carries no Conventional Commit type; `PR_TITLE` titles it `<PR title> (#N)`. `merge_commit_message=PR_BODY` puts the PR's description into the commit, so it is kept in the repo and not only on GitHub, and a `BREAKING CHANGE:` footer written there travels with it ([`commits-and-changelogs.md`](commits-and-changelogs.md)).
- **`delete_branch_on_merge`** auto-removes the branch after merge. The back-merge PR's head is a branch of its own, never `main`, so this can never reach `main`.
- Left as they are: `develop` as the default branch; `allow_auto_merge` false, since auto-merge would be offered on every PR and a feature PR is the user's merge ([`ai-collaboration.md`](ai-collaboration.md#shared-state-writes-need-explicit-authorization)); `allow_update_branch` false; no branch rulesets; and `required_linear_history` false on both trunks. The squash title and message settings become inert.
- `develop → main` is done from the CLI during a release (`git merge --no-ff develop` on `main`, not the PR button) for the reasons in [`releases.md`](releases.md#branch-roles--why-bumptag-on-main). That needs `main` to accept direct pushes; don't add a PR-required ruleset to `main` without rethinking this.
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

## `reuse.yml`: REUSE/SPDX (every repo)

Triggers on `pull_request`/`push` to `main` and `develop`; runs `uvx --from "reuse[charset-normalizer]" reuse lint`. Universal: code and docs repos alike (it's the handbook's PR gate, since the handbook has no `test.yml`).

## `version-guard.yml`: version SoT unchanged (every repo)

On `pull_request` to `develop`, one job, `no-version-change` (the required context), with two modes, chosen by the PR's head branch inside that one job. A second job selected by an `if:` would report success when skipped, and a PR could then satisfy the required context by its branch name alone.

**Ordinary mode**, for every PR but a back-merge: it fails if the project's own version differs from the base's: bumps belong at release on `main`. In each version file the PR's tree holds, it reads that version: `[project].version` in `pyproject.toml` and the top-level `version` in `package.json`, as `back-merge-check` reads them; in `Cargo.toml`, which `back-merge-check` does not read, `[package].version` (or `[workspace.package].version` where the crate inherits it or the manifest is a workspace's); and `VERSION.txt` whole. The TOML files are parsed with Python's `tomllib` and `package.json` with `jq`, so a version line of any other table (a tool's, a dependency's, a nested `"version"`) is not compared, and neither is the line's formatting. See [Version checks](#version-checks). A version file the base branch does not yet have is a first introduction, not a bump, and passes; a file with no static version here or at the base (in `pyproject.toml`, a dynamic one) has nothing to guard and passes; and a file that cannot be parsed fails. The one exception is the repair of the base's version file: where the base's version cannot be read, because its file cannot be parsed or holds no static version, a PR that makes it readable passes, whatever version it sets, and one that leaves it unreadable fails ([`releases.md`](releases.md#the-releases-last-step-the-back-merge-pull-request)). Whilst the base's file cannot be parsed, every other PR fails, since its merge carries the base's file.

Because the check is *unchanged-vs-base* (not a format check), it's fine for a code repo's `develop` to sit at a `X.Y.Z.dev0` between releases (the open cycle; see [`releases.md`](releases.md#development-versioning)); feature PRs that don't touch it still pass. So does a branch cut *before* the cycle was opened: the step reads the working tree, which on a `pull_request` event is GitHub's synthetic merge of the head into the base, and in that merge the branch carries `develop`'s version. Bringing the branch up to date is then the up-to-date rule's business, not the guard's.

**Back-merge mode**, for a PR from this repo (never a fork) whose head branch matches `back-merge-v*`: it runs dev-tools' `back-merge-check`, checked out at a pinned release ([below](#shared-dev-scripts-dev-tools)), and passes only for a clean back-merge: one merge commit that is not on `main`, whose tree equals the clean automatic merge of its parents, bringing only commits in the tag the branch names or that tag's changelog commit, at `main`'s version, optionally followed by the open-cycle commit and nothing else. One case differs: for a release picked onto `main` in a code repo, it admits instead the merge with the project's version lines taken from `main`'s release, which [`releases.md`](releases.md#the-releases-last-step-the-back-merge-pull-request) describes under the back-merge's build. The branch name selects the mode and grants nothing: a PR so named that is not a clean back-merge fails, and one from a fork is checked in the ordinary mode, which fails any change of version. The conditions are specified once, in the comment at the head of [`back-merge-check`](https://github.com/ParkviewLab/dev-tools/blob/main/scripts/back-merge-check).

The check is evaluated on explicit commits, never on the checked-out `HEAD`: the head is `github.event.pull_request.head.sha`, and the base is the synthetic merge's first parent (`git rev-parse HEAD^1`), the `develop` tip this run was tested against, because GitHub does not document when the event's `base.sha` is refreshed. `HEAD` itself is the synthetic merge, which is a merge commit not on `main`, so a check computed from it would refuse every back-merge. The checkout keeps `fetch-depth: 0` and nothing re-fetches a branch shallow: a shallow `develop` makes every ancestry and merge-base answer through its tip wrong, and the check refuses a shallow repository outright.

## `test.yml`: code repos, on every PR/push

Triggers on `pull_request` and `push` to `main` and `develop`. Steps:

```yaml
- uses: actions/checkout@v6
- uses: astral-sh/setup-uv@v8.1.0      # pin exactly — not floating @v8
- run: uv sync
- run: uv run ruff check src tests
- run: uv run ruff format --check src tests
- run: uv run ty check                 # ty must be a dev dependency
- run: uv run pytest -m "not network and not integration" -q
```

The test subset excludes the slow/networked tiers (see [`testing.md`](testing.md)).

**Node repos** use [`test-node.yml`](../templates/.github/workflows/test-node.yml) instead: a `node-version` matrix running `npm ci` · `npm run typecheck`/`lint`/`test`. See [`node-tooling.md`](node-tooling.md).

**Electron apps** use [`test-electron.yml`](../templates/.github/workflows/test-electron.yml): `npm ci` · `npm run lint` · `npm run build` (the electron-vite build as a smoke test). See [`electron-tooling.md`](electron-tooling.md).

## `release.yml`: on `v*` tag push

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
# from the repo's root, with H an absolute path to the handbook's parts
H=<handbook>/templates/.github/workflows/release
cat "$H"/head.yml "$H"/gate.yml "$H"/docker.yml "$H"/changelog.yml > .github/workflows/release.yml
# then in that file: needs: [gate, docker], and no installers download step
```

`dev-tools` does that assembly, from v1.3.0, so that propagating a change to the parts is a command rather than an edit repeated in each repo:

```bash
assemble-workflows --handbook <handbook>          # write release.yml, and dev-release.yml where the repo has dev builds
assemble-workflows --handbook <handbook> --check  # write nothing; report every difference from the assembly
```

`--check` names the job each difference falls in and exits 0 when the workflows match, 1 when a difference is undeclared, and 2 on a usage or declaration error, so CI and `convention-auditor` can run it. One line is outside the comparison: the `ref:` of a step that checks `ParkviewLab/dev-tools` out is the repo's own pin, which the pin policy ([below](#shared-dev-scripts-dev-tools)) lets differ from the part's, so the check prints every such pin on a line of its own and leaves it to be judged by its floor, and writing a workflow keeps the repo's pin rather than the part's; a re-assembly neither moves a pin back to an older release nor moves it forward unasked. A repo declares what it publishes, and each difference it keeps on purpose, in `.github/workflows/.assembly.toml`: its `targets`, whether it has `dev` builds, its SPDX `header`, and a `[[slots]]` entry for each slot with its `job`, its `reason` and the workflow it applies to. A repo without that file has its targets and header read from the `release.yml` it already carries and declares no slot, so the check runs anywhere without preparing the repo first; a repo with a slot adds the file so that its slot reads as declared rather than as drift.

Left in place, `TARGET_JOBS` fails `actionlint` and GitHub's own validation, so the workflow does not run at all: an unfinished assembly cannot half-publish. Run `actionlint` on the result before committing it.

A difference from a part is judged, not forbidden. State every difference in the repo's pull request with its reason. A need of that repo alone is documented in the repo as its slot, in a comment at the job or in its `docs/decisions.md`: paper-boxing's three-image matrix and jonobones's scoped alias are the cases today. A difference that improves the part goes back into the handbook's part by a handbook pull request, and the other repos take it at their next re-assembly where it improves them. Only a mistaken or unexplained difference is corrected. `convention-auditor` runs `assemble-workflows --check` rather than comparing by hand, and reports each undeclared difference for that judgement rather than as a defect.

Notes that belong to CI:

- **Pin action versions exactly** (`astral-sh/setup-uv@v8.1.0`, not `@v8`).
- **Keep actions on the Node 24 runtime.** GitHub has removed Node 20 from its runners (actions were force-upgraded to node24 on 2026-06-16). Several actions only switched to node24 *several majors* up, so a naïve "one major up" can still land on node20. Verified node24 floors (lowest node24 version): `actions/checkout@v6` · `astral-sh/setup-uv@v8.1.0` (≥v7) · `docker/setup-qemu-action@v4` · `docker/setup-buildx-action@v4` · `docker/login-action@v4` · `docker/metadata-action@v6` · `docker/build-push-action@v7` (skip v6, still node20) · `actions/upload-artifact@v6` (skip v5) · `actions/download-artifact@v7` (skip v5/v6) · `actions/upload-pages-artifact@v5` (skip v4, bundles a node20 upload-artifact) · `actions/deploy-pages@v5` · `actions/configure-pages@v6` · `actions/setup-python@v6` · `actions/cache@v5`. (All node24 majors need Actions Runner ≥ 2.327.1; GitHub-hosted runners satisfy this.)
- **GHCR Docker tags always include `latest`:**

  ```yaml
  tags: |
    type=semver,pattern={{version}}
    type=semver,pattern={{major}}.{{minor}}
    type=raw,value=latest
  ```
- **Trusted publishing (OIDC), no long-lived secrets**: PyPI (`pypa/gh-action-pypi-publish`, `environment: pypi`) and npm. Register the publisher at the org level so the package is born org-owned; see [Org-owned trusted publishers](#org-owned-trusted-publishers) below.
- The `changelog` job needs `contents: write` and `pull-requests: read`, scoped to that job (a job's `permissions:` block sets every scope it does not name to none), the org-level `ANTHROPIC_API_KEY`, and `GH_TOKEN` for reading the merged pull requests. It checks `dev-tools` out into `dev-tools/` at the pinned release ([below](#shared-dev-scripts-dev-tools)) and runs `uv run --script dev-tools/scripts/generate-changelog`, which installs the exact anthropic SDK version the script declares for that run alone, whatever the repo's own dependencies.

## The documents assembly: `VERSION.txt` repos, on a `v*` tag push

A repo whose version lives in `VERSION.txt` (docs repos like this handbook, and `dev-tools`) publishes documents, and its `release.yml` is `head.yml` + `gate.yml` + `documents.yml`: the same three-check gate, then a `release` job that creates the GitHub Release with `gh release create --verify-tag --generate-notes` (`contents: write` scoped to that job). Nothing else. There is no artifact to build or publish, and no `changelog` job: a documents repo keeps no `CHANGELOG.md` to generate and commit back to `main`, and GitHub's generated notes are its release record, listing every pull request merged since the previous tag with its link, which is why the PR-title prefix still matters here. `.github/release.yml`, copied from [`templates/.github/release.yml`](../templates/.github/release.yml), keeps the release's own bookkeeping out of those notes: it excludes the label `release-bookkeeping`, which `git back-merge` puts on each back-merge PR. The job is idempotent: a re-run, or a Release already created by hand, finds it and exits 0. To add hand-written notes, edit the Release after the workflow has created it (`gh release edit v<new> --notes-file …`). The handbook's own `.github/workflows/release.yml` is that assembly byte for byte.

## `dev-release.yml`: on-demand dev build

A dev build is for local testing, and it is optional: a repo has one or it has none. Where it has one, `.github/workflows/dev-release.yml` is assembled the same way from the parts in [`templates/.github/workflows/dev-release/`](../templates/.github/workflows/dev-release/): `head.yml`, `gate.yml`, and then the dev part of each of the repo's targets that has one, in the order `docker.yml`, `testpypi.yml`, `installers.yml`. npm has no dev part, as documents have none ([`releases.md`](releases.md#what-a-release-publishes)).

It is manually triggered (`workflow_dispatch`) with one input, `kind` (`patch`, `minor` or `major`), and run from `develop` (`git dev-release <kind>`, or `gh workflow run dev-release.yml --ref develop -f kind=patch`). A dev build commits nothing: the dev gate refuses any ref but `develop` and *computes* the version instead of reading a committed one: the newest `vX.Y.Z` tag incremented by the kind, as dev-tools' `_sot.sh` increments a plain version, plus a build number from the run (`github.run_number × 100 + github.run_attempt`, so a re-run never repeats a file name, which PyPI and TestPyPI refuse), giving `X.Y.Z.devN`, or `X.Y.Z-devN` where the version lives in `package.json`. Before the repo's first release there is no tag to count from, so the target is the version file's own version with any dev marker removed and the kind is not used. The gate publishes that version as an output, and each building job writes it into its own workspace (`uv version`, or `npm version --no-git-tag-version`) before it builds, so `develop` gains no commit. It creates no `v*` tag, so it never trips the `release.yml` gate, and it runs no changelog job. What each dev job publishes is its target's dev counterpart: the image tagged `dev`, with the dev version and `sha-<commit>` (never `latest`), the dev version on TestPyPI, or unsigned installers kept seven days as workflow artifacts.

TestPyPI belongs to the PyPI target. A repo that publishes to PyPI and has dev builds needs its own TestPyPI trusted publisher, which differs from the PyPI one in two fields: it authorizes the workflow `dev-release.yml` (not `release.yml`) and the environment `testpypi` (not `pypi`). TestPyPI is a separate instance from pypi.org: its own account and login, and an org must be requested there independently; until that org is approved the publisher is a plain individual-account pending publisher, which is fine for a throwaway sandbox. Create a matching `testpypi` GitHub environment (no protection rules). A repo that does not publish to PyPI needs none of this. See [`releases.md`](releases.md#development-versioning).

## Version checks

Two guards keep versioning honest (see [`releases.md`](releases.md#version-rules)):

- **Feature PRs into `develop` must not change the version.** `version-guard.yml` fails the PR if the project's own version differs from the base's (`[project].version` in `pyproject.toml`, the top-level `version` in `package.json`, `[package].version` or `[workspace.package].version` in `Cargo.toml`, `VERSION.txt` whole; [above](#version-guardyml-version-sot-unchanged-every-repo)): bumps belong at release, on `main`, not in feature work. The release's back-merge PR is the one PR that does change it, bringing the version released on `main` and, in a code repo, the open-cycle commit after it, and the same required check examines it in its back-merge mode ([above](#version-guardyml-version-sot-unchanged-every-repo)): it admits those and nothing else.
- **The release gate enforces a monotonic increase.** On top of the existing gate checks (tag == SoT version, tag reachable from `origin/main`), it rejects a tag whose version is not strictly greater than the previous tag, catching a forgotten or backwards bump before anything publishes. Implemented as the third step of the gate part, which every repo's release workflow carries on `develop`, and on `main` since its first release from the parts (pvl-dotview's `main` still holds the workflow of its last release before).
- **The release gate refuses a dev version.** The first gate step fails a tag whose version still carries a `.devN` or `-devN` marker. Like the monotonic check, it is in the gate part, and so in every release workflow the parts assembled. The promotion brings `develop`'s placeholder onto `main`, so a tag cut before `git bump release` would otherwise publish a dev version to every target, `latest` among the image's tags.

## `license-check.yml`: copyleft guard

Some repos run `pip-licenses` to block copyleft transitive dependencies (GPL/AGPL/LGPL) from sneaking into a permissively-licensed package. Include it where the repo's own license requires keeping deps non-copyleft.

## Org-level secrets

`ANTHROPIC_API_KEY` is set at the ParkviewLab org level and inherited by every repo (used by the changelog job's Highlights call). A missing key degrades gracefully: the changelog gets a placeholder and the release still ships.

## Org-owned trusted publishers

A package should be owned by the ParkviewLab PyPI org, not by whoever's account happened to run the first publish. How you get there depends on whether the package exists yet:

- **New package (not yet published) →** register a pending trusted publisher at the org level before the first release: *ParkviewLab → Publishing* on PyPI, with owner `ParkviewLab`, the repo name, workflow `release.yml`, and environment `pypi`. The first publish then creates the project born org-owned, with no personal-account step to undo. (Org-level pending publishers are a PyPI feature, added 2025-11.)
- **Existing package (already published under a personal account) →** move it in from the org Projects page → "Transfer existing project" (the drop-down of your personal projects at the bottom of the org's Projects page). Do not confuse this with the project-settings "Transfer project" control, which is org→org and makes you type the project name. You must act as an org Owner for the transfer to take.

**Trusted publishers survive the transfer; leave them untouched.** OIDC is attached to the *project* record and checks only the GitHub token claims (`repository_owner`, repo, `release.yml`, `environment`); it consults no PyPI account or org identity. Because every ParkviewLab repo already lives at `github.com/ParkviewLab/<repo>`, the org move changes no claim and releases keep working. Recreating an overlapping publisher is what causes a race; don't.

## Dependency management

- **`uv.lock` is committed**: the reproducible-build source of truth.
- Updates land via PR (a `build-` branch).
- **Dependabot:** its security updates are on in deco-assaying alone, which has had five Dependabot pull requests, and no repo has version updates (a `.github/dependabot.yml`). Dependency-update automation beyond that is a deferred in-flight idea (see `deco-assaying/docs/dependency-update-automation.md`); add it per repo when it is worth the moving parts.

## Shared dev scripts: `dev-tools`

Cross-project scripts that encode an org convention live in [`ParkviewLab/dev-tools`](https://github.com/ParkviewLab/dev-tools), not in each repo. `dev-tools/install.sh` symlinks `scripts/*` into `~/.local/bin/`, so a `git pull` in `dev-tools` propagates a *changed* script to every dev with no re-run; a *new* script, `git back-merge` among them, needs one `install.sh` run on each machine to be linked. Git auto-discovers `git-<verb>` binaries on `PATH`, which is how `git bump` / `git release` / `git back-merge` work (see [`releases.md`](releases.md)).

The test for what belongs in `dev-tools` vs a repo's own `scripts/`: *if I changed this, would it need changing in other repos too?* Yes → `dev-tools`. No → the repo's `scripts/`.

A `dev-tools` script may also run inside a repo's workflow, from a checkout of `dev-tools` at an exact release into `dev-tools/`, a subfolder of the checkout. Three do: `build-pages-site`, which builds the documentation site ([`docs-site.md`](docs-site.md#the-build-script)); `generate-changelog`, which writes the release notes in the `changelog` job ([`commits-and-changelogs.md`](commits-and-changelogs.md)); and `back-merge-check`, which the version guard runs in its back-merge mode ([above](#version-guardyml-version-sot-unchanged-every-repo)). The pin is what makes each a locked dependency rather than one on `dev-tools`' state, and a workflow never checks `dev-tools` out at a branch. It holds only while what the pin names cannot change, and the pins meet that condition in two ways:

- The `changelog` job and the version guard pin the release's full commit SHA, with its tag in a comment on the same line (`ref: <sha> # vX.Y.Z`, the SHA from `git rev-parse vX.Y.Z^{commit}`). A SHA names one commit by construction: nothing done in `dev-tools` can redirect it. For the `changelog` job, which commits to `main` and creates the Release, that also means a re-run of a past release job runs exactly what the original ran; for the guard, that the rule deciding what a back-merge PR may bring into `develop` changes only when the pin does.
- The documentation site's pin in `pages-docs.yml` is the tag itself, and a tag names its commit only while nothing moves it. `dev-tools` carries a ruleset on `refs/tags/v*` that refuses the update, the force push and the deletion of a release tag and names no bypass actor, so no one, an administrator included, can move a release tag while it is active. An administrator can still disable or delete the ruleset, which makes it a guard rather than a lock, and it is to be kept: it holds the site's pin in place, and it keeps the tag in each SHA pin's comment true. Its cost is that a `dev-tools` release cut in error cannot be re-tagged; the next patch release corrects it.

Every workflow pin of a `dev-tools` script, the documentation site's excepted, follows one policy, each pin with its own script:

- A pin names a `dev-tools` release whose own release run passed and which is at or after the pin's floor: the newest such release that changed the pinned script. A `dev-tools` release that leaves the script unchanged raises no floor, so it makes no pin lag and costs no repo a pull request. Only a release whose run passed counts: that run's gate checks the tag after the tag exists, so a tag that fails it stays under the ruleset, and it is passed over.
- A pin below its floor is moved during the next piece of work done in the repo. Preparing a release counts as such a piece of work, so a pin below the floor is moved by a pull request before the promotion: a release is when the script writes the notes, and notes once published stay as published. Before a hotfix, the pin's pull request into `develop` is then also picked onto `main` with `git cherry-pick -m 1`, before the hotfix's bump. The hotfix's own release runs the workflows as `main` holds them, which a pull request into `develop` does not change, so only the pick makes that release run the pinned script at or above its floor ([`releases.md`](releases.md#picking-a-merged-pull-request-onto-the-release-line)). A pin that is moved, or set for the first time, takes the newest `dev-tools` release whose run passed.
- No pin pull requests are opened across the repos when `dev-tools` releases. The pin in the handbook's release parts catches up with the next handbook change.
- The floor is computed from `dev-tools`' release tags whose release runs passed: the newest of them whose range from the previous tag touched the script's file (`git log <previous tag>..<tag> -- scripts/<script>`, or `gh api repos/ParkviewLab/dev-tools/compare/<previous tag>...<tag>`). `convention-auditor` and the release preflight report a pin below its floor, and a pin whose SHA is not its tag's commit; the job summary names the `dev-tools` version each release ran.
- A local run, such as a dry run or the repair of a failed changelog job, takes the script from a `dev-tools` worktree at the pin, not from the clone `install.sh` links, which runs whatever branch that clone has checked out.

The documentation site's pin moves on its own occasions, when a repo needs a newer `build-pages-site`; bumping it is a one-line change in that repo.
