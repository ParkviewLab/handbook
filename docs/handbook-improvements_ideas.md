<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# ParkviewLab handbook & dev-tools — research and improvement proposals

## Context

The `ParkviewLab` GitHub org documents how it does development in two public
meta-repos: `handbook` (the single source of truth for conventions; a
`VERSION.txt` repo at `v0.10.0`) and `dev-tools` (shared `git-*` bash scripts).
This notebook is the detailed backing for the handbook's own improvement backlog
([`in-flight_ideas.md`](in-flight_ideas.md)): it inventories the processes and
methodologies the two repos encode today, the topics researched against the
2025-2026 state of the art, the findings, and a prioritized set of proposals to
build upon and improve them.

Nothing here is executed without a separate go-ahead: each proposal is a
candidate, to be evaluated against the northstar and promoted or dropped
individually through the backlog. It was raised from a 2026-07 human+AI research
sweep.

Both repos were read in full from their local `develop` worktrees
(`handbook-develop`, `dev-tools-develop`): all 19 handbook docs, the README,
`AGENTS.md`/`CLAUDE.md`, the three `dev-tools` scripts plus `_sot.sh`, and the
load-bearing templates (`generate_changelog.py`, `cliff.toml`, `release.yml`,
`sync-agent-files.sh`).

The scope spans three additions beyond the core survey, each folded into the proposals:

- The handbook serves human and AI engineers alike, so proposals may recommend
  consolidating or reorganizing the two repos, and building new tooling: dev
  tools for people, and AI artifacts (Claude Code skills, hooks, subagents, MCP
  servers) for agents, where the benefit is clear.
- A forthcoming Apple Vision Pro / visionOS product line (native Swift), a
  toolchain and distribution path the handbook does not yet cover. This warrants
  a new "visionOS profile" analogous to the Electron and website profiles.
- A survey of the whole org (below).

### The org today (survey, 2026-07)

Thirteen public repos, all active, forming the "family": two meta repos
(`handbook`, `dev-tools`); a cluster of Python MCP servers (`deco-assaying`
tree-sitter parsing, `smalt-mcp`, `flint-slating`, `ebony-enriching`,
`cobalt-grinding` an agentic LLM-wiki); a Python MCP *client*
(`cogrind-workshop`); a TypeScript knowledge daemon (`jonobones`); an Electron
3D-graph app (`conception-space`); a PySide6 Qt GUI (`pvl-dotview`); and two
static websites (`parkviewlab.ai`, `zoestum.ai`). The centre of gravity is
Python MCP servers; there is as yet no Swift or Apple-platform repo, confirming
visionOS is genuinely new ground.

The org's stated intent (from `handbook/docs/northstar.md`) frames every
proposal below:

1. One shape across many repos (a family, not a monorepo, not one-offs).
2. Self-contained and self-describing repos.
3. Legible to humans and AI alike.
4. Use AI to automate the defined processes.

Axioms: one source of truth; convention over configuration; write it down;
automate the mechanical, gate the irreversible. The maintainer is near-solo plus
AI agents, so *low ceremony* is a first-class constraint: a proposal that adds
process must earn it.

---

## Part 1 — Inventory of processes and methodologies

What the two repos actually encode today, grouped by area. This is the baseline
the research and proposals build on.

### Repository & family architecture
- A "family of repos" model: shared layout, toolchain, release flow, and brand
  across many independently-released repos; deviations must be documented.
- Contained bare-clone + worktrees layout per repo: `<repo>.git` (bare) plus
  permanent `<repo>-main` and `<repo>-develop` worktrees and ephemeral
  `<repo>-<branch>` worktrees, all siblings under one plain container dir.
- Repo-prefixed, self-identifying worktree names (an editor tab reads
  `deco-assaying-develop`, never a bare `develop`).
- A `core.bare`-unset guard defusing a `worktreeConfig` config-leak hazard
  unique to bare-clone-plus-worktrees.
- House naming: mineral/pigment + gerund (`cobalt-grinding`); MCP servers may
  take a `-mcp` suffix; meta repos are plain (`handbook`, `dev-tools`).
- Required repo contents: root `README.md`, `docs/`, `scripts/`, `AGENTS.md` +
  `CLAUDE.md`, language scaffold.

### Branching & merge model
- Two-trunk model: `develop` (integration) and `main` (release-only surface).
- Short-lived, hyphen-prefixed working branches in ephemeral worktrees
  (`feature-`/`bug-`/`doc-`/`ops-`/`ci-`/`build-`/`release-`) mirroring the
  Conventional Commit types.
- Squash-only merges into `develop`; the *PR title* carries the changelog prefix
  (the squash subject `git-cliff` parses).
- `develop → main` promotion via `git merge --no-ff develop` from the CLI as
  part of a release (not a reviewed PR).
- `git pull --ff-only` everywhere; "consume `main`, not `develop`."
- Humans review and squash-merge; AI devs open PRs but do not merge.

### Commits & changelogs
- Conventional Commits + git-cliff (`cliff.toml` copied verbatim across repos).
- A language-agnostic, two-phase `generate_changelog.py` (`--mode=generate`
  against the tag; `--mode=insert` onto a fresh `main`).
- An LLM-written "Highlights" paragraph via the Anthropic API (pinned model,
  capped input, graceful degradation to a placeholder if the key/call fails).
- Keep-a-Changelog format under an `## [Unreleased]` marker.

### Versioning & releases
- Version single-source-of-truth per repo: `pyproject.toml` `[project].version`
  / `package.json` `version` / a top-level `VERSION.txt`.
- Runtime reads the version from package metadata; never a literal.
- Tag-driven releases: pushing a `v*` tag triggers publish; the version is
  derived, never typed on the `git tag` line.
- Bespoke `dev-tools` bash: `git bump`, `git release`, `git dev-release`, sharing
  `_sot.sh` (auto-detects the SoT shape; PEP 440 vs semver dev-suffix logic).
- A release gate: tag == SoT version, tag reachable from `origin/main`, and the
  version strictly greater than the last tag (monotonic).
- A `version-guard.yml` check blocks version-file changes in `develop` PRs.
- A mandatory, manual back-merge cascade (`main → develop → working branches`)
  after each release, which also opens the next dev cycle.
- Development versioning: a dev pre-release names the *next* release
  (`X.Y.Z.devN` PEP 440 / `X.Y.Z-devN` semver); on-demand dev builds to
  TestPyPI + a GHCR `:dev` image, never per-merge.
- Bump-kind proposed by the releaser, confirmed by the engineer; never silent.

### CI/CD
- GitHub Actions: `reuse.yml` + `version-guard.yml` (every repo);
  `test.yml`/`test-node`/`test-electron`; `release.yml`/`-node`/`-electron`;
  `dev-release.yml`; `license-check.yml`.
