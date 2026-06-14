<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Licensing

Copyright © 2026 **Gary Frattarola**. This repository is the ParkviewLab
engineering handbook; it dogfoods the per-bucket licensing it documents (see
[`docs/licensing.md`](docs/licensing.md)).

## Per-bucket licensing

| Bucket | License | What |
|---|---|---|
| Documentation — `docs/**`, `README.md`, this file, the prose templates | `CC-BY-4.0` | the writing |
| Scripts & templates — `scripts/**`, `templates/**` (code/config) | `AGPL-3.0-or-later` | the tooling/boilerplate |
| Brand logos — `brand/logos/**` | `LicenseRef-AllRightsReserved` | the marks (not open) |
| Bundled font — `brand/fonts/**` (Michroma) | `OFL-1.1` | third-party typeface (bundled, not relabeled) |

The split is encoded in [`REUSE.toml`](REUSE.toml) and per-file SPDX headers; the
root [`LICENSE`](LICENSE) holds the primary (AGPL-3.0-or-later) text for GitHub
detection; full license texts are in [`LICENSES/`](LICENSES/).

A commercial license for the AGPL-covered material is available — inquiries to
**garyf@parkviewlab.ai**.

## REUSE

This repo is [REUSE](https://reuse.software/)-compliant; verify with:

```bash
uvx --from "reuse[charset-normalizer]" reuse lint
```
