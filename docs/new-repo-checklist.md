<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# New-repo checklist

The master sequence for bootstrapping a new ParkviewLab repo into every convention. Each step links to the doc with the detail.

> **If it's a website** (static site on GitHub Pages — e.g. parkviewlab.ai), follow the lighter path in [`website.md`](website.md): contained worktrees named **`live`/`staging`** (default branch `staging`); Pages via Actions; REUSE with `LicenseRef-AllRightsReserved` + the bundled font's license; `reuse-website.yml`
> + `pages-deploy.yml`; the page footers (copyright + "updated on" date) + a stamp step + a local preview script. **Skip §2 (language scaffold), §3 (targets and packaging), and §8 (first release) entirely** — a website has no version, tags, or PyPI/Docker publish; "publishing" is promoting `staging`→`live`. §1, §5 (licensing), §6 (docs), and §7 (AI pointers) still apply, adapted as `website.md` describes.

## 1. Name & create

- [ ] Pick a name in the house style — mineral/pigment + gerund (or `-mcp`). See [`repo-layout.md`](repo-layout.md#repo-naming).
- [ ] Create the GitHub repo under `ParkviewLab/`.
- [ ] Set up the local **contained, repo-prefixed worktree** layout (`<repo>.git` + `<repo>-main` + `<repo>-develop`). See [`repo-layout.md`](repo-layout.md#creating-the-layout).
- [ ] Make `develop` the GitHub default branch (PRs target integration).
- [ ] Configure **squash-only** merge settings (squash on; merge-commit + rebase off; `squash_merge_commit_title=PR_TITLE`; auto-delete branches). See [`ci.md`](ci.md#repo-merge-settings).

## 2. Language scaffold

> **If it's a Node repo**, use the Node stack instead of the Python one below: `package.json` from [`templates/package.json.template`](../templates/package.json.template), TypeScript + ESLint + Vitest, version read at runtime via `src/version.ts` — see [`node-tooling.md`](node-tooling.md). §3–§8 still apply, and §3 decides what the repo publishes.

> **If it's an Electron desktop app**, use the Electron stack: the app at the repo **root** (`package.json` + `src/{main,preload,renderer}` + `electron.vite.config.js`
> + `electron-builder.yml`), electron-vite + electron-builder, plain JS **or** TS — see [`electron-tooling.md`](electron-tooling.md). An app that ships OS installers takes the installers target in §3 and §4.

- [ ] `pyproject.toml` from [`templates/pyproject.toml.template`](../templates/pyproject.toml.template) — name, description, deps; src-layout; ruff/ty/pytest config; `.python-version` = `3.13`. See [`python-tooling.md`](python-tooling.md).
- [ ] If it's an MCP server: the `src/<pkg>/` skeleton (`config.py`, `__main__.py`, `server.py`, `tools.py`, `schema.py`) with `/health` + `/admin/version` and `--transport`. See [`mcp-server-conventions.md`](mcp-server-conventions.md).
- [ ] Version read from package metadata at runtime — no literal. See [`releases.md`](releases.md).
- [ ] `tests/` + `conftest.py` (session-scoped client if MCP); pytest markers. See [`testing.md`](testing.md).

## 3. Targets and packaging

- [ ] Decide what the product publishes: one or several of the five targets in [`releases.md`](releases.md#what-a-release-publishes) (an image on GHCR, a package on PyPI, a package on npm, installers, documents). The workflows in §4 and the publishers in §5 follow from this.
- [ ] Each target's packaging: `Dockerfile` (uv base, `/data` volume, `CMD python -m <pkg>`) and `docker-compose.yml` (CHANGE-ME env, named volume) for the image, see [`packaging-and-deployment.md`](packaging-and-deployment.md); the `pyproject.toml` build for PyPI, see [`python-tooling.md`](python-tooling.md); `package.json`'s `files` and `bin` for npm, see [`node-tooling.md`](node-tooling.md); `electron-builder.yml` for installers, see [`electron-tooling.md`](electron-tooling.md).
- [ ] README in the house shape, with the run section for the repo's targets and the Configuration env-var table. See [`documentation.md`](documentation.md).

## 4. Changelog & CI

- [ ] `cliff.toml` — copy **verbatim** from [`templates/cliff.toml`](../templates/cliff.toml).
- [ ] `scripts/generate_changelog.py` from [`templates/generate_changelog.py`](../templates/generate_changelog.py).
- [ ] Workflows from [`templates/.github/workflows/`](../templates/.github/workflows/): `reuse.yml` + `version-guard.yml` (**every** repo); the test workflow of the repo's stack (`test.yml`, or `test-node.yml` / `test-electron.yml`); `license-check.yml` where the repo's license requires it; `release.yml`, assembled from the parts of the repo's targets, and optionally `dev-release.yml`, assembled from their dev parts. A documents repo has neither a test workflow nor a dev workflow, and needs no `cliff.toml` or `generate_changelog.py`. Pin actions exactly; GHCR tags include `latest`. See [`ci.md`](ci.md#releaseyml--on-v-tag-push).
- [ ] **Branch protection on `develop`:** mark the workflow checks as **required status checks** (so the merge button waits for green); **let admins bypass** so the release back-merge/promotion (direct pushes) aren't blocked. See [`ci.md`](ci.md#required-checks-before-merge).
- [ ] **Branch protection on `main`:** block force pushes and deletions, nothing else (no required checks or reviews: the release flow pushes directly). See [`ci.md`](ci.md#repo-merge-settings).
- [ ] Confirm the org `ANTHROPIC_API_KEY` secret is inherited.
- [ ] Configure one **trusted publisher** per registry target: PyPI (workflow `release.yml`, environment `pypi`) and, where the repo has dev builds, TestPyPI (`dev-release.yml`, `testpypi`); npm (`release.yml`). The image, installers and documents targets need none.

## 5. Licensing

- [ ] Choose the repo's license (per-repo decision).
- [ ] `LICENSE` (root, for GitHub detection), `LICENSING.md` ([template](../templates/LICENSING.md.template)), `LICENSES/` texts, `REUSE.toml` ([template](../templates/REUSE.toml.template)) with the per-bucket split. Per-file SPDX headers on source. See [`licensing.md`](licensing.md).
- [ ] `reuse lint` green: `uvx --from "reuse[charset-normalizer]" reuse lint`.

## 6. Docs

- [ ] _(optional)_ `docs/northstar.md` from [`templates/northstar.md`](../templates/northstar.md) (complementary intents → axioms → "what it is not") — the author's choice. See [`documentation.md`](documentation.md).
- [ ] Optionally an AI-authored `docs/northstar.html` per [`md-to-html.md`](md-to-html.md).
- [ ] `docs/in-flight_ideas.md` started.
- [ ] `docs/CONTRIBUTING.md` from [`templates/CONTRIBUTING.md`](../templates/CONTRIBUTING.md).
- [ ] _(optional, public repos)_ Publish `docs/` as a site at `parkviewlab.github.io/<repo>/`: `pages-docs.yml` (it checks out `dev-tools` and runs its `build-pages-site`; no script of the repo's own), an optional `site/intro.html` and, for styling of the repo's own, `site/shell.html`, Pages source = Actions, and the `github-pages` environment restricted to `main`; after the release that first publishes the site, the README's `Documentation:` line in its own pull request. Record the new `site/**` tree's licensing in `REUSE.toml` (the `reuse` check fails otherwise), and author `docs/northstar.html` — without it the index opens with a Markdown link the browser shows as source text. See [`docs-site.md`](docs-site.md).
- [ ] Visible copyright footer on published/standalone docs (HTML footers, root README, northstar) — bottom of file, consistent with the SPDX header. See [`documentation.md`](documentation.md#copyright-footers).

## 7. AI pointers

- [ ] Run `scripts/sync-agent-files.sh` (from the handbook) to write `AGENTS.md` + `CLAUDE.md`. See [`ai-collaboration.md`](ai-collaboration.md).

## 8. First release

- [ ] `git bump` → `git release` → `git push --follow-tags` (from `main`).
- [ ] `gh run watch` until the whole workflow, including the job that creates the Release, is green.
- [ ] Back-merge cascade `main → develop → working branches`. See [`releases.md`](releases.md).
