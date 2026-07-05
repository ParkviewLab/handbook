<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Versioning & releases

## The version number has one source of truth

Every project keeps its version in **exactly one file**:

- **Python** → `pyproject.toml` `[project].version`
- **Node** → `package.json` `version`
- **Docs / other (no package manifest)** → a top-level `VERSION.txt` file (one
  line, e.g. `0.1.0`). This handbook uses one.

Two hard rules follow:

### 1. Nothing duplicates the version

No second copy anywhere that can drift — not in `__init__.py`, `setup.py`/`setup.cfg`,
a module constant, a hard-coded CLI `--version` string, a docs/README badge, or a
Dockerfile `LABEL`. If something needs the version, it **derives** it from the one
source. (Badges pull from PyPI/release tags; the Docker label is stamped by the
release workflow's metadata-action.)

### 2. The running app reads the version from that source at runtime

When an app displays its version, it reads it from package metadata — never a
literal baked into the code.

**Python** — `importlib.metadata`, with a fallback for editable/uninstalled runs,
re-exported as `__version__`:

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

Source: `deco-assaying/.../config.py` + `__init__.py` (mirrored in smalt-mcp,
flint-slating, ebony-enriching). The `/health` and `/admin/version`
endpoints surface this same `VERSION` (see
[`mcp-server-conventions.md`](mcp-server-conventions.md)).

**Node** — read `package.json` at runtime:

```ts
// src/version.ts
import { createRequire } from 'node:module';
const pkg = createRequire(import.meta.url)('../package.json') as { version: string };
export const VERSION = pkg.version;
```

Source: jonobones's `src/version.ts`.

> If you find the version duplicated somewhere, remove the duplicate and replace
> the read-site with the metadata lookup.

## Cutting a release

Releases are **tag-driven**: pushing a `v*` tag triggers CI, which publishes
everything. You never type a version on the `git tag` line — the `dev-tools`
helpers derive it from the source-of-truth file (see [`ci.md`](ci.md) for the
helpers' home).

```bash
# in the <repo>-main worktree — the whole release runs from the CLI under one authorisation:
git pull --ff-only                   # sync main
git -C ../<repo>-develop pull --ff-only   # sync develop too — see the caution below
git merge --no-ff develop            # promote develop→main; the merge commit is the release ledger entry
git bump <patch|minor|major|release|X.Y.Z>   # edits the SoT file, commits "release v<new>"
git release                          # annotated tag v<new>, derived from the SoT
git push --follow-tags               # the tag push fires the release workflow
```

> **Sync `develop` before you promote.** `git merge --no-ff develop` merges the *local*
> `develop` worktree, not `origin/develop`. After a PR **squash-merges on GitHub**, that
> local worktree is stale, so the merge quietly promotes and tags a commit that omits the
> merged work. The `git -C ../<repo>-develop pull --ff-only` line above closes the gap;
> skip it and you ship the wrong commit. (This is why the layout sets branch upstream
> tracking at creation — see [`repo-layout.md`](repo-layout.md#creating-the-layout).)

- **`git bump`** bumps the version in the source of truth (`pyproject.toml` /
  `package.json` / `VERSION.txt`, auto-detected), stages the change (+ lockfile if
  touched), and commits `release v<new>`. It does **not** tag. `git bump release`
  finalizes a dev cycle (drops the `.devN`) — see
  [Development versioning](#development-versioning).
- **`git release`** reads the version back out and makes the annotated tag
  `v<version>`. It refuses on a dirty tree or an existing tag. It does **not**
  push.
- **Choosing the bump kind:** the releaser **reviews the changes since the last
  release, proposes** major / minor / patch with a one-line rationale, and the
  **engineer confirms** before `git bump`. The Conventional Commit types in the
  range are the signal — any breaking change → **major**, any `feat:` → **minor**,
  otherwise (`fix:`/`perf:`) → **patch**. Never bump silently; never infer the kind
  from past cadence. See [`ai-collaboration.md`](ai-collaboration.md).
- **Docs-only / `VERSION.txt` repos have no Conventional-Commit signal** (it's all
  docs), so choose the bump by the **significance** of the change: a whole new
  convention or section → **minor**; a clarification, correction, or typo →
  **patch**; removing or reversing an established convention → **major**. (This
  handbook's v0.4.0 was a minor — it added the dual-license layout.)
- **`VERSION.txt`-file repos** (no `pyproject`/`package.json`, e.g. this handbook):
  `git bump`/`git release` are **SoT-aware** — they detect `VERSION.txt` and bump /
  tag from it just like a `pyproject` repo, so docs repos release with the same
  tooling, no hand-editing.

### Version rules

- **Feature work never changes the version.** A PR into `develop` must not touch the
  version source-of-truth file; the bump happens only at release, on `main`. A CI
  check on `develop` PRs enforces this — see [`ci.md`](ci.md#version-checks).
- **The version only ever increases.** The release gate rejects a tag whose version
  isn't **strictly greater** than the last released one — a guard against forgetting
  to bump or going backwards (see [`ci.md`](ci.md#version-checks)).

### Branch roles & why bump+tag on `main`

`main` is the **release-only surface**; `develop` is the integration trunk
(see [`branching.md`](branching.md)). The bump+tag happens on `main` because:
clean working-branch history (no release mechanics on feature branches), a
deliberate "I'm shipping" moment, and the tag is trivially reachable from
`origin/main` so the CI gate passes by construction.

Promotion is `develop → main` done **from the CLI** with `git merge --no-ff
develop` — a merge commit, so `git log --first-parent main` is a dated per-release
ledger (see [`branching.md`](branching.md)). It is **not** a reviewed PR: the repo
is squash-only, so this merge commit is made locally as part of the release, and a
single release authorisation covers it (see
[`ai-collaboration.md`](ai-collaboration.md)). Pulls use `git pull --ff-only`.

## What the release workflow does

`.github/workflows/release.yml` fires on `push: tags: ['v*']` and runs:

1. **`gate`** (both publish jobs `needs: gate`, so a failure ships nothing):
   - tag (minus `v`) **==** the source-of-truth version,
   - the tagged commit is **reachable from `origin/main`** (release tags must
     come from `main`), and
   - the version is **strictly greater than the previous tag** (monotonic — see
     [`ci.md`](ci.md#version-checks)).
   A shared gate — rather than inline checks in one publish job — means a bad tag
   can't slip out through the job that didn't check.
2. **`docker`** — build + push to GHCR (`ghcr.io/parkviewlab/<repo>`), multi-arch
   `linux/amd64,linux/arm64`, tags `{{version}}`, `{{major}}.{{minor}}`, and
   `latest`.
3. **publish** — Python: `uv build` → PyPI trusted publishing (OIDC,
   `environment: pypi`). Node: npm trusted publishing.
4. **`changelog`** (`needs: [gate, docker, pypi]`) — runs `generate_changelog.py`
   `--mode=generate` against the tag (the one LLM call), switches to fresh
   `origin/main`, `--mode=insert`, commits `docs(changelog): v<new> [skip ci]`
   back to `main`, and creates the GitHub Release from the same body.

**Electron apps diverge:** no GHCR image — the middle is a macOS/Windows/Linux build
matrix (electron-builder), and the `changelog` job attaches the OS installers to the
GitHub Release. See [`electron-tooling.md`](electron-tooling.md).

**Pure CLI/library packages diverge too:** a package that ships no container image (e.g.
`cogrind-workshop`) drops the `docker` job entirely — from `release.yml` and, if present,
`dev-release.yml` — leaving only `gate` → `publish` → `changelog`. Trim the job from the
template; no separate template is needed.

Reference implementations: deco-assaying's `release.yml` (Python/PyPI) and
jonobones's `.github/workflows/release.yml` (Node/npm).

## After the release: the back-merge cascade (mandatory)

A release leaves `main` with commits `develop` doesn't have — the `release v<new>`
bump **and** the workflow's `docs(changelog): v<new>` auto-commit. If you don't
bring them back to `develop`, the *next* `develop → main` promotion conflicts on
the version line every single time.

So, after a release:

1. **Wait for the whole workflow to go green** — including the `changelog` job
   (`gh run watch <id>`). The changelog commit lands *during* CI, after the tag
   push.
2. **Pull `main`** to pick up that auto-commit.
3. **Cascade down:** `main → develop`, then `develop → each open working branch`.

```bash
# in the <repo>-main worktree, after `gh run watch` shows the whole workflow green:
git pull --ff-only                                   # main picks up the changelog auto-commit
git -C ../<repo>-develop merge main && git -C ../<repo>-develop push
# repeat for each open working branch: git -C ../<repo>-<branch> merge develop
```

The cascade is **manual on purpose** (a small number of commands at a moment the
user is already at the keyboard; an auto-PR version was considered and declined).

## Development versioning

Between releases `develop` should carry an **honest pre-release version**, and an engineer should be
able to cut a **dev build** on demand — to exercise a candidate in real settings before the real
release.

**1. The dev version names the *next* release, not the last one.** A dev suffix is a *pre-release* —
it sorts **before** the version it's attached to:

```
0.3.0   <   0.3.1.dev0   <   0.3.1
```

So after shipping `0.3.0`, `develop` works toward `0.3.1.dev0` — above the last release, below the
target. **Never** suffix a version you've already shipped: `0.3.0-dev` sorts *below* `0.3.0`, so
pip/uv/Docker treat it as *older* than the release. Form: Python `X.Y.Z.devN` (PEP 440);
**Node/Electron `X.Y.Z-devN`** (semver — `npm version` rejects the dotted PEP-440 form);
`VERSION.txt` / Docker `X.Y.Z-dev` / a `:dev` tag.

**2. Open the next cycle at release time.** The
[back-merge cascade](#after-the-release-the-back-merge-cascade-mandatory) also bumps `develop`'s SoT
to the next-patch placeholder `X.Y.(Z+1).dev0` (a direct push — exempt from `version-guard.yml`, like
the back-merge itself). Feature PRs leave it unchanged, so the guard still passes; `develop` now
reports e.g. `0.3.1.dev0` everywhere — `/admin/version`, a casual editable install, a deploy. *(A
feature branch cut before the open-cycle trips the version-guard until it merges `develop` — the same
sync the up-to-date rule already requires.)*

**3. Cut a dev build on demand — never per-merge.** When an engineer asks for one, `git dev-release`
**asks the bump kind** (patch/minor/major) — re-pointing the target if it's now known to be a minor or
major (e.g. `0.4.0.dev0`) — then sets the SoT to `<target>.devN` (incrementing `N` per build), pushes
`develop`, and dispatches the dev-publish workflow. It publishes a **pre-release**: a GHCR **`:dev`**
image (+ `:X.Y.Z.devN`) and `X.Y.Z.devN` to **TestPyPI**. It creates **no `v*` tag**, so the real
`release.yml` and its main-reachability gate are untouched. See [`ci.md`](ci.md) (`dev-release.yml`).

**4. The real release finalizes the cycle.** Promote `develop → main`, then **`git bump`** drops the
`.devN` — the engineer just confirms the bump kind, as always. From the placeholder `0.3.1.dev0`:
`git bump patch` → `0.3.1` (ship it); `git bump minor` → `0.4.0` (it was a feature release —
re-points off the last tag); `git bump release` → `0.3.1` (ship exactly the declared target, no
re-point). Then `git release` + push the tag as above; the monotonic gate passes (`0.3.1 > 0.3.0`).

**`VERSION.txt` / docs repos** carry the same honest `X.Y.Z-dev` on `develop` and finalize at release,
but publish **no** dev artifacts (nothing to build) — the dev *build/publish* path is code-repo-only.
