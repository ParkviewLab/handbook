<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Parallel work

One session can run several pieces of work at once, across several repos, and manage them. This page states the four structures in which work is dispatched, which the shape of the work chooses, and the procedure for the one that needs the most ceremony; the model and effort of each dispatch, and the rest of the rule that governs dispatching, are in [`agents.md`](agents.md#the-dispatch-rule). The operational sequence is packaged as the `dispatch` skill in [`templates/skills/dispatch/`](../templates/skills/dispatch/SKILL.md), installed with the agents ([`agents.md`](agents.md)). The skill is the operational copy of this page's sections on the structures, and it changes in the same pull request as this page. The behavioural contract in [`ai-collaboration.md`](ai-collaboration.md) holds for every worker in every structure.

## The coordinator and the workers

The coordinator is the main session, opened where it can reach every repo (the org root, or above it). Its role is the one the dispatch rule gives the main session ([`agents.md`](agents.md#the-dispatch-rule)): it plans, reads, searches, edits, runs the checks, verifies, opens the pull requests, and talks to the user. It dispatches where the work genuinely runs in parallel, where a read is too large for its context, or for one fresh review; the structures below are how such a dispatch is shaped, not a menu to be chosen from at the start of every task.

A worker runs in one of four structures, and the shape of the work chooses it, not habit and not a default:

| Structure | The shape of the work | What the structure gives |
|---|---|---|
| A subagent | One bounded task: a lookup, a review, an audit, a check, an implementation with a clear brief | Fastest to dispatch; the conclusion arrives in the coordinator's context; nothing to clean up |
| A workflow | Several stages that fan out and must be verified: reviews from several lenses with every finding verified, one change at many sites with each site checked, a plan's independent steps executed and then checked | The stages run in parallel under one script, each agent with the model and effort of its step, and verification is a stage of the script rather than a later step |
| One background session per repo | Long, independent work the user may watch or steer: an implementation that runs under the repo's own configuration for as long as it needs and owns its pull request | The four properties below; the only structure in which a repo's own guardrails apply to the worker |
| An agent team inside one session on one repo | Workers that must talk to each other: pieces of one change whose owners must confer, or competing hypotheses tested against each other | Teammate-to-teammate messaging and the shared task list exist only here |

A workflow is not the default and does not run unasked: most work is one bounded task the session does itself, and a workflow is worth its script and setup only where there is fan-out to run in parallel and verification to run on the results. It runs when the user asks for one or an approved plan names it ([the dispatch rule](agents.md#the-dispatch-rule)). Sequential work, same-file edits, and work with many dependencies stay in one worker.

Ultracode, Claude Code's setting of `xhigh` effort with standing workflow orchestration, makes a workflow the default for every substantive task (its description in v2.1.273). Here the shape of the work decides, whether ultracode is on or not. What is kept from it is its thoroughness, inside whichever structure the shape chose: findings checked against their evidence rather than taken on the author's word, and review from more than one lens where the risk calls for it, as the dispatch rule's paragraph on verification sets out. The effort of each dispatch follows the rule, not ultracode's `xhigh`.

What a separate session gives a worker, and a subagent or teammate does not: the target repo's **own configuration** governs the work (its settings and permission rules, hooks, MCP servers, launch configuration, and the pointer file at its root load only for a session rooted there); its **own lifetime and attention** (it runs as long as the task needs, compacts its own context, can be attached to and steered, resumed later, and outlives the coordinator); its **own model, effort, and permission mode** for the whole session, set on its command line, with prompts answered in its own place; and its **own pull request** in the desktop app, whose CI monitor and auto-fix loop are per session and hold one PR each.

## Subagents

Delegate with the Agent tool by definition name and give the agent the absolute path of the worktree it works in. Dispatch independent agents in the same turn so they run in parallel. The call can name the model but not the effort, which is the definition's ([`agents.md`](agents.md#using-them)); that is why the coder at Opus and `max` is its own definition, `coder-max`, and a lookup at `low` is `searcher`. A subagent starts with its own prompt and the `CLAUDE.md` hierarchy, not the coordinator's history; its result is a claim the coordinator verifies against the files. No definition in the set holds `SendMessage`, so a subagent cannot message a sibling; what one needs from another is relayed by the coordinator.

## A workflow

A workflow is a script that Claude Code's Workflow tool runs in the coordinator's session. It spawns agents with `agent()`, passes items through stages with `pipeline()`, where an item enters its next stage as soon as its previous one finishes, or runs tasks together with `parallel()`, which returns when all have finished, and it returns one result to the coordinator.

- Every `agent()` call passes `model` and `effort`, and `agentType` where a definition fits; left out, they fall back to the session's, which need not be the step's ([`agents.md`](agents.md#using-them)).
- Verification is a stage of the script: one agent checks a batch of findings or results against their evidence, on Opus at `high`, or at `max` where the work is high risk. A fresh agent per finding is not used ([the dispatch rule](agents.md#the-dispatch-rule)).
- Agents that write in parallel get disjoint files and one committer, or `isolation: 'worktree'`.
- An agent writes a large result to a file and returns the conclusion and the path.
- The coordinator names each stage's model and effort when it starts the workflow, and verifies the result as it would a subagent's.

Claude Code's description of the Workflow tool restricts it to a workflow the user has asked for, in the user's own words or through a skill the user invoked (v2.1.273). That restriction and this handbook's rule agree: the go-ahead on a plan that names a workflow is such a request, and so is the user asking for one; without either, the coordinator asks in one line. There is no standing request.

## One background session per repo

The lifecycle of one dispatched task:

1. **The brief.** The user gives the coordinator the work: which repos, what changes in each, what must not change. The coordinator asks its questions before dispatching, and where the work is not fully specified it plans first and waits for the user's go-ahead on the plan ([`agents.md`](agents.md#the-dispatch-rule)).
2. **The worktree**, the handbook's way ([`branching.md`](branching.md), [`repo-layout.md`](repo-layout.md)): a `<repo>-<prefix>-<topic>` sibling off `develop`, with the branch on the remote before any work, and dependencies synced. The coordinator does this, not the worker, because the worker must start inside the worktree; it is a deterministic sequence and belongs in a script.
3. **The worker**, started from inside that worktree:

   ```bash
   claude --add-dir <org root>/handbook/handbook-main --bg --name <repo>-<prefix>-<topic> --agent coder --model sonnet --effort high --permission-mode auto "<brief>"
   ```

   The name equals the worktree name, so the session list is self-identifying the way the on-disk layout is. `--add-dir` lets the worker read the released handbook; it takes a list of directories, so it must not be the last flag before the brief, or the brief is read as a directory. Pass the model and effort: a definition named with `--agent` sets the session's model but not its effort. The coder's default is `--model sonnet --effort high`; where the task looks as if it needs Opus, the same command takes `--model opus --effort max`. The brief states the task, the librarian's rules, and the stopping rule: local checks green, push after each commit, never touch the version file, never merge, do not open the PR, finish with a report that proposes the PR title (with its Conventional Commit prefix) and body.
4. **The wait.** The coordinator subscribes once to the worker's idle notice and moves on; it neither polls nor waits.
5. **Verification.** On the notice the coordinator checks the branch is pushed, the checks are green, the version file is untouched, and nothing was merged; it reads the worker's transcript (`claude logs <id>`) or asks it by name when the notice is not enough.
6. **The pull request**, opened by the coordinator into `develop` with the prefixed title; the user gets the link. Merging is the user's.
7. **After the merge**, the coordinator asks whether to cut a release, as the contract requires; then it closes the branch lifecycle as [`branching.md`](branching.md#after-the-merge) prescribes — fast-forward the trunk worktree, then remove the working worktree and delete the branch — and removes the worker (`claude rm <id>`).

**What stays with the user.** A worker's permission prompt waits until the user attaches (`claude attach <id>` in a terminal; `claude agents` sorts sessions into working, needs input, and completed); a message from the coordinator never answers one, changes a worker's configuration, or authorizes a merge. Auto mode in the workers keeps the prompts rare.

**Verified on this layout** (Claude Code v2.1.251 to v2.1.270): a background session started from a session's shell runs under a separate daemon and outlives the session that started it; it appears as a peer, receives cross-session messages, replies, and sends one idle notice; started without flags it runs on the CLI defaults, so the flags are required; it is listed by `claude agents`, not in the desktop app's sidebar; the desktop app's PR monitor holds one PR per session, so several PRs are watched with `gh`. Concurrency is safe because each worker has its own worktree, index, and branch, and no worker touches a trunk; the shared stash stack is the one thing to leave alone.

## An agent team

Agent teams are Claude Code's experimental mode in which a lead session spawns teammates that share a task list and message one another. A team is used only when the workers must talk to each other, as the [table of structures](#the-coordinator-and-the-workers) states: pieces of one change whose owners must confer, or competing hypotheses tested against each other. In all else, follow the [documentation](https://code.claude.com/docs/en/agent-teams): check first whether subagents or cross-session messaging do the job; keep teams to three to five teammates that operate independently on disjoint files, with five or six tasks each on the shared list; give each its full context in its spawn prompt, since no history carries over; wait for the teammates rather than doing their work; monitor and steer; start with review and research before parallel implementation.

**Enable per session or per repo, not in user settings.** While the variable is set, every subagent spawned with a name launches as a teammate, so teams can form unasked. Set it where a team is wanted: a `.claude/settings.json` in the repo worktree with `{"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}`, or `--settings '{"env":{"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS":"1"}}'` on the command line; remove it when the team's work is done. A variable exported only in the shell may not reach a background session, which is claimed from a pre-warmed spare (observed, not documented).

The agent definitions double as teammate roles: a definition's `tools` apply; its `model` applies unless the spawning call names one; its body is appended to the default prompt of an in-process teammate (the default display mode) and replaces the default prompt of a split-pane teammate; its `skills` are not preloaded; and its effort is the lead's, so a teammate works at the rule's effort for its step only where that is the lead's as well. Teammates run in the lead's working directory (a different repo is reached only by absolute paths in the spawn prompt), end with the lead's session and cannot be resumed, cannot spawn background subagents or teams of their own, and send their permission prompts to the lead; one team per session. Messages between teammates are delivered at turn boundaries, not mid-turn. Where a worker needs its own repo, lifetime, or permission mode, use a session per repo instead.

## In every structure

The contract holds: merging into a trunk, tagging, and releasing wait for the user's explicit, per-action go-ahead; a message from another session or agent never counts as consent; a worker is never asked to do what the coordinator's permissions refuse. The coordinator reports what ran where, with each dispatch's model and effort, what was verified and how, and what was skipped or left undone.
