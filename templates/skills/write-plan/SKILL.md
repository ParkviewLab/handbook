---
name: write-plan
description: Write a plan the ParkviewLab way: put it where the user keeps plans, search Discovered Tangents for entries the plan carries out (closed when it is done) or touches (put to the user, one at a time), settle every decision with the user in prose before the go-ahead, and state the dispatch budget. Use when writing a plan, including in plan mode.
---

# Write a plan

A task that is not fully specified is planned before it is executed. The rule is the plan paragraph of the handbook's `docs/agents-and-dispatch.md` ("The dispatch rule"); this skill is its procedure, and where the two differ the rule wins. The main session settles the plan's decisions itself, even where it has dispatched a planning agent to draft the plan, as the rule allows: settling them takes conversation with the user, which a subagent cannot hold.

## Where the plan goes

Where the user's `CLAUDE.md` names a place for plans, the plan goes there, under the name it gives; otherwise in a Markdown file outside the repositories. Where plan mode prescribes a file of its own, write the plan there whilst planning, and copy it to the user's place as the first step after the go-ahead; from then on only that copy is edited. The plan opens with a Context section: why the change is made, what prompted it, and the intended outcome.

## Check Discovered Tangents

Whilst writing, search Discovered Tangents yourself for the open entries that match the plan's repositories, files and subjects. Discovered Tangents is a folder of the Library's vault (`$PARKVIEWLAB_LIBRARY`; the `tangent` skill gives the default and the entry's shape), which holds only the open ones, one Markdown file per idea with `target`, `origin` and `keywords` in its frontmatter: `grep -lE '^target: "?<repo>"?$'` over the folder for each of the plan's repositories, and a `grep` for a subject's specific terms where the plan's subject is wider than one repository. Read a file only where its name is not enough to decide.

- An entry the plan carries out in full is named in the plan, and the plan ends with a closing step that sets it done once the plan has been executed: `status: "done"` in its frontmatter, the account of what finished it (the pull request or release) as its last paragraph, and the file moved to the `Handled Tangents` folder, as the `tangent` skill prescribes.
- Each related entry is put to the user, one at a time, with a recommendation on its merits: include it whole, or leave it. The answer is written into the plan.

Something new found whilst planning, and not taken into the plan, is filed with the `tangent` skill.

## Settle every decision

The plan the user approves holds no open decision. Put each one to the user before the go-ahead, in prose at the end of a message: the recommendation and its reasons first, then the options, one per line, then one question. Not through a multiple-choice dialog, even where plan mode suggests one, because the dialog hides the reasoning written before it. Approving a plan does not answer a decision it left open, and a ruling is never extended to a case the user did not rule on.

## Dispatch budget

State the budget `docs/agents-and-dispatch.md` requires (the greatest number of agents, the greatest number of review rounds per phase, and the conditions on which the work stops and asks), and name each dispatch with its model, effort and advisor. Fable, a workflow and an agent team each need what that rule requires; the rule is not restated here.

## Scope

This skill governs the writing of a plan. Once the plan is approved, its scope holds: nothing is pulled into it from Discovered Tangents on the session's own initiative, and what is found and set aside during execution is filed as a tangent.
