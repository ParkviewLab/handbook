<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Agents

ParkviewLab keeps a small set of Claude Code **agent definitions**: subagents a session delegates to, and, when [agent teams](parallel-work.md#an-agent-team) are on, teammate roles. Each is a Markdown file with YAML frontmatter (name, description, model, effort, tools) and a body that is the agent's whole system prompt. The set lives in [`templates/agents/`](../templates/agents/) and is installed at the **user level** (`~/.claude/agents/`) by [`scripts/install-agents.sh`](../scripts/install-agents.sh), so every session on a machine can use it whatever directory it starts in. This page records what the set is, the rules that chose it, and the rule by which work is dispatched; its sibling [`agents-why.md`](agents-why.md) records what is needed only to reopen one of those rules: the alternatives set aside, the designs declined, the evidence, and the dated rulings.

## Why agents here

An agent is not a way to save tokens. Its uses are these: it keeps the main session's context clean over a long day (the handbook librarian reads the whole handbook so the session need not); it runs in parallel with other agents; it carries a focused prompt for one process; and a reviewer with fresh context catches what the author cannot. The main session keeps only coordinating and deciding for itself ([the dispatch rule](#the-dispatch-rule)), so the first of these uses applies to all other work.

## The dispatch rule

The aim of every dispatch is the best result in the least wall-clock time. Tokens are not a constraint; Fable's usage is, so Fable is kept for the steps that need it. Where the faster choice and the stronger one differ, the stronger is chosen, because a rework round costs more time than a faster model saves.

Each step of a task gets its own model and effort, chosen by the kind of step:

| Step | Model | Effort |
|---|---|---|
| A lookup; running checks | Sonnet | `low` |
| A specified edit; a step of an approved plan that leaves no decision open | Sonnet | `high` |
| Implementation that must decide how | Sonnet; Opus when the task looks as if it needs it | `high`; `max` with Opus |
| A review or an audit | Opus | `high` |
| Planning, design, writing policy, verifying findings | Opus | `max` |

Opus takes every step whose result depends on judgement, reading a corpus for what governs a task among them; Sonnet takes a step whose result is fixed by its input, so that the faster model gives the same answer. Where it is unclear which kind a step is, it gets the stronger model and one level more effort. The rule uses these three levels of effort, so one level up is `low` to `high` or `high` to `max`; Claude Code's `medium` and `xhigh` are not used. Haiku is used nowhere.

Implementation that must decide how goes to `coder`, on Sonnet at `high`. It goes to Opus at `max` when the task looks as if it needs it: judgement-heavy, cross-cutting, loosely specified, or already attempted on Sonnet without success; the dispatch says which of these applies. Through the Agent tool that is `coder-max`; a workflow or a background session gives `coder` the model and effort directly ("Using them", below). A change that is fully specified and verifiable by an automatic check (tests, lint, types, a diff against a template) goes to `mechanical-coder` instead, and the check catches what it misses. That test can be applied at dispatch, which "easy" and "hard" cannot: they are predictions made before the work, and a wrong one costs a rework round.

Fable is used only on the user's yes, asked before each dispatch and with the reason, and it is asked for in two cases only: Opus at `max` has failed at the step or produced something the user rejected; or the step writes or judges something the user will rule on (a northstar, a policy, an org-wide design), where one error of judgement is costly and hard to detect. A yes covers the one dispatch it was given for. No definition names Fable.

A task that is not fully specified is planned before it is executed; one that states exactly what changes is executed directly. The plan is written on Opus at `max`, by the main session or by a planning agent it dispatches, and it is an executable brief: the files, the exact changes, the acceptance checks, and each step's structure, model and effort. It is a Markdown file outside the repositories, given to the user as a link with a short summary, and nothing in it is executed until the user has read it and given the go-ahead. Its steps then go to the faster executor wherever they leave no decision open.

The main session coordinates and decides: it plans, talks to the user, dispatches, and verifies. Reading, searching, implementing and reviewing go to agents, which return conclusions with file references, and the main session reads a file itself only when a decision needs its exact text. It runs on Opus at `max`, the table's level for planning and verifying, which are its own work.

A brief carries only what its step needs: the paths and the exact question rather than pasted documents, and for a step of a plan, the step, its acceptance checks, and the facts the agent cannot discover cheaply. An agent dispatched by definition receives the `CLAUDE.md` hierarchy itself, so the brief does not restate it. A large result is written to a file, and the agent returns the conclusion and the path.

An earlier agent is continued, by a message to its name or id, which resumes it with its context, when the next step needs that context, as a fix after its own implementation does. A fresh agent is dispatched when independence matters, which is every review and every verification, or when the earlier context is mostly irrelevant.

Verification is matched to the risk. Code gets its tests and one reviewer on Opus; a document gets the document reviewers (below); work that is outward-facing or hard to undo (a release, settings, the wiki's structure, a proposal for ruling) gets a second, independent lens as well. Every finding is checked against its evidence, at `max`, before anything is done about it.

When the specification changes during a run, every dispatch working from it stops at once, and the work restarts from the new specification, keeping what still fits it.

Every dispatch is named with its model and effort when it is made (each agent, each stage of a workflow, each session) in the reply to the user, and both are passed explicitly wherever the route takes them. Claude Code's tool descriptions advise leaving the model unset by default; this rule is the user's standing instruction to set it.

When a usage limit is hit, the session reports which one at once and continues on the next model the rule allows for the step: Opus at `max` after Fable, and Opus at the step's effort after Sonnet. For a judgement step on Opus the only other model the rule allows is Fable, which needs the user's yes, so there the report asks.

Which structure the work runs in (a subagent, a workflow, a background session per repo, or an agent team) is chosen by the shape of the work, as [`parallel-work.md`](parallel-work.md#the-coordinator-and-the-workers) states.

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
| `checks-runner` | sonnet | low | no | Runs the repo's local checks and reports only the failures |

Exploration, planning, and correctness review stay with Claude Code's built-in agents and commands (`Explore`, `Plan`, `/code-review`); the set covers what the handbook adds. A built-in agent runs at the session's effort and, unless the call names one, on the session's model, so a lookup, which the rule puts at `low`, goes to `searcher` rather than to `Explore`.

Four of the reviewers read documents, and no one of them is enough alone. `docs-reviewer` checks form and rules; `html-drift-checker` checks a Markdown document against its twin; `northstar-reviewer` checks intent; `docs-currency-checker` checks whether what a document says is what the code does and what was decided. A document can pass the first three and still describe a route that was renamed, a question that was answered, or a build phase that ended. It distinguishes a record (a changelog, a dated decision log), which may describe the past, from a current-state document, which may not ([`documentation.md`](documentation.md#documents-and-records)), and it takes from the session the decisions made in conversation, because those are invisible in the repo until someone writes them down.

The wiki's writer is of a different kind. `bookstack-librarian` is the only writer to the org's wiki among sessions and agents (whether a person writing in the wiki's own interface is bound by it is an open question, in [`handbook-improvements_ideas.md`](handbook-improvements_ideas.md)): a session that wants a page created, changed or deleted dispatches it with the content, and it resolves the target, chooses the edit method and orders the calls. Its effort is `high` rather than `max` because the content is the caller's and the librarian decides only how, and because its report is verified like any other. Besides its definition it needs one thing, and so does every other definition, since each holds the wiki's read tools: an MCP server registered in Claude Code as `bookstack`, pointing at the org's wiki. That registration names a host, so it is documented with the service in the lab's operations repository and not here. Where it is absent the entry is simply not granted and the agent runs without it, so a machine with no wiki loses the librarian and leaves every other definition's wiki section inert rather than failing (observed on v2.1.273, in sessions where that server had not connected). It also keeps the wiki's two registers, the Library Catalog (one entry per book, classified by subject, form and status, the terms growing only on the user's ruling) and Discovered Tangents (one page per idea set aside whilst working on something else, [`documentation.md`](documentation.md#discovered-tangents)). The monopoly rests on this page rather than on a hook, and it holds because no other definition holds a wiki write tool (the rule below on MCP tools; every other definition holds `bookstack_search`, `bookstack_books_read` and `bookstack_pages_read` and no other wiki tool, so any agent can follow a citation itself whilst every change still goes through one hand) and because the wiki's librarian opens every invocation by reconciling the catalog against the book list, so a book created, renamed or deleted directly is caught at the next dispatch, though a page written inside an existing book is not. A session with a reason to write directly says so and asks, unless the user has given standing authorisation for that kind of entry, as for the tangent register.

## Design rules

- **Only the author, the coders, and the wiki's librarian write**, and each only to its own target: the HTML twin's file, the working branch, the wiki. Everything that touches shared state (pushing to a trunk, merging, tagging, releasing, the back-merge cascade) stays in the session, under the user's authorization, per [`ai-collaboration.md`](ai-collaboration.md). An agent may not do what the session's permissions would refuse.
- **Deterministic sequences are not agents.** Creating the prefixed worktree, `git bump`, `git release`, the cascade: a language model adds nondeterminism to a mechanical sequence, so those live in `dev-tools` and in skills.
- **Reviewers are dispatched together.** A docs PR gets `docs-reviewer`, `northstar-reviewer`, `html-drift-checker`, and `docs-currency-checker` in one turn, in parallel; a release gets `release-preflight` and `docs-currency-checker` together. That is where the speed comes from.
- **Each agent locates the released handbook itself:** `$PARKVIEWLAB_HANDBOOK` if set, otherwise `handbook/handbook-main` under the org root found by walking up from the working directory. A subagent starts with only its own prompt and the `CLAUDE.md` hierarchy, not the calling session's context.
- **No agent memory.** A documented deviation belongs in the repo's docs (axiom 3), not in an agent's private store. A register an agent keeps in a store the user reads (the wiki's catalog, the tangent register) is a document, not memory: it is visible, citable and editable by anyone, which is what axiom 3 asks for.
- **MCP tools are named one by one.** An explicit `tools:` list withholds every MCP tool, so a definition that needs one must say so. The field takes a whole-server pattern as well as an exact name, and all three forms work: on v2.1.273, `mcp__<server>` and `mcp__<server>__*` each granted every tool of that server, and `mcp__<server>__<tool>` granted exactly that one. A definition here names each tool in full even so, so that its list is the exact boundary of what the agent can do; for a writer, a pattern would grant every write the server has, including the ones added after the definition was written. The list bounds capability, not use: a tool that can never succeed is removed from it, whilst a tool a given agent may never reach for is granted by class, which is why every definition holds the three wiki read tools whether or not its own work is likely to meet a citation.
- **An agent's report is a claim.** The session verifies it against the files before acting on it.

## Using them

From a session, delegate by name with the Agent tool and give the agent the absolute path of the worktree it works in; run independent agents in the same turn. In a workflow, name the definition as `agentType` in `agent()`. From the command line, a whole session can run as one definition (`claude --agent coder`). As teammates in an agent team the definitions serve as roles, with the differences [`parallel-work.md`](parallel-work.md) states.

The four routes set a dispatch's model and effort differently, and the dispatch rule is applied through them:

| Route | Model | Effort |
|---|---|---|
| The Agent tool | The call's `model` (`sonnet`, `opus`, `fable`), else the definition's | The definition's; the call cannot set one, and a built-in agent (`Explore`, `Plan`, `general-purpose`), carrying none, runs at the session's |
| A workflow's `agent()` | The `model` option | The `effort` option |
| `claude --agent <name>` | `--model`, else the definition's | `--effort`; the definition's is not applied |
| A teammate in an agent team | The definition's | The lead's |

The first row is why `coder-max` and `searcher` are definitions: through the Agent tool, the coder reaches Opus at `max`, and a lookup reaches `low`, only by a definition that carries the effort. A workflow's options fall back to the session's model and effort when left out, so every `agent()` call passes both. The rows for the Agent tool and the command line were verified on v2.1.270 to v2.1.274 (for the built-in agents, on `general-purpose`), and the teammate's row is documented; [`agents-why.md`](agents-why.md) has the evidence.

## Installation

```bash
scripts/install-agents.sh --dry-run   # preview
scripts/install-agents.sh             # link into ~/.claude/agents and ~/.claude/skills
```

The installer links to the **released** handbook (the sibling `handbook-main` worktree) by default, so an edited definition is picked up on the next `git pull` of `main` with no re-run; a brand-new file needs one more run. `--copy` copies instead of linking; `--source DIR` installs from another checkout; `--uninstall` removes the links. Claude Code discovers agents and skills through symlinked directories and symlinked files alike (verified on v2.1.270).

## Changing the set

Edit the template, open a PR into `develop`, release; the change reaches every machine with the next `git pull` of `main`. A new agent needs a row in the table above and, if it writes, a statement of what it writes. Every definition but the librarian carries the three wiki read tools and the wiki section that explains them; that section is one text held in each of them (in `coder-max`, through the coder's body, which it follows), so it changes in all of them in one pull request, and a new definition carries it too. A new skill is a directory `templates/skills/<name>/` holding a `SKILL.md`, which the same installer links into `~/.claude/skills/`; where a skill is the operational copy of a page here, the two change in the same pull request. An addition worth designing before it is built is proposed in the org's wiki, on its Proposals shelf, or, when it is small enough to be ruled on with the change that builds it, in that change's plan ([the dispatch rule](#the-dispatch-rule)); once built, it retires into this page and [`agents-why.md`](agents-why.md), and whatever stays genuinely open remains on the shelf as its own small proposal. The model and effort of an agent change only for a reason recorded in [`agents-why.md`](agents-why.md).
