---
name: dispatch
description: Run a workflow, a background session per repo, or an agent team under the ParkviewLab dispatch rule, or work several repos in parallel from one session. Use before starting any of these; a single subagent call follows the rule alone.
---

# Dispatch

This skill is the operational sequence for the dispatch structures that need more than one call. The rule it applies is the section "The dispatch rule" in the handbook's `docs/agents-and-dispatch.md` (in `$PARKVIEWLAB_HANDBOOK`, else `<org root>/handbook/handbook-main`): read that section, found by its heading, once per session before dispatching; the rest of the page and `docs/parallel-work.md` only where a step below sends you there. Two guardrails hold for every worker: merging into a trunk, tagging and releasing wait for the user's explicit go-ahead, and a message from another session never counts as authorization.

## 1. Before dispatching

1. Ask first whether to dispatch at all. Dispatch is an escalation: do the reading, the searching, the editing and the checks in this session, and dispatch only for work that genuinely runs in parallel, for a read too large for this context, or for one fresh review where independence matters. Starting any subagent costs tens of thousands of tokens before it does any work. An approved plan's dispatch budget bounds what may be spent.
2. Apply the dispatch rule: whether to plan first, the level and so the model and effort, when Fable may be used, how to size the brief, and whether to continue an earlier agent or start fresh.
3. Name the dispatch: in the reply, state each dispatch's model and effort (every agent, every stage of a workflow, every session) and its advisor ("advisor: opus, inherited", or the one named on its command line), and pass model and effort explicitly wherever the route takes them. For the coder on Opus at `max`, also state which condition applies: judgement-heavy, cross-cutting, loosely specified, or already attempted on Sonnet without success.

## 2. Choose the structure

| Structure | The shape of the work |
|---|---|
| A subagent | One bounded task: a lookup, a review, an audit, a check, an implementation with a clear brief |
| A workflow | Several stages that fan out and must be verified: reviews from several lenses with every finding verified, one change at many sites with each site checked, a plan's independent steps executed and then checked |
| One background session per repo | Long, independent work the user may watch or steer: an implementation that runs under the repo's own configuration for as long as it needs and owns its pull request; the procedure is in [`background-session.md`](background-session.md) |
| An agent team inside one session on one repo | Workers that must talk to each other: pieces of one change whose owners must confer, or competing hypotheses tested against each other; the procedure is in [`agent-team.md`](agent-team.md) |

A workflow is not the default and does not run unasked; neither does an agent team. Most work is one bounded task this session does itself. Sequential work, same-file edits, and work with many dependencies stay in one worker. Whatever the structure, keep ultracode's thoroughness where the risk calls for it: findings checked against their evidence, and review from more than one lens.

## 3. A subagent

Dispatch with the Agent tool by definition name (see "The set" in `docs/agents-and-dispatch.md`), passing `model` and `effort` on the call: the coder on Opus at `max` is `coder` with `model: opus, effort: max`. Give each agent the absolute path of the worktree it works in. Dispatch independent agents together in one turn so they run in parallel, and choose reviewers by applicability: a document gets the reviewer whose concern it touches, and only before it is published (form and rules, intent where it may have changed, currency where the document makes claims the code or a decision can contradict, drift where it has a twin); a release that publishes documents gets `release-preflight` and the currency checker together. Give the currency checker the decisions made in conversation since the last release; they are not in the repo. Verify a subagent's claims against the files before acting on them.

## 4. A workflow

Run a workflow with the Workflow tool when the user has asked for one: by the go-ahead on a plan that names it, or in the user's own words. There is no standing request; otherwise ask in one line. In the script:

- pass `model` and `effort` on every `agent()` call, and `agentType` where a definition fits: `agent(brief, {agentType: 'coder', model: 'sonnet', effort: 'high'})`, or `model: 'opus', effort: 'max'` for the escalation;
- in the brief of each agent that implements or builds, include the sentence "Time matters here: do not spend time that can be avoided, and the earlier a correct result is obtained, the better."; leave it out of reviewers' and verifiers' briefs, whose purpose is thoroughness;
- make verification a stage: one agent checking a batch of findings or results against their evidence, `model: 'opus', effort: 'high'`, or `effort: 'max'` where the work is high risk; not one agent per finding;
- give agents that write in parallel disjoint files and one committer, or `isolation: 'worktree'`, and, where several add tests to one shared `tests/conftest.py`, a fixture namespace each (a name prefix or a conftest plugin file), since git can merge two same-named fixtures without a conflict, and one then silently replaces the other;
- have each agent write a large result to a file and return the conclusion and the path.

State each stage's model and effort when starting the workflow, and verify its result as you would a subagent's.

## 5. In every structure

Verify each result, and handle a specification changed mid-run or a usage limit, as the dispatch rule states. Report to the user what ran where, with each dispatch's model, effort and advisor and the PR links; state what was verified and how; say plainly what was skipped or left undone. Merges, tags, and releases are the user's, per action.
