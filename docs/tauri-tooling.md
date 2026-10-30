<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Tauri tooling

A desktop app whose core is Rust is built with [Tauri 2](https://v2.tauri.app/), for macOS and Linux. [phonorheos](https://github.com/ParkviewLab/phonorheos) is the reference implementation, including the pattern below for an app that carries its own Python. Its `docs/why.md` holds the evidence behind each rule here.

## The stack

- **Cargo workspace:** the Tauri app is one crate (`crates/<repo>-app`); logic that needs no window (the interface, the queue) is a library crate with its own tests, and a command-line client a third.
- **Front end:** plain HTML, CSS and JavaScript in `ui/`, through Tauri's global API object (`"withGlobalTauri": true`), with no Node, npm or bundler, so the repository holds Rust (and Python, where carried) only. `"frontendDist": "../../ui"`; a strict `csp`.
- **Tauri CLI:** `cargo install tauri-cli --version "^2" --locked`, never npm.
- **One binary:** `mainBinaryName` is the repo name; where the app also has a command, the app's `main` runs the command for its subcommands and opens the window otherwise, so on macOS the command is the app's own binary, linked onto the path once.
- **Version SoT:** `VERSION.txt`. Tauri's `version` in `tauri.conf.json` stays `0.0.0`; the build script passes the real one with `--config`, converting a `.devN` to semver's `-devN`.

## Carrying a Python helper

Where the app needs a Python library (phonorheos: Kokoro and PyTorch), the app starts a Python helper process and talks to it over its standard input and output, one JSON object a line.

- **The Python:** a standalone Python (python-build-standalone, `uv python install`) copied into the app crate's `python/` and listed under `bundle.resources`. The helper's packages go into it with `UV_PROJECT_ENVIRONMENT=<that folder> uv sync --frozen --no-editable` from the helper's own lock file; never `uv export` with an install, which re-resolves and loses the lock's sources and overrides.
- **Starting it:** `<resources>/python/bin/python3.12 -I -B -m <helper>`. A development run points an environment variable at a local environment instead.
- **Platform indexes:** a Linux-only source in `[tool.uv.sources]` (PyTorch's CPU index, `explicit = true`) keeps the Linux build from carrying CUDA.
- **Licences:** a dependency's copyleft extra is removed with `override-dependencies`, and the build fails if it reappears; a script writes every bundled component's notice into a file carried in the app.

## Packaging

`scripts/build-app` prepares the Python, writes the notices, and runs `cargo tauri build --bundles …` on each system.

- **macOS:** `app,dmg`, Apple Silicon, `minimumSystemVersion` and `hardenedRuntime: true`. Tauri signs only its own binary, so every Mach-O file in the bundled Python is signed first (`codesign --force --timestamp --options runtime`); no entitlements were needed for PyTorch. The disk image is then notarised and stapled with `notarytool`, using the same five Apple secrets as an Electron app ([`electron-tooling.md`](electron-tooling.md#packaging-electron-builderyml)), and checked with `stapler validate` and `spctl`.
- **Linux:** `deb,appimage`, built on the oldest Ubuntu runner the target desktop accepts. The AppImage needs `libfuse2t64`, `NO_STRIP=true` (linuxdeploy's strip fails on newer libraries' relocations), and `LD_LIBRARY_PATH` set to the bundled Python's library folders, since linuxdeploy does not follow `$ORIGIN`. Build packages: `libwebkit2gtk-4.1-dev libayatana-appindicator3-dev librsvg2-dev patchelf file`, plus what the app links (ALSA's headers for audio).
- **Size:** a bundled PyTorch makes the installers about 250 MB (macOS) to 400 MB (Linux). Models are downloaded on first run, not bundled.

## CI and release

- **CI:** `test.yml` runs `cargo test` and `clippy` on `macos-15` and `ubuntu-24.04`, and the helper's ruff, ty and pytest; with `reuse.yml` and `version-guard.yml`, these are `develop`'s required checks.
- **Release:** `release.yml` has the usual gate and `changelog` jobs ([`ci.md`](ci.md#releaseyml-on-v-tag-push)) with two building jobs, `installers-macos` (certificate imported into a temporary keychain, `scripts/build-app`, `scripts/notarize`) and `installers-linux`.
