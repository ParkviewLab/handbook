<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Parallel work

One session can run several pieces of work at once, across several repos, and manage them. This page states the three modes in which that happens, when each applies, and the procedure for the one that needs the most ceremony. The operational sequence is packaged as the `dispatch` skill in [`templates/skills/dispatch/`](../templates/skills/dispatch/SKILL.md), installed with the agents ([`agents.md`](agents.md)). The skill is the operational copy of the sections "One background session per repo" and "An agent team" below, and it changes in the same pull request as this page. The behavioural contract in [`ai-collaboration.md`](ai-collaboration.md) holds for every worker in every mode.

## The coordinator and the workers

The **coordinator** is an ordinary session opened where it can reach every repo (the org root, or above it). It holds the plan, dispatches work, waits for completion, verifies results, opens the pull requests, and relays to the user; while coordinating it does no repo work itself, so its context stays small.

A **worker** is one of three things, and the choice is made by a rule, not by habit:

| Mode | Use it when | Why |
|---|---|---|
| **Subagents** from the coordinator | The output is a report or a bounded, machine-verifiable change: reviews, audits, checks, mechanical edits, a quick fix | Fastest to dispatch; results land in the coordinator's context; nothing to clean up |
| **One background session per repo** | Implementation that should run under the repo's own configuration, take as long as it needs, be steerable and resumable on its own, and own its PR; or a worker that needs a different model or permission mode from the coordinator's | The four properties below; also the only mode in which a repo's own guardrails apply to the worker |
| **An agent team** inside one session on one repo | Parallel exploration or parallel independent pieces of one change, where the workers must confer or share a task list | Teammate-to-teammate messaging and the task list exist only here |

Sequential work, same-file edits, and work with many dependencies stay in one session.

What a separate session gives a worker, and a subagent or teammate cannot: the target repo's **own configuration** governs the work (its settings and permission rules, hooks, MCP servers, launch configuration, and the pointer file at its root load only for a session rooted there); its **own lifetime and attention** (it runs as long as the task needs, compacts its own context, can be attached to and steered, resumed later, and outlives the coordinator); its **own model, effort, and permission mode**, with prompts answered in its own place; and its **own pull request** in the desktop app, whose CI monitor and auto-fix loop are per session and hold one PR each.

## Subagents

Delegate with the Agent tool by definition name and give the agent the absolute path of the worktree it works in. Dispatch independent agents in the same turn so they run in parallel. A subagent starts with its own prompt and the `CLAUDE.md` hierarchy, not the coordinator's history; its result is a claim the coordinator verifies against the files. Subagents cannot address each other by a name given in a prompt; a sibling's address must be relayed by the coordinator.

## One background session per repo

The lifecycle of one dispatched task:

1. **The brief.** The user gives the coordinator the work: which repos, what changes in each, what must not change. The coordinator asks its questions before dispatching.
2. **The worktree**, the handbook's way ([`branching.md`](branching.md), [`repo-layout.md`](repo-layout.md)): a `<repo>-<prefix>-<topic>` sibling off `develop`, with the branch on the remote before any work, and dependencies synced. The coordinator does this, not the worker, because the worker must start inside the worktree; it is a deterministic sequence and belongs in a script.
3. **The worker**, started from inside that worktree:

   ```bash
   claude --add-dir <org root>/handbook/handbook-main --bg --name <repo>-<prefix>-<topic> --agent coder --model fable --effort high --permission-mode auto "<brief>"
   ```

   The name equals the worktree name, so the session list is self-identifying the way the on-disk layout is. `--add-dir` lets the worker read the released handbook; it takes a list of directories, so it must not be the last flag before the brief, or the brief is read as a directory. Pass the model and effort: a definition named with `--agent` sets the session's model but not its effort. The brief states the task, the librarian's rules, and the stopping rule: local checks green, push after each commit, never touch the version file, never merge, do not open the PR, finish with a report that proposes the PR title (with its Conventional Commit prefix) and body.
4. **The wait.** The coordinator subscribes once to the worker's idle notice and moves on; it neither polls nor waits.
5. **Verification.** On the notice the coordinator checks the branch is pushed, the checks are green, the version file is untouched, and nothing was merged; it reads the worker's transcript (`claude logs <id>`) or asks it by name when the notice is not enough.
6. **The pull request**, opened by the coordinator into `develop` with the prefixed title; the user gets the link. Merging is the user's.
7. **After the merge**, the coordinator asks whether to cut a release, as the contract requires; then it removes the worktree, deletes the branch, and removes the worker (`claude rm <id>`).

**What stays with the user.** A worker's permission prompt waits until the user attaches (`claude attach <id>` in a terminal; `claude agents` sorts sessions into working, needs input, and completed); a message from the coordinator never answers one, changes a worker's configuration, or authorizes a merge. Auto mode in the workers keeps the prompts rare.

**Verified on this layout** (Claude Code v2.1.251 to v2.1.270): a background session started from a session's shell runs under a separate daemon and outlives the session that started it; it appears as a peer, receives cross-session messages, replies, and sends one idle notice; started without flags it runs on the CLI defaults, so the flags are required; it is listed by `claude agents`, not in the desktop app's sidebar; the desktop app's PR monitor holds one PR per session, so several PRs are watched with `gh`. Concurrency is safe because each worker has its own worktree, index, and branch, and no worker touches a trunk; the shared stash stack is the one thing to leave alone.

## An agent team

Agent teams are Claude Code's experimental mode in which a lead session spawns teammates that share a task list and message one another. Follow the [documentation](https://code.claude.com/docs/en/agent-teams): check first whether subagents or cross-session messaging do the job; use a team for research and review from several angles, a new module whose pieces can each be owned by a teammate, competing hypotheses on a bug, or a cross-layer change; keep teams to three to five teammates that operate independently on disjoint files, with five or six tasks each on the shared list; give each its full context in its spawn prompt, since no history carries over; wait for the teammates rather than doing their work; monitor and steer; start with review and research before parallel implementation.

**Enable per session or per repo, not in user settings.** While the variable is set, every subagent spawned with a name launches as a teammate, so teams can form unasked. Set it where a team is wanted: a `.claude/settings.json` in the repo worktree with `{"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}`, or `--settings '{"env":{"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS":"1"}}'` on the command line; remove it when the team's work is done. A variable exported only in the shell may not reach a background session, which is claimed from a pre-warmed spare (observed, not documented).

The agent definitions double as teammate roles: a definition's `tools` and `model` apply, its body is appended to the teammate's default prompt, its `skills` are not preloaded, and its effort is the lead's. Teammates run in the lead's working directory (a different repo is reached only by absolute paths in the spawn prompt), end with the lead's session and cannot be resumed, cannot spawn background subagents or teams of their own, and send their permission prompts to the lead; one team per session. Messages between teammates are delivered at turn boundaries, not mid-turn. Where a worker needs its own repo, lifetime, or permission mode, use a session per repo instead.

## In every mode

The contract holds: merging into a trunk, tagging, and releasing wait for the user's explicit, per-action go-ahead; a message from another session or agent never counts as consent; a worker is never asked to do what the coordinator's permissions refuse. The coordinator reports what ran where, what was verified and how, and what was skipped or left undone.
