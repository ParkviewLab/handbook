<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# ParkviewLab brand

This is the single source of truth for the ParkviewLab visual brand. It is
extracted verbatim from the live site (`parkviewlab.ai/assets/style.css` and
`assets/img/`). When the brand changes, change it on the site first, then
mirror the change here.

The brand exists so that ParkviewLab documents — especially designed HTML
(see [`md-to-html.md`](md-to-html.md)) — share one coherent look without a
build step, a CSS framework, or a network call.

> **Relationship to the global "dual-track HTML" discipline.** The generic
> discipline (system fonts only, three colours max) is a sensible default *in
> the absence of a brand*. ParkviewLab has a brand, so for ParkviewLab docs the
> brand below **supersedes** that default. We keep the discipline's spirit:
> one self-contained file, no build step, no network — which is why Michroma is
> embedded as a base64 `woff2`, not fetched.

## Palette

The canonical tokens, as CSS custom properties. Use the variable names; do not
hard-code the hexes in new docs.

| Token | Hex | Role |
|---|---|---|
| `--teal` | `#00C2C7` | Brand accent — rules, marks, links-on-hover-target |
| `--teal-deep` | `#004f52` | Brand primary — headings, links |
| `--sage` | `#90b095` | Brand secondary — the logo's foliage, soft fills |
| `--ink` | `#141414` | Primary text, borders |
| `--red` | `#E2483D` | Bauhaus/Kandinsky accent — hover, emphasis |
| `--blue` | `#2547C8` | Bauhaus/Kandinsky accent |
| `--yellow` | `#F2B33D` | Bauhaus/Kandinsky accent |
| `--paper` | `#f3eee2` | Page background |
| `--paper-2` | `#ece5d4` | Secondary surface, chips |
| `--card` | `#fbf8f1` | Card surface |
| `--muted` | `#5d6258` | Secondary text |
| `--code` | `#161412` | Code-block background |
| `--code-text` | `#ece5d4` | Code-block text |

The three brand colours (`--teal`, `--teal-deep`, `--sage`) carry identity. The
three Bauhaus accents (`--red`, `--blue`, `--yellow`) are for emphasis and
should stay sparse — they are seasoning, not structure.

### `:root` block (copy verbatim)

```css
:root {
  /* Brand */
  --teal:#00C2C7; --teal-deep:#004f52; --sage:#90b095; --ink:#141414;
  /* Bauhaus / Kandinsky accents */
  --red:#E2483D; --blue:#2547C8; --yellow:#F2B33D;
  /* Surfaces */
  --paper:#f3eee2; --paper-2:#ece5d4; --card:#fbf8f1; --muted:#5d6258;
  --code:#161412; --code-text:#ece5d4;
  --mono:ui-monospace,SFMono-Regular,"SF Mono",Menlo,Consolas,monospace;
  --sans:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  --display:'Michroma',var(--sans);
}
```

## Typography

| Token | Stack | Use |
|---|---|---|
| `--display` | `'Michroma', <sans>` | Headings, the wordmark, section labels. Uppercase, wide letter-spacing. |
| `--sans` | system sans (`-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, …`) | Body text. |
| `--mono` | system mono (`ui-monospace, SFMono-Regular, "SF Mono", Menlo, …`) | Labels, chips, code, metadata. Often uppercase with letter-spacing. |

**Michroma** is the display face — geometric, wide, technical. It is the one
non-system font in the brand. Two rules:

1. **Self-host it.** The canonical file is
   [`brand/fonts/michroma-latin.woff2`](../brand/fonts/michroma-latin.woff2)
   (~11 KB). Never `@import` it from Google Fonts.
2. **In standalone HTML, embed it as base64** so the file stays single-file and
   offline. The default scaffold
   ([`templates/md-to-html/default.html`](../templates/md-to-html/default.html))
   already does this — reuse that rather than re-encoding.

Michroma is for display sizes only (headings, labels). Body copy is the system
sans — Michroma at paragraph size is unreadable.

## Logos

Three variants live in [`brand/logos/`](../brand/logos/):

| File | When to use |
|---|---|
| `parkview_lab_color_horizontal_dark.svg` | Wide contexts — site header, doc header bar. Mark + "PARKVIEW / LAB" wordmark. |
| `parkview_lab_color_stacked_dark.svg` | Square-ish contexts — cards, social, narrow columns. |
| `parkview_lab_color_logo_only.svg` | The mark alone — favicons, tight corners, **and any self-contained HTML** (it has no font dependency; pair it with an inline Michroma wordmark). |

The mark is a sage cluster (a stylised parkview hedge) beside a teal
node-and-edge figure (the "lab" — a graph/molecule). The colours are exactly
`--sage` (`#90b095`), `--teal` (`#00C2C7`), and `--teal-deep` (`#004f52`).

> **Caveat — the horizontal and stacked SVGs `@import` Google Fonts** for their
> baked-in wordmark text. That is fine on the website (already online) but
> **breaks the no-network rule for standalone HTML**. For designed HTML, embed
> `parkview_lab_color_logo_only.svg` (pure shapes) and set the wordmark in
> inline Michroma text. The default scaffold shows the pattern.

## Voice & tone

Short, technical, unembellished. Lowercase where it reads naturally; uppercase
display type for structure. No marketing adjectives. The writing matches the
[AI-collaboration norms](ai-collaboration.md): no hype, no filler, say the
thing. Mixed metaphors and clichés read as careless — avoid them.

## Licensing of brand assets

The **logos/marks** are **all rights reserved** (`LicenseRef-AllRightsReserved`),
not open-licensed like the rest of the repo — when a repo vendors a ParkviewLab
logo, that file keeps the all-rights-reserved SPDX tag. The **Michroma** font is
third-party under the **SIL Open Font License 1.1** (`OFL-1.1`) — bundle it with
its license text, don't relabel it. See
[`licensing.md`](licensing.md#per-bucket-licensing).
