<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# In-flight ideas

*Candidates under consideration for the ParkviewLab handbook and dev-tools. Each
is a question, not a commitment: to research, weigh against the northstar, and
either promote to a plan or drop. Nothing here is acted on silently. Raised from
a 2026-07 human+AI research sweep.*

> This is the condensed, scannable index. The detail, research, and rationale
> behind every entry live in the sibling notebook
> [`handbook-improvements_ideas.md`](handbook-improvements_ideas.md); the
> bracketed tags (e.g. `[B1, P1]`) point into its Part 4.

## The environment improves itself (a possible fifth northstar intent)
Should the northstar name, as a peer intent, that both human and AI developers
can raise, debate, and land improvements to the shared tools and processes
through a defined low-friction loop, and that the friction they hit becomes the
backlog? [B1, P1]

## A proposal (RFC) lifecycle both humans and AIs can drive
Evolve this file from a flat scratchpad into a backlog with explicit states
(raised → discussion → decided → recorded/dropped): humans enter via a GitHub
issue template, agents via a propose-improvement skill, into one backlog, with a
periodic triage that promotes a proven direction into `future-goals.md`. [B2, P1]

## Point-of-action guardrails, not just prose
A synced `.claude/settings.json` (allow read-only, ask on write/push, deny
secrets/force-push) and the `ai-collaboration.md` contract delivered as an
enforced Claude Code plugin/hook layer generated from that one doc. [A10, C3]

## One source of truth, made structural
`CLAUDE.md` as an `@AGENTS.md` import; the Electron template reconciled with the
shipped signed config; the visionOS version pulled into one `Version.xcconfig`
the build derives from. [A8, A7, A25]

## Onboarding a fresh session to the handbook
Replace "familiarize yourself" with a bounded, deterministic path: `dev-tools`
keeps a local clone of the released handbook and each repo's `CLAUDE.md`
auto-loads a small derived digest + doc-map (only `CLAUDE.md` auto-loads, and
`@`-imports are local-only, so the current GitHub links load nothing); then a
`/handbook` skill + librarian subagent for task-scoped depth, optionally a
handbook MCP server, bundled as a versioned plugin. [C7]

## Supply-chain hardening (the low-regret cluster)
SHA-pin actions + Dependabot together; build-provenance attestations for GHCR
images and Electron installers; per-job token minimization; then Scorecard and
an SBOM. [A1-A6]

## Template propagation as the missing channel
Copier (`copier update` + per-repo answers + drift detection) to carry a handbook
change into existing repos, absorbing `sync-agent-files.sh`. [C6]

## A visionOS profile
A `swift-tooling.md` + `visionos-tooling.md` pair with `vos-gspheres` as the
reference: pinned macOS runner, Swift Testing + swift-format + SPM, the
testable-core split, the `.xcconfig` version SoT, and a fastlane-to-TestFlight
release path (the one justified long-lived-secret deviation). [A24-A26]

## Decision hygiene
An ADR log (Nygard), a Diátaxis map, docs-link lint, and short
considered-and-declined notes (release-please, Biome, Backstage, Harden-Runner)
with revisit triggers. [B3, B5]

## A future-goals.md doc convention
A third sibling to `northstar.md` and `in-flight_ideas.md` for decided-but-unbuilt
direction, distinct from the timeless northstar and from undecided in-flight
questions. Unlike in-flight ideas, future goals are meant to shape present design
(build forward-compatibly toward them); document it in `documentation.md` and seed
the handbook's own with the LLM-Wiki convergence. [B7]

## Branching: keep two trunks, automate the tax
Decided: keep the permanent `develop`+`main` model, not release-from-main.
Instead automate the back-merge cascade (a `git back-merge` dev-tool) and harden
the promotion against a stale local `develop`; record the keep-two-trunk choice
as an ADR. [D1]

## Quality gates sized for a one-engineer org
Coverage floors + a testing-trophy note; publint/attw before npm publish; a
pinned `ty`; Electron Fuses + renderer-security tripwire; tightened MCP
CORS/auth; the `/sse` to `/mcp` rename. [A9, A11-A18]

## Watch list (track, don't adopt yet)
ty 1.0; TypeScript 7 / tsgo (RC); Node 26 LTS (Oct 2026); npm explicit-actions
publisher requirement (May 2026); SPDX 3.x tooling; distroless base images;
a generated docs site past ~30 docs; a DCO before the first outside contribution.
