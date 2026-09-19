<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Electron tooling

ParkviewLab's desktop apps are **Electron**, built on the Node stack ([`node-tooling.md`](node-tooling.md)) plus two extras: **[electron-vite](https://electron-vite.org/)** bundles the app and **[electron-builder](https://www.electron.build/)** packages it into per-OS installers. **conception-space** is the reference implementation.

A desktop app diverges from a Node service in a few deliberate ways:

| | Node service ([node-tooling.md](node-tooling.md)) | Electron app (this doc) |
|---|---|---|
| Language | TypeScript | TS **or** plain JS (the bundler handles either) |
| Runs as | `node dist/…` | a windowed app the user launches |

The stack decides those two. What the app publishes is decided by its targets ([`releases.md`](releases.md#what-a-release-publishes)): an app takes the installers target, whose `.dmg` / `.exe` / `.AppImage` + `.deb` are attached to a **GitHub Release**, and takes an image or a package target as well only where it publishes those too. conception-space and pensa-grex publish installers alone; jonobones, a Node service, publishes an npm package and an image.

## The stack

- **electron-vite** — bundles `src/main`, `src/preload`, `src/renderer` → `out/` (`npm run build`); HMR dev server (`npm run dev`).
- **electron-builder** — packages `out/` (+ the Electron runtime) into installers, configured by `electron-builder.yml`. It layers *on top of* electron-vite; it doesn't replace it.
- **Renderer** — whatever the app needs (conception-space: Three.js + CodeMirror).
- **ESLint** flat config — `eslint.config.mjs` (`.mjs`, because an Electron app is usually **not** `"type": "module"`). **TypeScript + Vitest are optional** — adopt them as the app grows; conception-space is plain JS with a lint + build CI.
- **Version SoT** = `package.json` `version`, read at runtime (e.g. the About box: `import pkg from '../../package.json'` → `pkg.version`). Same rule as [`releases.md`](releases.md).

## Repo layout — the app lives at the repo root

`package.json` + `src/{main,preload,renderer}` + `electron.vite.config.js` + `electron-builder.yml` sit at the **repo root**, not in an `app/` subdirectory. That keeps `package.json` the root-level version source-of-truth, so `git bump` / `git release`, `version-guard.yml`, and `reuse` all work with no special-casing (an app-in-a-subdir would need a SoT-path shim). `src/main/index.js` reads `../../package.json` for its version.

## Packaging — `electron-builder.yml`

Copy [`templates/electron-builder.yml`](../templates/electron-builder.yml); set `appId` (`ai.parkviewlab.<repo>`), `productName`, and the `publish` owner/repo. Targets: **macOS** `dmg`, **Windows** `nsis`, **Linux** `AppImage` + `deb`. Build locally with `npm run build:dist` (= `electron-vite build && electron-builder`).

- **macOS signing + notarization.** When the five Apple secrets are set, the release workflow signs the macOS build with a **Developer ID Application** cert (`CSC_LINK` = the base64-encoded `.p12`; `CSC_KEY_PASSWORD` = its export password) and **notarizes** it via an **App Store Connect API key** (`APPLE_API_KEY_B64` = the base64-encoded `.p8`, which the workflow decodes to a file and points `APPLE_API_KEY` at; plus `APPLE_API_KEY_ID` and `APPLE_API_ISSUER`). `electron-builder.yml` sets `mac.hardenedRuntime: true`, and notarization activates from those env vars — no `mac.notarize: true` needed. The signing env is scoped to the macOS runner (`runner.os == 'macOS'`) so the creds never reach the Windows job; **Windows and Linux stay unsigned** (SmartScreen warns on first launch — document the bypass in the README). Keep the five secrets at repo or org level; absent them, macOS falls back to an unsigned build (Gatekeeper warns). electron-builder itself must be **26.16.1 or newer**, or signing fails on the current runner image — see [macOS signing needs electron-builder 26.16.1 or newer](#macos-signing-needs-electron-builder-26161-or-newer).
- **App icon** — drop a 1024×1024 `build/icon.png`; electron-builder derives the `.icns` / `.ico` / Linux icons. With none, the default Electron icon ships.
- **macOS arch** — `macos-latest` is arm64, so the `.dmg` is Apple-Silicon-only; add an x64 / universal build when Intel coverage is needed.
- **Auto-update** — deferred. electron-builder already emits `latest*.yml` (the electron-updater foundation); wire `electron-updater` when wanted.

## CI & release

- **CI** — [`test-electron.yml`](../templates/.github/workflows/test-electron.yml): `npm ci` · `npm run lint` · `npm run build` (the electron-vite build is the smoke test). Add `typecheck` / `test` steps if the app adopts TS / Vitest. `reuse.yml` + `version-guard.yml` apply unchanged.
- **Release** — `release.yml`, assembled with the `installers` part (see [`ci.md`](ci.md#releaseyml--on-v-tag-push)): on a `v*` tag, the gate (tag == `package.json` version, reachable from `main`, strictly greater than the previous tag), then the `installers` job, a **macOS / Windows / Linux build matrix** (electron-vite + electron-builder), then the `changelog` job, which commits `CHANGELOG.md` to `main` and creates the **GitHub Release with the three OS installers attached**. An app that publishes no image has no `docker` job, having no image target.
- **Dev build** — `dev-release.yml`, assembled with the dev `installers` part: `workflow_dispatch` from `develop` → the same 3-OS matrix → unsigned installers as 7-day **workflow artifacts**. It creates **no `v*` tag** and no Release (so the real release gate is untouched), and it publishes to no registry: the installers target's dev counterpart is a build to test in the lab. `develop` must still carry a `-dev` version, or the build is stamped identically to a real release; the gate fails fast if it isn't (open a cycle with `git dev-release --open`).
- Changelog automation (`cliff.toml` + `scripts/generate_changelog.py`) is the same language-agnostic pair as everywhere else.

### macOS signing needs electron-builder 26.16.1 or newer

- **Symptom** — the macOS leg of the release fails in `Package installers` with `⨯ /usr/bin/security process failed 1` on a `security set-key-partition-list -S apple-tool:,apple: -s -k *** …` call, and `security: SecKeychainUnlock: The user name or passphrase you entered is not correct`. The message points at the certificate password; the certificate is not the problem.
- **Cause** — electron-builder creates a throwaway keychain with its own random password and imports the `.p12` into it, but up to and including **26.16.0** it passed the *certificate* password to `security set-key-partition-list -k`, where `security` wants the *keychain's* password. Older runner images tolerated the mismatch, because the unlock short-circuited on a keychain that was already unlocked; `macos-latest` then moved within the macOS 26 line (kernel 25.4.0 in July, 25.6.0 in September), the unlock is now checked, and the call fails.
- **Fix** — pin **`electron-builder@26.16.1`** (published 2026-09-07), which passes the keychain password: `npm install --save-dev electron-builder@26.16.1`. npm's `latest` dist-tag still points at `26.15.3` (checked 2026-09-15) and `26.16.1` is published under the `v26` tag, so a routine update does **not** pick the fix up — confirm with `npm view electron-builder dist-tags` and pin explicitly for as long as that holds. pensa-grex v3.5.1 failed twice, then signed and notarized on the first attempt on the pin, with the same repo, secrets and certificate.
- **Ruling out the certificate** — the diagnosis is worth copying. The signing secrets had been untouched since 20 July, a week before a release that signed and notarized with them; electron-builder, Node and the runner family were identical across the two failures and that success; only the runner image version differed. A signing pipeline that worked months ago is not evidence that it works now: a hosted image moves within its major line and can change behaviour the build depends on.

## License notices + in-app viewer

A packaged Electron app bundles third-party code (Electron → Chromium/Node, plus the npm dependency tree) whose MIT/BSD/ISC notices must travel with the binary. Ship a small, **generated `legal/` bundle** and surface it in-app. [conception-space](https://github.com/ParkviewLab/conception-space) is the reference implementation (`scripts/prepare-legal.mjs`, `src/main/index.js`).

- **`scripts/prepare-legal.mjs`** (committed) recreates a gitignored `legal/` and copies the project `LICENSE` + `LICENSING.md` + `LICENSES/` **and Electron's own `LICENSES.chromium.html`** from `node_modules/electron/dist/`. electron-builder **deletes `LICENSES.chromium.html` from the macOS `.app`** (it only survives next to the binary on Win/Linux), so shipping our own copy gives one stable path on all three OSes.
- **Extract Electron's prebuilt before `npm run legal` (Electron 43).** Electron 43 ships no npm install script, so `npm ci` does **not** unpack its prebuilt `dist/`. `npm run legal` reads the Chromium notices straight from `dist/` on disk (the legal step only reads files; it never runs Electron), so an unextracted `dist/` leaves the notices absent and the step fails. Run **`node node_modules/electron/install.js`** right after `npm ci`, before `npm run legal`, so `dist/` and its `LICENSES.chromium.html` exist. `install.js`'s `isInstalled()` returns false whenever `dist/version` or `path.txt` is missing — exactly the post-`npm ci` state on 43 — so it downloads and extracts; it short-circuits only when that marker is already present, so it cannot repair a *partial* extraction (a different, older failure mode; see the note below). `prepare-legal.mjs` then **asserts** both Electron notice files are present and `LICENSES.chromium.html` is non-trivial, so a missed extraction fails the build loudly instead of silently shipping empty notices. The `installers` part and its dev counterpart both run the `install.js` step.
- **Historical: the `yauzl` override (Electron ≤ 34, now inert).** On Electron 34, `npm ci` **did** run Electron's `postinstall` → `install.js`, but a Node 24.16+/26.1+ `extract-zip` regression left the pinned `yauzl@2.x` extracting `dist/` only **partially** (a notice file missing per run, failing `npm run legal`); the fix was `"overrides": { "yauzl": "^3.3.1" }` in `package.json` ([electron/electron#51619](https://github.com/electron/electron/issues/51619), [nodejs/node#63487](https://github.com/nodejs/node/issues/63487)). Electron 43's extraction path no longer reaches that code, so the override is **inert**; the reference repo dropped it (conception-space #24), and a new Electron-43 repo needs only the `install.js` step above.
- devDeps **`generate-license-file`** → `legal/THIRD-PARTY-NOTICES.txt` (full texts) and **`license-checker-rseidelsohn`** → `legal/oss-licenses.json` (the structured list the viewer renders; a small cleanup script drops the app itself and strips absolute build paths).
- npm scripts `legal:prepare` / `legal:notices` / `legal:list`, a combined `legal`, and `build:dist` runs `npm run legal` before electron-builder. Add `legal/` to `.gitignore`.
- **`electron-builder.yml`** `extraResources` copies `legal/` to `process.resourcesPath/legal`.
- **CI** runs `node node_modules/electron/install.js` then `npm run legal` after `npm ci`, before packaging (the `installers` part and its dev counterpart).
- **In-app** — a `Help → Open Source Licenses` window reads the bundled files (styled to match the app's own UI), plus a `Source code → GitHub` link in About. Make the **Help menu cross-platform** — without it Windows/Linux have no About/licenses entry at all.

All `legal/` files are generated build artifacts (gitignored); only the scripts are committed, covered by the `scripts/**` REUSE bucket. (An all-permissive dependency set needs no SBOM or CI license-gate; add those only if a copyleft/unknown dep ever ships.)

## Dev versions are semver

Between releases `develop` carries a pre-release version (see [`releases.md`](releases.md#development-versioning)). For a Node/Electron repo it must be **semver** — `X.Y.Z-devN` (e.g. `0.9.1-dev0`) — **not** the Python PEP-440 `X.Y.Z.devN`, which `npm version` rejects. The dev-release gate **requires** a `-dev` marker on `develop`: a dev build cut from a plain release version is indistinguishable from the real release in the filename and About box. Open the cycle with `git dev-release --open` right after each release.

## Everyday commands

```bash
npm ci                 # install deps into this worktree's node_modules
npm run dev            # electron-vite dev server (HMR)
npm run lint           # eslint .  (CI runs this)
npm run build          # electron-vite build -> out/  (CI smoke test)
npm run build:dist     # build + package installers locally (-> dist/)
```

Version/release commands (`git bump`, `git release`) are in [`releases.md`](releases.md).
