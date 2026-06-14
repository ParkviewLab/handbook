<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Licensing & REUSE

This documents **how** ParkviewLab applies licensing — the file layout, the
[REUSE](https://reuse.software/) mechanics, the PEP 639 metadata, and the
per-bucket split. It does **not** mandate one license org-wide: **each repo's
license is chosen at creation time.** Current repos vary (some Python repos are
MIT with a single `LICENSE`; conception-space and cobalt-grinding are
AGPL-3.0-or-later + REUSE). When you adopt a license, apply it with the mechanics
below.

## File layout

- **`LICENSING.md`** (note the filename — *not* `LICENSE.md`) is the authoritative
  human-readable guide: the default open license, the **commercial alternative**
  (inquiries → `garyf@parkviewlab.ai`), and the copyright holder
  **Gary Frattarola**.
- **`LICENSE`** in the root holds the primary license text — kept there for
  GitHub's license auto-detection. (A **dual-permissive** repo instead ships
  `LICENSE-MIT` + `LICENSE-APACHE` and no single `LICENSE` — see
  [Permissive dual-licensing](#permissive-dual-licensing-mit-or-apache-20) below.)
- **`LICENSES/`** holds the full REUSE license texts (one file per SPDX id used,
  e.g. `AGPL-3.0-or-later.txt`, `CC-BY-4.0.txt`, `LicenseRef-AllRightsReserved.txt`).
- **`REUSE.toml`** is the catch-all annotator (see below).

## REUSE compliance — keep `reuse lint` green

Every file must have a license, either via a per-file SPDX header or a
`REUSE.toml` annotation. Check with:

```bash
uvx --from "reuse[charset-normalizer]" reuse lint
```

- **Per-file SPDX headers** on source files (`.py`, scripts, configs that take
  comments):

  ```python
  # SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
  # SPDX-License-Identifier: AGPL-3.0-or-later
  ```

  Bulk-apply with `uvx --from "reuse[charset-normalizer]" reuse annotate`.
- **`REUSE.toml`** annotates the rest (binaries, vendored assets, whole trees) so
  you don't touch files that should stay verbatim.
- Any **new** file must get a header or a `REUSE.toml` entry, or the lint breaks.

## Copyright statements: SPDX header vs. visible footer

Two different things, two different audiences — keep them straight:

<!-- REUSE-IgnoreStart -->
- **The SPDX header is the copyright statement of record, and the only one REUSE
  cares about.** `SPDX-FileCopyrightText:` + `SPDX-License-Identifier:` in the
  top comment (or `.license` / `REUSE.toml`) is what `reuse lint` checks. Every
  file has this.
- **A human-visible copyright footer is additive** — for people *reading* the
  rendered document (the top comment is invisible once Markdown/HTML is rendered).
  It does **not** satisfy REUSE on its own (REUSE needs the `SPDX-License-Identifier:`
  tag), so it never replaces the header.
<!-- REUSE-IgnoreEnd -->

**Where the visible footer goes** (placement detail lives in
[`documentation.md`](documentation.md#copyright-footers)):
- **HTML** — in the page `<footer>`, e.g. `© 2026 Gary Frattarola · CC-BY-4.0`.
- **Markdown** — at the **bottom**, after a `---` rule (not the top — that's the
  title + SPDX comment):
  ```markdown
  ---
  <sub>© 2026 Gary Frattarola · Licensed under [CC-BY-4.0](../LICENSES/CC-BY-4.0.txt) · part of the ParkviewLab handbook</sub>
  ```

Scope: the visible footer goes on **published/standalone docs** (HTML files, the
root README, the northstar). Internal topic docs rely on their top SPDX header.
Keep year, holder, and license consistent between header and footer.

## Per-bucket licensing

The established pattern (from conception-space) licenses different *kinds* of
content differently:

| Bucket | SPDX | What |
|---|---|---|
| Code, build scripts, configs, lockfiles, examples | `AGPL-3.0-or-later` | the program |
| Docs (`docs/`, `README.md`, `LICENSING.md`) | `CC-BY-4.0` | the writing |
| Brand / logo assets | `LicenseRef-AllRightsReserved` | the marks (not open) |

The dual-license commercial option keeps the AGPL code commercially viable; the
docs stay freely shareable; the **brand marks are all rights reserved** so the
logo isn't relicensed by being in an open repo.

## PEP 639 in `pyproject.toml`

Use the SPDX expression form, no trove classifier:

```toml
license = "AGPL-3.0-or-later"      # or "MIT", per the repo's choice
license-files = ["LICENSE"]
```

## Permissive dual-licensing (`MIT OR Apache-2.0`)

A repo that wants to be **maximally reusable** can license under `MIT OR Apache-2.0`
— the Rust-ecosystem convention, where the recipient picks *either* license at their
option. It's a **uniform** permissive license, so it skips the per-bucket split above.
**Reference implementation: [deco-assaying](https://github.com/ParkviewLab/deco-assaying).**

- **Root license files:** ship **both** `LICENSE-MIT` and `LICENSE-APACHE`, and **no
  single `LICENSE`** (the pair *is* the license). Their full REUSE texts go in
  `LICENSES/MIT.txt` + `LICENSES/Apache-2.0.txt`, fetched with:
  ```bash
  uvx --from "reuse[charset-normalizer]" reuse download MIT Apache-2.0
  ```
- **Uniform per-file SPDX:** every source file carries
  <!-- REUSE-IgnoreStart -->`SPDX-License-Identifier: MIT OR Apache-2.0`<!-- REUSE-IgnoreEnd --> (uppercase `OR`). No per-bucket split —
  one identifier everywhere. `REUSE.toml` keeps a single catch-all annotation for the
  files that can't hold a comment header (dotfiles, the lockfile, the version pin).
- **`pyproject.toml` (PEP 639):**
  ```toml
  license = "MIT OR Apache-2.0"
  license-files = ["LICENSE-MIT", "LICENSE-APACHE"]
  ```
- **GitHub shows `NOASSERTION`.** GitHub's licensee can't resolve an SPDX `OR`
  expression (or a pair of root license files) to one license, so the repo sidebar
  shows **NOASSERTION** instead of a license badge. That's expected — **the fix is a
  README `## License` section** in the Rust convention:
  > Licensed under either of Apache License 2.0 or the MIT license at your option.
  > In SPDX terms: `MIT OR Apache-2.0`.

  …followed by the standard "any contribution … shall be dual-licensed as above" clause.
- **`LICENSING.md`** uses the permissive **"either at your option"** framing — *not*
  the AGPL + commercial-alternative wording from [File layout](#file-layout) above
  (there's no commercial alternative to sell once the code is already permissive).

## This handbook eats its own dogfood

The `handbook` repo itself follows the per-bucket pattern: `docs/**` and
`README.md` are `CC-BY-4.0`, `scripts/**` and `templates/**` are
`AGPL-3.0-or-later`, **`brand/logos/**` is `LicenseRef-AllRightsReserved`**, and
the bundled **`brand/fonts/**` (Michroma) is `OFL-1.1`** (third-party — bundle its
license, don't relabel it). Its `REUSE.toml` encodes this and `reuse lint` is
green. When a repo vendors a ParkviewLab logo, that file keeps the
all-rights-reserved tag.

See [`templates/REUSE.toml.template`](../templates/REUSE.toml.template) and
[`templates/LICENSING.md.template`](../templates/LICENSING.md.template) to start
a new repo.
