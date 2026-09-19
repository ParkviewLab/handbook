<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Documentation sites

A public repo may publish **its own `docs/`** as a small website at `https://parkviewlab.github.io/<repo>/`, built and deployed by GitHub Actions on every push to `main`. `pensa-grex` is the **pilot** and the reference for the published shape (the address, `main` only, the two failure modes); its site is at <https://parkviewlab.github.io/pensa-grex/>.

This is **not** a [website repo](website.md). A website repo *is* a site (`parkviewlab.ai`), with `live`/`staging` trunks, a custom domain, and no release ceremony. A documentation site is one facility of an ordinary two-trunk code repo, which keeps its `main`/`develop`, its tags, and its release flow unchanged. It adds a workflow, two repository settings and, optionally, an introduction and a page shell under `site/`.

## The address and the shape

The site has three parts, all served from `https://parkviewlab.github.io/<repo>/`:

- **A generated index at the root** — the repo's introduction plus a list of every document in `docs/`. Assembled at deploy time; never committed.
- **`/docs/` — the repo's `docs/` directory, byte-identical** to what the repository holds, plus a generated `index.html` in each subfolder that holds documents (see below).
- **Any hand-built extra pages**, each in its own folder. `pensa-grex` has a themed download page at `/downloads/`, sharing `/assets/` with the index.

The hand-built pages and their assets live under `site/` in the repo (`site/intro.html`, a `site/shell.html` where the repo has styling of its own, `site/downloads/index.html`, `site/assets/`), and `site/` as a whole is optional; `docs/` stays exactly what it is for a reader of the repository.

## Published from `main` only

This is the decision the rest follows from. The workflow triggers on **push to `main`** and checks `main` out explicitly (`ref: main`), and the `github-pages` environment's **deployment branch policy lists `main` and nothing else** — a repository setting, changed once. A `workflow_dispatch` run from another branch therefore cannot publish it.

Because `main` advances only at a release ([`branching.md`](branching.md)), **what the site says is what the newest release ships**. That is the point: a visitor reading the documentation site is reading the documentation for the version they can download.

