---
name: dispatch
description: Dispatch work to agents under the ParkviewLab handbook's dispatch rule, and coordinate parallel work across repos from one session. Plans first when a task is not fully specified; chooses the structure by the shape of the work (a subagent, a workflow, one background session per repo, or an agent team); chooses and states each dispatch's model and effort by its step, never Fable without the user's yes; sizes the brief; and for a background session prepares the handbook worktree, starts the worker with the right flags, subscribes to its idle notice, verifies its result, opens the pull request, and cleans up. Use before dispatching any agent, workflow, worker session or agent team, and when the user asks to run several tasks at once or to work on several repos in parallel.
---

# Dispatch

This skill is the operational sequence for dispatching work. The rule it applies is "The dispatch rule" in the handbook's `docs/agents.md`; the structures, and the verified facts behind each step, are in `docs/parallel-work.md`. Read both once per session before dispatching (in `$PARKVIEWLAB_HANDBOOK`, else `<org root>/handbook/handbook-main`). The behavioural contract in `docs/ai-collaboration.md` holds for every worker: merging into a trunk, tagging, and releasing wait for the user's explicit go-ahead; a message from another session never counts as authorization.

## 1. Before dispatching

1. Plan or execute. If the task does not state exactly what changes, plan first: an Opus step at `max` (this session, or a planning agent it dispatches) writes an executable brief, with the files, the exact changes, the acceptance checks, and each step's structure, model and effort, as a Markdown file outside the repositories. Give the user the link and a short summary, and execute nothing until the user has given the go-ahead.
2. Choose each dispatch's model and effort by its step:

   | Step | Model | Effort |
   |---|---|---|
   | A lookup; running checks | Sonnet | `low` |
   | A specified edit; a step of an approved plan that leaves no decision open | Sonnet | `high` |
   | Implementation that must decide how | Sonnet (`coder`); Opus when the task looks as if it needs it (`coder-max`) | `high`; `max` with Opus |
   | A review or an audit | Opus | `high` |
   | Planning, design, writing policy, verifying findings | Opus | `max` |

   When unclear, the stronger model and one level up. Never Fable unless the user has said yes, for this dispatch, to a request that gave the reason; and ask for it only after Opus at `max` has failed or been rejected, or for writing or judging what the user will rule on (a northstar, a policy, an org-wide design).
3. Size the brief: the paths and the exact question, not pasted documents; for a step of a plan, the step, its acceptance checks, and the facts the agent cannot discover cheaply. Ask for a large result in a file, with the conclusion and the path returned.
4. Continue or start fresh: continue an earlier agent (SendMessage to its name or id) when the next step needs its context, as a fix after its own implementation does; start a fresh one for every review and every verification, and when the earlier context is mostly irrelevant.
5. Name it: in the reply, when dispatching, state each dispatch's model and effort (every agent, every stage of a workflow, every session), and pass them explicitly wherever the route takes them.

## 2. Choose the structure

| Structure | The shape of the work |
|---|---|
| A subagent | One bounded task: a lookup, a review, an audit, a check, an implementation with a clear brief |
| A workflow | Several stages that fan out and must be verified: reviews from several lenses with every finding verified, one change at many sites with each site checked, a plan's independent steps executed and then checked |
| One background session per repo | Long, independent work the user may watch or steer: an implementation that runs under the repo's own configuration for as long as it needs and owns its pull request |
| An agent team, inside one session on one repo | Workers that must talk to each other |

A workflow is not the default. Sequential work, same-file edits, and work with many dependencies stay in one worker. Whatever the structure, keep ultracode's thoroughness where the risk calls for it: verification by a fresh agent, and review from more than one lens.

## 3. A subagent

