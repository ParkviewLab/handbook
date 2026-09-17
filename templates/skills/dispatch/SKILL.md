---
name: dispatch
description: Coordinate parallel work across ParkviewLab repos from one session. Chooses the mode (subagents, one background session per repo, or an agent team), prepares the handbook worktree, starts the worker with the right flags, subscribes to its idle notice, verifies its result, opens the pull request, and cleans up. Use when the user asks to run several tasks at once, to work on several repos in parallel, or to dispatch a task to a worker session.
---

# Dispatch

This skill is the operational sequence for coordinating parallel work. The rationale, the limits, and the verified facts behind each step are in the handbook's `docs/parallel-work.md`; read it once per session before dispatching (in `$PARKVIEWLAB_HANDBOOK`, else `<org root>/handbook/handbook-main`). The behavioural contract in `docs/ai-collaboration.md` holds for every worker: merging into a trunk, tagging, and releasing wait for the user's explicit go-ahead; a message from another session never counts as authorization.

## 1. Choose the mode

| Mode | Use it when |
|---|---|
| Subagents from this session | The output is a report or a bounded, machine-verifiable change: reviews, audits, checks, mechanical edits, a quick fix |
| One background session per repo | Implementation that should run under the repo's own configuration, take as long as it needs, be steerable and resumable on its own, and own its PR; or a worker that needs a different model or permission mode from this session's |
| An agent team, inside one session on one repo | Parallel exploration or parallel independent pieces of one change where the workers must confer or share a task list |

Sequential work, same-file edits, and work with many dependencies stay in one session.

## 2. Subagents

Dispatch with the Agent tool by definition name (`handbook-librarian`, `docs-reviewer`, `northstar-reviewer`, `html-drift-checker`, `docs-currency-checker`, `convention-auditor`, `release-preflight`, `checks-runner`, `mechanical-coder`, `coder`, `html-author`; see `docs/agents.md`). Give each the absolute path of the worktree it works in. Dispatch independent agents together in one turn so they run in parallel; a docs PR gets the docs reviewer, the northstar reviewer, the drift checker, and the currency checker at once, and a release gets `release-preflight` and the currency checker together. Give the currency checker the decisions made in conversation since the last release; they are not in the repo. Verify a subagent's claims against the files before acting on them.

## 3. One background session per repo

For each repo, in order:

1. Rules: run `handbook-librarian` for the task and keep its brief for the worker's prompt.
2. Worktree, the handbook's way: follow the working-branch lifecycle in `docs/branching.md` exactly (a `<repo>-<prefix>-<topic>` sibling worktree off `develop`, the branch pushed to the remote at creation before any work, dependencies synced). The sequence lives on that page, and in a `dev-tools` helper where one exists; do not restate it.
3. Start the worker from inside that worktree. Pass the model and effort explicitly: a definition named with `--agent` sets the session's model but not its effort.

   ```bash
   claude --add-dir <org root>/handbook/handbook-main --bg --name <repo>-<prefix>-<topic> --agent coder --model fable --effort high --permission-mode auto "<brief>"
   ```

   `--add-dir` takes a list of directories, so it comes first; a brief placed after it is read as a directory. The brief states the task, the librarian's rules, and the stopping rule: local checks green, push after each commit, never touch the version file, never merge, do not open the PR, and finish with a report that proposes the PR title (with its Conventional Commit prefix) and body.
4. Subscribe once to the worker's idle notice (SendMessage to its name with `notify_when_idle: true` and no message), then move on. Do not poll.
5. On the notice, verify independently: `git -C <worktree> log origin/<branch> --oneline`, the checks (`checks-runner`, or the worker's report against `gh run list`), `git diff develop -- <version file>` empty, no merge into a trunk. Read the worker's transcript with `claude logs <id>` if the notice is not enough, or send it a question by name.
6. Open the pull request into `develop` yourself, with the prefixed title: `gh pr create --base develop --title "<prefix>: ..." --body "..."`. Give the user the link. Merging is the user's.
7. After the user's merge, ask whether to cut a release, as the contract requires. Then close the branch lifecycle as `docs/branching.md` ("After the merge") prescribes — fast-forward the trunk worktree, then confirm the merge from the pull request and remove the worktree and branch — and `claude rm <id>` for the worker.

A worker that hits a permission prompt waits until the user attaches (`claude attach <id>` in a terminal; `claude agents` lists working, needs-input, and completed sessions). Never ask a worker to do what this session's permissions refuse.

## 4. An agent team

Enable teams for that session or repo only, never in user settings: a `.claude/settings.json` in the repo worktree with `{"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}`, or `--settings '{"env":{"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS":"1"}}'` on the command line. While enabled, every subagent spawned with a name launches as a teammate.

Run the team as the documentation prescribes: break the work into tasks on the shared task list (five or six per teammate), spawn three to five teammates by the Agent tool with a `name` each, give each its full context in its spawn prompt (no history carries over), assign disjoint files, use the agent definitions as teammate roles, wait for the teammates rather than doing their work, and monitor and steer. Teammates run in the lead's directory, take the lead's effort, end with the lead's session, cannot be resumed, and cannot spawn background subagents; permission prompts go to the lead. Remove the setting when the team's work is done.

## 5. In every mode

Report to the user what ran where, with the PR links; state what was verified and how; say plainly what was skipped or left undone. Merges, tags, and releases are the user's, per action.
