<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# The agent set: the reasoning, the evidence and the decisions

This file is the second half of the record of the agent set. The line between the two is what a reader needs: [`agents.md`](agents.md) keeps every rule and every reason needed to apply one, and this file adds what is needed only to reopen a decision, which is the alternatives set aside, the designs declined, the evidence, and the dated rulings. Entries are in date order and the record at the foot summarises them. The life cycle by which an addition to the set is proposed and then retires into this pair is on that page, under "Changing the set".

It is a record, so it describes the past and keeps doing so ([`documentation.md`](documentation.md#documents-and-records)). An open question does not belong here. One about the set as released goes to [`in-flight_ideas.md`](in-flight_ideas.md); one of a proposal's own undecided points stays with that proposal until it is built.

## 2026-09-13: ten definitions, and the rules that chose them

Released as v0.17.0 (#35), with the dispatch skill, the installer, [`agents.md`](agents.md) and [`parallel-work.md`](parallel-work.md).

The originating requirement was stated before any design: agents with specific models and efforts, and one session able to manage several repos at once. The set and the rules that follow from it are on the page; what the page does not record is what they were chosen against.

Sorting coding work into easy and hard was the obvious alternative to the criterion the page now states, and it was rejected because easy and hard are predictions made before the work, whilst a wrong prediction costs a rework round trip that exceeds the time the faster model saved. Saving tokens as a reason for delegating was rejected in the same discussion, which is why the model rule runs against the usual instinct and buys speed and accuracy instead.

The two facts the page cites as verified were established by experiment that day rather than read from documentation, because the documentation did not settle them: that a definition named on the command line sets a session's model but not its effort, and that symlinked definitions are discovered, which is what allows the installer to link rather than copy.

## 2026-09-14: no steward for the proposal life cycle

The cycle by which a proposal is opened, ruled upon, built and retired is a fixed sequence of hand-offs, and the design rule that deterministic sequences are not agents applies to it. The ruling was therefore about form: should the cycle ever be automated, it is a skill run by the coordinating session, which dispatches the wiki's librarian, recorded below, for the wiki writes and a coder for the repo writes, and not a steward agent. No such skill exists. The cycle's only judgement, whether a proposal is ripe, superseded or in conflict with a northstar, is the kind of fresh-context report a reviewer already gives; a reviewer of that kind is the agent to add if the shelf grows long, not a steward writing to both the wiki and a repo, which the design rule on which agents write forbids.

## 2026-09-17: a fourth document reviewer

`docs-currency-checker` released as v0.20.0 (#39).

Three document reviewers could all pass a document that describes a route since renamed, a question since answered, or a build phase since ended, because each was checking something else: form and rules, a document against its twin, intent. The gap was currency, which needs the code rather than another document. Its effort is `max` because the judgement it returns cannot be re-derived by reading the files, which is the same reason the alignment reviewer has `max`.

## 2026-09-17: the wiki's librarian, and the registers it keeps

`bookstack-librarian` released as v0.21.0 (#40), with the `tangent` skill, a section in [`documentation.md`](documentation.md#discovered-tangents), an amendment to axiom 3 of the northstar, and a bullet in [`ai-collaboration.md`](ai-collaboration.md).

The need was a cross-project register for work discovered whilst doing something else. A repo's `in-flight_ideas.md` is the right home for an idea that repo is considering and the wrong home for the moment of discovery: writing one paragraph into another repo costs a branch, a commit, a pull request and a review, which is more than the idea is worth whilst attention is elsewhere, and an idea belonging to no repo has no file at all. The register costs one page.

A separate recording agent was considered and rejected. The substance of an entry (what the idea is, where it arose, why it was set aside) is known only to the working session, so the session must compose it in any case; what is delegable is the filing, and filing into the wiki is already the librarian's duty. A second writer would have been the librarian under another name.

The write monopoly rests on [`agents.md`](agents.md) and not on a hook. A `PreToolUse` guard was designed, verified to work, and declined. Its cost was not the reason: the script, timed on the workstation over twenty runs against one recorded event, took about ten milliseconds a call, an order less than the round trip it would have gated. The reasons were these: a hard deny removes the judgement a convention allows, and an agent with a reason to write directly should be able to say so and ask; the catalog's own reconciliation repairs the book-level lapse the guard was built for, a book created, renamed or deleted directly, though not a page written inside an existing book; the administrative operations the guard would have blocked are already unavailable, the wiki account holding no administrative permission; and the handbook governs far more consequential writes, pushes to a trunk and releases, by convention and explicit authorisation, so a hook for the wiki alone would make the wiki stricter than the trunk. The gentler form of the same mechanism, a hook returning "ask" rather than "deny", is available if the convention proves insufficient, and would be adopted on evidence rather than in advance.

The librarian's effort is `high` and not `max`, unlike the two reviewers whose judgement cannot be re-derived by reading: the content of a write is the caller's, the librarian decides only how to carry it out, and its report is verified like any other.

The catalog classifies a book on three facets, subject, form and status, rather than by subject headings alone, and each project is its own subject heading. The nine headings first proposed were rejected for mixing what a book is about (a machine, a project) with what kind of document it is (a proposal, a design record), which are different questions with different answers for the same book; and nine headings for the nine books then in the library gives several of them a single book, which is no heading. The vocabulary grows by rule: the librarian proposes a term with its scope note and stops, the term is discussed, and it is added only on a ruling.

Axiom 3 of the northstar was amended in the same change. It named two homes for what matters, the handbook or a repo's `docs` directory, and the register is neither. The axiom now admits it as an inbox, with the promotion path that returns an idea to its repo by pull request, and states that the wiki is never the only home of anything a repo's reader needs. The alternative, leaving the axiom alone and calling the register an exception, was rejected: an axiom that quietly admits exceptions is not one.

The writers rule was amended in the same change, from two writers to three. It had read that only the author and the coders write, each to its own target; the librarian is a third writer whose target is neither a file nor a branch but the wiki, and the rule now names three writers and three kinds of target. The amendment was made rather than treated as an exception, for the reason that follows in the next paragraph about axiom 3: a rule that quietly admits exceptions is not one.

The rule against agent memory was qualified in the same change rather than excepted: a register an agent keeps in a store the user reads is a document, not memory, being visible, citable and editable by anyone, which is what the axiom on writing things down asks for.

The behavioural contract gained a bullet in the same change, because a standing authorisation to record an entry without asking would otherwise have contradicted its rule against unprompted action. Such an authorisation is per kind of act, covers no other act, and is always reported in one line, an unmentioned record not existing for its reader.

The proposal's own record retired into this file rather than into the lab's operations repository. That repository is for the lab's machines and the stacks running on them, one runbook per host or service with a why file beside it, and an agent of the working environment is neither; the handbook owns the agent, so the handbook owns the reasoning. Only the facts about the wiki service itself, the account, the upload path, the rate limit and the bridge, stayed with that service, where they already were.

## 2026-09-17: how a definition's tools list treats MCP tools

The rule as first written claimed that an MCP tool can be named only in full and never by a whole-server pattern. That was wrong as a statement of fact, and an experiment settled it on Claude Code v2.1.273: `mcp__<server>__<tool>` granted exactly that one tool; `mcp__<server>` and `mcp__<server>__*` each granted every tool of that server. An explicit list that names no MCP tool still withholds them all, which is why, at that point, no other definition held a wiki tool; the last entry below reverses that. The wrong rule was written and corrected inside the same pull request, so no release ever carried it; the documentation and the experiment agree.

Naming each tool in full is therefore the choice here and not a necessity, and the page states it as such with its reason.

The same principle removed two tools from the librarian's list on the same day. Its list held the two recycle-bin tools, and a read dispatched to the agent returned "Insufficient permissions for this operation", the wiki's routes for the recycle bin being served only to an administrative role that the account deliberately lacks. A list that is meant to be the exact boundary of what an agent can do cannot carry two entries that can never succeed, so they were removed rather than left as an aspiration.

One further observation from the same day, recorded for whoever meets it: installing a new definition mid-session made the new skill available to the running session at once, whilst the new agent could not be dispatched for some minutes, after which it worked with no restart and no further action.

## 2026-09-17, later: the four decisions the proposal had left open

The librarian's proposal was built with four of its decisions unruled, which is why its book stayed on the wiki's Proposals shelf. All four were ruled the same evening, and the book now holds nothing open.

Where the classification metadata lives: on the catalog entries, and nowhere else. The alternative was tags on the books themselves, and the library's own state decided it. Across the eleven books, their own tags carried four incompatible schemes, three books carried none, one used labels with no values, and only two used the ruled vocabulary, whilst every catalog entry was uniform because all were written in one pass by one rule. That is what happens when classification lives on the described thing and is applied by whoever creates it. The three books whose tags merely duplicated their entries lost those tags in consequence; the older ad-hoc tags on the rest are their authors' and stay.

Withdrawn entries: kept, as built. A deleted book's entry moves to a chapter named Withdrawn with a note of where its substance went, so the catalog records what the library held as well as what it holds. The cost is nothing and the benefit appears only when someone asks after a book that is gone.

The desktop application's writes: left alone, and recorded as an idea rather than a plan ([`in-flight_ideas.md`](in-flight_ideas.md)). The convention reaches Claude Code sessions through [`agents.md`](agents.md); the desktop application has no hooks and is not bound by it, so a write made there goes directly under the same wiki account. Binding it would need a second wiki account and token, a read-only token for the shared server, a second bridge and per-agent server configuration, which is a great deal of machinery for a client that writes rarely.

Read-only wiki tools for the reading agents: granted, to every read-only definition rather than to the document reviewers alone. The line between a reviewer and any other reader is arbitrary once the tools are read-only, and the monopoly was always about writes; a reader that must ask for an excerpt cannot follow a citation, which makes the librarian a bottleneck in the one case where it adds nothing. Each of the eight gains exactly two tools, a search and a page read, and the sentence in [`agents.md`](agents.md) that said no other definition holds a wiki tool had to be restated in terms of writes, which is the measure of how far the grant reaches.

## 2026-09-18: the dispatch rule

The rule of 2026-09-13 put Fable on every step whose output depends on judgement, which made the scarcest model the default. Fable's usage limit then stopped work part-way three times: two workers on 2026-09-15, which were continued on Opus at `max`, and a workflow's coder on 2026-09-18. The ruling after the third stop was that Fable is not used without asking, with a reason, and that the coder runs on Sonnet at `high` unless the task looks as if it needs Opus at `max`. An interview the same day extended the ruling into a rule for every dispatch, which [`agents.md`](agents.md#the-dispatch-rule) states and [`parallel-work.md`](parallel-work.md) applies to the choice of structure.

The aim was kept: the best result in the least wall-clock time, with tokens no constraint and the stronger choice taken where the two differ, because a rework round costs more time than a faster model saves. What the three stops showed is that Fable's usage is a constraint, so a rule that makes Fable the default spends it on steps that do not need it and stops work where it runs out. Opus now takes the judgement steps, and Fable is asked for per dispatch, with the reason, in two cases only: after Opus at `max` has failed or been rejected, and for writing or judging what the user will rule on, where one error of judgement is costly and hard to detect.

Effort by the cost of an error gave way to effort by the step: `low` for lookups and running checks, `high` for implementation and reviews, `max` for planning, design, writing policy and verifying findings, and one level up where the kind of step is unclear. Claude Code offers five levels; the rule uses the three it names, so that one level up is the larger step that the preference for the stronger choice asks for.

`northstar-reviewer` keeps `max`, one level above a review, because a judgement against the northstar is of the kind that the rule's second case for Fable, above, calls costly and hard to detect. `docs-currency-checker` keeps `max` because checking each claim against the code and the decisions supplied is the work of verifying findings. `handbook-librarian` moves from `medium` to `high`: reading a corpus for what governs a task is judgement and not a plain lookup, since what it leaves out reaches every worker's brief, so it takes one level above a lookup's `low`, which on the rule's three levels is `high`.

The criterion between the two coders stands, and what changed is the coder's model and the mechanical coder's effort, from `medium` to `high`, since a specified edit is implementation. The coder runs on Sonnet at `high` by default, as the executor of a plan's step does once an Opus planning step has written it, and on Opus at `max` when the task looks as if it needs it. The Agent tool takes a model but not an effort, so that escalation cannot be reached through it with one definition, and `coder-max` carries it. Its body directs the agent to read the coder's definition and follow its body, which keeps one source for the instructions; the costs are that they arrive as a file the agent reads rather than as its system prompt, which is why the body names that file as the one it reads as instructions, and that an agent unable to read it stops. Four alternatives were set aside: a copy of the body kept identical by a check, which puts the instructions in the system prompt but makes the second copy that axiom 1 prefers to avoid; a copy generated by the installer, which is one source with a derivation but would be stale after each `git pull` that changes the coder until the installer ran again, undoing the reason the installer links rather than copies; the `skills` field, which preloads a skill into a subagent but not into a teammate, so the teammate role would lose its instructions; and reaching `max` through a workflow or a background session instead, which would choose the structure by the model rather than by the shape of the work. `searcher` exists for the same reason at the other end of the scale: a lookup is `low`, and a built-in agent dispatched through the Agent tool carries no effort of its own and runs at the session's, which for a main session at `max` is the highest level there is. Both were proposed, with their alternatives, in the plan for this change and ruled on there rather than on the wiki's Proposals shelf, and the page's rule on changing the set now admits that route for an addition small enough to be ruled on with the change that builds it.

The dispatch skill was cut back to its procedure rather than kept as a second copy of the rule: it now states only the steps a session follows when it dispatches, and points to [`agents.md`](agents.md#the-dispatch-rule) for the rule itself, so the rule has one source. A copy of the rule in the skill, kept in step with this page only by editing both together, was set aside.

Planning comes first where a task is not fully specified, as a file the user approves before anything is executed, because a clear brief makes the execution faster and lets a faster executor carry it out. The main session keeps coordination and decision for itself and gives reading, searching, implementing and reviewing to agents, so that its context holds no more than the task needs; the page's earlier sentence that a session does the work itself where no use of an agent applies gave way to that.

Workflows by default were considered and rejected: the shape of the work decides between a subagent, a workflow, a background session and an agent team. Ultracode makes a workflow the default for every substantive task; what was kept from it is its thoroughness, verification by a fresh agent and review from more than one lens where the risk calls for it, inside whichever structure the shape chose.

Every definition now holds the wiki's read tools, and a book read joins the search and the page read, so that an agent can find its way within a book to the page a citation names. The grant of 2026-09-17 reached the read-only definitions alone; its reason, that an agent which must ask for an excerpt cannot follow a citation, applies to a writer as much as to a reader, and writes remain the librarian's alone. Making every coder, or every dispatch, an agent team with the librarian was set aside: a teammate is a full session, idle for most tasks, and agent teams are experimental.

The facts about the routes were established as follows. From the agents' transcripts on the workstation: a definition's effort applied to subagents dispatched with the Agent tool (`checks-runner` at `low` and `handbook-librarian` at `medium`, v2.1.271); a call naming `model: opus` ran `docs-reviewer` on Opus at its definition's `high`, and a `general-purpose` agent called with `model: sonnet` ran at the session's `max` (v2.1.274); a background session started with `--agent coder`, `--model opus` and `--effort max` ran on Opus at `max` while the definition named Fable at `high` (v2.1.270, 2026-09-15), so `--model` takes precedence over the definition's model. From Claude Code's own tool schemas and descriptions (v2.1.273), not measured: the Agent tool's parameters include a model and no effort; a workflow's `agent()` takes both and falls back to the session's, its behaviour with `agentType` and no effort not measured; the built-in `Explore` and `Plan` carry no effort. From `claude --help` (v2.1.273): `--model`, and `--effort` with the levels `low`, `medium`, `high`, `xhigh` and `max`.

This supersedes, from 2026-09-13: the model and effort rule; the coder's model and the mechanical coder's effort in the coding criterion, whose test stands; the sentence that Opus has no role while Fable is available; the three modes of parallel work, which are now four structures; and the sentence that the session does the work itself where no use of an agent applies. From 2026-09-17 it supersedes the grant of two wiki read tools to the read-only definitions alone.

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
| 2026-09-17 | The two recycle-bin tools in the librarian's list | Removed; the account holds no administrative permission, so they could never succeed |
| 2026-09-17 | Axiom 3 and a register outside every repo | Amended to admit the register as an inbox, with the promotion path, and never as a sole home |
| 2026-09-17 | Recording an entry without asking | Authorised standing, per kind of act, and always reported in one line |
| 2026-09-17 | Agent memory and a register in a shared store | The rule qualified, not excepted: such a register is a document, not memory |
| 2026-09-17 | Where the proposal's own record retires | Into this file, the handbook owning the agent; the lab's operations repository is for its machines and stacks |
| 2026-09-17 | Naming MCP tools in a definition | Each in full, as a choice; whole-server patterns work but would grant a writer every write, including later ones |
| 2026-09-17 | Where the classification metadata lives | On the catalog entries alone; the books' own tags carried four incompatible schemes whilst every entry was uniform |
| 2026-09-17 | Withdrawn entries in the catalog | Kept in their own chapter, so the catalog records what the library held as well as what it holds |
| 2026-09-17 | The desktop application's writes | Left alone and recorded as an idea; binding it would need a second account, token, bridge and per-agent configuration |
| 2026-09-17 | Read-only wiki tools for the reading agents | Granted to every read-only definition, two tools each; the monopoly is about writes, and a reader must be able to follow a citation |
| 2026-09-18 | The model rule | By the step: Opus for judgement, Sonnet for a step whose result is fixed by its input and for the coder's default, the stronger where unclear, Haiku nowhere; supersedes the model clauses of the 2026-09-13 rule, including "Opus has no role while Fable is available" |
| 2026-09-18 | Fable | Only on the user's yes, asked per dispatch with the reason, after Opus at `max` has failed or been rejected, or for writing or judging what the user will rule on; no definition names it |
| 2026-09-18 | The effort rule | By the step: `low` for lookups and checks, `high` for implementation and reviews, `max` for planning, design, policy and verifying findings, one level up where unclear, three levels only; supersedes "effort by the cost of an error" (2026-09-13) |
| 2026-09-18 | The coder's model | Sonnet at `high` by default, Opus at `max` when the task looks as if it needs it; the 2026-09-13 criterion between the two coders stands, its "coder (Fable, high)" and "mechanical-coder (Sonnet, medium)" superseded |
| 2026-09-18 | Opus at `max` for the coder through the Agent tool | A second definition, `coder-max`, whose body reads and follows the coder's; a checked copy, an installer-generated copy, a preloaded skill and a change of structure declined |
| 2026-09-18 | Lookups at `low` through the Agent tool | A read-only definition, `searcher`, on Sonnet at `low`, because a built-in agent runs at the session's effort |
| 2026-09-18 | Planning | A task not fully specified is planned first, on Opus at `max`, as an executable brief in a Markdown file the user approves before anything is executed |
| 2026-09-18 | The main session | Coordinates and decides, on Opus at `max`; reading, searching, implementing and reviewing go to agents; supersedes "where none of those applies, the session does the work itself" (2026-09-13) |
| 2026-09-18 | The structure of a dispatch | By the shape of the work: a subagent, a workflow, a background session per repo, or an agent team; workflows by default rejected; supersedes the three modes of 2026-09-13 |
| 2026-09-18 | Ultracode | Its thoroughness kept inside the structure the shape chose; its default of a workflow for every task not adopted |
| 2026-09-18 | Verification | Matched to risk: tests and one Opus reviewer for code, the document reviewers for documents, a second independent lens for what is outward-facing or hard to undo; every finding checked against its evidence at `max` |
| 2026-09-18 | The brief | Only what the step needs: paths and exact questions, the plan's step and its checks, facts not cheaply discoverable; large results written to files |
| 2026-09-18 | Continuing an agent | Continued when the next step needs its context; fresh for every review and verification, or when the earlier context is mostly irrelevant |
| 2026-09-18 | A specification changed mid-run | Every dispatch working from it stops at once; the work restarts from the new specification, keeping what still fits |
| 2026-09-18 | Naming a dispatch | Every dispatch's model and effort stated when it is made, and passed explicitly wherever the route takes them |
| 2026-09-18 | A usage limit | Reported at once; the work continues on the next model the rule allows for the step, and for a judgement step on Opus the session asks; supersedes the practice, recorded nowhere in the handbook, of continuing on Opus at `max` after Fable's limit, which is now the rule's first case |
| 2026-09-18 | Wiki read tools for every definition | Granted to every definition but the librarian, three tools each (search, book read, page read), with the section that explains them; writes stay the librarian's; supersedes the 2026-09-17 grant of two tools to the read-only definitions |
| 2026-09-18 | An agent team with the librarian for every coder or every dispatch | Declined: a teammate is a full session, idle for most tasks, and agent teams are experimental |
| 2026-09-18 | Where a small addition to the set is proposed | In the plan of the change that builds it, and ruled on there, as an alternative to the wiki's Proposals shelf; the rule on changing the set amended to say so |
| 2026-09-18 | The dispatch skill's copy of the rule | Cut back to the procedure, pointing to `agents.md` for the rule itself, so the rule has one source; a copy of the rule kept in step with this page by editing both together declined |
