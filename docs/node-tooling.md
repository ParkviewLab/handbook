<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Node tooling

The ParkviewLab Node stack is **npm + TypeScript + ESLint + Vitest**, on **Node
24+**, with a `src/` layout compiled to `dist/`. Every Node repo's `package.json`
is nearly identical — start from the template
([`package.json.template`](../templates/package.json.template)) and change only the
name/description/deps. **jonobones** is the reference implementation.

## The stack

- **[npm](https://docs.npmjs.com/)** — package manager and runner.
  `package-lock.json` is **committed** (reproducible builds; see [`ci.md`](ci.md)).
  `npm ci` installs; `npm run <script>` runs. Each worktree gets its own
  `node_modules` (run `npm ci` per worktree).
- **[TypeScript](https://www.typescriptlang.org/)** — strict mode, `NodeNext`
  modules; `tsc` builds (`tsconfig.build.json`) and type-checks (`tsc --noEmit`).
- **[ESLint](https://eslint.org/)** — flat config (`eslint.config.js`).
- **[Vitest](https://vitest.dev/)** — tests (see [`testing.md`](testing.md)).
- **`engines.node`** pins `>=24`; ES modules (`"type": "module"`).
- Docker images base on **`node:24-slim`** (multi-stage) — see
  [`packaging-and-deployment.md`](packaging-and-deployment.md).

## Canonical `package.json` shape

```json
{
  "name": "jonobones",
  "version": "0.1.4",                       // single source of truth — see releases.md
  "description": "…",
  "license": "MIT",                         // per-repo choice — see licensing.md
  "author": "Gary Frattarola <garyf@parkviewlab.ai>",
  "type": "module",
  "repository": { "type": "git", "url": "git+https://github.com/ParkviewLab/<repo>.git" },
  "bin": { "<repo>": "bin/<repo>.js" },
  "files": ["bin/", "dist/", "README.md", "LICENSE"],
  "engines": { "node": ">=24" },
  "scripts": {
    "build": "tsc -p tsconfig.build.json",
    "typecheck": "tsc --noEmit",
    "lint": "eslint .",
    "test": "vitest run"
  },
  "dependencies": { },
  "devDependencies": { "typescript": "…", "eslint": "…", "vitest": "…" }
}
```

Source: jonobones's `package.json`.

### The settings that are fixed across repos

- **Version is the single source of truth in `package.json` `version`** — read at
  runtime, never hard-coded and never typed on a `git tag` line. The canonical read
  (jonobones's `src/version.ts`):
  ```ts
  import { createRequire } from 'node:module';
  const pkg = createRequire(import.meta.url)('../package.json') as { version: string };
  export const VERSION = pkg.version;
  ```
  Bump/release with the SoT-aware `git bump` / `git release` — see
  [`releases.md`](releases.md).
- **`"type": "module"`**, `engines.node = ">=24"`, `src/` → `dist/` (`tsc`), `bin/`
  for CLIs.
- **License + `author`** per [`licensing.md`](licensing.md). SPDX headers go on
  `.ts` / `.mjs` / `.js` with `//` comments; JSON files (`package.json`,
  `tsconfig.json`, the lockfile) can't take comments — cover them in `REUSE.toml`.

## CI & release

- **CI** — [`test-node.yml`](../templates/.github/workflows/test-node.yml): a
  `node-version` matrix runs `npm ci` · `npm run typecheck` · `npm run lint` ·
  `npm test`. `reuse.yml` + `version-guard.yml` apply unchanged (the version guard
  already understands `package.json`). Repos may add tiers — jonobones adds
  `interop` / `docker` / `e2e` (see [`testing.md`](testing.md)).
- **Release** — [`release-node.yml`](../templates/.github/workflows/release-node.yml):
  `gate` (tag == `package.json` version + reachable from `main`) → GHCR multi-arch
  image + **npm trusted publishing (OIDC)** → the shared `changelog` job.
  Optionally publish a second **scoped-alias** name (`@org/<pkg>`, as jonobones does
  with `jonobones` + `@parkviewlab/jonobones`) — see the commented block in the
  template.
- The changelog automation (`cliff.toml` + `scripts/generate_changelog.py`) is
  **language-agnostic**: the Python script reads `package.json` as well as
  `pyproject.toml`. Copy both from the handbook templates (see
  [`commits-and-changelogs.md`](commits-and-changelogs.md)).

## Everyday commands

```bash
npm ci                 # install deps into this worktree's node_modules
npm run typecheck      # tsc --noEmit
npm run lint           # eslint .  (CI runs this)
npm test               # vitest run
npm run build          # tsc -p tsconfig.build.json
```

The `version`/release commands (`git bump`, `git release`) are in
[`releases.md`](releases.md).
