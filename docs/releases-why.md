<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Releases: the reasoning, the evidence and the decisions

This file is the second half of the record of how a release is put together. The line between the two is what a reader needs: [`releases.md`](releases.md) and [`ci.md`](ci.md) keep every rule and every reason needed to apply one, and this file adds what is needed only to reopen a decision, which is the alternatives set aside, the evidence, and the dated rulings. Entries are in date order and the record at the foot summarises them.

It is a record, so it describes the past and keeps doing so ([`documentation.md`](documentation.md#documents-and-records)). An open question does not belong here; one about releases as they now stand goes to [`in-flight_ideas.md`](in-flight_ideas.md).

## 2026-09-18: a release carries the jobs of what its product publishes

The ruling of 18 September 2026: a repository's release carries exactly the jobs of what its product publishes. Its language does not decide them, and no single template does. There are five publish targets, and dev builds follow the same targets and no others, so a product uses TestPyPI if and only if it publishes to PyPI. [`releases.md`](releases.md#what-a-release-publishes) states the rule; [`ci.md`](ci.md#releaseyml--on-v-tag-push) gives the parts and the assembly.

What the handbook had said instead was chosen by stack: four release templates (`release.yml` for Python, `release-node.yml`, `release-electron.yml`, `release-txt.yml`) and two dev templates, with a repository that published less trimming its copy by hand. Only one such trim was documented, the deletion of the `docker` job. An audit of `docs/`, `templates/`, the README and the handbook's own release workflow at v0.24.0 found thirty-seven passages that tied a release to a stack rather than to what the product publishes.

The practice was already the rule. Checked on each repository's `develop` on 18 September 2026, against the organisation's GHCR packages, PyPI, TestPyPI, npm and the latest GitHub Release's assets: no ParkviewLab repository carried a job for a target it does not publish, all eight dev workflows held exactly the dev counterparts of their repository's targets, and the `pypi` and `testpypi` environments existed only where the repository publishes to PyPI. What the templates named was the stack; what the repositories did was the targets. That is why no job is removed anywhere by the migration, and why the re-assembly's substance is elsewhere: it brings the gate's version-increase check to the nine release workflows that lack it, and a gate to jonobones, which has none.

The purpose of dev builds was stated in the same conversation, in the ruling's own words: "dev builds are for local testing". A dev build is a candidate that CI builds for testing in the lab before its release, not a version for others to use. That settled npm's dev counterpart (T3) and the installers' (T10), and it is why the handbook now says what a dev build is for wherever it describes one.

### The templates: one part per target (T1)

One template part per target and per shared piece, assembled into each repository's single `release.yml` and single `dev-release.yml`, each job named as its part. Each job's text then has one source (axiom 1), a new combination of targets needs no new template, and the changelog job, whose action pins move at every handbook change, exists once.

Set aside, (b): one complete workflow per combination in use (`release-ghcr.yml`, `release-pypi.yml`, `release-pypi-ghcr.yml`, `release-npm-ghcr.yml`, `release-installers.yml`, `release-documents.yml`, and the four dev combinations), each copied whole into a repository's `release.yml`. A repository would then copy one file and a whole-file diff would check it, with no assembly. Against it: the release gate would sit in six files, the dev gate in four and the changelog job in five, all kept identical by a check; the template pins moved at every handbook change would be six rather than two; and each new combination, npm alone or PyPI with npm, would need a new file.

Set aside, (c): composite actions in dev-tools, pinned by commit SHA, sharing the steps whilst the jobs stay in each repository. Every job of every release would then depend on dev-tools at a pin, which is the dependency between repositories that intent 2 asks to avoid, and a repository's release would no longer be legible from its own file.

Set aside as well: one template holding every target and trimmed per repository, which is the practice the ruling rejects; every target's job in every repository, switched off by a condition or a repository variable, since the ruling asks for exactly the targets' jobs; and reusable workflows called from each repository. The last is partly impossible and wholly undesirable. PyPI's trusted publishing names a repository, a workflow file and an environment, and does not accept a reusable workflow as a publisher's workflow (docs.pypi.org/trusted-publishers/troubleshooting), so the `pypi` and `testpypi` jobs would stay in each repository under any scheme; npm checks the calling workflow's file name (docs.npmjs.com/trusted-publishers). The image, installers, gate and changelog jobs have no publisher's constraint and could have been shared, but every release would then depend on another repository at a pin, and a reusable workflow holds the job itself, its permissions capped by the caller's and its secrets passed on by the caller. Those same publisher constraints are why every repository's files keep the names `release.yml` and `dev-release.yml`, whatever its targets.

### Dev builds stay optional (T2), and npm has none (T3)

A repository has dev builds or it has none; where it has them, `dev-release.yml` holds the dev job of every one of its release targets that has one, and no other. Set aside: dev builds required wherever PyPI is a target, and dev builds covering only some of a repository's targets.

npm has no dev counterpart, as documents have none. The reading first put, a dev version published to the public npm registry under the `dev` tag, came from the v0.24.0 template's header ("a Node repo would publish an npm dist-tag instead") and had never been asked for; the purpose of dev builds rules it out, since a package is tested locally from the working copy. A dev build that packs the package into a tarball kept as a workflow artifact is the form to add if a repository ever needs one.

### The assembly is judged, not scripted (T4)

Each repository's `release.yml` and `dev-release.yml` are assembled by the recipe in [`ci.md`](ci.md#releaseyml--on-v-tag-push), starting from the parts and adapting them to the repository at hand. An assembler script with a check mode was set aside, and no in-flight entry was opened for one: the adaptation is judgement, and a script that could not make it would only move the judgement to whoever read its report.

A difference from a part is therefore judged rather than forbidden, in the ruling's words: "when drift is improvement then it is good and should be adopted where it is an improvement". Each difference is stated in the repository's pull request with its reason; a need of that repository alone is documented in the repository as its slot; a difference that improves the part is carried back into the handbook's part by a handbook pull request, and the other repositories take it at their next re-assembly where it improves them. Only a mistaken or unexplained difference is corrected. `actionlint` checks every assembly, and `convention-auditor` reports each undocumented difference for that judgement rather than as a defect.

### The northstar amended (T5)

The ruling's words were the reason: "the handbook is a guide, it says what we have tried and found to work well. it's how new things should be done until new information shows up a better way. and when we find/invent these better ways, we need to update the handbook with them." Four passages of [`northstar.md`](northstar.md) carry it: a new second paragraph of the opening, intent 1's deviation sentence, intent 1's explanation (which gained the sentence "Every release starts with a tag, then a gate checks the version, and then it ends in a published product."), and the second item of "What ParkviewLab engineering is not". Axiom 2 is unchanged, and the twin, `northstar.html`, follows the Markdown as the dual-track rule requires. The options put and set aside were no amendment at all, and one sentence in intent 1.

### The timing of re-assembly (T6)

Once the handbook release that carries this change has shipped, every repository's workflows are re-assembled from the parts at once, one pull request per repository. The reason is the version-increase check: it is missing from nine release gates (cobalt-grinding, cogrind-workshop, conception-space, deco-assaying, ebony-enriching, flint-slating, pensa-grex, pvl-dotview and smalt-mcp) and jonobones has no gate at all, so re-assembling at once puts the check in every release gate the same day. Set aside: each repository at its next change; the re-assembly folded into the changelog build's switch pull requests; and each repository at its next change with the version-increase step brought forward on its own.

Until a repository is re-assembled, its workflow is a copy of one of the replaced templates, and the auditor reports it as not yet re-assembled rather than as drift.

### The order against the builds in flight (T7, T8)

This fix went first, before the changelog build's handbook pull request and the real-merges build's, and both plans were amended to it. hazel-tracking waits for this fix's release under its own ruling, whereas each build's handbook pull request stays open until its own pilot has passed, so folding this fix into either would have held hazel-tracking as long; neither build's handbook branch existed yet, so going first cost them file names and no rework; and it made their template work smaller, one changelog part for three templates and one dev gate for two. The cost is the changelog build's calendar: its pilot starts about five hours later.

Two consequences of going first are recorded here because they are corrections, not form. NR08: the reason `release-txt.yml` gave for having no changelog job, that a docs repository "has no Conventional-Commit signal to categorise", was false of dev-tools, whose merged pull requests carry typed titles and which ships the changelog generator itself. The true reason, now in the documents part and in both pages, is that the repository publishes no package and GitHub's generated notes already list every pull request merged since the previous tag, each with its link. And the real-history set of the changelog generator's acceptance tests, which had been named by language, was relabelled by version file and publish target, since the script reads the version file and its lock file: `pyproject.toml` with GHCR (paper-boxing), `pyproject.toml` with PyPI (cogrind-workshop), `pyproject.toml` with PyPI and GHCR (smalt-mcp), `package.json` with npm and GHCR (jonobones), `package.json` with installers (pensa-grex), and `Cargo.toml` with installers pending pensa-forma's first release. "Node, GHCR only" left the set, its two dimensions being covered by paper-boxing and jonobones. That relabelling was made in its own dev-tools pull request.

### One dev gate for every target (T9), and the installers' dev build (T10)

The installers part writes a computed dev version into the repository's version file in its workspace only, as the registry parts do, with nothing committed, and `git dev-release` keys on its declared input alone with no case for a stack. The alternative, installers keeping a committed dev marker whilst the registry targets computed theirs, would have made two dev gates out of one.

The installers' dev counterpart is unsigned installers built on each system and kept seven days as workflow artifacts, with no tag and no GitHub Release. A GitHub pre-release was set aside: it would add a tag for the release's checks to pass over, and the dev build is for local testing.

### Durations

Agent wall-clock time, measured, for the record and to calibrate the next estimate of the same kind of work.

| Step | Estimated | Measured |
|---|---|---|
| The rule, the parts and the pages | 4.5 h | 0.5 h |

## Decision record

| Date | Decision | Ruling |
|---|---|---|
| 2026-09-18 | What decides a release's jobs | What the product publishes: five targets, one job each, and never the language or one template |
| 2026-09-18 | The organisation of the templates (T1) | One part per target and per shared piece, assembled per repository; one workflow per combination, and composite actions in dev-tools, set aside |
| 2026-09-18 | Dev builds (T2) | Optional per repository; where present, the dev job of every one of its release targets that has one, and no other |
| 2026-09-18 | An npm dev counterpart (T3) | None, as documents have none; a tarball dev build added only where a repository needs it; a `dev` dist-tag on the public registry set aside |
| 2026-09-18 | How a workflow is assembled (T4) | By the recipe in `ci.md`, with no assembler script; a difference from a part is judged, not forbidden |
| 2026-09-18 | The northstar (T5) | Amended in four passages: the handbook is a guide, and a better way found is carried back into it |
| 2026-09-18 | When the repositories are re-assembled (T6) | All at once after the release, one pull request each, so the version-increase check reaches every release gate the same day |
| 2026-09-18 | The real-history set of the changelog tests (T7) | Relabelled by version file and publish target, `Cargo.toml` pending; made in dev-tools' own pull request |
| 2026-09-18 | The order against the builds in flight (T8) | This fix first, the other plans amended to it; the changelog build's untouched files start at once |
| 2026-09-18 | The dev gate and installers (T9) | One dev gate for every target: the installers part writes the dev version in its workspace only, nothing committed |
| 2026-09-18 | The installers' dev counterpart (T10) | Unsigned installers kept seven days as workflow artifacts, with no tag and no GitHub Release; a pre-release set aside |
