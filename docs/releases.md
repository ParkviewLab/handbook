<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Versioning & releases

## The version number has one source of truth

Every project keeps its version in **exactly one file**:

- **Python** → `pyproject.toml` `[project].version`
- **Node** → `package.json` `version`

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

Source: `jonobones/main/src/version.ts`.

> If you find the version duplicated somewhere, remove the duplicate and replace
> the read-site with the metadata lookup.

## Cutting a release

Releases are **tag-driven**: pushing a `v*` tag triggers CI, which publishes
everything. You never type a version on the `git tag` line — the `dev-tools`
helpers derive it from the source-of-truth file (see [`ci.md`](ci.md) for the
helpers' home).

```bash
# on the main worktree, after develop has been promoted to main (see below):
git bump <patch|minor|major|X.Y.Z>   # edits the SoT file, commits "release v<new>"
git release                          # annotated tag v<new>, derived from the SoT
git push --follow-tags               # the tag push fires the release workflow
```

- **`git bump`** bumps the version (Python: via `uv version --bump`), stages the
  change (+ `uv.lock` if touched), and commits `release v<new>`. It does **not**
  tag.
- **`git release`** reads the version back out and makes the annotated tag
  `v<version>`. It refuses on a dirty tree or an existing tag. It does **not**
  push.
- **Default bump kind:** *minor* for new surface, *patch* for fix-only — but if
  the user didn't specify, **ask** (see [`ai-collaboration.md`](ai-collaboration.md)).

### Branch roles & why bump+tag on `main`

`main` is the **release-only surface**; `develop` is the integration trunk
(see [`branching.md`](branching.md)). The bump+tag happens on `main` because:
clean working-branch history (no release mechanics on feature branches), a
deliberate "I'm shipping" moment, and the tag is trivially reachable from
`origin/main` so the CI gate passes by construction.

Promotion is `develop → main` via `gh pr merge --merge` (merge-commit
convention); pulls use `git pull --ff-only`.

## What the release workflow does

`.github/workflows/release.yml` fires on `push: tags: ['v*']` and runs:

1. **`gate`** (both publish jobs `needs: gate`, so a failure ships nothing):
   - tag (minus `v`) **==** the source-of-truth version, and
   - the tagged commit is **reachable from `origin/main`** (release tags must
     come from `main`).
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

Reference implementations: `deco-assaying/.../release.yml` (Python/PyPI),
`jonobones/main/.github/workflows/release.yml` (Node/npm).

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
# after `gh run watch` shows the whole workflow (incl. changelog) green:
git -C ../main pull --ff-only
git -C ../develop merge main && git -C ../develop push
# repeat develop → <branch> for each open working branch
```

The cascade is **manual on purpose** (a small number of commands at a moment the
user is already at the keyboard; an auto-PR version was considered and declined).

## Dev releases vs real releases — PROPOSED

> **Current state:** there is a single release tier — a `v*` tag from `main`
> produces a real release. There is **no** `develop`-triggered prerelease today.
> Pre-release/RC tags from `develop` were considered and deferred (the gate's
> reachability check would have to relax for `*-rc*` / `*.devN` tag shapes).
>
> **Proposed (not yet built — do not add CI for this without explicit
> go-ahead):** keep real releases exactly as above, and add an *optional*
> dev-release path where a push/merge to `develop` publishes a prerelease — e.g.
> a GHCR `:dev` / `:develop` image tag, and optionally `X.Y.Z.devN` to TestPyPI.
> This would make "merge to develop → dev release; merge to main → real release"
> real. Revisit when the need is concrete.
