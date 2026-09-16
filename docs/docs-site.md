<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Documentation sites

A public repo may publish **its own `docs/`** as a small website at `https://parkviewlab.github.io/<repo>/`, built and deployed by GitHub Actions on every push to `main`. `pensa-grex` is the **reference implementation** of everything below; its site is at <https://parkviewlab.github.io/pensa-grex/>.

This is **not** a [website repo](website.md). A website repo *is* a site (`parkviewlab.ai`), with `live`/`staging` trunks, a custom domain, and no release ceremony. A documentation site is a facility bolted onto an ordinary two-trunk code repo: same `main`/`develop`, same tags, same releases. The only thing it adds is a workflow, a build script, and one repository setting.

## The address and the shape

The site has three parts, all served from `https://parkviewlab.github.io/<repo>/`:

- **A generated index at the root** — the repo's introduction plus a list of every document in `docs/`. Assembled at deploy time; never committed.
- **`/docs/` — the repo's `docs/` directory, byte-identical** to what the repository holds, plus a generated `index.html` in each subfolder (see below).
- **Any hand-built extra pages**, each in its own folder. `pensa-grex` has a themed download page at `/downloads/`, sharing `/assets/` with the index.

The hand-built pages and their assets live under `site/` in the repo (`site/intro.html`, `site/downloads/index.html`, `site/assets/`); `docs/` stays exactly what it is for a reader of the repository.

## Published from `main` only

This is the decision the rest follows from. The workflow triggers on **push to `main`** and checks `main` out explicitly (`ref: main`), and the `github-pages` environment's **deployment branch policy lists `main` and nothing else** — a repository setting, changed once. A `workflow_dispatch` run from another branch therefore cannot publish it.

Because `main` advances only at a release ([`branching.md`](branching.md)), **what the site says is what the newest release ships**. That is the point: a visitor reading the documentation site is reading the documentation for the version they can download.

The cost is explicit, and worth stating before adopting it:

- **A docs-only change goes public through a release.** Merging it into `develop` does not publish it.
- **For a desktop app with an update check, an urgent doc fix is not cheap** — it costs a rebuild of every installer and an update notice to installed copies. Weigh that before treating the site as the only home for a correction; GitHub's rendered view of `develop` is always available in the meantime.

### Enabling it on a repo

Three steps, once per repo:

```bash
# 1. Pages builds from the Actions workflow, not from a served branch:
gh api -X PUT repos/ParkviewLab/<repo>/pages -f build_type=workflow

# 2. The github-pages environment may deploy from main and nothing else
#    (Settings → Environments → github-pages → deployment branches: main).

# 3. Add the workflow and the build script (below), and release.
```

The workflow template is [`templates/.github/workflows/pages-docs.yml`](../templates/.github/workflows/pages-docs.yml).

## The generated index

**One committed fragment, everything else derived.** The hand-written introduction is a fragment of HTML (`site/intro.html` — paragraphs, no `<html>`/`<head>`/`<body>`); the rest of the index is read off the documents themselves at build time:

- An **HTML document's** title comes from its `<title>`, and its description from `<meta name="description">` when present.
- A **Markdown document's** title comes from its first `# ` heading.

The documents are listed in five groups, in this order:

1. **Northstar** — `northstar.html` if present, else `northstar.md`.
2. **HTML documents** — the designed twins and standalone studies.
3. **Specifications and notes** — the Markdown documents.
4. **Ideas under consideration** — `in-flight_ideas.md` and `*_ideas.md`.
5. **Contributing** — `CONTRIBUTING.md`.

**A Markdown document with an HTML twin is listed once**, under the twin, with a small "Markdown source" link beside it. Within a group, order by title.

**Every subfolder of `docs/` gets a generated index too.** Pages serves no directory listings, so a folder without an `index.html` answers 404 — a link to `/docs/<folder>/` would break. A folder that ships its own `index.html` keeps it; the build leaves that one alone.

### Markdown links

GitHub Pages serves a `.md` file as **plain text**, so a Markdown document with no HTML twin is not worth linking to on the site itself. Link it instead to **GitHub's rendered view, pinned to the release tag**: `https://github.com/ParkviewLab/<repo>/blob/vX.Y.Z/docs/<file>.md`. Pinning to the tag, not to `main`, keeps the reader on the version the site is publishing. The "Markdown source" link beside a twin goes to the same place.

