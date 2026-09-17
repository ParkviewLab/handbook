<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Agents

ParkviewLab keeps a small set of Claude Code **agent definitions**: subagents a session delegates to, and, when [agent teams](parallel-work.md#an-agent-team) are on, teammate roles. Each is a Markdown file with YAML frontmatter (name, description, model, effort, tools) and a body that is the agent's whole system prompt. The set lives in [`templates/agents/`](../templates/agents/) and is installed at the **user level** (`~/.claude/agents/`) by [`scripts/install-agents.sh`](../scripts/install-agents.sh), so every session on a machine can use it whatever directory it starts in. This page records what the set is and the rules that chose it.

## Why agents here

An agent is not a way to save tokens. Its uses are these: it keeps the main session's context clean over a long day (the handbook librarian reads the whole handbook so the session need not); it runs in parallel with other agents; it carries a focused prompt for one process; and a reviewer with fresh context catches what the author cannot. Where none of those applies, the session does the work itself.

## The model and effort rule

Model and effort are chosen for speed and accuracy, not for cost:

- **Fable** wherever the output depends on judgement or on reading a large corpus accurately.
- **Effort by the cost of an error:** `max` for a deliverable (the HTML twin) and for a judgement the session cannot re-derive by reading the files (alignment, currency); `high` for reports that a person or the calling session will check anyway; `medium` or `low` where the task is reading or running.
- **Sonnet** only for a mechanical, well-specified task where the faster model should give the same answer: a sentence-by-sentence comparison, a specified edit, running the checks.
- Haiku is used nowhere; Opus has no role while Fable is available.

**The coding criterion.** "Easy" and "hard" are predictions made before the work, and a wrong prediction costs a rework round trip that exceeds the time the faster model saved. The criterion is checkable at dispatch instead: is the change **fully specified and verifiable by an automatic check** (tests, lint, types, a diff against a template)? If yes, `mechanical-coder` (Sonnet, medium) applies it and the check catches what it misses. If the agent must decide how, `coder` (Fable, high).

## The set

| Agent | Model | Effort | Writes | Purpose |
|---|---|---|---|---|
| `handbook-librarian` | fable | medium | no | Reads released `main` for the rules that govern a task and returns a cited brief |
| `convention-auditor` | fable | high | no | Audits one repo against the checklist, layout, CI, licensing, and GitHub settings |
| `northstar-reviewer` | fable | max | no | Judges a change against the repo's and the handbook's northstar; flags intent changes |
| `release-preflight` | fable | high | no | Runs the release preflight and proposes the bump kind; never bumps, tags, or pushes |
| `html-author` | fable | max | one file | Authors the designed HTML twin from the scaffold and verifies the discipline |
| `html-drift-checker` | sonnet | high | no | Compares a Markdown doc with its twin and reports drift, Markdown canonical |
| `docs-reviewer` | fable | high | no | Reviews a docs change against the writing and documentation rules |
| `docs-currency-checker` | fable | max | no | Verifies that documents are current: claims against the code by execution where the stack allows it, tense and open questions against the repo's state, text against the decisions supplied and against each other |
| `bookstack-librarian` | fable | high | the wiki | Sole writer to the org's wiki; keeps the Library Catalog and the Discovered Tangents register; answers questions with citations |
| `coder` | fable | high | the branch | Implements a bounded task the handbook's way; pushes; opens no PR, merges nothing |
| `mechanical-coder` | sonnet | medium | the branch | Applies a fully specified, machine-verifiable change and runs the named check |
| `checks-runner` | sonnet | low | no | Runs the repo's local checks and reports only the failures |

Exploration, planning, and correctness review stay with Claude Code's built-in agents and commands (`Explore`, `Plan`, `/code-review`); the set covers what the handbook adds.

Four of the reviewers read documents, and no one of them is enough alone. `docs-reviewer` checks form and rules; `html-drift-checker` checks a Markdown document against its twin; `northstar-reviewer` checks intent; `docs-currency-checker` checks whether what a document says is what the code does and what was decided. A document can pass the first three and still describe a route that was renamed, a question that was answered, or a build phase that ended. It distinguishes a record (a changelog, a dated decision log), which may describe the past, from a current-state document, which may not ([`documentation.md`](documentation.md#documents-and-records)), and it takes from the session the decisions made in conversation, because those are invisible in the repo until someone writes them down.

The wiki's writer is of a different kind. `bookstack-librarian` is the only writer to the org's wiki among sessions and agents (whether a person writing in the wiki's own interface is bound by it is an open question, in [`handbook-improvements_ideas.md`](handbook-improvements_ideas.md)): a session that wants a page created, changed or deleted dispatches it with the content, and it resolves the target, chooses the edit method and orders the calls. Its effort is `high` rather than `max` because the content is the caller's and the librarian decides only how, and because its report is verified like any other. Besides its definition it needs one thing: an MCP server registered in Claude Code as `bookstack`, pointing at the org's wiki. That registration names a host, so it is documented with the service in the lab's operations repository and not here. It also keeps the wiki's two registers, the Library Catalog (one entry per book, classified by subject, form and status, the terms growing only on the user's ruling) and Discovered Tangents (one page per idea set aside whilst working on something else, [`documentation.md`](documentation.md#discovered-tangents)). The monopoly rests on this page rather than on a hook, and it holds because the other definitions cannot reach the wiki at all (the rule below on MCP tools) and because the wiki's librarian opens every invocation by reconciling the catalog against the book list, so a book created, renamed or deleted directly is caught at the next dispatch, though a page written inside an existing book is not. A session with a reason to write directly says so and asks, unless the user has given standing authorisation for that kind of entry, as for the tangent register.

## Design rules

- **Only the author, the coders, and the wiki's librarian write**, and each only to its own target: the HTML twin's file, the working branch, the wiki. Everything that touches shared state (pushing to a trunk, merging, tagging, releasing, the back-merge cascade) stays in the session, under the user's authorization, per [`ai-collaboration.md`](ai-collaboration.md). An agent may not do what the session's permissions would refuse.
- **Deterministic sequences are not agents.** Creating the prefixed worktree, `git bump`, `git release`, the cascade: a language model adds nondeterminism to a mechanical sequence, so those live in `dev-tools` and in skills.
- **Reviewers are dispatched together.** A docs PR gets `docs-reviewer`, `northstar-reviewer`, `html-drift-checker`, and `docs-currency-checker` in one turn, in parallel; a release gets `release-preflight` and `docs-currency-checker` together. That is where the speed comes from.
- **Each agent locates the released handbook itself:** `$PARKVIEWLAB_HANDBOOK` if set, otherwise `handbook/handbook-main` under the org root found by walking up from the working directory. A subagent starts with only its own prompt and the `CLAUDE.md` hierarchy, not the calling session's context.
- **No agent memory.** A documented deviation belongs in the repo's docs (axiom 3), not in an agent's private store. A register an agent keeps in a store the user reads (the wiki's catalog, the tangent register) is a document, not memory: it is visible, citable and editable by anyone, which is what axiom 3 asks for.
- **MCP tools are named one by one.** An explicit `tools:` list withholds every MCP tool, so a definition that needs one must say so. The field takes a whole-server pattern as well as an exact name, and all three forms work: on v2.1.273, `mcp__<server>` and `mcp__<server>__*` each granted every tool of that server, and `mcp__<server>__<tool>` granted exactly that one. A definition here names each tool in full even so, so that its list is the exact boundary of what the agent can do; for a writer, a pattern would grant every write the server has, including the ones added after the definition was written.
- **An agent's report is a claim.** The session verifies it against the files before acting on it.

## Using them

From a session, delegate by name with the Agent tool and give the agent the absolute path of the worktree it works in; run independent agents in the same turn. From the command line, a whole session can run as one definition: `claude --agent coder` sets the session's tools and model from the definition, but **not its effort**, so pass `--effort` explicitly (verified on v2.1.270). For a subagent dispatched with the Agent tool, the definition's effort applies (documented; not measured here). As teammates in an agent team the definitions serve as roles, with the differences [`parallel-work.md`](parallel-work.md) states.

## Installation

```bash
scripts/install-agents.sh --dry-run   # preview
scripts/install-agents.sh             # link into ~/.claude/agents and ~/.claude/skills
```

The installer links to the **released** handbook (the sibling `handbook-main` worktree) by default, so an edited definition is picked up on the next `git pull` of `main` with no re-run; a brand-new file needs one more run. `--copy` copies instead of linking; `--source DIR` installs from another checkout; `--uninstall` removes the links. Claude Code discovers agents and skills through symlinked directories and symlinked files alike (verified on v2.1.270).

## Changing the set

Edit the template, open a PR into `develop`, release; the change reaches every machine with the next `git pull` of `main`. A new agent needs a row in the table above and, if it writes, a statement of what it writes. A new skill is a directory `templates/skills/<name>/` holding a `SKILL.md`, which the same installer links into `~/.claude/skills/`; where a skill is the operational copy of a page here, the two change in the same pull request. The model and effort of an agent change only for a reason this page can state.
