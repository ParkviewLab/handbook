<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Documentation conventions

## Where docs live

- **`README.md`** stays in the repo root — the standard entry point.
- **`docs/`** holds everything else of substance: `northstar.md`, `in-flight_ideas.md`, design docs, language references, and the HTML siblings of any of these.

## Line feeds in markdown

Markdown prose is never hard-wrapped. A line feed appears only where a break is meant: between paragraphs, list items, headings, table rows, and lines of code. A prose paragraph, a list item, or a blockquote paragraph is one line, and the viewer or editor wraps it; insert a line feed where you want a break, never to make a long line wrap.

The reason is editability. A hard-wrapped paragraph cannot be edited by hand without managing the line feeds, and re-flowing it produces the very diff the wrapping was meant to avoid. The rule applies to every markdown file in a repo, `templates/` included; the handbook's own files follow it.

## The northstar

A repo **may** have a `docs/northstar.md` — the author's choice, not a requirement. Start one from [`templates/northstar.md`](../templates/northstar.md). When present, it's the canonical statement of the project's **intent** (why it exists), treated as authoritative even where it contradicts the README or the code. Structure (from jonobones and conception-space):

1. **Intent** — one to several **complementary intents**, presented as peers (not one primary + the rest secondary). Two to four is the sweet spot.
2. **Axioms** — a numbered list of design principles derived from the intents. The same axioms support all the intents, from different angles.
3. **Guiding questions** (optional) — the questions the design keeps answering.
4. **"What X is not"** — an explicit scope/non-goals section.

When intent surfaces a new principle during work, propose adding it to the northstar rather than acting on it silently.

**The northstar leads.** Its authority over the code means an *unintended* disagreement between them is a defect in the code. An *intended* one is a change of intent, and a change of intent is made in the northstar first, in the same pull request as the code that follows it, so that no disagreement is left standing by accident. The same discipline applies to any document a repo names as an authority (a specification, a design doc): the PR that changes what it specifies amends it too.

## In-flight ideas

`docs/in-flight_ideas.md` is the scratchpad for **ideas under consideration** — captured, not yet committed. Each entry is a question, not a plan; don't act on one silently. When an entry grows big enough to deserve its own exploration, split it into a sibling `docs/<topic>_ideas.md` (e.g. conception-space's `hand-authoring_ideas.md`, `ai-authoring_ideas.md`); `in-flight_ideas.md` stays the index.

> Some repos have an ad-hoc `humans_notes.md` (e.g. deco-assaying). Normalise these into `in-flight_ideas.md` when you touch them.

## Discovered tangents

Work turns up work. An idea discovered whilst doing something else (a fix belonging to another repo, a convention worth adopting, debt worth paying, a direction for a project not yet started) is either done then, in parallel, or set aside, and the ones set aside are recorded in the org's wiki, in a register named Discovered Tangents, one page per idea. The register sits outside the repos on purpose: a pull request in a foreign repo for one paragraph costs more than the idea is worth at the moment of discovery, and an idea belonging to no repo yet has no file to go in.

Recording is authorised in advance and interrupts nothing; saying so is required, in one line naming the idea and its page, because the register is read to decide when and how to act. The register is the inbox, `docs/in-flight_ideas.md` is the repo's considered list, and an idea moves from the one to the other by an ordinary `doc-` pull request when the project is next worked and the idea is ripe. Ripeness is the user's call, proposed and not assumed. The procedure is the `tangent` skill; the entry's shape and its tags are in the wiki librarian's definition, [`bookstack-librarian.md`](../templates/agents/bookstack-librarian.md).

## Documents and records

A repo's Markdown is of two kinds, and the kind decides what may describe the past. A **record** does, and keeps doing so: `CHANGELOG.md`, a decision log (`docs/decisions.md`, or a dated "Decided" section), and a `<page>-why.md` sibling, which is the decision log of one page and is earned when that page's rules were chosen among alternatives worth keeping ([`agents-why.md`](agents-why.md) is the first). Everything else is a **current-state document** (the README, the northstar, a guide, a runbook, a contract, a design or architecture document) and describes the software and the project as they are now: no planning tense, no open question (those live in `in-flight_ideas.md`), no build history, no list of what remains, no deadline. A stated trigger for a future change ("when a second repo adopts this, the script moves to `dev-tools`") is direction, not a plan left behind, and stays until the trigger has occurred. A document declares its kind by its title or its opening line; one that does not is current-state. `in-flight_ideas.md` and the `<topic>_ideas.md` notebooks are outside both kinds: they are the home of open questions, and are checked only for entries the repo or the session has since answered.

