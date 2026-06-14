<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Documentation conventions

## Where docs live

- **`README.md`** stays in the repo root — the standard entry point.
- **`docs/`** holds everything else of substance: `northstar.md`,
  `in-flight_ideas.md`, design docs, language references, and the HTML siblings of
  any of these.

## The northstar

Every repo has `docs/northstar.md` — the canonical statement of the project's
**intent** (why it exists), treated as authoritative even where it contradicts the
README or the code. Structure (from jonobones and conception-space):

1. **Intent** — one to several **complementary intents**, presented as peers (not
   one primary + the rest secondary). Two to four is the sweet spot. The tensions
   *between* intents are design-revealing — surface them rather than hide them.
2. **Axioms** — a numbered list of design principles derived from the intents.
   The same axioms support all the intents, from different angles.
3. **Guiding questions** (optional) — the questions the design keeps answering.
4. **"What X is not"** — an explicit scope/non-goals section.

When intent surfaces a new principle during work, propose adding it to the
northstar rather than acting on it silently.

## In-flight ideas

`docs/in-flight_ideas.md` is the scratchpad for **ideas under consideration** —
captured, not yet committed. Each entry is a question, not a plan; don't act on
one silently. When an entry grows big enough to deserve its own exploration,
split it into a sibling `docs/<topic>_ideas.md` (e.g. conception-space's
`hand-authoring_ideas.md`, `ai-authoring_ideas.md`); `in-flight_ideas.md` stays
the index.

> Some repos have an ad-hoc `humans_notes.md` (e.g. deco-assaying). Normalise
> these into `in-flight_ideas.md` when you touch them.

## README shape

ParkviewLab READMEs (especially the MCP servers) share a structure:

1. Title + one-line description (what it does, what it feeds).
2. Status (version, surface completeness, related repos).
3. **"Five ways to run it"** table — see
   [`packaging-and-deployment.md`](packaging-and-deployment.md).
4. Endpoints.
5. MCP tools, grouped by permission tier.
6. Configuration — an env-var table with defaults.
7. Releasing — the tag-driven flow (link to / mirror [`releases.md`](releases.md)).

## Designed HTML (dual-track)

For high-impact documents — the northstar, manifestos, key onboarding pieces —
keep an **MD canonical source** and author a **designed HTML presentation**
beside it. MD wins if they drift; HTML is re-authored from MD.

There are two HTML tracks:

- **Bespoke high-impact docs** (northstar, manifestos) — hand-authored layout
  using the brand tokens, with inline SVG where structure reads better seen than
  listed. The bar is `~/.claude/exemplars/northstar/` and
  `jonobones/main/docs/northstar.html`.
- **Other docs rendered to HTML** — also **AI-authored** from the MD (reworked
  for impact), *not* mechanically converted. See [`md-to-html.md`](md-to-html.md).

Both tracks follow the discipline: one self-contained file, no build step, no
network, responsive, faithful to the MD wording. The brand (palette + Michroma)
is in [`brand.md`](brand.md); the starting scaffold is
[`templates/md-to-html/default.html`](../templates/md-to-html/default.html). A
project may override with its own scaffold.

## Copyright footers

Every file carries its SPDX header at the top (compliance — see
[`licensing.md`](licensing.md#copyright-statements-spdx-header-vs-visible-footer)).
**Published/standalone docs** also carry a *human-visible* copyright statement, so
a reader of the rendered page sees it:

- **HTML** → in the page `<footer>` (e.g. `© 2026 Gary Frattarola · CC-BY-4.0`).
  The brand scaffold's footer already has the slot.
- **Markdown** → at the **bottom**, after a `---` rule. Bottom, not top: the top
  is the title + the (rendered-invisible) SPDX comment, and a footer is where
  readers expect copyright.
  ```markdown
  ---
  <sub>© 2026 Gary Frattarola · Licensed under [CC-BY-4.0](../LICENSES/CC-BY-4.0.txt) · part of the ParkviewLab handbook</sub>
  ```

Apply it to the docs likely to be read rendered or on their own (HTML, the root
README, the northstar). Internal topic docs rely on their top SPDX header. Keep
the footer consistent with the header (same year, holder, license).
