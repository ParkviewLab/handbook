<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Electron tooling

ParkviewLab's desktop apps are **Electron**, built on the Node stack
([`node-tooling.md`](node-tooling.md)) plus two extras:
**[electron-vite](https://electron-vite.org/)** bundles the app and
**[electron-builder](https://www.electron.build/)** packages it into per-OS
installers. **conception-space** is the reference implementation.

A desktop app diverges from a Node service in a few deliberate ways:

| | Node service ([node-tooling.md](node-tooling.md)) | Electron app (this doc) |
|---|---|---|
| Ships | npm package + GHCR image | OS installers (`.dmg` / `.exe` / `.AppImage` + `.deb`) |
| Release artifact home | npm + GHCR | a **GitHub Release** (installers attached) |
| Docker image | yes | **no** — a desktop app is not a server |
| Language | TypeScript | TS **or** plain JS (the bundler handles either) |
| Runs as | `node dist/…` | a windowed app the user launches |

## The stack

- **electron-vite** — bundles `src/main`, `src/preload`, `src/renderer` → `out/`
  (`npm run build`); HMR dev server (`npm run dev`).
- **electron-builder** — packages `out/` (+ the Electron runtime) into installers,
  configured by `electron-builder.yml`. It layers *on top of* electron-vite; it
  doesn't replace it.
- **Renderer** — whatever the app needs (conception-space: Three.js + CodeMirror).
- **ESLint** flat config — `eslint.config.mjs` (`.mjs`, because an Electron app is
  usually **not** `"type": "module"`). **TypeScript + Vitest are optional** — adopt
  them as the app grows; conception-space is plain JS with a lint + build CI.
- **Version SoT** = `package.json` `version`, read at runtime (e.g. the About box:
  `import pkg from '../../package.json'` → `pkg.version`). Same rule as
  [`releases.md`](releases.md).

## Repo layout — the app lives at the repo root

`package.json` + `src/{main,preload,renderer}` + `electron.vite.config.js` +
`electron-builder.yml` sit at the **repo root**, not in an `app/` subdirectory.
That keeps `package.json` the root-level version source-of-truth, so `git bump` /
`git release`, `version-guard.yml`, and `reuse` all work with no special-casing
(an app-in-a-subdir would need a SoT-path shim). `src/main/index.js` reads
`../../package.json` for its version.

## Packaging — `electron-builder.yml`

Copy [`templates/electron-builder.yml`](../templates/electron-builder.yml); set
`appId` (`ai.parkviewlab.<repo>`), `productName`, and the `publish` owner/repo.
Targets: **macOS** `dmg`, **Windows** `nsis`, **Linux** `AppImage` + `deb`. Build
locally with `npm run build:dist` (= `electron-vite build && electron-builder`).

- **Unsigned for now.** The release workflow sets `CSC_IDENTITY_AUTO_DISCOVERY=false`
  and `electron-builder.yml` has `mac.notarize: false`, so builds are unsigned —
  macOS Gatekeeper and Windows SmartScreen warn on first launch (document the
  bypass in the README). **To enable signing later** (a small, well-scoped change):
  add `CSC_LINK` / `CSC_KEY_PASSWORD` (mac + win) and `APPLE_ID` /
  `APPLE_APP_SPECIFIC_PASSWORD` / `APPLE_TEAM_ID` secrets, drop the
  `CSC_IDENTITY_AUTO_DISCOVERY` line, and set `mac.notarize: true`.
- **App icon** — drop a 1024×1024 `build/icon.png`; electron-builder derives the
  `.icns` / `.ico` / Linux icons. With none, the default Electron icon ships.
- **macOS arch** — `macos-latest` is arm64, so the `.dmg` is Apple-Silicon-only;
  add an x64 / universal build when Intel coverage is needed.
- **Auto-update** — deferred. electron-builder already emits `latest*.yml` (the
  electron-updater foundation); wire `electron-updater` when wanted.

## CI & release

- **CI** — [`test-electron.yml`](../templates/.github/workflows/test-electron.yml):
  `npm ci` · `npm run lint` · `npm run build` (the electron-vite build is the smoke
  test). Add `typecheck` / `test` steps if the app adopts TS / Vitest. `reuse.yml` +
  `version-guard.yml` apply unchanged.
- **Release** — [`release-electron.yml`](../templates/.github/workflows/release-electron.yml):
  on a `v*` tag, `gate` (tag == `package.json` version + reachable from `main`) → a
  **macOS / Windows / Linux build matrix** (electron-vite + electron-builder) → the
  shared `changelog` job, which commits `CHANGELOG.md` to `main` and creates the
  **GitHub Release with the three OS installers attached**. The `gate` + `changelog`
  jobs are identical to [`release-node.yml`](../templates/.github/workflows/release-node.yml);
  there is **no GHCR image**.
- **Dev build** — [`dev-release-electron.yml`](../templates/.github/workflows/dev-release-electron.yml):
  `workflow_dispatch` from `develop` → the same 3-OS matrix → installers as 7-day
  **workflow artifacts**. It creates **no `v*` tag** and no Release (so the real
  release gate is untouched), and — unlike the Python/TestPyPI dev-release — it
  publishes to no registry, so it needs no unique dev *counter*. `develop` must
  still carry a `-dev` version, or the build is stamped identically to a real
  release; the gate fails fast if it isn't (open a cycle with `git dev-release --open`).
- Changelog automation (`cliff.toml` + `scripts/generate_changelog.py`) is the same
  language-agnostic pair as everywhere else.

## Dev versions are semver

Between releases `develop` carries a pre-release version (see
[`releases.md`](releases.md#development-versioning)). For a Node/Electron repo it
must be **semver** — `X.Y.Z-devN` (e.g. `0.9.1-dev0`) — **not** the Python PEP-440
`X.Y.Z.devN`, which `npm version` rejects. The dev-release gate **requires** a
`-dev` marker on `develop`: a dev build cut from a plain release version is
indistinguishable from the real release in the filename and About box. Open the
cycle with `git dev-release --open` right after each release.

## Everyday commands

```bash
npm ci                 # install deps into this worktree's node_modules
npm run dev            # electron-vite dev server (HMR)
npm run lint           # eslint .  (CI runs this)
npm run build          # electron-vite build -> out/  (CI smoke test)
npm run build:dist     # build + package installers locally (-> dist/)
```

Version/release commands (`git bump`, `git release`) are in
[`releases.md`](releases.md).