The deploy fires on the release push (the promotion, bump, and tag) and **not** on the changelog commit CI makes afterwards, which carries `[skip ci]` ([`ci.md`](ci.md#releaseyml--on-v-tag-push)). So the published site is built from the release commit, before that changelog commit lands on `main`.

The cost is explicit, and worth stating before adopting it:

- **A docs-only change goes public through a release.** Merging it into `develop` does not publish it.
- **For a desktop app with an update check, an urgent doc fix is not cheap** — it costs a rebuild of every installer and an update notice to installed copies. Weigh that before treating the site as the only home for a correction; GitHub's rendered view of `develop` is always available in the meantime.
- **Whatever `main` holds is published, stale or not.** A pre-release sentence ("no image has been published yet"), an open question that was answered, or a work plan left in a design document ships as the release's documentation. The release preflight therefore includes the currency check ([`agents.md`](agents.md)), and a stale statement is fixed on `develop` before the promotion rather than corrected by a second release ([`documentation.md`](documentation.md#documents-and-records)).

### Enabling it on a repo

Four steps, once per repo:

```bash
# 1. Pages builds from the Actions workflow, not from a served branch.
#    POST creates the site where Pages has never been enabled;
#    PUT updates an existing one (POST answers 409 if it exists).
gh api -X POST repos/ParkviewLab/<repo>/pages -f build_type=workflow
gh api -X PUT  repos/ParkviewLab/<repo>/pages -f build_type=workflow

# 2. The github-pages environment may deploy from main and nothing else
#    (Settings → Environments → github-pages → deployment branches: main).

# 3. Add the workflow (the template below) and, for an introduction, site/intro.html; release.

# 4. After the release that first publishes the site: the README line (below),
#    in its own pull request. Never in the pull request that adds the workflow.
```

The workflow template is [`templates/.github/workflows/pages-docs.yml`](../templates/.github/workflows/pages-docs.yml); it checks out `dev-tools` at a released tag into `dev-tools/`, a subfolder of the checkout, and runs the shared build script, so the adopting repo commits no script of its own.

**The README line.** A first-time visitor lands on the repository, not on the site, so the README says where the documentation is, on its own line directly under the title and the one-line description, per [`documentation.md`](documentation.md#readme-shape): `Documentation: https://parkviewlab.github.io/<repo>/`. It goes in after the release that first publishes the site, in its own pull request ([below](#a-readme-that-links-to-addresses-the-release-has-not-published-yet)). `convention-auditor` reports a publishing repo whose README lacks the line, and a line whose address does not answer.

## The generated index

**One committed fragment, everything else derived.** The hand-written introduction, where the repo has one, is a fragment of HTML (`site/intro.html` — paragraphs, no `<html>`/`<head>`/`<body>`); the rest of the index is read off the documents themselves at build time:

- An **HTML document's** title comes from its `<title>`, and its description from `<meta name="description">` when present.
- A **Markdown document's** title comes from its first `# ` heading.

The documents are listed in five groups, in this order:

1. **Northstar** — `northstar.html` if present, else `northstar.md`.
2. **HTML documents** — the designed twins and standalone studies.
3. **Specifications and notes** — the Markdown documents.
4. **Ideas under consideration** — `in-flight_ideas.md` and `*_ideas.md`.
5. **Contributing** — `CONTRIBUTING.md`.

**A Markdown document with an HTML twin is listed once**, under the twin, with a small "Markdown source" link beside it. Within a group, order by title.

**Every subfolder that holds documents gets a generated index too.** Pages serves no directory listings, so a folder without an `index.html` answers 404 — a link to `/docs/<folder>/` would break. A folder that ships its own `index.html` keeps it; the build leaves that one alone. A folder holding no documents (assets only) gets no index and is not linked to.

**A published index with no `docs/northstar.html` opens with a Markdown link** — group 1 falls back to `northstar.md`, which the site serves as plain text (below), so the first thing a visitor clicks shows them source. That is the practical reason a publishing repo authors the designed twin ([`md-to-html.md`](md-to-html.md)); the northstar itself remains the author's choice ([`documentation.md`](documentation.md#the-northstar)).

### Markdown links

GitHub Pages serves a `.md` file as **plain text**, so a Markdown document with no HTML twin is not worth linking to on the site itself. Link it instead to **GitHub's rendered view, pinned to the release tag**: `https://github.com/ParkviewLab/<repo>/blob/vX.Y.Z/docs/<file>.md`. Pinning to the tag, not to `main`, keeps the reader on the version the site is publishing. The "Markdown source" link beside a twin goes to the same place.

These generated links are the one place an absolute same-repo URL is right: they are emitted by the build, pinned to a tag, and point at a rendering the site cannot serve itself.

## Links between a repo's own documents

The rule — **a link to a file in the repo's own tree is relative**, to the `.html` twin where one exists, otherwise to the `.md` — is in [`documentation.md`](documentation.md#links-between-a-repos-own-documents), because it binds every repo whether or not it publishes.

It matters more on a published site. The same document is then readable in three places (a working tree, GitHub's blob view, the site), and only a relative link resolves correctly in all three; an absolute one takes a reader of the site back to GitHub, out of the version they were reading. The one exception is the tag-pinned link above, which the build emits precisely because the site cannot render Markdown.

## The build script

The script is shared: `build-pages-site` in [`ParkviewLab/dev-tools`](https://github.com/ParkviewLab/dev-tools) (its README documents the command). The mechanics (the folder scan, twin pairing, grouping, tag resolution, the stamp, and the link check) are one implementation there; the page shell is the one per-repo part. Two hand-written implementations of the same mechanics is the duplication axiom 1 exists to prevent.

The **page shell** is the styling around the generated index: fonts, palette, top bar, hero and footer. A repo passes its own with `--shell site/shell.html`, an HTML file with named placeholders the script substitutes (the placeholder set is in the command's docstring and the dev-tools README); without one, a built-in shell in the ParkviewLab brand is used. A repo with styling of its own (a Googie theme, for one) keeps it as `site/shell.html` and passes it; a repo with none passes nothing. The introduction stays `site/intro.html`, and `site/` itself is optional: a repo with neither publishes its `docs/` alone under the default shell.

### The CLI contract

The shipped workflow hard-codes it, so it is fixed; the template's two per-repo slots are the `--shell` argument and the `ref:` of the dev-tools checkout:

```bash
python3 dev-tools/scripts/build-pages-site --out DIR [--tag vX.Y.Z] [--shell FILE] [--repo DIR]
```

- **`--out DIR` is required** — the directory the whole site is assembled into, new or empty.
- **`--tag vX.Y.Z` is optional**, for a local trial run; the build otherwise resolves the tag itself (below).
- **`--shell FILE` is optional**, the repo's page shell; absent, the brand default.
- **`--repo DIR` is optional**, the repository to build; absent, the current directory, which is where the workflow runs. The `dev-tools` checkout in a subfolder is not read.

The workflow checks `dev-tools` out at a **released tag** into `dev-tools/`, a subfolder of the checkout, and runs the command above from the repo root; the template carries the tag (its `ref:`), and a repo with a shell appends `--shell site/shell.html` to the build step. The tag is pinned so that a change to the script never reaches a site unreviewed; bumping it is a one-line change in the adopting repo, made on this pin's own occasions and not with the changelog job's pin. This is one of two places a workflow reads another ParkviewLab repo, each at an exact release; the other is the release workflow's changelog job, which runs dev-tools' `generate-changelog` ([`commits-and-changelogs.md`](commits-and-changelogs.md)). The pin is what keeps each within the northstar's rule against depending on another repo's state: an exact release is a locked dependency, not a live one, as long as what the pin names cannot change, and [`ci.md`](ci.md#shared-dev-scripts-dev-tools) states what keeps this tag in place. Run the same command locally before pushing (`build-pages-site` is on `PATH` once dev-tools' `install.sh` has run) and open the result with `python3 -m http.server`.

### What it must guarantee

- **Standard library only.** No dependency install in the deploy path.
- **Nothing generated is committed.** The script assembles into `--out` (refusing a directory that is non-empty, or inside `site/`/`docs/`), and the workflow uploads that directory. There is no Jekyll or other build system in the path.
- **It fails the build** when a document has **no title**, when a **placeholder survives the stamp** (the release tag substituted into a hand-built page), or when a **link in a page it generated or stamped does not resolve** against the assembled directory. That check covers every relative `href` and `src`, and every CSS `url()` inside a `<style>` element, in those pages.
- **It only reports** an unresolved reference inside an **HTML** document copied from `docs/`. Those are published exactly as the repository holds them, so a broken reference of their own is a defect to fix in that document, not a reason to withhold the whole site. **Copied Markdown is not link-checked at all** — GitHub renders it, and its links are checked where the repo is read, not where it is published.
- **It pins every GitHub link to one release tag**, taken from `git describe --tags --abbrev=0 --match 'v[0-9]*'` unless `--tag` overrides it, which is why the workflow checks out with `fetch-depth: 0`.

### What it must not do

**Do not make a late tag fatal** — we got this wrong once. The script takes the newest `v*` tag *reachable from HEAD*, and cannot tell whether that tag is **this** release's or the **previous** one: a run that somehow started before the tag landed would stamp the previous release and publish successfully. That leniency is wanted, because a manual re-run sits on the changelog commit rather than on the tagged one and must still build. What the script *does* detect is a repository with **no `v*` tag at all**, which refuses to publish. If a deployment ever does stamp a stale version, re-run the workflow by hand once the tag is in place. (`git push --follow-tags` sends the branch and its tag together, so in the normal release flow the tag is on the runner before the build reads it.)

## The two failure modes from the pilot

### A README that links to addresses the release has not published yet

**The repo's README is public on GitHub as soon as the change reaches the default branch** — for a repo defaulting to `develop`, that is the moment a PR merges, long before the release that publishes the site. (A repo still defaulting to `main` is spared this one: its README goes public with the release itself.) So a README edited to point at `/downloads/` or at the documentation site shows **broken links to everyone** in the window between that merge and the release. In the pilot this cost two extra pull requests: one to hold the links at what was actually live, and one to move them forward once the site was up.

**The rule: links to not-yet-published site addresses wait.** They move in a pull request merged *after* the release that publishes the site, never in the feature pull request that builds the thing they point at.

### A URL compiled into the application

A URL constant built into a shipped binary (`pensa-grex` has `DOWNLOAD_URL` in `src/main/update.js`) reaches users **only in the next release**, and installed copies keep using the old address indefinitely. So **the old address must keep working** after the site changes shape. That is why the site's root page carries the Downloads link prominently: an old build that sends a user to the repository root, or to the site root, must still land them somewhere that gets them the installer.

The general form: **treat any address an already-shipped artifact points at as permanent**, and make the new site a superset of what the old links expected.
