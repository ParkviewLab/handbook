<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# ParkviewLab engineering — northstar

The conventions defined in the other documents in this handbook are downstream of these intents; when a convention and an intent conflict, the intent wins and the convention needs to be fixed. A change of intent is made here first, in the same pull request as the convention that follows it, so that no disagreement is left standing by accident.

## Intents

ParkviewLab engineering serves four complementary intents: facets of one purpose, presented as peers rather than as one primary and three secondary, and mutually reinforcing.

1. **One shape across many repos.** ParkviewLab is a *family* of repos, not a monorepo and not a pile of one-offs. They share one layout, one toolchain, one release flow, one brand — so each repo is legible the moment you open it, and the family coheres without coupling. Deviation from the common shapes must be justified and documented.

2. **Self-contained and self-describing.** A repo carries everything needed to understand, build, run, and ship it: locked dependencies, a single source of truth for its version, tag-driven releases, and documentation as a first-class artifact. Nothing load-bearing lives only in someone's memory. Try hard to avoid dependencies between repos.

3. **Legible to humans and AI alike.** Humans and AI agents are both first-class developers here. The same handbook, the same branch prefixes, the same written norms serve both — and each repo carries pointer files so an agent loads the conventions automatically.

4. **Use AI to automate the processes.** Creating a branch, committing, merging, releasing, whatever it is, if it's a process with defined steps, then teach the AI (MD files, skills, etc.) to do it for us so that it gets done with consistency. If it could apply to more than one repo then put it here in the handbook repo.

### 1. One shape across many repos

The shape is concrete. Every repo is cloned the same way, a contained layout with a bare clone and one worktree per trunk; every repo has the same two trunks, `main` released and `develop` integrating, and the same prefixed ephemeral branches; every pull request is squash-merged with a Conventional Commit title, which is what the changelog is generated from; every release is cut by a tag; every README, licence header, and pointer file has the same place and the same form; and every repo wears the one brand. None of this is what a repo *does*. It is how a repo is laid out, tooled, licensed, and released, and it is the same whether the repo is a Python service, a desktop application, or this handbook.

The payoff is recognition. A developer who has worked in one ParkviewLab repo can open any other and know where the version lives, how to cut a branch, and what a release takes, before reading a line of its code. The family coheres without coupling: repos share a shape, not a build, and a change to one never breaks another. When a repo must deviate, the deviation is written down where the next reader will find it, so the shape stays legible even where it bends.

### 2. Self-contained and self-describing

A repo that needs something outside itself to be understood, built, or shipped has a dependency the next person will trip over. So each repo carries its own: locked dependencies, so a build is reproducible; one source of truth for its version, from which the runtime version, the tag, and the changelog all derive; tag-driven releases that run from the repo's own CI; and its documentation in `docs/`, a first-class artifact with the same standing as the code, starting with this kind of file. The pointer files (`AGENTS.md` and `CLAUDE.md` at the root, `docs/CONTRIBUTING.md`) say where the conventions are without restating them.

"Self-describing" is the test: could a new developer, human or AI, clone this repo and ship a release using only its README and the handbook? Whatever would stop them is something that lives only in someone's memory, and it belongs in the repo. Dependencies *between* repos are avoided for the same reason: they make one repo's build depend on another's state, and they turn the family back into the monorepo it is not.

### 3. Legible to humans and AI alike

Legibility means the shape is the same for both kinds of reader. A person and an agent read the same handbook, cut branches with the same prefixes, write the same PR titles, and are held to the same written norms; there is no second, private set of rules for either. The pointer files make it automatic for the agent: they are loaded at the start of a session and send it to the handbook and to the repo's own northstar before it works, so an agent begins from the conventions rather than from a guess.

This is why the norms are written and not merely known. A rule that lives in a head is invisible to an agent and forgotten by the next person; a rule in the handbook is read by both, and both can be held to it. The behavioural contract in `ai-collaboration.md` is the same idea applied to the agent's conduct: what it may do alone, what needs an explicit go-ahead, and how it reports.

### 4. Use AI to automate the processes

Any process with defined steps is a process an agent can be taught: creating a branch, committing, opening a pull request, bumping the version, cutting a release, regenerating a changelog. The teaching is written down, as handbook pages, as skills, as `dev-tools` helpers, so the process runs the same way every time, in every repo, whoever or whatever runs it. Consistency is the point; a process that is automated is a process that is no longer improvised.

The rule of placement is that anything that applies to more than one repo lives here, in the handbook, so that it is taught once. And the automation has an edge it does not cross: the mechanical steps are automated, and the irreversible ones, merging to a shared trunk, tagging, releasing, keep an explicit human hand (axiom 4).

### How the four reinforce each other

Each intent makes another possible. One shape (1) is only worth having if each repo in the family is complete in itself (2); a family of half-described repos would share a layout and nothing else. Legibility (3) follows from both: a reader, of either kind, understands a repo quickly because it looks like the others and describes itself. And automation (4) is possible only because the processes are written down (3): an agent can run a release exactly because the release flow is a page and a helper, not a memory.

Intents 1 and 2 meet at one point: N repos means N copies of the conventions to keep honest. The resolution is *shared* sources (this handbook and `dev-tools`) so the convention has one home even when it lives in many repos. Intent 4 stops where axiom 4 begins: the mechanical steps are automated, and merging, tagging, and releasing keep an explicit human hand, asked for per action rather than inferred.

## Axioms

The same axioms support all four intents, from different angles.

1. **One source of truth.** A fact stated twice is a fact that will drift. Prefer one source + derivation over two copies kept in sync by discipline. The version, each convention, the brand — each lives in exactly one place. Everything else *derives* from it (runtime version from package metadata; the changelog from commits; pointer files from templates).

2. **Convention over configuration.** Same layout, tooling, and release flow in every repo. A new repo should be boring. Deviations are documented, not improvised.

3. **Write it down.** If a practice matters, if a concept should be explained, it's in the handbook — or in a repo's `docs` directory. Like `northstar.md` or `in-flight_ideas.md` — not just in a head or a chat log. Read `docs/documentation.md` in this repo for further explanation.

4. **Automate the mechanical; gate the irreversible.** Changelogs and releases are scripted and verified by a CI gate — *and* merging to a shared trunk, tagging, and releasing still require an explicit human hand.

## Guiding questions

When making a decision, these are the questions to keep answering:

- Could a new developer — human or AI — clone this repo and ship a release using only its README and this handbook?
- Is there exactly one source of truth for this fact, and does everything else derive from it?
- If this practice matters, is it written down where the next person will find it?
- Is this a process with defined steps, and if so, has it been taught rather than repeated by hand?

## What ParkviewLab engineering is not

- **Not a monorepo.** Many independently-released repos that share a shape — not one big tree.
- **Not a place for improvised per-repo process.** Repos differ in *what* they do, not in *how* they're laid out, tooled, licensed, or released. When a repo must deviate, the deviation is documented.

---
<sub>© 2026 Gary Frattarola · Licensed under [CC-BY-4.0](../LICENSES/CC-BY-4.0.txt) · part of the ParkviewLab handbook</sub>