- Required status checks on `develop` with admin-bypass (so release direct-pushes
  aren't blocked).
- Actions pinned exactly (not floating majors), with a hand-maintained list of
  Node-24-runtime action floors.
- Trusted publishing via OIDC (PyPI, npm); no long-lived secrets.
- Org-owned trusted publishers via org-level *pending* publishers / "transfer
  existing project"; org-level `ANTHROPIC_API_KEY`.
- GHCR multi-arch (amd64 + arm64) images tagged `{{version}}`,
  `{{major}}.{{minor}}`, `latest`.
- Committed lockfiles (`uv.lock`, `package-lock.json`); no Dependabot/Renovate
  yet (a deferred in-flight idea).

### Language toolchains
- Python: uv + ruff + ty + hatchling, Python 3.13, `src/` layout.
- Node: npm + TypeScript (strict, `NodeNext`) + ESLint (flat config) + Vitest,
  Node ≥24, `src/` → `dist/` via `tsc`.
- Electron: electron-vite + electron-builder; per-OS installers to a GitHub
  Release (no GHCR); macOS signing + Apple notarization; a generated `legal/`
  notices bundle + in-app viewer; an `install.js` step completing Electron 43's
  prebuilt extraction before the legal bundle; auto-update deferred.

### MCP server architecture
- `mcp[cli]>=1.27` + FastAPI + uvicorn + starlette + pydantic; Streamable-HTTP
  mounted at `/sse` (+ optional stdio).
- Module layout: `config.py` (pure leaf), `__main__.py`, `server.py`,
  `tools.py`, `schema.py`.
- `/health` + `/admin/version` endpoints; permission scopes as an `Enum`;
  CORS + GZip middleware; config as plain dataclasses + `os.environ.get`.

### Testing
- pytest markers/tiers (`network`, `docling`, `integration`); fast subset in CI,
  full suite locally before a release.
- MCP conftest patterns (one session-scoped `TestClient`, reload guard,
  in-memory fixtures).
- Node tiered CI (interop / docker / e2e); visual/front-end verification by
  running the app via the Claude Preview MCP tools + screenshots.

### Packaging & deployment
- Dockerfile on the uv base image (layer-cached deps, `/data` volume); a
  docker-compose example; a "five ways to run it" README table; env-var config
  documented in a README table.

### Licensing
- REUSE/SPDX per-file headers + `REUSE.toml`; per-bucket licensing (code AGPL,
  docs CC-BY, brand All-Rights-Reserved, bundled Michroma font OFL-1.1); PEP 639
  SPDX expressions; a permissive `MIT OR Apache-2.0` option; `LICENSING.md` with
  a commercial alternative; a `reuse lint` gate; a pip-licenses copyleft guard.

### Documentation
- README in root, `docs/` for substance; an optional northstar (complementary
  intents → axioms → guiding questions → "what it is not"); `in-flight_ideas.md`
  (+ split-out `<topic>_ideas.md`); a dual-track designed-HTML discipline (MD
  canonical, hand-*authored* single-file no-network brand HTML); copyright
  footers.

### Website profile (lighter)
- `live`/`staging` trunks; GitHub Pages via Actions; custom-domain HTTPS on
  Cloudflare DNS-only with a documented `www` certificate gotcha; auto-stamped
  footers; a curated + auto-discovered hybrid releases hub; a local preview gate;
  no versioning/tags/release ceremony.

### Brand
- A CSS-custom-property palette + self-hosted Michroma + logos + a terse,
  unembellished voice.

### AI collaboration
- A behavioural contract: shared-state writes need explicit per-action
  authorization; propose-bump-kind-then-confirm; no sycophancy; label
  uncertainty; surface design forks; push after each commit.
- Thin `AGENTS.md` + `CLAUDE.md` pointer files generated from templates by
  `scripts/sync-agent-files.sh`, keeping the handbook the one source of truth.

---

## Part 2 — Research topics

The methodology inventory maps onto these research topics. Each is a lens on the
2025-2026 state of the art for an area the handbook covers, chosen to surface
where the org is current, behind, or holding a defensible minority position.

1. Branching models and git-worktree workflows (trunk-based vs two-trunk;
   merge queues; stacked PRs; worktree tooling).
2. Conventional Commits, changelog and release automation (git-cliff,
   release-please, semantic-release, changesets, release-plz, cocogitto;
   tag-driven vs release-PR flows; LLM-written release notes).
3. Software supply-chain security and release provenance (OIDC trusted
   publishing, PEP 740 attestations, npm provenance, SLSA, Sigstore/cosign,
   GitHub Artifact Attestations, SBOMs, SHA-pinning, OpenSSF Scorecard).
4. Python packaging and quality tooling (uv, ruff, ty vs mypy/pyright, build
   backends, PEP 735/751/639/440/723, Python cadence).
5. Node.js and TypeScript tooling (npm/pnpm/bun, ESLint/Biome/oxlint, tsc vs
   native TS-Go, Vitest, npm provenance).
6. Electron packaging, signing and distribution (builder vs forge, CI
   signing/notarization, auto-update, desktop SBOM/licenses, security checklist).
7. MCP server architecture and the current MCP spec (Streamable HTTP endpoint,
   authorization/OAuth, the Python SDK & FastMCP, MCP security guidance).
8. AI-agent collaboration conventions and instruction files (the AGENTS.md
   standard, Claude Code memory/skills, spec-driven development, agent guardrails).
9. Multi-repo consistency and scaffolding at org scale (copier/cookiecutter,
   `copier update` re-templating, Backstage software templates, org reusable
   workflows and rulesets, config-as-code for repo settings, drift detection).
10. Dependency-update automation (Renovate vs Dependabot; grouping, scheduling,
    automerge; updating action pins; noise control for a solo maintainer).
11. Documentation frameworks and engineering handbooks (Diátaxis, docs-as-code,
    ADRs, public handbooks as a genre, the northstar/intent-doc idea, docs sites).
12. Licensing, REUSE/SPDX and SBOM compliance (REUSE 3.x, SPDX 3.0, license
    scanning, PEP 639 rollout, DCO/CLA for contributions).
13. Container images and static-site/Pages deployment (distroless/minimal bases,
    multi-arch, image provenance/SBOM, non-root, Pages-via-Actions hardening).
14. Testing strategy, coverage and release quality gates (test tiering, coverage
    gates, mutation and property-based testing, contract/visual testing).
15. Apple / visionOS toolchain and release path (Swift, Xcode, SwiftUI +
    RealityKit + Reality Composer Pro, project-file-as-code, swift-format vs
    SwiftLint, Swift Testing, fastlane vs Xcode Cloud, App Store Connect API,
    TestFlight, signing, and how a "visionOS profile" fits the version-SoT and
    tag-driven-release conventions) — researched separately, being new ground.

Two further dimensions are handled at synthesis rather than as research topics,
because they are judgments about *this* org rather than external SOTA: how to
organize or consolidate the `handbook`/`dev-tools` pair, and which new human and
AI tools (skills, hooks, subagents, MCP servers, scripts) would repay building.

---

## Approach

- Present the augment-versus-replace tradeoff *per item* rather than pre-judging;
  the org's default lean is still low-ceremony and bespoke-friendly, so a
  "replace" recommendation must clear a high bar, but both sides are shown.
- Full prioritized sweep across every researched area (including visionOS, repo
  organization, and new human/AI tooling), ranked P1 (high value, low regret) to
  P3 (speculative).
- The condensed, scannable index of these proposals lives in the sibling
  [`in-flight_ideas.md`](in-flight_ideas.md); this notebook holds the detail
  behind each entry.

## Organizing principle (the goal the proposals serve)

The end this notebook serves, stated plainly: to best leverage and accelerate the
software-development efforts of both humans and AIs, in a frictionless and
adaptable environment where they work together; and, load-bearing, it must be
easy for both to *discover, suggest, debate, and decide upon* improvements to
the development tools and processes themselves.

Part 4 is organized around two pillars that follow from this:

- Pillar A, accelerate the shared loop with low friction: any human or AI can
  open any repo and move at once, conventions auto-loaded, mechanical steps
  automated, irreversible steps gated. The proposals under A are where friction
  still leaks (version drift, hand-maintained condensations, missing release
  provenance, no dependency automation, the visionOS gaps, MCP currency).
- Pillar B, a self-improvement governance loop: an explicit, lightweight
  lifecycle that carries an improvement from raised to debated to decided to
  recorded, with humans and AIs as symmetric participants and a durable trail.
  Today the org has capture (`in-flight_ideas.md`), intent (`northstar.md`), and
  a propagation rule ("change the handbook first, then sync"), but no defined
  propose-debate-decide-record lifecycle and no affordance for an agent to file
  or argue a proposal mid-work the way a human opens an issue. The fitting shapes
  are a small RFC/proposal process and Architecture Decision Records, adapted so
  an agent is first-class, plus a friction-capture channel.

This principle follows from and sharpens northstar intents 3 (legible to humans
and AI alike) and 4 (use AI to automate the processes); Part 4 includes a
proposal to add it to the northstar as a candidate fifth intent ("the
environment improves itself"), rather than acting on it silently.

## Part 3 — Web research findings

_(Two background research workflows: a 14-cluster methodology sweep and a
3-facet Apple/visionOS study, each with adversarial verification of its
version-sensitive claims. The visionOS study and two directly-read private
repos are captured below; the 14-cluster sweep lands in 3d.)_

### 3a — visionOS reference: `garycoding/vos-gspheres` (read directly)

A private Swift/visionOS repo, `GoldbergRoom` (a Goldberg-polyhedron generator,
immersive passthrough), already applies most handbook conventions and is the
natural reference implementation for a visionOS profile. Observed state:

- Conventions carried over intact: two-trunk (`develop` default), AGPL-3.0 +
  REUSE (`REUSE.toml`, `LICENSES/`, `LICENSING.md`), `VERSION.txt` as the version
  SoT, `cliff.toml` + `scripts/generate_changelog.py` mirrored verbatim, the
  `reuse`/`version-guard`/`test`/`release` workflows, `AGENTS.md`/`CLAUDE.md`, a
  full northstar and `in-flight_ideas.md`.
- Project-file-as-code: XcodeGen `project.yml` is the source of truth; the
  `.xcodeproj` is generated but committed so it opens directly, and `test.yml`
  runs `xcodegen generate` and fails on any drift from the committed project.
  This is a clean, handbook-worthy answer to the `.pbxproj` merge-conflict
  problem and fits "convention over configuration."
- Testability split: a RealityKit-free `Packages/GoldbergKit` SPM package holds
  the error-prone geometry, host-tested with plain `swift test` (no simulator);
  the app is a thin RealityKit layer. `test.yml` treats the host tests as the
  reliable gate and only *compile-checks* the app against the visionOS Simulator
  SDK, because hosted-runner simulator runtimes are churned as Xcode ships.
- Stack specifics: Swift 6.0, visionOS 26.0 deployment target,
  `TARGETED_DEVICE_FAMILY 7`, automatic signing, `DEVELOPMENT_TEAM 2CKMPN3Y7C`
  (the same Apple team as the Electron notarization — consistent), `macos-15`
  runners selecting the newest installed Xcode.

Two concrete gaps this surfaces, which the visionOS proposals must address:

1. The version SoT is violated. `VERSION.txt` (`0.1.0-dev0`), `project.yml`
   (`MARKETING_VERSION` / `CFBundleShortVersionString` `0.1.0`) and `Info.plist`
   (`0.1.0`, build `1`) each hold the version independently; none derives from
   the others, so they will drift — exactly what the handbook's version doctrine
   forbids. A visionOS profile needs `CFBundleShortVersionString` and
   `CFBundleVersion` to *derive* from `VERSION.txt` (a build phase or a
   `git bump` that patches `project.yml`), and `CFBundleVersion` (build number)
   must increase monotonically for every TestFlight/App Store upload, which a
   static `1` cannot.
2. There is no distribution. The `release.yml` is `gate → changelog` only: a
   tag produces a GitHub Release with notes but ships no artifact. A visionOS
   release path (archive → App Store Connect API upload → TestFlight/App Store)
   is unbuilt, and it necessarily diverges from the org's "push a tag, CI ships"
   model because App Store review makes "published" asynchronous.

### 3b — Apple / visionOS research (complete, verified)

Current line as of mid-2026 (verified): Xcode 26.6, Swift 6.3, visionOS 26.5
SDK, on Apple's year-based numbering. Xcode 26.3 (2026-02-26) added in-IDE
agentic coding with Claude and Codex, which is itself relevant to the org's
"legible to AI" intent. The recommended visionOS profile, and where it must
diverge from the handbook:

- CI substrate: GitHub Actions on a pinned `macos-26` Apple-silicon runner (not
  `macos-latest`), with an explicit Xcode-select step, so the org keeps one CI
  shape. macOS minutes bill about 10x Linux and count against private-repo
  quotas; public repos run free. Xcode Cloud is an escape hatch only (its
  triggers live outside the repo and it cannot run visionOS test actions).
- Distribution follows the iOS model: App Store + TestFlight only; there is no
  macOS-style Developer ID notarized sideload for visionOS. fastlane
  (`gym`/`pilot`/`deliver`) is the current, maintained toolchain; for a solo
  maintainer `Apple-Actions/import-codesign-certs` with one `.p12` is lower
  ceremony than `fastlane match` until a second machine appears.
- The one unavoidable, justified deviation from "OIDC, no long-lived secrets":
  Apple offers no trusted-publishing equivalent, so the release path must hold a
  long-lived App Store Connect `.p8` API key (+ signing cert) in GitHub Secrets.
  The Electron notarization secrets are the existing precedent. Mitigate with a
  least-privilege key role and manual rotation; this is the one repo class that
  legitimately keeps long-lived publish secrets.
- "Publish" is asynchronous: a tag can archive, sign, and upload to TestFlight,
  but App Store availability waits on human review (roughly 24-72h). Redefine
  the release workflow's success as "uploaded to TestFlight"; make store
  submission an explicit human-gated step, which actually aligns with "gate the
  irreversible." Keep the GitHub Release the changelog job already creates as the
  release ledger.
- Version SoT (the fix for the `vos-gspheres` gap): a single `Version.xcconfig`
  holding `MARKETING_VERSION` (fills `CFBundleShortVersionString`) and
  `CURRENT_PROJECT_VERSION` (fills `CFBundleVersion`) with
  `GENERATE_INFOPLIST_FILE=YES`, so no version literal is hand-maintained in
  `Info.plist`; the app reads its version from the bundle at runtime. Extend
  `git bump`/`git release`/`_sot.sh` with an `.xcconfig` SoT-shape detector so
  Apple repos join the auto-detecting release flow; `version-guard.yml` watches
  the `MARKETING_VERSION` line. The build number is a second monotonic axis the
  semver model lacks: derive it in CI as a single strictly-increasing integer
  (App Store rejects a reused build number, and compares only the leading dotted
  component, so keep it a plain integer).
- Project file: `vos-gspheres` uses XcodeGen (`project.yml`) with a committed,
  drift-checked `.xcodeproj`, which is a defensible answer. The lower-ceremony
  alternative for a first single-target app is Xcode 16+ buildable
  (synchronized) folders on a plain committed `.xcodeproj`, which stop file
  add/remove from churning the `.pbxproj`. Reserve Tuist for a later
  multi-module app.
- Toolchain conventions: Swift Testing (`@Test`/`#expect`) as the canonical unit
  framework (XCTest only for UI automation and performance); `swift-format`
  (in-toolchain, first-party) as the canonical formatter with SwiftLint optional
  and additive; SPM only, with a committed `Package.resolved` as the lockfile
  (note Xcode buries it inside the `.xcworkspace` bundle); Swift 6 language mode
  with Approachable Concurrency / default-MainActor isolation, the Xcode 26
  template default.
- Licensing carries over: `//` SPDX headers on `.swift`, and a `REUSE.toml`
  catch-all for comment-hostile assets (`.usdz`/`.usda`, `.rcproject`/Reality
  Composer Pro packages, `.xcassets`, `.entitlements`, the generated project).
  Native SwiftPM SBOM generation (SE-0509) exists but only in the Swift 6.4
  beta, so it is a watch-list item, not yet adoptable.
- Worktrees are unaffected: give each worktree an isolated, gitignored
  DerivedData (`xcodebuild -derivedDataPath` in CI); signing lives in the
  machine keychain.

The natural home is a new handbook doc pair, `swift-tooling.md` (the language
base) and `visionos-tooling.md` (the app profile), analogous to
`node-tooling.md` + `electron-tooling.md`, with `vos-gspheres` as the named
reference implementation once its version-SoT derivation is fixed.

### 3c — AI-governance mechanism: `garycoding/claude-style-policy` (read directly)

A private repo delivering a communication/writing-style directive to Claude Code
as durable policy. Its design is the relevant part. One canonical directive
(`AI_comm_and_writing_style.md`) is compiled by a root-owned, idempotent
installer into four independently-failing layers: a managed `CLAUDE.md`
(primacy, survives compaction), an output style (highest-weight system-prompt
seat), a `UserPromptSubmit` digest hook (recency, ~70 tokens/turn), and a `Stop`
judgment-review hook (a small model checks the reply against the rules,
distinguishing using a banned element from merely mentioning it). It is the
mechanism enforcing the style this very document is written in.

The bearing on ParkviewLab: the org already builds sophisticated,
context-durable AI-behaviour enforcement, but the handbook's own
`ai-collaboration.md` behavioural contract reaches agents only as static
`AGENTS.md`/`CLAUDE.md` pointer text, whose adherence is known to erode across a
long session. The same four-layer pattern could deliver the org's AI norms
(shared-state authorization, no-sycophancy, label-uncertainty, propose-bump-kind)
as an *enforced* layer: a small ParkviewLab Claude Code plugin or hook set,
generated from `ai-collaboration.md` as the one source. This is the strongest
"new AI tool to build" candidate the survey surfaced. Two secondary
observations: `claude-style-policy` is a personal repo (single-trunk `main`, no
license, outside the org and off the handbook shape), a candidate to bring into
the family or generalize; and the review-hook/digest condensations are
hand-maintained second sources the author already flags as drift-capable, the
same one-source-of-truth tension the handbook is built around.

### 3d — Methodology sweep (14 clusters), headline gaps

The 14-cluster sweep (29 agents, adversarial verification of the load-bearing
claims) de-duplicates into Part 4. The per-cluster headline gaps:

- Branching: the permanent `develop` trunk plus the mandatory manual back-merge
  cascade is the shape DORA and Atlassian now class as legacy (trunk-based /
  release-from-main superseded it); no merge queue; no explicit hotfix path.
- Release automation: the bespoke `git bump`/`git-cliff`/`generate_changelog.py`
  is defensible (no off-the-shelf tool auto-detects the org's four SoT shapes),
  but a PR-title Conventional-Commit check is missing and the LLM Highlights ship
  unlabelled and unread.
- Supply-chain: actions are pinned by tag, not SHA; GHCR images and Electron
  installers carry no build provenance (PyPI/npm get it free); no SBOM, no token
  minimization, no Scorecard.
- Python: a bare `ty` (pre-1.0, which upstream warns is unstable) undercuts the
  committed lockfile; the ruff selector can add PERF/TRY; a `pylock.toml` export
  is a cheap interop add.
- Node/TypeScript: no `publint`/`arethetypeswrong` correctness gate before npm
  publish.
- Electron: the handbook template still says "unsigned" while `conception-space`
  ships signed and notarized (drift); no Windows signing; no Fuses or
  renderer-security guard; no provenance.
- MCP: the mount path `/sse` is the deprecated-transport name (the spec and SDK
  use `/mcp`); wildcard CORS plus an all-interfaces bind is the DNS-rebinding
  shape; the shared-token auth is a pre-OAuth placeholder.
- Agent conventions: `AGENTS.md` and `CLAUDE.md` are byte-identical duplicates
  (should be an `@import`); there is no `settings.json` permission scoping, so
  the guardrails live only in advisory prose, not harness-enforced rules.
- Org scaffolding: the handbook is the content source of truth but has no
  source-to-instance propagation channel (no `copier update`, no drift
  detection) — the deepest structural gap.
- Dependency automation: none; Dependabot's 2025-2026 grouping features closed
  Renovate's former edge, and it is the prerequisite that keeps SHA-pins current.
- Docs frameworks: no ADRs (conventions are stated as fact with no rationale
  trail); the Diátaxis split is implicit; no docs-link lint.
- Licensing/REUSE: strong; the gaps are an SBOM with license data, a Node/Electron
  license gate, and a DCO decision before the first outside contribution.
- Containers/Pages: the Dockerfile lacks a non-root `USER`, a `HEALTHCHECK`, and
  an image scan; distroless is a watch item.
- Testing: no coverage floor; property, contract, mutation, and snapshot testing
  are opt-in opportunities; a flaky-quarantine policy is cheap to write now.

Notable fact-check corrections folded into the proposals: Azure Artifact Signing
(Windows) reached GA around January 2026 and issues non-EV certificates (not the
older EV-dongle framing); SPDX 3.0 is not yet an ISO standard (2.2.1 is), so
CycloneDX is the SBOM format to prefer now; `release-plz` is Rust/Cargo-only
(Marco Ieni), never a candidate for a polyglot family; the PEP 639 "2026-02-18"
date is a rolling deprecation warning, not a hard removal; GitHub Spec Kit is on
the 0.12.x line; and an unverified March-2026 Trivy-compromise report argues for
Syft as the default SBOM generator pending a check.

---

## Part 4 — Proposals

Organized around the two pillars of the organizing principle, then the
repo-organization and new-tooling questions, then the one deep structural fork.
Each entry carries a priority (P1 high value / low regret, P2, P3 speculative),
an effort (S/M/L), and a disposition: augment (add without removing),
preserve-bespoke (keep the bespoke tool, add a convention around it), or
replace-bespoke (swap a bespoke mechanism for a maintained tool). Per the chosen
framing, replace-bespoke entries state explicitly what is kept and what is
swapped; the org's default lean is bespoke-friendly, so those clear a high bar.
Bracketed numbers reference the synthesis items behind each.

### Pillar A — accelerate the shared loop, reduce friction

Supply-chain hardening (the largest cluster of near-free, low-regret wins;
sequence A1+A2 together, then A3/A4, then A5):

- A1 SHA-pin every third-party action with a trailing `# vX.Y.Z` comment,
  superseding the exact-version-tag rule, across all shared workflow templates
  (P1/S, augment). Closes the tag-retagging attack (the tj-actions/changed-files
  compromise). Must land with A2 or the pins rot. [3]
- A2 Adopt Dependabot org-wide via a per-language `dependabot.yml` template: a
  github-actions entry that does SHA-to-SHA bumps preserving the comment, a
  grouped weekly dependency update, a monthly lockfile-only group; document the
  automerge gate (patch auto-merges on green; minor/major need a human) and what
  an agent may do with a Dependabot PR unattended (P1/M, augment). Closes the
  long-deferred in-flight idea; keeps GitHub as the only trust boundary.
  Record the Renovate-declined decision to close the loop. [4]
- A3 Add `actions/attest-build-provenance` for GHCR image digests and Electron
  installers, and `--provenance=mode=max --sbom=true` on the buildx push, so the
  two artifact classes that lack registry-native provenance reach SLSA Build
  Level 2 (P1/S, augment). Depends on A4's token grants. [5]
- A4 Set workflow-level `permissions: {}` (default-deny) then grant per job in
  every template (P1/S, augment). Prerequisite for A3 and pre-empts the Scorecard
  token finding. [6]
- A5 Add an OpenSSF Scorecard workflow across the org (P2/S, augment), sequenced
  after A1/A4 so the first run reports genuine residual gaps. [20]
- A6 Generate and attach a CycloneDX SBOM at release and extend the copyleft
  license gate to the Node/Electron tree (P3/M, augment). Prefer Syft pending the
  Trivy-integrity check. [21]

One-source-of-truth repairs (the handbook drifting from its own reference apps):

- A7 Reconcile `electron-tooling.md` and the Electron templates with the
  signed+notarized config already in production on `conception-space` (Developer
  ID + App Store Connect API-key notarization + `hardenedRuntime`); delete the
  stale "unsigned for now" language (P1/S, augment). Transcribe from the live
  `main` files, not memory. [1]
- A8 Make `CLAUDE.md` a one-line `@AGENTS.md` import rather than a byte-identical
  copy, and simplify `sync-agent-files.sh` accordingly (P1/S, replace-bespoke:
  keeps the sync script for `AGENTS.md`, drops the dual full-render so divergence
  is impossible by construction). Confirm the pinned Claude Code version resolves
  `@`-imports. [2]
- A9 Pin `ty` to a narrow range in the template and every Python repo, with a
  one-line note that it is pre-1.0 and upstream-unstable (P1/S, augment). Closes
  the one hole in the committed-lockfile reproducibility guarantee. [7]

Point-of-action enforcement (moving "gate the irreversible" from prose to rules):

- A10 Add a `settings.json` permission-scoping template and an
  `agent-permissions.md` doc: allow read-only tools, ask on write/commit/push,
  deny secrets/`rm -rf`/force-push; cite the MCP `READ_ONLY→READ_WRITE→
  REMOVE_DESTRUCTIVE` ladder once and apply it to both MCP design and local agent
  permissions (P1/S, augment). Harness-enforced, unlike advisory `CLAUDE.md`
  prose. [8]

Changelog and CI hygiene:

- A11 Add a PR-title Conventional-Commit check on `develop` PRs so a mistyped
  prefix fails loudly instead of silently vanishing from the changelog
  (P1/S, augment). [9]
- A12 Label the LLM Highlights paragraph as machine-drafted and print it to the
  job summary before it ships, folding a read-before-ship moment into the
  existing bump-kind confirmation (P2/S, augment). [10]

Node/Electron correctness and security:

- A13 Add `publint` + `arethetypeswrong` as a pre-publish gate in the Node
  templates (P1/S, augment). A bad exports/types map is irreversible once
  published. [11]
- A14 Add Electron Fuses and a renderer-security baseline (contextIsolation,
  sandbox, no nodeIntegration, CSP) with a grep CI tripwire (P2/S, augment). [15]
- A15 Add a Windows signing path defaulting to Azure Artifact Signing (cloud HSM,
  no EV dongle, GA ~Jan 2026, non-EV certs) with the OV/EV alternative noted
  (P2/M, augment). Closes the largest remaining distribution gap (Windows ships
  unsigned). [19]

MCP currency and security:

- A16 Rename the mount path `/sse → /mcp` across the server family as a
  coordinated per-repo breaking release, preserving the raw-ASGI route with an
  explanatory comment (P2/S, replace-bespoke: renames the route, keeps the
  transport). [13]
- A17 Tighten CORS to an allowlist (or drop it for non-browser servers), validate
  the Origin header, default the bind to `127.0.0.1`, and add an honest "Auth
  model" section naming the shared token a pre-OAuth, localhost-only placeholder
  that must not be exposed publicly without a real OAuth 2.1 resource server
  (P2/S, augment). [14]

Testing, Python tooling, packaging, worktrees, merge safety:

- A18 Add low line-coverage floors (~70%, measure first) to the Python and Node
  templates and a one-paragraph "testing trophy" framing note (P2/S, augment).
  [12]
- A19 Document opt-in property (Hypothesis/fast-check), contract (Schemathesis
  against the MCP OpenAPI schema), snapshot (syrupy), and release-time mutation
  (mutmut on the permission-scope logic) testing, plus a "quarantine, don't
  blind-rerun" flaky policy (P3/M, augment). Opt-in framing is load-bearing. [30]
- A20 Add PERF and TRY to the ruff selector and an optional `pylock.toml` export
  (P3/M, augment). [29]
- A21 Harden the uv-in-Docker template: non-root `USER`, the cache-split layers,
  a `HEALTHCHECK` against the existing `/health`, and a non-blocking image scan
  (P3/M, augment). [22]
- A22 Add a per-worktree "run `uv sync`/`npm ci` on creation" convention (the one
  documented worktree footgun) (P2/S, preserve-bespoke). [25]
- A23 Enable GitHub's native merge queue on the protected trunk and document an
  explicit hotfix procedure (branch off `main`, patch-tag, backport)
  (P2/S, augment). Cheap insurance; low urgency at current PR concurrency. [24]

The visionOS profile (new ground; `vos-gspheres` is the reference, once its
version-SoT is fixed):

- A24 Add a `swift-tooling.md` + `visionos-tooling.md` doc pair (analogous to
  `node-tooling.md` + `electron-tooling.md`) codifying the verified shape: pinned
  `macos-26` runner + explicit Xcode select, Swift Testing + swift-format + SPM
  with committed `Package.resolved`, Swift 6 approachable concurrency, the
  RealityKit-free testable-core split, REUSE globs for `.usdz`/`.rcproject`, and
  XcodeGen-committed-with-drift-check (with buildable-folders noted as the
  lower-ceremony alternative) (P1/M, augment).
- A25 Fix the version-SoT violation: a single `Version.xcconfig` holding
  `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION` with
  `GENERATE_INFOPLIST_FILE=YES` so no `Info.plist` literal is hand-maintained;
  extend `git bump`/`git release`/`_sot.sh` with an `.xcconfig` SoT-shape
  detector; derive the build number in CI as a single monotonic integer (P1/M,
  augment). This restores the "one source of truth" axiom for Apple repos and is
  the clearest concrete win from reading `vos-gspheres`.
- A26 Build the visionOS release path: fastlane lanes (archive, sign via
  `import-codesign-certs`, `upload_to_testflight`); the App Store Connect `.p8`
  key as the one justified long-lived-secret deviation (Apple has no OIDC;
  Electron notarization is the precedent); redefine release success as "uploaded
  to TestFlight" with App Store submission a human-gated step; add
  `test-vision.yml` + `release-vision.yml` templates (P2/M, augment).

### Pillar B — the self-improvement governance loop

The part the organizing principle places load-bearing weight on: making it easy
for humans and AIs to discover, suggest, debate, and decide upon improvements to
the tools and processes, symmetrically and with a durable trail.

- B1 Add a fifth northstar intent, "the environment improves itself": both human
  and AI developers can raise, debate, and land improvements to the shared tools
  and processes through a defined, low-friction loop, and the friction they hit
  becomes the backlog (P1/S, augment). Written to the canonical `northstar.md`
  first, then the designed HTML. This is the principle articulated above,
  surfaced per the write-it-down discipline rather than acted on silently.
- B2 Define a lightweight proposal (RFC) lifecycle usable by humans and AIs
  alike: evolve `in-flight_ideas.md` from a flat scratchpad into a backlog with
  explicit states (raised → in discussion → decided → recorded/dropped), each
  entry carrying who/what/why and a decision; humans enter via a GitHub issue
  template, agents via a "propose-improvement" skill (C2/C3 family) that files
  into the same backlog; a stated periodic triage turns raised items into
  decisions, including recognizing an idea that has proven to be settled direction
  and promoting it into `future-goals.md` (B7), so the promotion path is an
  explicit triage outcome rather than an accident (P1/M, augment). This is the
  discover-suggest-debate-decide loop made concrete; it generalizes the existing
  `in-flight_ideas` convention rather than replacing it.
- B3 Add an ADR log (`docs/decisions/`, plain Nygard template), a one-paragraph
  Diátaxis map in `documentation.md`, and a docs-link lint (P2/S, augment).
  Back-fill 3-5 load-bearing decisions (two-trunk vs trunk-based, the worktree
  layout, the dual-license option, the dev-versioning scheme). ADRs are the
  "decided → recorded" terminus of B2's loop. [18]
- B4 Add a friction-capture channel ("papercuts"): a defined, near-zero-friction
  way for a human or an agent to log a friction hit mid-work (a labelled issue, a
  `docs/papercuts.md`, or an agent skill) that feeds B2's backlog rather than
  being forgotten (P2/S, augment). This is the "adaptable environment" half of
  the ask, and it extends the existing memory/feedback pattern the org already
  uses with its AI collaborators.
- B5 Write down the considered-and-declined decisions the research validated
  (keep `git bump` over release-please/semantic-release/changesets; keep ESLint
  over Biome/oxlint; decline Graphite, Backstage, Harden-Runner for now), each a
  short note with an explicit revisit trigger (P2/M, preserve-bespoke). Turns
  silent choices into auditable decisions so they are not re-litigated from
  generic advice. Include one rule whose rationale is currently unwritten: why
  dev builds are on-demand and never per-merge. A dev build is a gated publish,
  so a push-to-`develop` trigger would flood TestPyPI and the multi-arch and
  multi-OS CI matrices and drain the `.devN` sequence of meaning; recording that
  forecloses a well-meaning future change (an agent wiring `dev-release` to fire
  on merge as an apparent automation win) and belongs alongside the rule in
  `releases.md`. [27]
- B6 Document the already-active-but-unwritten mechanisms (PyPI PEP 740
  attestations and npm provenance already produced free; REUSE.toml already the
  chosen primitive) with one-line verification commands (P3/S, augment). A silent
  mechanism fails "self-describing" as much as a missing one. [28]

- B7 Add a `future-goals.md` per-repo documentation convention, a third sibling
  to `northstar.md` and `in-flight_ideas.md` (P2/S, augment). It records decided
  directional goals a repo is heading toward but has not yet built: the
  destination is agreed, the work is future. It is distinct from the other two,
  and the distinction is the point: the northstar is the timeless *why* (intent);
  `in-flight_ideas.md` is the *undecided* (questions weighed, then promoted or
  dropped); `future-goals.md` is the *decided-but-unbuilt where*. The load-bearing
  difference from an in-flight idea is that the guardrail inverts. An in-flight
  idea must not influence present design, because it is undecided; a future goal
  *should* shape present design, so a developer builds forward-compatibly toward
  it. The canonical example is the one that prompted this: build the librarian to
  speak MCP now, so it can re-point at cobalt-grinding's MCP once the handbook
  lives in the corpus, with no rework. Format: a terse declarative goal, the
  northstar intent it serves, an optional "design for this now" note, and a
  status; no dates (a dated roadmap is heavier ceremony than the ethos wants, and
  is why `future-goals` is a better name than `roadmap`). Lifecycle (paths, not a
  strict pipeline): an in-flight idea may be promoted to a future goal when it is
  accepted as direction, or go straight to a plan, or be dropped; and a future
  goal may also be declared directly from the intent without passing through the
  scratchpad. A future goal, once worked, becomes a plan and an implementation and
  is removed when reached (optionally recorded as an ADR).
  This composes with B3: `in-flight_ideas` (question), `future-goals` (direction), and
  ADRs (decision record) form one coherent trail, the write-it-down axiom across a
  fact's whole life, and it directly serves the "adaptable environment" of the
  organizing principle. Document it in `documentation.md` beside the northstar and
  in-flight conventions; author's-choice per repo like the others. The handbook's
  own `future-goals.md` would seed with the LLM-Wiki convergence, the enforced
  `ai-collaboration` layer (C3), and the Copier propagation channel (C6). Targets:
  `handbook/docs/documentation.md`, a new `handbook/docs/future-goals.md`, and
  `new-repo-checklist.md` (list it beside `in-flight_ideas.md`).

### Repo organization and new tooling (the explicit asks)

On whether to combine or reorganize `handbook` and `dev-tools`, and what new
human and AI tools to build:

- C1 Keep the split but unify installation. The two repos play genuinely
  different roles (the handbook is read-oriented documentation and the content
  source of truth; `dev-tools` is executable bash `git pull`-and-symlinked onto
  `PATH`), and merging them would entangle a reference doc with a globally
  installed toolkit. The higher-value move is to widen `dev-tools` (or a sibling
  installer) so one command sets up "the ParkviewLab way of working" for both
  audiences: the human `git-*` scripts and a set of AI artifacts (Claude Code
  skills, hooks, and a `settings.json`) generated from the handbook's canonical
  docs, on the `claude-style-policy` pattern (P2/M, augment). The augment/replace
  tradeoff: merging the repos is the replace option (one "engineering" repo,
  simpler to discover, but couples doc and tool release cadence and breaks the
  clean install boundary); this recommendation is the augment option. I lean
  toward keeping them separate and unifying the installer.
- C2 Package the release procedure as a Claude Code skill shipped from the
  handbook and synced per repo, with the `git bump`/`git release` bash kept as
  the mechanism; optionally add PreToolUse guardrail hooks that deny force-push
  and direct version-SoT edits outside a release invocation (P3/M, augment). A
  new AI tool that loads the multi-step procedure on invocation instead of
  carrying it in every session's context. [26]
- C3 Deliver the `ai-collaboration.md` behavioural contract as an enforced layer,
  not only pointer prose: a small ParkviewLab Claude Code plugin/hook set (a
  per-prompt digest, an optional review hook, a `settings.json`) generated from
  `ai-collaboration.md` as the one source, applying the four-layer
  `claude-style-policy` pattern to the org's own norms (shared-state
  authorization, propose-bump-kind, no-sycophancy) (P2/M, augment). The strongest
  "new AI tool" candidate the survey surfaced: it directly serves "legible to and
  enforced for AI" and closes the long-session adherence-erosion gap that static
  pointer files have.
- C4 Bring `claude-style-policy` (or a generalized, org-scoped variant of it)
  into the family and onto the handbook shape, or at least reference its pattern
  from `ai-collaboration.md` (P3/S, augment). It is currently a personal,
  single-trunk, unlicensed repo outside the org; its mechanism is org-relevant.
- C5 Candidate new human dev-tools, each small and cross-cutting enough to earn a
  place in `dev-tools`: a `git worktree-new` helper that creates the prefixed
  sibling worktree and runs `uv sync`/`npm ci` (implements A22); a `git new-repo`
  scaffolder that stands up the contained layout and branch protection; and a
  propagation/drift runner (folds into C6) (P3/M, augment).
- C6 Adopt Copier as the source-to-instance propagation engine, turning the
  verbatim-copied templates into a `copier.yml` template with per-repo
  `.copier-answers.yml`, so a handbook change reaches existing repos via
  `copier update` and drift is detectable; absorb `sync-agent-files.sh` into it;
  add scheduled review-only propagation PRs and a drift check (P2/M then P3/M,
  replace-bespoke: replaces verbatim-copy + the marker-block awk script, which
  genuinely lack update/drift capability; spike on one repo family first). This
  is also Pillar B infrastructure: it is how a decided improvement actually
  reaches all repos. [16][17]

- C7 Give a fresh Claude Code session a deterministic, bounded onboarding path
  in place of "point at the handbook and familiarize yourself" (augment). The
  failure today, now confirmed against current Claude Code behavior: only
  `CLAUDE.md` is auto-loaded (not `AGENTS.md`), and `@`-imports resolve local
  paths only (never a URL, recursion capped at four hops), so the pointer files'
  GitHub links load no handbook content at all, and each session reads an uneven
  slice or nothing. A layered fix, cheapest first:
  - C7a (P1/S): have `dev-tools`' `install.sh` keep a local clone of the released
    handbook (`main`) at a known path, and auto-load a bounded, derived digest
    (northstar plus the non-negotiable rules plus a doc-map with "read doc X
    before doing Y" triggers, kept under ~200 lines) via an absolute `@`-import
    in each repo's `CLAUDE.md`. Every session then gets a curated baseline and
    the full docs are locally present for on-demand deep reads. The digest is
    generated from the docs (or its update is procedural, part of any doc
    change), so it cannot drift into a second source. This alone captures most of
    the value and is small.
  - C7b (P2/M): a `/handbook` (or `/onboard`) skill whose description
    eager-loads (cheap) and whose body dispatches a handbook-librarian subagent
    to read and summarize the task-relevant docs in an isolated context,
    returning a brief so the main session stays lean. Skills load their body only
    on invocation, so this costs nothing until used.
  - C7c (P3/M): a handbook MCP server exposing the docs as searchable resources
    plus a lookup tool, retrieved on demand, deployable wherever the org runs
    its internal services. It composes with C7b: the librarian subagent becomes
    the in-session client that queries this shared backend. Do not over-build a
    bespoke handbook MCP, though: the org is converging on an LLM-Wiki (jonobones
    over a Joplin Notes corpus, with cobalt-grinding operating on it and exposed
    to Claude Code as an
    MCP server). The durable end state is to fold the handbook into that knowledge
    substrate and let cobalt-grinding's MCP serve it, so the librarian queries one
    corpus rather than a proliferation of doc servers; a near-term thin handbook
    MCP (or just C7a's local clone plus the librarian) is the pragmatic start that
    converges onto that substrate rather than becoming throwaway.
  Bundle C7b/C7c (the skill, the subagent, an optional `SessionStart` digest
  hook, and the MCP config) as a small ParkviewLab Claude Code plugin distributed
  via a private GitHub marketplace, versioned with the handbook; this is also the
  distribution channel for C2 (the release skill) and C3 (the enforced
  `ai-collaboration` layer). One-source-of-truth spine: the digest is derived
  from the docs, the skill/subagent/MCP all read the local clone of released
  `main`, nothing is hand-duplicated. Graceful degradation is a hard requirement:
  C7a (the local clone + digest) must not depend on any server, so a session
  works fully offline; the MCP server is an enhancement, never a dependency (per
  the self-contained axiom). Confirm the org-marketplace maturity
  against the installed Claude Code version, since sources disagree
  (GitHub-hosted private marketplaces read as GA in the current docs, while the
  earlier sweep flagged enterprise private-marketplace features as beta); C7a
  needs no plugin and is unaffected. Targets: `handbook/docs/` (a generated
  digest + doc-map), `templates/CLAUDE.md.template`, `dev-tools/install.sh`, a
  new `templates/skills/handbook/`, and a plugin/marketplace repo. Reinforces A8
  (only `CLAUDE.md` auto-loads, so the `@AGENTS.md`-import shape is also the
  correct auto-load shape).

### Branching: keep the two-trunk model, automate its tax

- D1 Keep the permanent two-trunk model (`develop` + `main`); do not move to
  release-from-main (decided 2026-07). The prevailing DORA/Atlassian guidance
  against a permanent `develop` is weaker here than it looks: the org already
  integrates through short-lived branches, so it does not suffer the
  delayed-integration pain trunk-based development exists to remove; it merely
  keeps a second permanent line, and that line earns its keep. The
  main-is-published invariant is genuinely valuable for read-consumed repos, the
  handbook above all, whose pointer files reference `/tree/main` precisely because
  `main` is the released conventions rather than the churning working line; the
  two trunks also give a legible structural map (`develop` = the integration and
  on-demand-dev-build surface, `main` = the release surface) that a one-trunk
  model would trade for a subtler tag-and-workflow distinction; and retiring
  `develop` would be a broad, family-wide migration touching every repo's
  protection, the version-guard base, the release gate, the `dev-tools` scripts,
  and the `live`/`staging` website profile, all to remove a bounded,
  self-correcting cost.

  Instead, automate that cost (P2/S-M, preserve-bespoke + augment). A
  `git back-merge` dev-tool runs the whole post-release tail as one command from
  the `<repo>-main` worktree: pull `main`, merge it down to `develop`, push, open
  the next dev cycle via the existing `git dev-release --open`, and fan `develop`
  out to each open working worktree. A promotion staleness guard (a `git promote`
  command, or a check folded into the flow) fetches `origin` and refuses
  `git merge --no-ff develop` unless local `develop` equals `origin/develop`,
  closing the stale-local-`develop` footgun that CI cannot catch, since the wrong
  commit is still reachable from `main`. Fold both into the release skill (C2) so
  neither is ever forgotten: the mechanical tail becomes one command inside the
  skill, while the irreversible tag push stays the explicit human step. Record the
  keep-two-trunk choice as an ADR (B3) with its revisit trigger stated, reconsider
  the model only if automating the cascade fails to remove the pain, since a
  deliberate divergence from the prevailing guidance is exactly what the ADR log
  exists to capture. Ties C2, C5, B3.

### Priority summary

P1 (high value, low regret): A1, A2, A3, A4, A7, A8, A9, A10, A11, A13, A24, A25,
B1, B2, C7a.
P2: A5, A12, A14, A15, A16, A17, A18, A22, A23, A26, B3, B4, B5, B7, C1, C3, C6,
C7b, D1 (D1 decided: keep two trunks; remaining work is automating the cascade).
P3: A6, A19, A20, A21, B6, C2, C4, C5, C7c.

A natural first wave is the supply-chain and one-source-of-truth P1/S cluster
(A1+A2, A3+A4, A7, A8, A9) plus the two governance foundations (B1, B2): all
low-regret, mutually reinforcing, and each an instance of a pattern the org
already trusts.

---

## The backlog index

The condensed, scannable backlog lives in the sibling
[`in-flight_ideas.md`](in-flight_ideas.md); this notebook holds the detail behind
each entry. As candidates are promoted or dropped, that index is the working
reference and this notebook is the rationale.

---

## Verification / how to proceed

This notebook is research and proposals, so "verification" is about the
soundness of the inputs and the safe path to acting, not a test suite.

- Provenance of the findings: both repos were read in full; the org and two
  private repos (`vos-gspheres`, `claude-style-policy`) were read directly; the
  external SOTA came from two research workflows whose load-bearing claims were
  adversarially re-checked, with the surviving corrections folded into Part 4.
  Before acting on any single proposal, re-confirm its version-sensitive facts
  (the watch-list items especially), since this field moves monthly.
- How to act, respecting the org's own gates: each proposal is a candidate for
  the normal flow, not a change to merge from here. The recommended sequence is
  to (1) choose candidates from the condensed backlog in `docs/in-flight_ideas.md`; (2)
  take the first wave (A1+A2, A3+A4, A7, A8, A9, B1, B2) each as its own
  prefixed working branch and PR into the handbook per `branching.md`, the human
  reviewing and merging; (3) treat C6 (adopting Copier) as a
  decide-first item, and record the now-settled D1 branching choice as an ADR.
- Rollout is two steps, not one: a handbook PR updates the source of truth and
  what new repos inherit, but a convention like A1 takes effect only when each
  existing repo's own copy carries it, since repos run their own workflows. So
  most template-and-convention proposals (A1-A6, A9, A11, A13, A14, A18, A20-A22,
  C7a, among others) are a handbook change followed by a per-repo rollout, each
  repo's change on its own `ci-`/`ops-` branch. Until C6 lands, that second step
  is a manual re-copy; C6 (Copier `copier update` plus scheduled propagation PRs)
  is the channel that will eventually automate it, turning the rollout into one
  reviewed PR per repo.
- End-to-end checks once items land: `reuse lint` stays green; a template change
  is validated by bootstrapping one throwaway repo from it (or `copier copy`
  once C6 lands); the SHA-pin + Dependabot pair is verified by confirming a
  Dependabot PR preserves the `# vX.Y.Z` comment; the attestations by
  `gh attestation verify`; the visionOS version-SoT fix by confirming the built
  app's About/`CFBundleShortVersionString` equals `Version.xcconfig` with no
  hand-edited literal; and the enforced agent layer (C3) by the same live-session
  marker checks `claude-style-policy` already documents.
