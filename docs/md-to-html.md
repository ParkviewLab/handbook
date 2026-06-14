<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Authoring HTML from Markdown

ParkviewLab does **not** mechanically convert Markdown to HTML. There is no
`md2html` tool. The HTML is **authored** — by an AI or a human — who reads the
document, thinks about it, and **reworks it for visual impact** wherever that
increases the reader's understanding. A 1:1 dump of the Markdown is a failure;
the whole point is that the HTML does something the linear Markdown can't.

This is the method. The brand tokens are in [`brand.md`](brand.md); the starting
scaffold is
[`templates/md-to-html/default.html`](../templates/md-to-html/default.html).

## When to make an HTML version at all

For high-impact documents — the northstar, manifestos, key onboarding or values
docs — where clarity and impact matter. Routine docs (per-file READMEs, ADRs,
code comments) stay Markdown. When in doubt, ask whether the visual channel would
actually carry meaning the prose can't; if not, skip it.

## The method

1. **Read the whole Markdown first.** Find its *shape* — the parts that are a set
   perceived at a glance (peers, a constellation), a contrast (this vs that), a
   process (a flow), a hierarchy. Those are the candidates for visual treatment.
2. **Start from the scaffold.** Copy `default.html` next to the source
   (`docs/foo.md` → `docs/foo.html`). It already has the brand palette, the
   embedded Michroma, the logo mark, and example patterns.
3. **Rework layout, keep wording.** Move structure into the visual channel:
   - a set of peers → a card grid (the reader sees "there are N; they're equal");
   - a contrast → two side-by-side panels;
   - a process/relationship → a bespoke inline SVG;
   - a key caveat → a callout.
   Keep the *wording* faithful to the Markdown — bit-precise where you can. If you
   must reword for visual rhythm, preserve the meaning exactly.
4. **Add bespoke SVG only where it earns its place.** A diagram that *shows* a
   relationship beats a list of it. Build it from the brand tokens.
5. **Verify the discipline** (below).

## Discipline (non-negotiable)

- **One self-contained file.** Inline `<style>`, inline `<svg>`. No external CSS,
  no JS framework, no build step.
- **No network.** Michroma is embedded as base64 `woff2` (the scaffold already
  does this). Use the **logo-only mark** inlined + an inline Michroma wordmark —
  the horizontal/stacked logo SVGs `@import` Google Fonts and must not be used in
  standalone HTML (see [`brand.md`](brand.md)).
- **Brand, used with restraint.** Three brand colours carry identity; the Bauhaus
  accents are sparse seasoning. For every visual choice ask: does this *clarify*
  or *decorate*? If it decorates, cut it.
- **Responsive.** Collapse to a single column on narrow screens (the scaffold's
  `@media (max-width:680px)`).
- **Faithful.** MD is canonical. If they drift, MD wins and the HTML is
  re-authored.

## Verify before shipping

- Open it in a browser with no network — fonts, logo, and layout all render.
- Grep the file: no `http://`/`https://` fetches (the SVG XML namespace
  `http://www.w3.org/2000/svg` is fine — it's an identifier, not a request) and
  no `fonts.googleapis`.
- Resize to a narrow viewport — it collapses cleanly.
- Read it against the Markdown — wording faithful, and it is *more* legible than
  the linear source, not just prettier.

The exemplar to study first: `~/.claude/exemplars/northstar/` (a multi-intent
northstar shown as a card grid + SVG panels + an axiom constellation).