## Links between a repo's own documents

Inside a repo, one document links to another **relatively** — to the `.html` twin where one exists, otherwise to the `.md` file — and **never with an absolute `github.com` link to the same repository**.

The reason is local development. An absolute link opens a *different version* of the document than the one being edited: the author clicks through from their working copy and lands on `main`'s copy on the web, reads the old text, and edits against it. A relative link stays inside whichever copy the reader is in — the working tree, the GitHub blob view, or the published site — and resolves correctly in all three. (A link to *another* repo is absolute, of course; the rule is about self-links.)

The [`html-drift-checker`](../templates/agents/html-drift-checker.md) agent flags absolute same-repo links as part of its discipline check.

A repo that publishes a documentation site is expected to carry at least **`docs/northstar.html`**, the designed twin ([`md-to-html.md`](md-to-html.md)): it heads the index and it is what a visitor reads first, so the site's quality is largely its quality. (The northstar itself remains the author's choice — see [`documentation.md`](documentation.md#the-northstar) — but a published repo without one has nothing to open with.)

## What the build script must guarantee

The script is **per-repo**, because the index carries the repo's own styling — `pensa-grex`'s is its Googie theme, and there is no useful common version to copy. The handbook therefore specifies the script's *guarantees*, not its code, and ships only the workflow:

- **Standard library only.** No dependency install in the deploy path.
- **Nothing generated is committed.** The script assembles the whole site into an output directory given on the command line (refusing one that is non-empty, or inside `site/`/`docs/`), and the workflow uploads that directory. There is no Jekyll or other build system in the path.
- **It fails the build** when a document has **no title**, when a **placeholder survives the stamp** (the release tag substituted into a hand-built page), or when a **generated link does not resolve** against the assembled directory.
- **It only reports** an unresolved reference inside a document copied from `docs/`. Those are published exactly as the repository holds them, so a broken reference of their own is a defect to fix in that document, not a reason to withhold the whole site.
- **It pins every GitHub link to one release tag**, taken from `git describe --tags --abbrev=0 --match 'v*'` (or an explicit `--tag` for a local trial run), which is why the workflow checks out with `fetch-depth: 0`.

And one thing it must **not** do, learned by getting it wrong once: **do not make a late tag fatal.** The script takes the newest `v*` tag *reachable from HEAD*, so it cannot tell a missing tag from a late one, and a run that somehow started before the tag landed would stamp the **previous** release and publish successfully. That leniency is wanted, because a manual re-run sits on the changelog commit rather than on the tagged one and must still build. The only guard is against a repository with **no `v*` tag at all**, which refuses to publish. If a deployment ever does stamp a stale version, re-run the workflow by hand once the tag is in place. (`git push --follow-tags` sends the branch and its tag together, so in the normal release flow the tag is on the runner before the build reads it.)

Run the script locally before pushing — it is the same one command the workflow runs — and open the result with `python3 -m http.server`.

## Two things that bite

### A README that links to addresses the release has not published yet

**The repo's README is public on GitHub the moment a PR merges into `develop`** — long before the release that publishes the site. So a README edited to point at `/downloads/` or at the documentation site shows **broken links to everyone** in the window between that merge and the release. In the pilot this cost two extra pull requests: one to hold the links at what was actually live, and one to move them forward once the site was up.

**The rule: links to not-yet-published site addresses wait.** They move in the release's own pull request, or immediately after it — never in the feature PR that builds the thing they point at.

### A URL compiled into the application

A URL constant built into a shipped binary (`pensa-grex` has `DOWNLOAD_URL` in `src/main/update.js`) reaches users **only in the next release**, and installed copies keep using the old address indefinitely. So **the old address must keep working** after the site changes shape. That is why the site's root page carries the Downloads link prominently: an old build that sends a user to the repository root, or to the site root, must still land them somewhere that gets them the installer.

The general form: **treat any address an already-shipped artifact points at as permanent**, and make the new site a superset of what the old links expected.