Two rules follow. A decision is recorded impersonally: the date, the decision, and the reason, never the person ("decided on 2026-09-17: nginx's own listing for a folder without an index, because a bare list of files is what one wants before an index exists"); the git history and the pull request hold who. And a document is checked for currency before it is published: before a docs PR, before a release (a release publishes `main`'s documents, on the docs site where there is one, [`docs-site.md`](docs-site.md)), and before an HTML twin is authored from it, the session dispatches `docs-currency-checker` ([`agents.md`](agents.md)). It verifies each checkable claim against the code, by execution where the stack allows it and otherwise against the implementing source, finds planning tense and answered questions, compares the documents with each other, and takes from the session the decisions made in conversation, since those are invisible in the repo until written down. Its report is a claim the session verifies; its verdict says whether the documents are publishable.

A design document written before the code is the common case of a document that goes stale. Once the code exists, the document is rewritten in the present tense from the code, its dated decisions move to the decision log, and its work plan goes: git and the pull requests are that record.

## README shape

ParkviewLab READMEs (especially the MCP servers) share a structure:

1. Title + one-line description (what it does, what it feeds), then, for a repo that publishes its `docs/` as a site, one line on its own: `Documentation: https://parkviewlab.github.io/<repo>/` (the newest release's documentation). When it goes in is in [`docs-site.md`](docs-site.md#enabling-it-on-a-repo).
2. Status (version, surface completeness, related repos).
3. **"Five ways to run it"** table — see [`packaging-and-deployment.md`](packaging-and-deployment.md).
4. Endpoints.
5. MCP tools, grouped by permission tier.
6. Configuration — an env-var table with defaults.
7. Releasing — the tag-driven flow (link to / mirror [`releases.md`](releases.md)).

## Designed HTML (dual-track)

For high-impact documents — the northstar, manifestos, key onboarding pieces — keep an **MD canonical source** and author a **designed HTML presentation** beside it. MD wins if they drift; HTML is re-authored from MD.

There are two HTML tracks:

- **Bespoke high-impact docs** (northstar, manifestos) — hand-authored layout using the brand tokens, with inline SVG where structure reads better seen than listed. The bar is this handbook's own [`northstar.html`](northstar.html) (what to study in it is listed in [`md-to-html.md`](md-to-html.md)) and jonobones's `docs/northstar.html`.
- **Other docs rendered to HTML** — also **AI-authored** from the MD (reworked for impact), *not* mechanically converted. See [`md-to-html.md`](md-to-html.md).

Both tracks follow the discipline: one self-contained file, no build step, no network, responsive, faithful to the MD wording. The brand (palette + Michroma) is in [`brand.md`](brand.md); the starting scaffold is [`templates/md-to-html/default.html`](../templates/md-to-html/default.html). A project may override with its own scaffold.

## Links between a repo's own documents

**A link to a file in the repo's own tree is relative** — to the `.html` twin where one exists, otherwise to the `.md` — and never an absolute `https://github.com/ParkviewLab/<repo>/blob/…` URL to the same repo.

The reason is that the same file is read in several places. A relative link resolves in the working tree, in GitHub's blob view, and on a published documentation site alike; an absolute one always lands on whatever `main` (or the pinned ref) holds, so an author clicking through from their working copy reads a *different version* of the document than the one they are editing, and a reader of the site is taken off it.

Two things are outside the rule:

- **GitHub's own UI surfaces** for the repo — the releases page, the tags list, a branch or tree view, an issue or pull request. There is no file in the tree to point at, so these are absolute (this handbook's README links to `tree/main` and to `tags` that way).
- **Tag-pinned links a site generator emits** (`blob/vX.Y.Z/docs/<file>.md`), which must be absolute because the published site cannot render Markdown. See [`docs-site.md`](docs-site.md#markdown-links).

Links to *other* repos are absolute, of course; the rule is about self-links.

## Publishing `docs/` as a site

A public repo may publish its own `docs/` at `https://parkviewlab.github.io/<repo>/`, built from `main` so the site always shows the newest **released** documentation. How that works — the generated index, the build script's contract and guarantees, and what it costs to correct a document after a release — is [`docs-site.md`](docs-site.md).

## Copyright footers

Every file carries its SPDX header at the top (compliance — see [`licensing.md`](licensing.md#copyright-statements-spdx-header-vs-visible-footer)). **Published/standalone docs** also carry a *human-visible* copyright statement, so a reader of the rendered page sees it:

- **HTML** → in the page `<footer>` (e.g. `© 2026 Gary Frattarola · CC-BY-4.0`). The brand scaffold's footer already has the slot.
- **Markdown** → at the **bottom**, after a `---` rule. Bottom, not top: the top is the title + the (rendered-invisible) SPDX comment, and a footer is where readers expect copyright.
  ```markdown
  ---
  <sub>© 2026 Gary Frattarola · Licensed under [CC-BY-4.0](../LICENSES/CC-BY-4.0.txt) · part of the ParkviewLab handbook</sub>
  ```

Apply it to the docs likely to be read rendered or on their own (HTML, the root README, the northstar). Internal topic docs rely on their top SPDX header. Keep the footer consistent with the header (same year, holder, license).
