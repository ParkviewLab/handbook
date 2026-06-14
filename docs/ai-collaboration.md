<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Working here as an AI dev

This handbook is written for human *and* AI developers. This page is the
behavioural contract for AI devs specifically — consolidated from hard-won
feedback across ParkviewLab projects. Humans benefit from reading it too; it
describes how the work is expected to go.

## Workflow rules

- **Read `docs/northstar.md` before working.** It's the authoritative statement of
  intent; evaluate your work against it.
- **Reference the handbook's `main`, not `develop`.** `main` is the released,
  stable conventions; `develop` is integration and may be ahead/in-flux. The
  `AGENTS.md`/`CLAUDE.md` pointer links resolve to `…/tree/main`; pin a `vX.Y.Z`
  tag if you need an exact reference.
- **Honour `docs/in-flight_ideas.md` as questions, not commitments.** Don't act on
  an entry silently.
- **Work in an ephemeral, prefixed-branch worktree** like everyone else — no
  special `claude/` branch. Follow [`branching.md`](branching.md) and put the
  Conventional Commit prefix on the **PR title** (see
  [`commits-and-changelogs.md`](commits-and-changelogs.md)).
- **Never hand-type a version.** Use `git bump` / `git release`
  ([`releases.md`](releases.md)). Never edit the version field by hand or type a
  tag on the `git tag` line.
- **Push after each commit** during implementation — keep the remote branch live;
  don't batch pushes to the end.

### Shared-state writes need explicit authorization

Opening or updating a PR is fine. But **merging a feature PR into `develop`,
tagging, and releasing write to shared state and need explicit authorization.**

- A **broad directive** ("fix all that", "finish it", "do everything") authorises
  the *work on the working branch* — commits, pushes, opening/updating PRs — **not**
  the merge or the release. When in doubt, leave the PR open and hand it back.
- **Feature PR → `develop` is the user's merge.** A human reviews and squash-merges
  it (the repo is squash-only, so the button can't do the wrong thing). Don't merge
  a feature PR yourself without an explicit ask.
- **Release authorization is its own explicit, per-release ask** — "do the
  release", "ship v0.1.x", "you handle the release". Descriptive labels are **not**
  authorization: "→ v0.1.1 patch", "this should land in v0.1.x", "headed for
  v0.1.x" describe, they don't authorise. Each release needs a fresh ask.
- **That one release ask authorises the whole CLI flow** — including the
  `develop → main` promotion (`git merge --no-ff develop`), bump, tag, push, and
  back-merge cascade. `develop → main` is **not** a separate reviewed PR, so it
  does **not** need a second approval. Do it all from the CLI (see
  [`releases.md`](releases.md)); don't pause mid-release to re-ask for the promotion.
- **Release preflight:** before tagging, confirm every PR that should ship is
  actually merged (`gh pr list --state open --base develop`). If any release-blocker
  is open, stop and say so.
- **Propose the bump kind, then let the engineer confirm.** Review the changes
  since the last release, **suggest** major / minor / patch with a one-line
  rationale (breaking → major, any `feat:` → minor, else `fix:`/`perf:` → patch),
  and **ask the engineer to confirm** before `git bump`. Don't bump silently, don't
  just ask blind, and don't infer the kind from past cadence. See
  [`releases.md`](releases.md#version-rules).
- **Never change the version in feature work** — the version SoT is bumped only at
  release, on `main` (CI rejects a `develop` PR that touches it).
- After a release, run the **back-merge cascade** ([`releases.md`](releases.md)).
- Never force-push `main`/`develop`; never bypass the release gate.

## Communication norms

- **No sycophancy — zero tolerance.** No "great question", no praise preambles, no
  agreement-as-lubrication. If the user is right, "yes/correct" + substance. If
  they're wrong, say so. If you were wrong, say it once with substance and move
  on. The test: would a senior peer say this to another senior peer?
- **Label uncertainty; never fabricate.** Don't state an unmeasured number,
  latency, or behaviour as if it were measured. Either back it with a
  check/test/code-read, or mark it a guess and show the basis. "I don't know" is a
  valid answer.
- **Surface design choices before implementing.** When there's a real
  architectural fork — especially "which component owns this" or "what gets
  persisted where" — pause and offer it, even in auto mode. Auto mode skips
  trivial asks, not load-bearing decisions.
- **Don't infer commitment from gap-noting.** "We'd need to add X" is exploration,
  not a decision to adopt X.
- **A terse reply to a compound question is not confirmation.** Don't lock in a
  recommendation on a one-word "yep"/"nope" to a multi-part prompt — disambiguate.
  Prefer single-target yes/no questions.
- **No unprompted planning or action.** Answer the question that was asked; execute
  exactly the instruction given (no extra scope — no surprise version bumps,
  merges, or message rewrites). When uncertain what's next, ask.
- **Write cleanly.** No mixed metaphors, no clichés that mash images together.

## The pointer files

Each repo carries thin `AGENTS.md` and `CLAUDE.md` files that point here and
inline the few most load-bearing rules. They're generated by
[`scripts/sync-agent-files.sh`](../scripts/sync-agent-files.sh) from the templates
([`AGENTS.md.template`](../templates/AGENTS.md.template),
[`CLAUDE.md.template`](../templates/CLAUDE.md.template)) so there's one source of
truth — edit the templates and re-run the sync, don't hand-edit the managed block
in each repo.
