---
name: tangent
description: Record a tangential idea discovered whilst working on something else into the wiki's Discovered Tangents register, or list the open tangents for a repo. Use when work turns up something that should be done but not now (a fix belonging to another repo, a convention worth adopting, a piece of technical debt, an idea for a project not yet started), and at the start of work on a repo to see what was set aside earlier.
---

# Tangent

Work turns up work. An idea discovered whilst doing something else is either done then, in parallel, or set aside; the ones set aside are recorded here, because otherwise they are lost. The register is a book in the org's wiki named Discovered Tangents, one page per idea, and it is the inbox that feeds a repo's `docs/in-flight_ideas.md`. Its shape, its fields and its tags are the librarian's, in `templates/agents/bookstack-librarian.md`; the convention it serves is in the handbook's `docs/documentation.md` ("Discovered tangents").

## Recording is authorised; telling the user is required

Recording an entry needs no approval, and you do not interrupt the work to ask for one. You do have to say that you recorded it: the user reads the register to decide when and how to act, and an entry they do not know about is an entry that does not exist for them. One line in the reply that names the idea and gives the page URL discharges this. If you are in the middle of a long task, the line goes in the report at the end of it, not in a separate interruption.

## Record one

1. Decide that it belongs here. It does if it is work that should be done and is not being done now. It does not if you can simply do it as part of the current task, if it is a defect in the change you are making (fix it), if it is a preference about how to work (that is a memory), or if the target repo's `docs/in-flight_ideas.md` already states it: read that file first when the idea concerns a repo you have open.
2. Compose the entry. Only this session knows the substance, so this part is not delegable: the idea in one paragraph in the words used when it arose, its origin (the repo, and the branch, pull request or task), the date, why it was set aside, and, where you can give one, what it would take in agent wall-clock hours with the waits named.
3. Dispatch `bookstack-librarian` with that entry and the target repo, and let it file the page, check for a near-duplicate and tag it. If this session cannot dispatch the librarian because the definition is not in its list, write the page yourself through the wiki's tools in the shape the definition prescribes: the standing authorisation to record covers that one write, and the line to the user says it was made directly.
4. Tell the user, as above.

Several tangents found in one stretch of work are filed in one dispatch, as several entries, not one page with a list: a page per idea is what lets an idea be promoted, dropped or finished on its own.

## List the open ones

At the start of work on a repo, and whenever asked, dispatch the wiki librarian for the open entries whose `target` tag is that repo, and give them as a short list: the title, one line of substance, and the date. This is a prompt for the user's judgement, not a plan. An entry is a question, not a commitment, and nothing in the register is acted upon silently.

## Promote one

An idea whose design is clear, whose trade-offs are understood and whose fit with the repo's northstar is good is ripe for its repo's `docs/in-flight_ideas.md`, and from there for a plan. Ripeness is the user's call: propose the promotion, with the reason, and wait. On the go-ahead, the entry moves into that repo's `docs/in-flight_ideas.md` in an ordinary `doc-` branch and pull request, and the librarian is then dispatched to set the entry's disposition to promoted, naming that pull request. The entry stays in the register as the record of where the idea came from.
