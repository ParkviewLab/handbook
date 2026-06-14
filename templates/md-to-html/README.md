<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# MD → HTML default scaffold

`default.html` is the org default starting point for a **designed HTML
rendering** of a Markdown document. It is **not** a converter target — there is
no build step that injects content into it. ParkviewLab HTML is **authored**, by
an AI or a human, who reads the Markdown and reworks it for visual impact. See
[`docs/md-to-html.md`](../../docs/md-to-html.md) for the method and
[`docs/brand.md`](../../docs/brand.md) for the brand tokens.

## What the scaffold gives you

- The ParkviewLab `:root` palette and font stacks (verbatim from `brand.md`).
- **Michroma embedded as base64 `woff2`** — so the result is one file, offline,
  no network. (Already injected; don't re-encode unless the font changes.)
- The logo-only mark inlined in a header bar (pure shapes, no font dependency).
- Example patterns to draw from: hero, section label, peer-card grid, callout,
  chips, code blocks, and a slot for a bespoke inline SVG panel. **Delete what
  the document doesn't need.**
- Responsive single-column collapse at 680px.

## How to use it

1. Copy `default.html` next to the Markdown you're rendering (e.g.
   `docs/foo.md` → `docs/foo.html`).
2. Replace the hero, set `<title>` to `ParkviewLab · <doc>`, and rebuild the
   body from the Markdown — **rework the layout, keep the wording faithful.**
3. Add bespoke SVG only where a relationship/process reads better seen than
   listed.
4. Verify it opens standalone with no network requests (the discipline in
   `md-to-html.md`).

## Overriding per project

A project may keep its **own** scaffold instead of this one — same discipline
(one file, no build, no network, responsive), different look. Put it at
`docs/_scaffold.html` (or wherever the project documents) and author against
that. The handbook default is a starting point, not a mandate.
