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

- **macOS signing + notarization.** When the five Apple secrets are set, the release
  workflow signs the macOS build with a **Developer ID Application** cert (`CSC_LINK` = the
  base64-encoded `.p12`; `CSC_KEY_PASSWORD` = its export password) and **notarizes** it via an
  **App Store Connect API key** (`APPLE_API_KEY_B64` = the base64-encoded `.p8`, which the
  workflow decodes to a file and points `APPLE_API_KEY` at; plus `APPLE_API_KEY_ID` and
  `APPLE_API_ISSUER`). `electron-builder.yml` sets `mac.hardenedRuntime: true`, and
  notarization activates from those env vars — no `mac.notarize: true` needed. The signing env
  is scoped to the macOS runner (`runner.os == 'macOS'`) so the creds never reach the Windows
  job; **Windows and Linux stay unsigned** (SmartScreen warns on first launch — document the
  bypass in the README). Keep the five secrets at repo or org level; absent them, macOS falls
  back to an unsigned build (Gatekeeper warns).
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

## License notices + in-app viewer

A packaged Electron app bundles third-party code (Electron → Chromium/Node, plus the
npm dependency tree) whose MIT/BSD/ISC notices must travel with the binary. Ship a small,
**generated `legal/` bundle** and surface it in-app.
[conception-space](https://github.com/ParkviewLab/conception-space) is the reference
implementation (`scripts/prepare-legal.mjs`, `src/main/index.js`).

- **`scripts/prepare-legal.mjs`** (committed) recreates a gitignored `legal/` and copies
  the project `LICENSE` + `LICENSING.md` + `LICENSES/` **and Electron's own
  `LICENSES.chromium.html`** from `node_modules/electron/dist/`. electron-builder
  **deletes `LICENSES.chromium.html` from the macOS `.app`** (it only survives next to the
  binary on Win/Linux), so shipping our own copy gives one stable path on all three OSes.
- **Extract Electron's prebuilt before `npm run legal` (Electron 43).** Electron 43 ships no
  npm install script, so `npm ci` does **not** unpack its prebuilt `dist/`. `npm run legal`
  reads the Chromium notices straight from `dist/` on disk (the legal step only reads files; it
  never runs Electron), so an unextracted `dist/` leaves the notices absent and the step fails.
  Run **`node node_modules/electron/install.js`** right after `npm ci`, before `npm run legal`,
  so `dist/` and its `LICENSES.chromium.html` exist. `install.js`'s `isInstalled()` returns
  false whenever `dist/version` or `path.txt` is missing — exactly the post-`npm ci` state on
  43 — so it downloads and extracts; it short-circuits only when that marker is already present,
  so it cannot repair a *partial* extraction (a different, older failure mode; see the note
  below). `prepare-legal.mjs` then **asserts** both Electron notice files are present and
  `LICENSES.chromium.html` is non-trivial, so a missed extraction fails the build loudly instead
  of silently shipping empty notices. Both electron workflows run the `install.js` step.
- **Historical: the `yauzl` override (Electron ≤ 34, now inert).** On Electron 34, `npm ci`
  **did** run Electron's `postinstall` → `install.js`, but a Node 24.16+/26.1+ `extract-zip`
  regression left the pinned `yauzl@2.x` extracting `dist/` only **partially** (a notice file
  missing per run, failing `npm run legal`); the fix was `"overrides": { "yauzl": "^3.3.1" }` in
  `package.json`
  ([electron/electron#51619](https://github.com/electron/electron/issues/51619),
  [nodejs/node#63487](https://github.com/nodejs/node/issues/63487)). Electron 43's extraction
  path no longer reaches that code, so the override is **inert**; the reference repo dropped it
  (conception-space #24), and a new Electron-43 repo needs only the `install.js` step above.
- devDeps **`generate-license-file`** → `legal/THIRD-PARTY-NOTICES.txt` (full texts) and
  **`license-checker-rseidelsohn`** → `legal/oss-licenses.json` (the structured list the
  viewer renders; a small cleanup script drops the app itself and strips absolute build
  paths).
- npm scripts `legal:prepare` / `legal:notices` / `legal:list`, a combined `legal`, and
  `build:dist` runs `npm run legal` before electron-builder. Add `legal/` to `.gitignore`.
- **`electron-builder.yml`** `extraResources` copies `legal/` to `process.resourcesPath/legal`.
- **CI** runs `node node_modules/electron/install.js` then `npm run legal` after `npm ci`,
  before packaging (both electron workflows).
- **In-app** — a `Help → Open Source Licenses` window reads the bundled files (styled to
  match the app's own UI), plus a `Source code → GitHub` link in About. Make the **Help menu
  cross-platform** — without it Windows/Linux have no About/licenses entry at all.

All `legal/` files are generated build artifacts (gitignored); only the scripts are
committed, covered by the `scripts/**` REUSE bucket. (An all-permissive dependency set
needs no SBOM or CI license-gate; add those only if a copyleft/unknown dep ever ships.)

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
