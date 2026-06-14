<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# ParkviewLab engineering — northstar

The conventions defined in the other documents in this handbook are downstream
of these intents; when a convention and an intent conflict, the intent wins and
the convention needs to be fixed.

## Intents

1. **One shape across many repos.**
   ParkviewLab is a *family* of repos, not a monorepo and not a pile of
   one-offs. They share one layout, one toolchain, one release flow, one brand —
   so each repo is legible the moment you open it, and the family coheres without
   coupling. Deviation from the common shapes must be justified and documented.

2. **Self-contained and self-describing.**
   A repo carries everything needed to understand, build, run, and ship it:
   locked dependencies, a single source of truth for its version, tag-driven
   releases, and documentation as a first-class artifact. Nothing load-bearing
   lives only in someone's memory. Try hard to avoid dependencies between repos.

3. **Legible to humans and AI alike.**
   Humans and AI agents are both first-class developers here. The same handbook,
   the same branch prefixes, the same written norms serve both — and each repo
   carries pointer files so an agent loads the conventions automatically.

4. **Use AI to automate the processes.**
   Creating a branch, committing, merging, releasing, whatever it is, if it's
   a process with defined steps, then teach the AI (MD files, skills, etc.)
   to do it for us so that it gets done with consistency. If it could apply
   to more than one repo then put it here in the handbook repo.

The "Many repos" intent (1) is usefully in tension with "Self-contained" intent (2).
N repos means N copies of the conventions to keep honest. The resolution is
*shared* sources (this handbook and `dev-tools`) so
the convention has one home even when it lives in many repos.

## Axioms

The same axioms support all four intents, from different angles.

1. **One source of truth.**
   A fact stated twice is a fact that will drift.
   Prefer one source + derivation over two copies kept in sync by discipline.
   The version, each convention, the brand — each lives
   in exactly one place. Everything else *derives* from it (runtime version from
   package metadata; the changelog from commits; pointer files from templates).

2. **Convention over configuration.** Same layout, tooling, and release flow in
   every repo. A new repo should be boring. Deviations are documented, not
   improvised.

3. **Write it down.** If a practice matters, if a concept should be explained,
   it's in the handbook — or in a repo's `docs` directory. Like `northstar.md` or
   `in-flight_ideas.md` — not just in a head or a chat log.
   Read `docs/documentation.md` in this repo for further explanation.

4. **Automate the mechanical; gate the irreversible.** Changelogs and releases
   are scripted and verified by a CI gate — *and* merging to a shared trunk,
   tagging, and releasing still require an explicit human hand.

## Guiding questions

When making a decision, these are the questions to keep answering:

- Could a new developer — human or AI — clone this repo and ship a release using
  only its README and this handbook?
- Is there exactly one source of truth for this fact, and does everything else
  derive from it?
- If this practice matters, is it written down where the next person will find
  it?

## What ParkviewLab engineering is not

- **Not a monorepo.** Many independently-released repos that share a shape
  — not one big tree.
- **Not a place for improvised per-repo process.** Repos differ in *what* they
  do, not in *how* they're laid out, tooled, licensed, or released. When a repo
  must deviate, the deviation is documented.

---
<sub>© 2026 Gary Frattarola · Licensed under [CC-BY-4.0](../LICENSES/CC-BY-4.0.txt) · part of the ParkviewLab handbook</sub>
