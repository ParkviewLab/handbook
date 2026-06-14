<!-- PARKVIEWLAB:BEGIN (managed by ParkviewLab/handbook — do not edit inside this block; run scripts/sync-agent-files.sh to update) -->
# ParkviewLab conventions

This repo follows the **[ParkviewLab handbook](https://github.com/ParkviewLab/handbook)**.
Read it for the full conventions; the load-bearing rules are inlined here.

**Read `docs/northstar.md` before working.** It states the project's intent and is authoritative.

## Branching & commits
- Branch off `develop` into an ephemeral, **prefixed** worktree: `feature-`, `bug-`/`fix-`, `doc-`, `test-`, `ops-`, `ci-`, `build-`, `release-` (hyphen, not slash).
- Open a PR into `develop`. PRs are **squash-merged**, so the **PR title carries the Conventional Commit prefix** (`feat:`/`fix:`/`docs:`/…) that the changelog is generated from. No prefix → dropped from the changelog.

## Versioning & releases
- The version lives in **one file** (`pyproject.toml` / `package.json`) and is read at runtime from package metadata — never hard-coded elsewhere.
- Never hand-type a version or tag: use `git bump` then `git release` (from `ParkviewLab/dev-tools`). Releases are cut from `main`; after a release, run the back-merge cascade.

## Python tooling
- `uv sync` · `uv run ruff check src tests` · `uv run ty check` · `uv run pytest -m "not network and not docling" -q`.
- Push after each commit during implementation (don't batch).

## Shared-state writes need explicit authorization
- **Merging a PR, tagging, and releasing are the user's call.** A broad directive ("fix all that", "finish it") authorizes work on the branch, **not** the merge/release.
- **Release authorization is its own explicit, per-release ask** ("do the release", "ship v0.1.x"). Descriptive labels ("→ v0.1.1") are not authorization.

## Communication
- No sycophancy. Label uncertainty (never state an unmeasured number/behaviour as fact). Surface real design choices before implementing. A terse reply to a compound question is not confirmation. Don't plan or take extra-scope action unprompted.
<!-- PARKVIEWLAB:END -->

<!-- Repo-specific guidance below this line is preserved by the sync script — add anything particular to this repo here. -->