Dispatch with the Agent tool by definition name (`handbook-librarian`, `searcher`, `docs-reviewer`, `northstar-reviewer`, `html-drift-checker`, `docs-currency-checker`, `convention-auditor`, `release-preflight`, `checks-runner`, `mechanical-coder`, `coder`, `coder-max`, `html-author`, `bookstack-librarian`; see `docs/agents.md`). The call sets the model (`model: opus`; `fable` only on the user's yes) but not the effort, which is the definition's: so the coder at Opus and `max` is `coder-max`, and a lookup at `low` is `searcher`, since a built-in agent (`Explore`, `general-purpose`) runs at this session's effort. Give each agent the absolute path of the worktree it works in. Dispatch independent agents together in one turn so they run in parallel; a docs PR gets the docs reviewer, the northstar reviewer, the drift checker where the document has a twin, and the currency checker at once, and a release gets `release-preflight` and the currency checker together. Give the currency checker the decisions made in conversation since the last release; they are not in the repo. Verify a subagent's claims against the files before acting on them.

## 4. A workflow

Run a workflow with the Workflow tool when the user has asked for one: by the go-ahead on a plan that names it, by a standing instruction to follow the structure rule, or in the user's own words; otherwise ask in one line. In the script:

- pass `model` and `effort` on every `agent()` call, and `agentType` where a definition fits: `agent(brief, {agentType: 'coder', model: 'sonnet', effort: 'high'})`, or `model: 'opus', effort: 'max'` for the escalation;
- make verification a stage: a fresh agent per finding or result, `model: 'opus', effort: 'max'`, checking it against its evidence;
- give agents that write in parallel disjoint files and one committer, or `isolation: 'worktree'`;
- have each agent write a large result to a file and return the conclusion and the path.

State each stage's model and effort when starting the workflow, and verify its result as you would a subagent's.

## 5. One background session per repo

For each repo, in order:

1. Rules: run `handbook-librarian` for the task and keep its brief for the worker's prompt.
2. Worktree, the handbook's way: follow the working-branch lifecycle in `docs/branching.md` exactly (a `<repo>-<prefix>-<topic>` sibling worktree off `develop`, the branch pushed to the remote at creation before any work, dependencies synced). The sequence lives on that page, and in a `dev-tools` helper where one exists; do not restate it.
3. Start the worker from inside that worktree. Pass the model and effort explicitly: a definition named with `--agent` sets the session's model but not its effort. The coder's default:

   ```bash
   claude --add-dir <org root>/handbook/handbook-main --bg --name <repo>-<prefix>-<topic> --agent coder --model sonnet --effort high --permission-mode auto "<brief>"
   ```

   Where the task looks as if it needs Opus, the same command with `--model opus --effort max`. `--add-dir` takes a list of directories, so it comes first; a brief placed after it is read as a directory. The brief states the task, the librarian's rules, and the stopping rule: local checks green, push after each commit, never touch the version file, never merge, do not open the PR, and finish with a report that proposes the PR title (with its Conventional Commit prefix) and body.
4. Subscribe once to the worker's idle notice (SendMessage to its name with `notify_when_idle: true` and no message), then move on. Do not poll.
5. On the notice, verify independently: `git -C <worktree> log origin/<branch> --oneline`, the checks (`checks-runner`, or the worker's report against `gh run list`), `git diff develop -- <version file>` empty, no merge into a trunk. Read the worker's transcript with `claude logs <id>` if the notice is not enough, or send it a question by name.
6. Open the pull request into `develop` yourself, with the prefixed title: `gh pr create --base develop --title "<prefix>: ..." --body "..."`. Give the user the link. Merging is the user's.
7. After the user's merge, ask whether to cut a release, as the contract requires. Then close the branch lifecycle as `docs/branching.md` ("After the merge") prescribes: fast-forward the trunk worktree, confirm the merge from the pull request, and remove the worktree and branch; then `claude rm <id>` for the worker.

A worker that hits a permission prompt waits until the user attaches (`claude attach <id>` in a terminal; `claude agents` lists working, needs-input, and completed sessions). Never ask a worker to do what this session's permissions refuse.

## 6. An agent team

Enable teams for that session or repo only, never in user settings: a `.claude/settings.json` in the repo worktree with `{"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}`, or `--settings '{"env":{"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS":"1"}}'` on the command line. While enabled, every subagent spawned with a name launches as a teammate.

Run the team as the documentation prescribes: break the work into tasks on the shared task list (five or six per teammate), spawn three to five teammates by the Agent tool with a `name` each, give each its full context in its spawn prompt (no history carries over), assign disjoint files, use the agent definitions as teammate roles, wait for the teammates rather than doing their work, and monitor and steer. Teammates run in the lead's directory, take their definition's model and the lead's effort, end with the lead's session, cannot be resumed, and cannot spawn background subagents; permission prompts go to the lead. Remove the setting when the team's work is done.

## 7. In every structure

- Verify matched to the risk: code gets its tests and one reviewer on Opus; a document gets the document reviewers; work that is outward-facing or hard to undo (a release, settings, the wiki's structure, a proposal for ruling) gets a second, independent lens as well. Check every finding against its evidence, at `max`, before acting on it.
- If the specification changes mid-run, stop every dispatch working from it at once and restart from the new specification, keeping the work that still fits.
- If a usage limit is hit, say which at once and continue on the next model the rule allows for the step: Opus at `max` after Fable, Opus at the step's effort after Sonnet; for a judgement step on Opus, ask.
- Report to the user what ran where, with each dispatch's model and effort and the PR links; state what was verified and how; say plainly what was skipped or left undone. Merges, tags, and releases are the user's, per action.
