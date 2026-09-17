<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# The agent set: the reasoning, the evidence and the decisions

This file is the second half of the record of the agent set. [`agents.md`](agents.md) says what the set is and how it is used; this file says why it is as it is: the questions that came up, the evidence gathered, the alternatives considered and set aside, and the rulings, each dated. Entries are in date order and the record at the foot summarises them. A proposal for an addition to the set lives in the org's wiki, on the Proposals shelf, until it is built; then it retires into this pair, and whatever remains genuinely open stays on the shelf as its own small proposal.

It is a record, so it describes the past and keeps doing so ([`documentation.md`](documentation.md#documents-and-records)). An open question does not belong here; it belongs in [`in-flight_ideas.md`](in-flight_ideas.md) or on the shelf.

## 2026-09-13: ten definitions, and the rules that chose them

Released as v0.17.0 (#35), with the dispatch skill, the installer, [`agents.md`](agents.md) and [`parallel-work.md`](parallel-work.md).

The set was designed from a stated requirement: agents with specific models and efforts, and one session able to manage several repos at once. Four uses justify a definition, and where none of them applies the session does the work itself: keeping the main session's context clean over a long day, running in parallel with other agents, carrying a focused prompt for one process, and reviewing with fresh context what the author cannot see. Saving tokens is not among them, which is why the model rule runs the other way from the usual instinct.

Model and effort are chosen for speed and accuracy. Fable wherever the output depends on judgement or on reading a large corpus accurately; Sonnet only where a faster model should give the same answer on a mechanical, well-specified task; Haiku nowhere; Opus with no role whilst Fable is available. Effort follows the cost of an error rather than the size of the task.

The coding criterion was settled against the obvious alternative of sorting work into easy and hard. Easy and hard are predictions made before the work, and a wrong prediction costs a rework round trip that exceeds the time the faster model saved. The criterion is therefore checkable at dispatch: a change fully specified and verifiable by an automatic check goes to the mechanical coder, and one where the agent must decide how goes to the coder.

Four design rules followed, each with its reason. Only the author and the coders write, because everything touching shared state stays in the session under the user's authorisation. Deterministic sequences are not agents, because a language model adds nondeterminism to a mechanical sequence; they live in `dev-tools` and in skills. Reviewers are dispatched together, because that is where the speed comes from. And no agent keeps memory, because a documented deviation belongs in a repo's docs.

Verified by experiment that day, not taken from documentation: `claude --agent <definition>` sets a session's model but not its effort, so the effort must be passed explicitly; symlinked agents and skills are discovered, which is what allows the installer to link rather than copy, so an edited definition arrives with the next pull of `main`.

## 2026-09-14: no steward for the proposal life cycle

The cycle by which a proposal is opened, ruled upon, built and retired is a fixed sequence of hand-offs, and the design rule that deterministic sequences are not agents applies to it. The ruling was therefore about form: should the cycle ever be automated, it is a skill run by the coordinating session, which dispatches the librarian for the wiki writes and a coder for the repo writes, and not a steward agent. No such skill exists. The cycle's only judgement, whether a proposal is ripe, superseded or in conflict with a northstar, is the kind of fresh-context report a reviewer already gives; a reviewer of that kind is the agent to add if the shelf grows long, not a steward writing to both the wiki and a repo, which the design rule on which agents write forbids.

## 2026-09-17: a fourth document reviewer

`docs-currency-checker` released as v0.20.0 (#39).

Three document reviewers could all pass a document that describes a route since renamed, a question since answered, or a build phase since ended, because each was checking something else: form and rules, a document against its twin, intent. The gap was currency, which needs the code rather than another document, so the definition runs read-only executions and takes from the session the decisions made in conversation, those being invisible in the repo until someone writes them down. Its effort is `max` because the judgement it returns cannot be re-derived by reading the files, which is the same reason the alignment reviewer has `max`.

## 2026-09-17: the wiki's librarian, and the registers it keeps

`bookstack-librarian` released as v0.21.0 (#40), with the `tangent` skill, a section in [`documentation.md`](documentation.md#discovered-tangents), an amendment to axiom 3 of the northstar, and a bullet in [`ai-collaboration.md`](ai-collaboration.md).

The need was a cross-project register for work discovered whilst doing something else. A repo's `in-flight_ideas.md` is the right home for an idea that repo is considering and the wrong home for the moment of discovery: writing one paragraph into another repo costs a branch, a commit, a pull request and a review, which is more than the idea is worth whilst attention is elsewhere, and an idea belonging to no repo has no file at all. The register costs one page.

A separate recording agent was considered and rejected. The substance of an entry (what the idea is, where it arose, why it was set aside) is known only to the working session, so the session must compose it in any case; what is delegable is the filing, and filing into the wiki is already the librarian's duty. A second writer would have been the librarian under another name.

The write monopoly rests on this documentation and not on a hook. A `PreToolUse` guard was designed, verified to work, and declined. Its cost was measured at 9.5 ms median over twenty runs and was not the reason. The reasons were these: a hard deny removes the judgement a convention allows, and an agent with a reason to write directly should be able to say so and ask; the catalog's own reconciliation repairs the lapse the guard was built for, since a book created, renamed or deleted directly is caught at the next dispatch; the administrative operations the guard would have blocked are already unavailable, the wiki account holding no administrative permission; and the handbook governs far more consequential writes, pushes to a trunk and releases, by convention and explicit authorisation, so a hook for the wiki alone would make the wiki stricter than the trunk. The gentler form of the same mechanism, a hook returning "ask" rather than "deny", is available if the convention proves insufficient, and would be adopted on evidence rather than in advance.

The catalog classifies a book on three facets, subject, form and status, rather than by subject headings alone, and each project is its own subject heading. The nine headings first proposed were rejected for mixing what a book is about (a machine, a project) with what kind of document it is (a proposal, a design record), which are different questions with different answers for the same book; and nine headings for nine books gives several of them a single book, which is no heading. The vocabulary grows by rule: the librarian proposes a term with its scope note and stops, the term is discussed, and it is added only on a ruling.

Axiom 3 of the northstar was amended in the same change. It named two homes for what matters, the handbook or a repo's `docs` directory, and the register is neither. The axiom now admits it as an inbox, with the promotion path that returns an idea to its repo by pull request, and states that the wiki is never the only home of anything a repo's reader needs. The alternative, leaving the axiom alone and calling the register an exception, was rejected: an axiom that quietly admits exceptions is not one.

The writers rule was amended in the same change, from two writers to three. It had read that only the author and the coders write, each to its own target; the librarian is a third writer whose target is neither a file nor a branch but the wiki, and the rule now names three writers and three kinds of target. The amendment was made rather than treated as an exception, for the reason that follows in the next paragraph about axiom 3: a rule that quietly admits exceptions is not one.

The behavioural contract gained a bullet in the same change, because a standing authorisation to record an entry without asking would otherwise have contradicted its rule against unprompted action. Such an authorisation is per kind of act, covers no other act, and is always reported in one line, an unmentioned record not existing for its reader.

## 2026-09-17: how a definition's tools list treats MCP tools

The rule as first written claimed that an MCP tool can be named only in full and never by a whole-server pattern. That was wrong as a statement of fact, and an experiment settled it on Claude Code v2.1.273: `mcp__<server>__<tool>` granted exactly that one tool; `mcp__<server>` and `mcp__<server>__*` each granted every tool of that server. An explicit list that names no MCP tool still withholds them all, which is why the other definitions cannot reach the wiki at all.

Naming each tool in full is therefore the choice here and not a necessity. The reason is that the list is then the exact boundary of what the agent can do, and for a writer a pattern would grant every write the server has, including the ones added after the definition was written.

One further observation from the same day, recorded for whoever meets it: installing a new definition mid-session made the new skill available to the running session at once, whilst the new agent could not be dispatched for some minutes, after which it worked with no restart and no further action.

## Decision record

| Date | Decision | Ruling |
|---|---|---|
| 2026-09-13 | The model and effort rule | Fable for judgement, Sonnet only for mechanical and verifiable work, Haiku nowhere, effort by the cost of an error |
| 2026-09-13 | How to choose between the two coders | By whether the change is fully specified and automatically verifiable, not by predicted difficulty |
| 2026-09-13 | Which agents may write | Only the author and the coders, each to its own target |
| 2026-09-14 | A steward agent for the proposal life cycle | No; should the cycle be automated it is a skill run by the coordinating session, dispatching the librarian and a coder |
| 2026-09-17 | A fourth document reviewer | Added, at `max` effort, because currency needs the code and not another document |
| 2026-09-17 | A separate agent to record tangents | No; the session composes the entry and the librarian files it |
| 2026-09-17 | Enforcing the wiki's write monopoly | Documentation alone; the guard hook declined, its "ask" form left available on evidence |
| 2026-09-17 | A third writer, the wiki's librarian | Admitted, to the wiki only, by amending the writers rule rather than by exception |
| 2026-09-17 | How the catalog classifies a book | Three facets, subject, form and status, with a heading per project; the vocabulary grows by proposal then ruling |
| 2026-09-17 | Axiom 3 and a register outside every repo | Amended to admit the register as an inbox, with the promotion path, and never as a sole home |
| 2026-09-17 | Naming MCP tools in a definition | Each in full, as a choice; whole-server patterns work but would grant a writer every write, including later ones |
