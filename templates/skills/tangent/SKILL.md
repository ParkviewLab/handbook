---
name: tangent
description: Record a tangential idea discovered whilst working on something else into Discovered Tangents in the org's Library (an Obsidian vault), or list the open tangents for a repo. Use when work turns up something that should be done but not now (a fix belonging to another repo, a convention worth adopting, a piece of technical debt, an idea for a project not yet started), and at the start of work on a repo to see what was set aside earlier.
---

# Tangent

Work turns up work. An idea discovered whilst doing something else is either done then, in parallel, or set aside; the ones set aside are recorded here, because otherwise they are lost. Discovered Tangents is a book in the `Tangents` collection of the org's Library, an Obsidian vault on every workstation (`$PARKVIEWLAB_LIBRARY` if set, otherwise `~/dev/ObsidianVaults/LibraryVault`), one note per idea; it is the inbox that feeds a repo's `docs/in-flight_ideas.md`. The convention it serves is in the handbook's `docs/documentation.md` ("Discovered tangents"). A session reads and writes the Library as it reads and writes any file: no agent and no server stands between. A session started outside the vault's tree (in a repository worktree, say) reaches it only if the vault is among the session's directories; where a write would be put to the user, the vault is added to the session's directories once, on each workstation, as the lab's workstation runbook says.

## Recording is authorised; telling the user is required

Recording an entry needs no approval, and you do not interrupt the work to ask for one. You do have to say that you recorded it: the user reads Discovered Tangents to decide when and how to act, and an entry they do not know about is an entry that does not exist for them. One line in the reply that names the idea and gives the file's path discharges this. If you are in the middle of a long task, the line goes in the report at the end of it, not in a separate interruption.

## The entry

One file, `Tangents/Discovered Tangents/<title>.md`, the title a short noun phrase naming the idea (no `/`, `:` or other character a filesystem refuses), shaped thus:

```
---
status: "open"
origin: "<repo where it was discovered>"
target: "<repo it concerns, or none>"
discovered: <YYYY-MM-DD>
keywords:
  - "<a specific it names>"
  - "<another>"
---

<the idea in one paragraph, in the words used when it arose>

Origin: <the branch, pull request or task where it arose>
Set aside because: <the reason>
What it would take: <agent time, with the waits named, where an estimate can be given>
```

`status` takes `open`, `done`, `promoted` or `dropped`; a `promoted` entry also carries `destination: "in-flight"` (the repo's `docs/in-flight_ideas.md`) or `destination: "proposal"`. The properties are what a Base in Obsidian and a `grep` in a session both read, so they are kept exact: every string value in double quotes, the date bare, one keyword per line. The body holds only what the frontmatter does not: the repository and the date are properties, not lines.

## Record one

1. Decide that it belongs here. It does if it is work that should be done and is not being done now. It does not if you can simply do it as part of the current task, if it is a defect in the change you are making (fix it), if it is a preference about how to work (that is a memory), or if the target repo's `docs/in-flight_ideas.md` already states it: read that file first when the idea concerns a repo you have open.
2. Look for a near-duplicate: `grep -il --exclude='000 - *'` over the folder for the entry's two or three most specific terms, reading a hit only where its name suggests the same idea. An entry that states the same idea is updated with the new origin and any new reasoning, not written twice, and the line to the user says which you did.
3. Write the file in the shape above. Only this session knows the substance, so nothing here is delegated.
4. Tell the user, as above.

Several tangents found in one stretch of work are several files, not one file with a list: a file per idea is what lets an idea be promoted, dropped or finished on its own.

## List the open ones

At the start of work on a repo, and whenever asked: `grep -lE '^target: "?<repo>"?$' "${PARKVIEWLAB_LIBRARY:-$HOME/dev/ObsidianVaults/LibraryVault}/Tangents/Discovered Tangents"/*.md` (the folder holds only the open ones), then the file names and, where a name is not enough, the first paragraph. Give them as a short list: the title, one line of substance, and the date. This is a prompt for the user's judgement, not a plan. An entry is a question, not a commitment, and nothing in Discovered Tangents is acted upon silently.

## Close one

An idea whose design is clear, whose trade-offs are understood and whose fit with the repo's northstar is good is ripe for its repo's `docs/in-flight_ideas.md`, and from there for a plan. Ripeness is the user's call: propose the promotion, with the reason, and wait. On the go-ahead, the entry moves into that repo's `docs/in-flight_ideas.md` in an ordinary `doc-` branch and pull request. Then, as for every closed entry, on the user's instruction and never on your own judgement: set `status` to `promoted` (with `destination`), `done` or `dropped`, append the account of how it was handled as the file's last paragraph (the pull request, the release, the proposal, or the reason it was dropped), and move the file to `Tangents/Handled Tangents`, so that Discovered Tangents holds only the open ones and Handled Tangents the record of where each idea came from and what became of it.
