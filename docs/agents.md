<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Agents

ParkviewLab keeps a small set of Claude Code **agent definitions**: subagents a session delegates to, and, when [agent teams](parallel-work.md#an-agent-team) are on, teammate roles. Each is a Markdown file with YAML frontmatter (name, description, model, effort, tools) and a body that is the agent's whole system prompt. The set lives in [`templates/agents/`](../templates/agents/) and is installed at the **user level** (`~/.claude/agents/`) by [`scripts/install-agents.sh`](../scripts/install-agents.sh), so every session on a machine can use it whatever directory it starts in. This page records what the set is, the rules that chose it, and the rule by which work is dispatched; its sibling [`agents-why.md`](agents-why.md) records what is needed only to reopen one of those rules: the alternatives set aside, the designs declined, the evidence, and the dated rulings.

## Why agents here

An agent costs what it reads and what it writes, so it is an escalation and not a floor. Its uses are these: it runs in parallel with other agents, where the work genuinely divides; it reads a corpus too large for the session's own context and returns the conclusion (the handbook librarian reads the handbook for the rules a task needs); and a reviewer with fresh context catches what the author cannot. Everything else the session does itself ([the dispatch rule](#the-dispatch-rule)).

## The dispatch rule

Usage is a constraint, alongside wall-clock time, and the aim is the best result within both. Where the faster choice and the stronger one differ, the stronger is taken when a rework round is likely: a rework round costs more than a stronger model saves, but only when it happens. Fable's usage is dearer again, so Fable is kept for the steps that need it.

Dispatch is an escalation. The session reads, searches, edits and runs the checks itself, and dispatches in three cases only: work that genuinely runs in parallel, a read too large for its context, and one fresh review where independence matters. The measurement that prompted this rule, and the practice it replaced, are in [`agents-why.md`](agents-why.md).

Model and effort follow the level of the work. The same three levels govern the session's own choice, which it states when it starts, and each dispatch's:

| Level | The work | Model and effort |
|---|---|---|
| Routine | A lookup, a specified edit, running checks, a step of an approved plan that leaves no decision open | Sonnet at `high` |
| With judgement in it | Implementation that must decide how, a review, an audit, reading a corpus for what governs a task | Opus at `high` |
| High risk | Work that meets the test below | Opus at `high`, and `max` for planning a hard problem and for the final verification |

High risk is defined by consequence, not by category: a mistake that would be published, that would reach many repositories at once, or that would be hard to undo. That covers architecture, security, a northstar, organisation-wide policy, anything that publishes (a release's documents, a site, the registers) and any cross-repository propagation. The mechanical steps of a release or of a settings change are not high risk in themselves, since their read-backs check them; what is, is the preflight and currency check before a release that publishes documents, and the check of a prepared settings call against this handbook.

There is no fixed default: the level decides, the session names its choice at the start as every dispatch names its own, and the user may change it at any time. Where it is unclear which level applies, take the higher. A definition keeps the effort its row in [the set](#the-set) gives it, which is how a lookup still reaches `low`; Claude Code's `medium` and `xhigh` are not used, and Haiku is used nowhere.

Checks are run by the session, which reads the output itself. `checks-runner` is dispatched in two cases only: a check whose output is too large to read in the session, and a failing check that needs diagnosis. That bound is stated here so that the agent does not become the habit again.

Implementation is the session's own work for a single repository. Where it is dispatched, which is where several repositories are worked at once or where the task runs whilst the session does something else, it goes to `coder`, on Sonnet at `high`. It goes to Opus at `max` when the task looks as if it needs it: judgement-heavy, cross-cutting, loosely specified, or already attempted on Sonnet without success; the dispatch says which of these applies. Through the Agent tool that is `coder-max`; a workflow or a background session gives `coder` the model and effort directly ("Using them", below). A change that is fully specified and verifiable by an automatic check (tests, lint, types, a diff against a template) goes to `mechanical-coder` instead, and the check catches what it misses. That test can be applied at dispatch, which "easy" and "hard" cannot: they are predictions made before the work, and a wrong one costs a rework round.

Fable is used only on the user's yes, asked before each dispatch and with the reason, and it is asked for in two cases only: Opus at `max` has failed at the step or produced something the user rejected; or the step writes or judges something the user will rule on (a northstar, a policy, an org-wide design), where one error of judgement is costly and hard to detect. A yes covers the one dispatch it was given for. No definition names Fable.

A task that is not fully specified is planned before it is executed; one that states exactly what changes is executed directly. The plan is written on Opus, at `max` where the problem is hard, by the main session or by a planning agent it dispatches, and it is an executable brief: the files, the exact changes, the acceptance checks, and each step's structure, model and effort. It is a Markdown file outside the repositories, given to the user as a link with a short summary, and nothing in it is executed until the user has read it and given the go-ahead. Every plan states its dispatch budget: the greatest number of agents it may spend, the greatest number of review rounds per phase, and the conditions on which the work stops and asks. A plan that names a workflow or an agent team is the user's request for one.

The main session does the work and decides: it plans, talks to the user, reads, searches, edits, runs the checks, and verifies. It dispatches in the three cases above, and its model and effort follow the level of the work rather than a fixed default.

A brief carries only what its step needs: the paths and the exact question rather than pasted documents, and for a step of a plan, the step, its acceptance checks, and the facts the agent cannot discover cheaply. An agent dispatched by definition receives the `CLAUDE.md` hierarchy itself, so the brief does not restate it; the exceptions are the built-in `Explore` and `Plan`, which receive none of it, managed policy files included, so a brief to either states the rules its step needs. A large result is written to a file, and the agent returns the conclusion and the path.

An earlier agent is continued, by a message to its name or id, which resumes it with its context, when the next step needs that context, as a fix after its own implementation does. A fresh agent is dispatched when independence matters, which is a review, or when the earlier context is mostly irrelevant.

Verification is matched to the risk. Code gets its tests and, where the risk calls for it, one reviewer on Opus; a document gets the reviewer whose concern it touches, and only before it is published; work that is high risk by the test above gets a second, independent lens as well. The session checks a review's findings against the evidence itself, in one batch, at `high`, and at `max` only at the high-risk level. A fresh agent per finding is not used: it multiplies a review's cost without a matching yield, and the batch found every real defect in the reviews of 18 and 19 September 2026.

When the specification changes during a run, every dispatch working from it stops at once, and the work restarts from the new specification, keeping what still fits it.

Every dispatch is named with its model and effort when it is made (each agent, each stage of a workflow, each session) in the reply to the user, and both are passed explicitly wherever the route takes them. Claude Code's tool descriptions advise leaving the model unset by default; this rule is the user's standing instruction to set it.

When a usage limit is hit, the session reports which one at once and continues on the next model the rule allows for the step: Opus at `max` after Fable, and Opus at the step's effort after Sonnet. For a judgement step on Opus the only other model the rule allows is Fable, which needs the user's yes, so there the report asks.

Which structure a dispatch runs in (a subagent, a workflow, a background session per repo, or an agent team) is chosen by the shape of the work, as [`parallel-work.md`](parallel-work.md#the-coordinator-and-the-workers) states. A workflow and an agent team are exceptions rather than defaults: one runs when the user asks for it or an approved plan names it.

## The set

| Agent | Model | Effort | Writes | Purpose |
|---|---|---|---|---|
| `handbook-librarian` | opus | high | no | Reads released `main` for the rules that govern a task and returns a cited brief |
| `searcher` | sonnet | low | no | Answers one lookup in the files or repos named, with file and line references |
| `convention-auditor` | opus | high | no | Audits one repo against the checklist, layout, CI, licensing, and GitHub settings |
| `northstar-reviewer` | opus | max | no | Judges a change against the repo's and the handbook's northstar; flags intent changes |
| `release-preflight` | opus | high | no | Runs the release preflight and proposes the bump kind; never bumps, tags, or pushes |
| `html-author` | opus | max | one file | Authors the designed HTML twin from the scaffold and verifies the discipline |
| `html-drift-checker` | sonnet | high | no | Compares a Markdown doc with its twin and reports drift, Markdown canonical |
| `docs-reviewer` | opus | high | no | Reviews a docs change against the writing and documentation rules |
| `docs-currency-checker` | opus | max | no | Verifies that documents are current: claims against the code by execution where the stack allows it, tense and open questions against the repo's state, text against the decisions supplied and against each other |
| `bookstack-librarian` | opus | high | the wiki | Sole writer to the org's wiki; keeps the Library Catalog and the Discovered Tangents register; answers questions with citations |
| `coder` | sonnet | high | the branch | Implements a bounded task the handbook's way; pushes; opens no PR, merges nothing |
| `coder-max` | opus | max | the branch | The coder at Opus and `max`, for the Agent tool, which cannot set effort; reads and follows `coder`'s body |
| `mechanical-coder` | sonnet | high | the branch | Applies a fully specified, machine-verifiable change and runs the named check |
| `checks-runner` | sonnet | low | no | Runs the repo's local checks and reports only the failures, where the output is too large to read in the session or a failure needs diagnosis |

Three of the document reviewers, `handbook-librarian` and `bookstack-librarian` have a model or an effort that the dispatch rule's table alone does not give. `handbook-librarian` reads a corpus for what governs a task, which is judgement, so it runs on Opus; what it leaves out reaches every worker's brief, so it is not a plain lookup, and it runs one level above `low`, at `high`. `bookstack-librarian` carries out writes, which is implementation, but resolves each target and catalogues each book by judgement, in a store whose structure is hard to undo, so it runs on Opus, at `high`. `northstar-reviewer` is a review taken one level up, to `max`, because a judgement against a northstar is of the kind the Fable paragraph above calls costly and hard to detect. `html-drift-checker` compares a document with its twin, and the answer is fixed by the two files, so it runs on Sonnet, at the effort of a review. `docs-currency-checker` checks each claim against the code and the decisions supplied, which is the work of verifying findings, so it runs at `max`.

Exploration, planning, and correctness review stay with Claude Code's built-in agents and commands (`Explore`, `Plan`, `/code-review`); the set covers what the handbook adds. A built-in agent runs at the session's effort and, unless the call names one, on the session's model (`Explore` at most Opus), so a lookup, which the rule puts at `low`, goes to `searcher` rather than to `Explore`.

Four of the reviewers read documents, and no one of them covers another's concern. `docs-reviewer` checks form and rules; `html-drift-checker` checks a Markdown document against its twin; `northstar-reviewer` checks intent; `docs-currency-checker` checks whether what a document says is what the code does and what was decided. A document can pass the first three and still describe a route that was renamed, a question that was answered, or a build phase that ended. Which of them runs is decided by what the change touches, as the design rules below state, not by the set being complete. It distinguishes a record (a changelog, a dated decision log), which may describe the past, from a current-state document, which may not ([`documentation.md`](documentation.md#documents-and-records)), and it takes from the session the decisions made in conversation, because those are invisible in the repo until someone writes them down.

The wiki's writer is of a different kind. `bookstack-librarian` is the only writer to the org's wiki among sessions and agents (whether a person writing in the wiki's own interface is bound by it is an open question, in [`in-flight_ideas.md`](in-flight_ideas.md)): a session that wants a page created, changed or deleted dispatches it with the content, and it resolves the target, chooses the edit method and orders the calls. Its effort is `high` rather than `max` because the content is the caller's and the librarian decides only how, and because its report is verified like any other. Besides its definition it needs one thing, and so does every other definition, since each holds the wiki's read tools: an MCP server registered in Claude Code as `bookstack`, pointing at the org's wiki. That registration names a host, so it is documented with the service in the lab's operations repository and not here. Where it is absent the entry is simply not granted and the agent runs without it, so a machine with no wiki loses the librarian and leaves every other definition's wiki section inert rather than failing (observed on v2.1.273, in sessions where that server had not connected). It also keeps the wiki's two registers, the Library Catalog (one entry per book, classified by subject, form and status, the terms growing only on the user's ruling) and Discovered Tangents (one page per idea set aside whilst working on something else, [`documentation.md`](documentation.md#discovered-tangents)). The monopoly rests on this page rather than on a hook, and it holds because no other definition holds a wiki write tool (the rule below on MCP tools; every other definition holds `bookstack_search`, `bookstack_books_read` and `bookstack_pages_read` and no other wiki tool, so any agent can follow a citation itself whilst every change still goes through one hand) and because the wiki's librarian opens every invocation by reconciling the catalog against the book list, so a book created, renamed or deleted directly is caught at the next dispatch, though a page written inside an existing book is not. A session with a reason to write directly says so and asks, unless the user has given standing authorisation for that kind of entry, as for the tangent register.

## Design rules

- **Only the author, the coders, and the wiki's librarian write**, and each only to its own target: the HTML twin's file, the working branch, the wiki. Everything that touches shared state (pushing to a trunk, merging, tagging, releasing, the back-merge cascade) stays in the session, under the user's authorization, per [`ai-collaboration.md`](ai-collaboration.md). An agent may not do what the session's permissions would refuse.
- **Deterministic sequences are not agents.** Creating the prefixed worktree, `git bump`, `git release`, the cascade: a language model adds nondeterminism to a mechanical sequence, so those live in `dev-tools` and in skills.
- **Reviewers are chosen by applicability.** A document gets the reviewer whose concern it touches, and only before it is published: `docs-reviewer` for form and the writing rules, `northstar-reviewer` where intent may have changed, `docs-currency-checker` where the document makes claims that the code or a decision can contradict, `html-drift-checker` where a changed document has a twin. A release that publishes documents gets `release-preflight` and `docs-currency-checker`. Where more than one applies they are dispatched in one turn, in parallel, which is where the speed comes from; where one applies, one runs.
- **Each agent locates the released handbook itself:** `$PARKVIEWLAB_HANDBOOK` if set, otherwise `handbook/handbook-main` under the org root found by walking up from the working directory. An agent of the set starts with only its own prompt and the `CLAUDE.md` hierarchy, not the calling session's context.
- **No agent memory.** A documented deviation belongs in the repo's docs (axiom 3), not in an agent's private store. A register an agent keeps in a store the user reads (the wiki's catalog, the tangent register) is a document, not memory: it is visible, citable and editable by anyone, which is what axiom 3 asks for.
- **MCP tools are named one by one.** An explicit `tools:` list withholds every MCP tool, so a definition that needs one must say so. The field takes a whole-server pattern as well as an exact name, and all three forms work: on v2.1.273, `mcp__<server>` and `mcp__<server>__*` each granted every tool of that server, and `mcp__<server>__<tool>` granted exactly that one. A definition here names each tool in full even so, so that its list is the exact boundary of what the agent can do; for a writer, a pattern would grant every write the server has, including the ones added after the definition was written. The list bounds capability, not use: a tool that can never succeed is removed from it, whilst a tool a given agent may never reach for is granted by class, which is why every definition holds the three wiki read tools whether or not its own work is likely to meet a citation. Every definition also lists `ToolSearch`: a whole session started with `--agent` can receive its MCP tools as deferred tools, which only `ToolSearch` loads, and on v2.1.273 (2026-09-18) a definition without it lacked its BookStack tools in both a headless (`-p`) and a background (`--bg`) session under the normal configuration, whilst with it both loaded and called them. `ToolSearch` loads nothing the list does not already name, so it widens nothing; a subagent receives its MCP tools without it.
- **An agent's report is a claim.** The session verifies it against the files before acting on it.

## Using them

From a session, delegate by name with the Agent tool and give the agent the absolute path of the worktree it works in; run independent agents in the same turn. In a workflow, name the definition as `agentType` in `agent()`. From the command line, a whole session can run as one definition (`claude --agent coder`). As teammates in an agent team the definitions serve as roles, with the differences [`parallel-work.md`](parallel-work.md) states.

The four routes set a dispatch's model and effort differently, and the dispatch rule is applied through them:

| Route | Model | Effort |
|---|---|---|
| The Agent tool | The call's `model` (`sonnet`, `opus`, `fable`), else the definition's | The definition's; the call cannot set one, and a built-in agent (`Explore`, `Plan`, `general-purpose`), carrying none, runs at the session's |
| A workflow's `agent()` | The `model` option | The `effort` option |
| `claude --agent <name>` | `--model`, else the definition's | `--effort`; the definition's is not applied |
| A teammate in an agent team | The spawning call's `model`, else the definition's | The lead's |

The first row is why `coder-max` and `searcher` are definitions: through the Agent tool, the coder reaches Opus at `max`, and a lookup reaches `low`, only by a definition that carries the effort. A workflow's options fall back to the session's model and effort when left out, so every `agent()` call passes both. The rows for the Agent tool and the command line were verified on v2.1.270 to v2.1.274 (for the built-in agents, on `general-purpose`), and the teammate's row is documented; [`agents-why.md`](agents-why.md) has the evidence.

## Installation

```bash
scripts/install-agents.sh --dry-run   # preview
scripts/install-agents.sh             # link into ~/.claude/agents and ~/.claude/skills
```

The installer links to the **released** handbook (the sibling `handbook-main` worktree) by default, so an edited definition is picked up on the next `git pull` of `main` with no re-run; a brand-new file needs one more run. A session started after that run can use a new agent at once; one already running may not offer it for some minutes, although a new skill reaches it at once (v2.1.273: on 2026-09-18 a fresh headless session dispatched an agent created 18 seconds earlier, whilst on 2026-09-17 a running session could not dispatch a new agent for a few minutes; the delay was not measured). Dispatch a new agent from a session started after the installer ran. `--copy` copies instead of linking; `--source DIR` installs from another checkout; `--uninstall` removes the links. Claude Code discovers agents and skills through symlinked directories and symlinked files alike (verified on v2.1.270).

## Changing the set

Edit the template, open a PR into `develop`, release; the change reaches every machine with the next `git pull` of `main`. A new agent needs a row in the table above and, if it writes, a statement of what it writes. Every definition but the librarian carries the three wiki read tools and the wiki section that explains them; that section is one text held in each of them (in `coder-max`, through the coder's body, which it follows), so it changes in all of them in one pull request, and a new definition carries it too. `coder-max` follows the coder's body but carries its own copy of the coder's `tools` list, so the two lists change together in one pull request. A new skill is a directory `templates/skills/<name>/` holding a `SKILL.md`, which the same installer links into `~/.claude/skills/`; where a skill is the operational copy of a page here, the two change in the same pull request. An addition worth designing before it is built is proposed in the org's wiki, on its Proposals shelf, or, when it is small enough to be ruled on with the change that builds it, in that change's plan ([the dispatch rule](#the-dispatch-rule)); once built, it retires into this page and [`agents-why.md`](agents-why.md), and whatever stays genuinely open remains on the shelf as its own small proposal, or, for an addition proposed in a plan, goes to [`in-flight_ideas.md`](in-flight_ideas.md). The model and effort of an agent change only for a reason recorded in [`agents-why.md`](agents-why.md).
