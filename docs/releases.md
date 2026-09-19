<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Versioning & releases

## The version number has one source of truth

Every project keeps its version in **exactly one file**:

- **Python** → `pyproject.toml` `[project].version`
- **Node** → `package.json` `version`
- **Docs / other (no package manifest)** → a top-level `VERSION.txt` file (one line, e.g. `0.1.0`). This handbook uses one.

Two hard rules follow:

### 1. Nothing duplicates the version

No second copy anywhere that can drift — not in `__init__.py`, `setup.py`/`setup.cfg`, a module constant, a hard-coded CLI `--version` string, a docs/README badge, or a Dockerfile `LABEL`. If something needs the version, it **derives** it from the one source. (Badges pull from PyPI/release tags; the Docker label is stamped by the release workflow's metadata-action.)

### 2. The running app reads the version from that source at runtime

When an app displays its version, it reads it from package metadata — never a literal baked into the code.

**Python** — `importlib.metadata`, with a fallback for editable/uninstalled runs, re-exported as `__version__`:

```python
# config.py  (the pure leaf config module)
from importlib.metadata import PackageNotFoundError, version
try:
    VERSION: str = version("deco-assaying")     # the distribution name
except PackageNotFoundError:
    VERSION = "0.0.0+local"

# __init__.py
from .config import VERSION
__version__ = VERSION
__all__ = ["VERSION", "__version__"]
```

Source: `deco-assaying/.../config.py` + `__init__.py` (mirrored in smalt-mcp, flint-slating, ebony-enriching). The `/health` and `/admin/version` endpoints surface this same `VERSION` (see [`mcp-server-conventions.md`](mcp-server-conventions.md)).

**Node** — read `package.json` at runtime:

```ts
// src/version.ts
import { createRequire } from 'node:module';
const pkg = createRequire(import.meta.url)('../package.json') as { version: string };
export const VERSION = pkg.version;
```

Source: jonobones's `src/version.ts`.

> If you find the version duplicated somewhere, remove the duplicate and replace the read-site with the metadata lookup.

## Cutting a release

Releases are **tag-driven**: pushing a `v*` tag triggers CI, which publishes everything. You never type a version on the `git tag` line — the `dev-tools` helpers derive it from the source-of-truth file (see [`ci.md`](ci.md) for the helpers' home).

```bash
# in the <repo>-main worktree — the whole release runs from the CLI under one authorisation:
git pull --ff-only                   # sync main
git -C ../<repo>-develop pull --ff-only   # sync develop too — see the caution below
git merge --no-ff develop            # promote develop→main; the merge commit is the release ledger entry
git bump <patch|minor|major|release|X.Y.Z>   # edits the SoT file, commits "release v<new>"
git release                          # annotated tag v<new>, derived from the SoT
git push --follow-tags               # the tag push fires the release workflow
```

> **Sync `develop` before you promote.** `git merge --no-ff develop` merges the *local* `develop` worktree, not `origin/develop`. After a PR **squash-merges on GitHub**, that local worktree is stale, so the merge quietly promotes and tags a commit that omits the merged work. The `git -C ../<repo>-develop pull --ff-only` line above closes the gap; skip it and you ship the wrong commit. (This is why the layout sets branch upstream tracking at creation — see [`repo-layout.md`](repo-layout.md#creating-the-layout).)

- **`git bump`** bumps the version in the source of truth (`pyproject.toml` / `package.json` / `VERSION.txt`, auto-detected), stages the change (+ lockfile if touched), and commits `release v<new>`. It does **not** tag. `git bump release` finalizes a dev cycle (drops the `.devN`) — see [Development versioning](#development-versioning).
- **`git release`** reads the version back out and makes the annotated tag `v<version>`. It refuses on a dirty tree or an existing tag. It does **not** push.
- **Choosing the bump kind:** the releaser **reviews the changes since the last release, proposes** major / minor / patch with a one-line rationale, and the **engineer confirms** before `git bump`. The Conventional Commit types in the range are the signal — any breaking change → **major**, any `feat:` → **minor**, otherwise (`fix:`/`perf:`) → **patch**. Never bump silently; never infer the kind from past cadence. See [`ai-collaboration.md`](ai-collaboration.md).
- **Docs currency:** a release publishes `main`'s documents, in the tag's tree everywhere and on the docs site where the repo has one ([`docs-site.md`](docs-site.md)). The currency check is part of the preflight ([`agents.md`](agents.md)); a stale or wrong statement it finds is fixed on `develop` before the promotion.
- **Docs-only / `VERSION.txt` repos have no Conventional-Commit signal** (it's all docs), so choose the bump by the **significance** of the change: a whole new convention or section → **minor**; a clarification, correction, or typo → **patch**; removing or reversing an established convention → **major**. (This handbook's v0.4.0 was a minor — it added the dual-license layout.)
- **`VERSION.txt`-file repos** (no `pyproject`/`package.json`, e.g. this handbook): `git bump`/`git release` are **SoT-aware** — they detect `VERSION.txt` and bump / tag from it just like a `pyproject` repo, so docs repos release with the same CLI flow, no hand-editing. Their release workflow is the documents assembly: the gate, then the GitHub Release, with no artifact and no `changelog` job (see [below](#what-the-release-workflow-does)).

### Version rules

- **Feature work never changes the version.** A PR into `develop` must not touch the version source-of-truth file; the bump happens only at release, on `main`. A CI check on `develop` PRs enforces this — see [`ci.md`](ci.md#version-checks).
- **The version only ever increases.** The release gate rejects a tag whose version isn't **strictly greater** than the last released one — a guard against forgetting to bump or going backwards (see [`ci.md`](ci.md#version-checks)).

### Branch roles & why bump+tag on `main`

`main` is the **release-only surface**; `develop` is the integration trunk (see [`branching.md`](branching.md)). The bump+tag happens on `main` because: clean working-branch history (no release mechanics on feature branches), a deliberate "I'm shipping" moment, and the tag is trivially reachable from `origin/main` so the CI gate passes by construction.

Promotion is `develop → main` done **from the CLI** with `git merge --no-ff develop` — a merge commit, so `git log --first-parent main` is a dated per-release ledger (see [`branching.md`](branching.md)). It is **not** a reviewed PR: the repo is squash-only, so this merge commit is made locally as part of the release, and a single release authorisation covers it (see [`ai-collaboration.md`](ai-collaboration.md)). Pulls use `git pull --ff-only`.

## What a release publishes

What a repo's release does is decided by what the product publishes, never by its language or by a single template. There are five publish targets, and a product publishes to one of them or to several.

| Target | Release job | Dev-build job |
|---|---|---|
| A container image on GHCR | `docker`: amd64 and arm64, tagged with the version, major.minor and `latest` | `docker`: tagged `dev` and with the dev version, never `latest` |
| A package on PyPI | `pypi`: trusted publishing, environment `pypi` | `testpypi`: the dev version on TestPyPI, environment `testpypi` |
| A package on npm | `npm`: trusted publishing | none |
| Installers for macOS, Windows or Linux | `installers`: built on each system and attached to the GitHub Release | `installers`: unsigned, kept seven days as workflow artifacts, with no tag and no GitHub Release |
| Documents, for a `VERSION.txt` repo | `release`: the GitHub Release with GitHub's generated notes | none |

The release workflow holds the gate, the job of each of the product's targets, and the job that creates the GitHub Release (`changelog`, which writes the notes, or `release` for documents). It carries no job for a target the product does not publish. Each workflow is assembled from the handbook's parts, one part per target, by the recipe in [`ci.md`](ci.md#releaseyml--on-v-tag-push).

Dev builds are for local testing: a dev build is a candidate that CI builds for testing in the lab before its release, not a version for others to use. A repo may have dev builds or not. Where it has them, a dev build publishes the dev counterpart of each of its targets that has one, and nothing else. So a repo that publishes to PyPI publishes its dev builds to TestPyPI, and one that does not publish to PyPI never touches TestPyPI. npm has no dev counterpart, as documents have none: a package is tested locally from the working copy. A dev build that packs the package into a tarball kept as a workflow artifact is added only when a repo needs it.

A Python service may publish only an image, a Python library only to PyPI, a Node command-line tool only to npm, and an application ships installers whatever builds it. The stack decides the tooling, the tests and the file that holds the version; the targets decide the release. A documentation site ([`docs-site.md`](docs-site.md)) and a website ([`website.md`](website.md)) are published otherwise and are not release targets.

## What the release workflow does

`.github/workflows/release.yml` fires on `push: tags: ['v*']` and runs:

1. `gate` (every other job `needs: gate`, so a failure ships nothing):
   - tag (minus `v`) equals the version in the repo's one version file, read in `git bump`'s order (`pyproject.toml`, `package.json`, `VERSION.txt`), and that version carries no dev marker: the promotion brings `develop`'s `.devN` placeholder onto `main`, and `git bump release` drops it before the tag,
   - the tagged commit is reachable from `origin/main` (release tags must come from `main`), and
   - the version is strictly greater than the previous tag (monotonic, see [`ci.md`](ci.md#version-checks)). A shared gate, rather than inline checks in one publish job, means a bad tag can't slip out through the job that didn't check.
2. The job of each of the repo's publish targets, in parallel:
   - `docker`: build + push to GHCR (`ghcr.io/parkviewlab/<repo>`), multi-arch `linux/amd64,linux/arm64`, tags `{{version}}`, `{{major}}.{{minor}}`, and `latest`.
   - `pypi`: `uv build`, then PyPI trusted publishing (OIDC, `environment: pypi`).
   - `npm`: npm trusted publishing (OIDC), with an optional scoped-alias publish.
   - `installers`: electron-builder on a macOS / Windows / Linux matrix, each leg uploading its installers as `installers-<os>`.
3. `changelog` (`needs:` the gate and every target job): runs `generate_changelog.py` `--mode=generate` against the tag (the one LLM call), switches to fresh `origin/main`, `--mode=insert`, commits `docs(changelog): v<new> [skip ci]` back to `main`, and creates the GitHub Release from the same body. Where the release builds installers, it downloads them first and attaches them to the Release.

The documents target replaces that last job with `release`, which creates the GitHub Release with GitHub's generated notes (the merged-PR titles since the previous tag, each with its link). It has no `changelog` job because the repo publishes no package and those notes already list what shipped, which is why the PR-title prefix still matters there. For hand-written notes, edit the Release after the workflow has created it (`gh release edit v<new> --notes-file …`). This handbook's own `release.yml` is the documents assembly, byte for byte.

Reference implementations, by target: paper-boxing (image; its three-image matrix is a documented slot), cogrind-workshop (PyPI), smalt-mcp (PyPI and image), jonobones (npm and image), pensa-grex (installers), and this handbook (documents).

## After the release: the back-merge cascade (mandatory)

A release leaves `main` with commits `develop` doesn't have — the `release v<new>` bump **and**, where the release has a `changelog` job, the workflow's `docs(changelog): v<new>` auto-commit. If you don't bring them back to `develop`, the *next* `develop → main` promotion conflicts on the version line every single time.

So, after a release:

1. **Wait for the whole workflow to go green** — including the `changelog` job (`gh run watch <id>`). The changelog commit lands *during* CI, after the tag push. (A documents repo has no `changelog` job, so nothing lands on `main` during CI; still wait for `release.yml` to go green before cascading.)
2. **Pull `main`** to pick up that auto-commit (a no-op where the release has no `changelog` job).
3. **Cascade down:** `main → develop` as a merge commit (`--no-ff`), then `develop → each open working branch`.

```bash
# in the <repo>-main worktree, after `gh run watch` shows the whole workflow green:
git pull --ff-only                                   # main picks up the changelog auto-commit, where there is one
git -C ../<repo>-develop pull --ff-only              # a PR may have landed while CI ran
git -C ../<repo>-develop merge --no-ff main -m "Back-merge: main → develop after $(git describe --tags --abbrev=0)" \
  && git -C ../<repo>-develop push
# repeat for each open working branch: git -C ../<repo>-<branch> merge develop
```

`--no-ff` is deliberate. A fast-forward would move `develop` onto `main`'s tip and replace `develop`'s first-parent history with `main`'s release ledger; the merge commit keeps `develop`'s first-parent chain as the per-feature ledger [`branching.md`](branching.md#tracking-when-a-feature-was-added) describes (one squash commit per feature, one back-merge per release). `-m` keeps the editor closed; when `develop` already equals `main`, git reports "Already up to date" and creates nothing.

The cascade is **manual on purpose** (a small number of commands at a moment the user is already at the keyboard; an auto-PR version was considered and declined).

## Development versioning

Between releases a repo's `develop` should carry an **honest pre-release version**, and an engineer should be able to cut a **dev build** on demand. A dev build is for local testing: a candidate that CI builds before the real release, to exercise in the lab, and never a version for others to use. It publishes the dev counterpart of each of the repo's targets that has one, and nothing else ([What a release publishes](#what-a-release-publishes)).

**1. The dev version names the *next* release, not the last one.** A dev suffix is a *pre-release* — it sorts **before** the version it's attached to:

```
0.3.0   <   0.3.1.dev0   <   0.3.1
```

So after shipping `0.3.0`, `develop` works toward `0.3.1.dev0` — above the last release, below the target. **Never** suffix a version you've already shipped: `0.3.0-dev` sorts *below* `0.3.0`, so pip/uv/Docker treat it as *older* than the release. Form: Python `X.Y.Z.devN` (PEP 440); **Node/Electron `X.Y.Z-devN`** (semver — `npm version` rejects the dotted PEP-440 form); the dev image carries the tag `dev` and the dev version as the version file holds it (`0.3.1.dev1`), never `latest`.

**2. Open the next cycle at release time.** The [back-merge cascade](#after-the-release-the-back-merge-cascade-mandatory) also bumps `develop`'s SoT to the next-patch placeholder `X.Y.(Z+1).dev0` (a direct push — exempt from `version-guard.yml`, like the back-merge itself). Feature PRs leave it unchanged, so the guard still passes; `develop` now reports e.g. `0.3.1.dev0` everywhere — `/admin/version`, a casual editable install, a deploy. *(A feature branch cut before the open-cycle trips the version-guard until it merges `develop` — the same sync the up-to-date rule already requires.)*

**3. Cut a dev build on demand — never per-merge.** When an engineer asks for one, `git dev-release` **asks the bump kind** (patch/minor/major) — re-pointing the target if it's now known to be a minor or major (e.g. `0.4.0.dev0`) — then sets the SoT to `<target>.devN` (incrementing `N` per build), pushes `develop`, and dispatches the dev-publish workflow. It publishes the dev counterpart of each target: the `dev` image on GHCR (+ `:X.Y.Z.devN`), `X.Y.Z.devN` on TestPyPI, unsigned installers as workflow artifacts. It creates **no `v*` tag**, so the real `release.yml` and its main-reachability gate are untouched. See [`ci.md`](ci.md) (`dev-release.yml`).

**4. The real release finalizes the cycle.** Promote `develop → main`, then **`git bump`** drops the `.devN` — the engineer just confirms the bump kind, as always. From the placeholder `0.3.1.dev0`: `git bump patch` → `0.3.1` (ship it); `git bump minor` → `0.4.0` (it was a feature release — re-points off the last tag); `git bump release` → `0.3.1` (ship exactly the declared target, no re-point). Then `git release` + push the tag as above; the monotonic gate passes (`0.3.1 > 0.3.0`).

**Documents repos skip the open cycle.** Nothing reads a documents repo's version between releases (no app, no package, no dev build), so `develop` keeps the last released version until the next `git bump` on `main`. Documents have no dev counterpart, so there is no dev build to cut.
