<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# In-flight ideas

*Candidates under consideration for the ParkviewLab handbook and dev-tools. Each is a question, not a commitment: to research, weigh against the northstar, and either promote to a plan or drop. Nothing here is acted on silently. Raised from a 2026-07 human+AI research sweep.*

> This is the condensed, scannable index. The detail, research, and rationale behind every entry live in the sibling notebook [`handbook-improvements_ideas.md`](handbook-improvements_ideas.md); the bracketed tags (e.g. `[B1, P1]`) point into its Part 4.

## Many agents under one hand (a possible facet of intent 4)
The northstar speaks of "an agent" in the singular. `parallel-work.md` now describes one session coordinating several workers across several repos, under the same contract, with the human hand asked for per action and never supplied by another agent or session. Is that a facet of purpose that intent 4 should name (with the rule that a step whose outcome must be identical every time is scripted, whilst a step that needs judgement is delegated to an agent), or is it mechanism only? Raised by the northstar review of the agent set, 2026-09-13. Evidence of 2026-09-27: GitHub attributes an agent's push to the owner's account, so on the record an agent's push cannot be told from the owner's own.

## Documentation for the software's users (a possible facet of intent 2)
The northstar's readers are developers and agents, but a documentation site is read by the software's users, at the version they can download ([`docs-site.md`](docs-site.md#published-from-main-only)). Is "documentation published to the software's users, at the released version" a facet of intent 2 worth naming, or is it covered by intent 2's documentation as a first-class artifact? Raised by the northstar review of 2026-09-17 and moved here from Discovered Tangents in the Library (BookStack) in the handbook review of 2026-09-27.

## A gate the flow bypasses (axiom 4)
Should axiom 4 say that a gate the flow bypasses routinely is no gate, and that the flow is changed until the gate applies? The question arose when every release reached `develop` by direct pushes under the administrators' bypass (measured in [`branching-why.md`](branching-why.md#the-measured-problem)), so that the bypass notice which would have marked a real exception looked like every other; the back-merge pull request is the change made in answer to it. A second instance on 2026-09-27: a coding agent's direct push to `dev-tools`' `develop` passed under the same bypass, since an agent's commands run with the owner's credentials, and administrators were then bound on every protected `develop` ([`branching-why.md`](branching-why.md#2026-09-27-the-rollout-and-administrators-bound-at-once)); whether axiom 4's wording should say so remains open.

## A proposal (RFC) lifecycle both humans and AIs can drive
Evolve this file from a flat scratchpad into a backlog with explicit states (raised → discussion → decided → recorded/dropped): humans enter via a GitHub issue template, agents via a propose-improvement skill, into one backlog, with a periodic triage that promotes a proven direction into `future-goals.md`. [B2, P1] Ruled on 2026-09-17: an entry and a decision carry what and why, not who (`documentation.md`, "Documents and records"); git and the pull request hold who. Landed in part: the agents' entry point exists as the `tangent` skill and the Library's Discovered Tangents register, which take an idea discovered in one repo whilst working in another and promote it into the target repo's `in-flight_ideas.md` by pull request (`documentation.md`, "Discovered tangents"); the explicit states, the issue template for humans, the single backlog and the periodic triage remain open. Landed further on 2026-09-17 for one class of proposal: an addition to the agent set is proposed in the Library, built, and then retired into `agents.md` and its why sibling, with whatever stays open left on the shelf, which is a state model and a recorded terminus for that class (`agents.md`, "Changing the set"). Amended on 2026-09-18 for the same class: an addition small enough to be ruled on with the change that builds it may instead be proposed in that change's plan, a Markdown file outside the repositories, and it retires into the same pair once built (`agents.md`, "Changing the set"). The states for an ordinary entry here, the issue template, the single backlog and the triage remain open.

## Binding the desktop application to the Library's write convention
Should the write convention bind a second client, or a person writing in the Library's own interface, at all, or does the catalog's reconciliation suffice? Writes to the org's Library go through `bookstack-librarian`, a convention Claude Code sessions follow and the Claude desktop application does not, so a write made there reaches the Library unmediated and the catalog learns of it only at the next reconciliation. Left alone on 2026-09-17 with the machinery it would take and the reasoning recorded in [`agents-why.md`](agents-why.md). The trigger to revisit: a write made in the desktop application that the catalog's reconciliation cannot repair.

## Point-of-action guardrails, not just prose
A synced `.claude/settings.json` (allow read-only, ask on write/push, deny secrets/force-push) and the `ai-collaboration.md` contract delivered as an enforced Claude Code plugin/hook layer generated from that one doc. [A10, C3] The first recorded case of the written rule not holding came on 2026-09-27, when a coding agent pushed to a trunk directly; binding administrators enforces `develop`'s checks, not the go-ahead a push needs, so the point-of-action form (a permission rule that refuses `git push` to the trunks for every agent) remains the open question.

## One source of truth, made structural
`CLAUDE.md` as an `@AGENTS.md` import; the Electron template reconciled with the shipped signed config; the visionOS version pulled into one `Version.xcconfig` the build derives from. [A8, A7, A25]

## Onboarding a fresh session to the handbook
Replace "familiarize yourself" with a bounded, deterministic path: `dev-tools` keeps a local clone of the released handbook and each repo's `CLAUDE.md` auto-loads a small derived digest + doc-map (only `CLAUDE.md` auto-loads, and `@`-imports are local-only, so the current GitHub links load nothing); then a `/handbook` skill + librarian subagent for task-scoped depth, optionally a handbook MCP server, bundled as a versioned plugin. [C7] Landed in part: the librarian subagent exists as `templates/agents/handbook-librarian.md`, installed at the user level with the rest of the set (see [`agents.md`](agents.md)); the local clone and digest (C7a), the handbook MCP server (C7c), and the plugin channel that would version the bundle with the handbook remain open; until then the installer's symlinks from released `main` carry the same versioning.

## Supply-chain hardening (the low-regret cluster)
SHA-pin actions + Dependabot together; build-provenance attestations for GHCR images and Electron installers; per-job token minimization; then Scorecard and an SBOM. [A1-A6]

## Template propagation as the missing channel
Copier (`copier update` + per-repo answers + drift detection) to carry a handbook change into existing repos, absorbing `sync-agent-files.sh`. [C6]

## A visionOS profile
A `swift-tooling.md` + `visionos-tooling.md` pair with `vos-gspheres` as the reference: pinned macOS runner, Swift Testing + swift-format + SPM, the testable-core split, the `.xcconfig` version SoT, and a fastlane-to-TestFlight release path (the one justified long-lived-secret deviation). [A24-A26]

## Decision hygiene
An ADR log (Nygard), a Diátaxis map, docs-link lint, and short considered-and-declined notes (release-please, Biome, Backstage, Harden-Runner) with revisit triggers. [B3, B5] Landed in part on 2026-09-17: `docs/decisions.md` as a single dated file and the impersonal entry form (`documentation.md`, "Documents and records"); B3's per-decision directory remains the option for a repo whose log outgrows one file; the Nygard template, the Diátaxis map, the link lint and the declined notes remain open. Landed further on 2026-09-17: the handbook's first actual decision record is a `<page>-why.md` sibling (`agents-why.md`), a third form beside the single file and the per-decision directory, and `documentation.md` now names it with the rule that earns a page one; the short declined notes have their form too, three of them in that file with their reasons, though B5's own list is untouched.

## A future-goals.md doc convention
A third sibling to `northstar.md` and `in-flight_ideas.md` for decided-but-unbuilt direction, distinct from the timeless northstar and from undecided in-flight questions. Unlike in-flight ideas, future goals are meant to shape present design (build forward-compatibly toward them); document it in `documentation.md` and seed the handbook's own with the LLM-Wiki convergence. [B7] Sharpened on 2026-09-17: a current-state document carries no list of what remains (`documentation.md`, "Documents and records"), and a stated trigger for a future change is admitted there; direction without a trigger has no home yet, which is this entry's question.

## Branching: keep two trunks, automate the tax
Decided: keep the permanent `develop`+`main` model, not release-from-main. Instead automate the back-merge cascade (a `git back-merge` dev-tool) and harden the promotion against a stale local `develop`; record the keep-two-trunk choice as an ADR. [D1] Landed in part on 2026-09-26, with dev-tools v1.4.0: `git back-merge` exists in dev-tools and brings the release back by a pull request rather than by a push, with the open cycle inside it, and the two-trunk choice is recorded in [`branching-why.md`](branching-why.md), the third form D1's note named. On 2026-09-27 every code repository but three switched to it ([`branching-why.md`](branching-why.md#2026-09-27-the-rollout-and-administrators-bound-at-once)). What remains open: the promotion's staleness guard, which would refuse `git merge --no-ff develop` while local `develop` differs from `origin/develop`, and folding the release flow into a release skill [C2].

## Quality gates sized for a one-engineer org
Coverage floors + a testing-trophy note; publint/attw before npm publish; a pinned `ty`; Electron Fuses + renderer-security tripwire. [A9, A11-A15, A18]

## MCP transport currency and security (conventions landed, rollout open)
A16/A17 are recorded in `mcp-server-conventions.md`: the endpoint is `/mcp`, `POST`-only for a stateless server, with explicit `TransportSecuritySettings`, allowlist-scoped CORS, and an honest "Auth model" section. What remains is the per-repo migration, each its own breaking release: bronze-scribing first, then deco-assaying, smalt-mcp, flint-slating, and ebony-enriching when next touched. [A16, A17]

## Watch list (track, don't adopt yet)
ty 1.0; TypeScript 7 / tsgo (RC); Node 26 LTS (Oct 2026); npm explicit-actions publisher requirement (May 2026); SPDX 3.x tooling; distroless base images; a generated docs site past ~30 docs; a DCO before the first outside contribution.

## The pilot's switch to the shared build script
Whether `pensa-grex` switches at its next release or sooner: its `scripts/build_pages_site.py` becomes dev-tools' `build-pages-site`, its Googie page moves into `site/shell.html`, its workflow takes the template's shape (a checkout of `dev-tools` at the pinned tag), and its README's site link moves onto the `Documentation:` line under the title. Raised 2026-09-17 when the script moved to `dev-tools` with `paper-boxing` as the second adopter; until it lands, the pilot runs its own copy, which built an identical site from pensa-grex v3.5.1 (dev-tools PR #6); since dev-tools v1.5.2 the shared script leaves the brand prefix out of the index, which the pilot's copy keeps.
