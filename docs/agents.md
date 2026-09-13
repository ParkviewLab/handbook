<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Agents

ParkviewLab keeps a small set of Claude Code **agent definitions**: subagents a session delegates to, and, when [agent teams](parallel-work.md#an-agent-team) are on, teammate roles. Each is a Markdown file with YAML frontmatter (name, description, model, effort, tools) and a body that is the agent's whole system prompt. The set lives in [`templates/agents/`](../templates/agents/) and is installed at the **user level** (`~/.claude/agents/`) by [`scripts/install-agents.sh`](../scripts/install-agents.sh), so every session on a machine can use it whatever directory it starts in. This page records what the set is and the rules that chose it.

## Why agents here

An agent is not a way to save tokens. Its uses are these: it keeps the main session's context clean over a long day (the librarian reads the whole handbook so the session need not); it runs in parallel with other agents; it carries a focused prompt for one process; and a reviewer with fresh context catches what the author cannot. Where none of those applies, the session does the work itself.

## The model and effort rule

Model and effort are chosen for speed and accuracy, not for cost:

- **Fable** wherever the output depends on judgement or on reading a large corpus accurately.
- **Effort by the cost of an error:** `max` for a deliverable (the HTML twin) and for alignment verdicts; `high` for reports that a person or the calling session will check anyway; `medium` or `low` where the task is reading or running.
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
| `coder` | fable | high | the branch | Implements a bounded task the handbook's way; pushes; opens no PR, merges nothing |
| `mechanical-coder` | sonnet | medium | the branch | Applies a fully specified, machine-verifiable change and runs the named check |
| `checks-runner` | sonnet | low | no | Runs the repo's local checks and reports only the failures |

Exploration, planning, and correctness review stay with Claude Code's built-in agents and commands (`Explore`, `Plan`, `/code-review`); the set covers what the handbook adds.

## Design rules

- **Only the author and the coders write**, and only to their target file or branch. Everything that touches shared state (pushing to a trunk, merging, tagging, releasing, the back-merge cascade) stays in the session, under the user's authorization, per [`ai-collaboration.md`](ai-collaboration.md). An agent may not do what the session's permissions would refuse.
- **Deterministic sequences are not agents.** Creating the prefixed worktree, `git bump`, `git release`, the cascade: a language model adds nondeterminism to a mechanical sequence, so those live in `dev-tools` and in skills.
- **Reviewers are dispatched together.** A docs PR gets `docs-reviewer`, `northstar-reviewer`, and `html-drift-checker` in one turn, in parallel; that is where the speed comes from.
- **Each agent locates the released handbook itself:** `$PARKVIEWLAB_HANDBOOK` if set, otherwise `handbook/handbook-main` under the org root found by walking up from the working directory. A subagent starts with only its own prompt and the `CLAUDE.md` hierarchy, not the calling session's context.
- **No agent memory.** A documented deviation belongs in the repo's docs (axiom 3), not in an agent's private store.
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

Edit the template, open a PR into `develop`, release; the change reaches every machine with the next `git pull` of `main`. A new agent needs a row in the table above and, if it writes, a statement of what it writes. The model and effort of an agent change only for a reason this page can state.
