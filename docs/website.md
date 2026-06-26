<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Website repos

A **website repo** is a static site we publish to the internet — plain HTML/CSS
(no framework), self-hosted brand, served by **GitHub Pages** on a custom domain.
`parkviewlab.ai` and `zoestum.ai` are the examples; `parkviewlab.ai` is the
**reference implementation** of everything below.

It is a deliberately **lighter** profile than the Python-package one. A package
shipped to PyPI can't be unpublished and has many consumers, so its release
ceremony (version bumps, tags, the gate, the back-merge cascade) buys real safety.
A website is the opposite: **instantly re-deployable** — a bad change is reverted
and live again in seconds. So the website profile keeps the conventions that pay
for themselves and **drops the release ceremony that doesn't**. The goal is that
updating and publishing the site is *easy*.

## What carries over, what's dropped

**Keep** (the universal conventions — see the linked docs):

- The contained, repo-prefixed **worktree layout** ([`repo-layout.md`](repo-layout.md)).
- **Two trunks** + a one-step publish (below).
- **REUSE/SPDX licensing** ([`licensing.md`](licensing.md)).
- **`AGENTS.md` + `CLAUDE.md`** pointers (`scripts/sync-agent-files.sh`).
- The **brand** — palette, Michroma, logos ([`brand.md`](brand.md)).
- A **visible copyright footer** on every page ([`documentation.md`](documentation.md#copyright-footers)) — extended here with a "last updated" date.

**Drop** (no website equivalent — don't scaffold these):

- `pyproject.toml`, `ruff`/`ty`/`pytest`, `test.yml` — there's no Python package.
- **No version source-of-truth, no `VERSION.txt`, no git tags, no `release.yml`** — see [Versioning](#versioning).
- No `Dockerfile`, no PyPI/GHCR publish, no `version-guard.yml`, no `dev-release.yml`.

## Branches: `live` + `staging`

Website repos name their two trunks for what they *are*, not the generic
`main`/`develop`:

- **`live`** — production. **This is what GitHub Pages serves**; a push here
  publishes to the internet. The name is the warning.
- **`staging`** — integration. The **GitHub default branch**; work targets it.

> Website repos are the one place we diverge from the org-wide `main`/`develop`
> names. The deploy semantics are clearer this way, and the divergence is
> contained to this profile (its workflow templates trigger on `live`/`staging`,
> and `sync-agent-files.sh` knows the `*-staging`/`*-live` worktree names).

**Working branches are optional.** Mandating a prefixed branch + PR for a typo on
a few static pages is friction without payoff. Commit small edits straight to
`staging`; use a prefixed worktree branch (`feature-`/`doc-`/… → PR into
`staging`) only for a real redesign. See [`branching.md`](branching.md) for the
prefixes when you do.

**Publishing is one step: promote `staging` → `live`.** That promotion *is* the
"release", and it triggers the deploy:

```bash
# in the <repo>-live worktree, when staging is reviewed and ready:
git pull --ff-only
git merge --ff-only staging
git push                     # push to live → fires the deploy workflow
```

No tag, no bump, no cascade. To roll back, promote the previous commit (or
`git revert` on `live` and push).

### On-disk layout

The usual contained worktrees ([`repo-layout.md`](repo-layout.md)), named for the
website branches:

```
ParkviewLab/
└── <repo>/
    ├── <repo>.git/          ← bare clone (run `git config --unset core.bare`)
    ├── <repo>-live/         ← production worktree (Pages serves this branch)
    └── <repo>-staging/      ← integration worktree (GitHub default branch)
```

## Deploy: GitHub Pages via Actions

Website repos deploy through a **GitHub Actions Pages workflow**, *not* the legacy
"serve a branch" mode. The Actions path lets the deploy **build** (refresh any
generated pages, stamp the "last updated" dates) and publishes the result
**without committing generated artifacts to git**.

Set the Pages source to GitHub Actions:

```bash
gh api -X PUT repos/ParkviewLab/<repo>/pages -f build_type=workflow
```

The deploy workflow ([`templates/.github/workflows/pages-deploy.yml`](../templates/.github/workflows/pages-deploy.yml))
triggers on **push to `live`** (publish), a **nightly `schedule`** (so generated
pages pick up changes — e.g. new project releases — without a site edit), and
**`workflow_dispatch`** (manual). It checks out `live` with full history
(`fetch-depth: 0`, needed for the git dates), runs the build + stamp steps,
assembles the site files, then `actions/upload-pages-artifact` →
`actions/deploy-pages`. Keep the `CNAME` file in the published artifact so the
custom domain holds.

Generated pages and stamped dates are **build output, not source** — `.gitignore`
them.

## Custom domain & HTTPS

The custom domain is the **apex** (`parkviewlab.ai`), set in **Pages settings** —
the `CNAME` file in the published artifact holds it (see
[Deploy](#deploy-github-pages-via-actions)). DNS lives at **Cloudflare**, and every
record on the certificate path must be **DNS-only (grey-cloud)**: a proxied
(orange-cloud) record hides the origin, so GitHub can't validate or renew its
Let's Encrypt certificate.

Two records, both DNS-only:

- **Apex** — four `A` records to GitHub's Pages IPs
  (`185.199.108.153`–`185.199.111.153`).
- **`www`** — a `CNAME` to **`parkviewlab.github.io`**: the **org** Pages host, the
  *same target for every ParkviewLab domain*. It is **not** `<domain>.github.io` —
  there is no `zoestum` GitHub account; `zoestum.ai`'s repo lives under the
  ParkviewLab org too. The repo's Settings → Pages page says it outright: "serve
  your site from a domain other than `parkviewlab.github.io`."

GitHub then issues a **single Let's Encrypt certificate covering both the apex and
`www`**, and `www` 301-redirects to the bare apex.

### The www-certificate gotcha

Even with DNS correct, `https://www.<domain>` can keep failing with
`SSL_ERROR_BAD_CERT_DOMAIN` — it's serving GitHub's `*.github.io` fallback cert,
which has no `www` SAN — while the apex is fine. The Pages API shows it stuck:

```bash
gh api repos/ParkviewLab/<repo>/pages --jq '.https_certificate | {state, domains}'
# stuck:  {"state":"dns_changed","domains":["<domain>"]}            ← apex only
# fixed:  {"state":"approved","domains":["<domain>","www.<domain>"]}
```

> **The fix is to LOAD the repo's Settings → Pages page in a browser — not the REST
> API.** GitHub re-evaluates whether `www` needs a certificate *every time that page
> loads*; the API `cname` remove/re-add (`PUT .../pages`) does **not** re-derive
> `www`, and leaves the cert stuck in `dns_changed` for hours. One page load flips it
> to `approved` for both names within minutes; the live cert follows after CDN
> propagation. *Then* tick **Enforce HTTPS** — only once `www` actually serves.

So the two-step recovery when `www` is stuck is:

1. Ensure `www` is `CNAME → parkviewlab.github.io`, DNS-only (fix it if it's pointed
   at the apex or proxied).
2. Open `https://github.com/ParkviewLab/<repo>/settings/pages` once. Don't churn the
   page; leave Enforce HTTPS off until the certificate covers `www`.

Verify on the wire — success is a `www` SAN:

```bash
echo | openssl s_client -connect www.<domain>:443 -servername www.<domain> 2>/dev/null \
  | openssl x509 -noout -ext subjectAltName
#   X509v3 Subject Alternative Name:
#       DNS:<domain>, DNS:www.<domain>          ← both names
```

**Don't chase the usual red herrings.** For a DNS-only Pages domain they're inert:
DNSSEC (check it's even enabled before touching it), CAA (the apex needs none; `www`
inherits `github.io`'s, which already permits `letsencrypt.org`), Let's Encrypt
rate-limits (they return errors — they don't silently hang), and re-enabling the
Cloudflare proxy (that *breaks* GitHub's native cert and its renewal). The cause is
almost always the `www` record shape plus the API-vs-UI re-derivation above.

## Versioning

**None.** A website has no version its consumers depend on, and it's
continuously re-deployable, so the package release machinery is pure overhead
here. The commit on `live` *is* the version; `git log live` is the history. Don't
add `VERSION.txt`, don't tag, don't write a `release.yml`. (This is the one place
the [releases.md](releases.md) flow does **not** apply.)

## CI

Only **`reuse`** ([`ci.md`](ci.md)) — REUSE/SPDX compliance, the one check that
applies to any repo. Use the website variant
([`templates/.github/workflows/reuse-website.yml`](../templates/.github/workflows/reuse-website.yml)),
identical to `reuse.yml` but triggering on `[live, staging]`. No `test.yml`,
`version-guard.yml`, `license-check.yml`, or `release.yml`.

Branch protection is **light or omitted** — for a solo maintainer who wants easy
edits, requiring the `reuse` check on `staging` (admins bypass, no required PR) is
plenty. Leave `live` pushable so the one-step promote isn't blocked.

## Licensing

REUSE still applies — every file needs an SPDX tag and `reuse lint` stays green
([`licensing.md`](licensing.md)). But a public **brand/marketing site** is
typically **standard copyright**, not open-source: license first-party files
(HTML, CSS, build scripts, content) as **`LicenseRef-AllRightsReserved`**. A
bundled third-party font keeps its own license — the Michroma woff2 is `OFL-1.1`;
don't relabel it. (A site you *want* reused can pick an open license instead; it's
a per-repo decision like any other.)

So `REUSE.toml` is short: an all-rights-reserved catch-all for first-party files,
plus the font's `OFL-1.1`. There's **no root `LICENSE`** for an all-rights-reserved
site (GitHub correctly shows no license badge). `LICENSING.md` says
"© 2026 Gary Frattarola. All rights reserved."

## Page footers: copyright + last-updated

Every page shows, in its `<footer>`, two human-visible lines (this extends the
[copyright-footer rule](documentation.md#copyright-footers) to *all* site pages,
not just standalone docs):

- **Copyright** — `Copyright © <year> <holder>` (link the email as `mailto:`).
- **Last updated** — `This page updated on <Month D, YYYY>`.

The date is **auto-stamped at deploy**, never hand-typed: a small stdlib stamp
step fills a placeholder in each static page from that file's git last-commit date
(`git log -1 --format=%cs -- <file>`). A generated page (e.g. a releases index)
uses its build date instead. Stamping runs in the deploy workflow *and* in the
local preview, so what you review is what ships.

## Brand integration

Use the brand directly in pages ([`brand.md`](brand.md)):

- **Michroma is self-hosted** (`assets/fonts/michroma-*.woff2`, `OFL-1.1`) via a
  single `@font-face` in the shared stylesheet — never a Google Fonts call.
- **Logo SVGs are inlined** in the HTML so they render with the page's own
  Michroma. (The brand palette lives once in `assets/style.css` as CSS custom
  properties.)

## Local preview — review before publishing

A website repo ships a stdlib **preview script** (`scripts/preview.sh`) that runs
the same build + stamp steps the deploy runs, then serves on `localhost` (e.g.
`python3 -m http.server`). This is the review gate: a human opens the local site,
confirms it, *then* promotes `staging` → `live` to publish. No change reaches the
internet unreviewed.

## Org hub / releases page (optional)

A site that lists the org's projects (parkviewlab.ai's `releases/` page) keeps a
**curated** project list — each rich card needs a human-written tagline/summary —
but discovers new repos so the list can't silently fall behind. The pattern is
**hybrid**:

- New **public** org repos (minus a "not a product" **denylist** — the handbook,
  dev-tools, the websites themselves, internal tools) appear automatically in the
  summary **table** (name + current version + registry — low-risk facts pulled
  from PyPI/npm).
- Rich descriptive **cards** render only for **curated** entries — each sourced from the
  project's registry (PyPI/npm) or, for a desktop/installer product with no registry package,
  from its **GitHub Releases** (version + per-OS download links; conception-space is the reference).

So a newly-released project shows up on the next nightly build with its version,
and a human upgrades it to a full card when ready. Fully-automatic listing is a
trap: it would publish the handbook and tooling repos as if they were shippable
products.

## Starting a website repo

Follow the **"If it's a website"** path in
[`new-repo-checklist.md`](new-repo-checklist.md): contained worktrees named
`live`/`staging`; default branch `staging`; Pages → Actions; REUSE
(`LicenseRef-AllRightsReserved` + the font's license); `reuse-website.yml` +
`pages-deploy.yml`; `AGENTS.md`/`CLAUDE.md`; the page footers + stamp step + the
preview script. Skip the entire Python/packaging/release section.
