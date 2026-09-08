<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

<!--
templates/northstar.md — the blueprint for a repo's docs/northstar.md.

Copy this file to <repo>/docs/northstar.md and replace every bracketed
placeholder. Keep the section order: it is the structure documentation.md
prescribes (intents as peers → how they reinforce each other → axioms →
guiding questions → what it is not). Delete these authoring comments as you
go; the finished file carries only the SPDX header, the prose, and the footer.

Guidance, in brief:
- Two to four complementary intents, presented as peers. One clear intent
  beats several muddled ones; do not force a second. The tensions between
  intents are design-revealing, so state them rather than hide them.
- Axioms are design principles derived from the intents. The same axioms
  support all the intents, from different angles; do not group them per intent.
- Wording is the author's own. This document is read by people and by AI
  agents alike, and it is the authority over every other document and over
  the code (see documentation.md, "The northstar leads").
- The designed HTML twin, if the repo wants one, is authored from this file
  afterwards (md-to-html.md); this file stays canonical.
-->

# [Project]: northstar

The canonical statement of what [Project] is for. Design decisions and feature
proposals are weighed against it. Where it and any other document disagree,
this one is the authority and the other is the thing to fix; where it and the
code disagree, the code is wrong. A change of intent is therefore made here
first, in the same pull request as the code that follows it, so that no
disagreement is ever left standing by accident.

## What it is

[One paragraph: what the project is, in plain terms, for a reader who has
never seen it. Name the things it is made of and the one or two facts a
newcomer must hold to read the rest.]

## Why it exists

[One or two paragraphs: the gap in the world this fills, and why the existing
answers do not fill it. This is the "why", not a feature list.]

## Intents

[Project] serves [N] complementary intents: facets of one purpose, presented
as peers rather than as one primary and the rest secondary, and mutually
reinforcing. The tensions between them, below, are where the design is
decided.

1. **[Intent 1, as a short name.]** [One paragraph stating it.]

2. **[Intent 2.]** [One paragraph.]

3. **[Intent 3, if any.]** [One paragraph.]

### 1. [Intent 1]

[The deep dive: what this intent asks of the design, what it rules out, and
the concrete choices already made in its service. One to three paragraphs.]

### 2. [Intent 2]

[Deep dive.]

### 3. [Intent 3]

[Deep dive.]

### How the intents reinforce each other

[One paragraph on the dependencies: which intent makes which possible, and
what accumulates when they hold together.]

[One or more tensions, each worked: name the two intents that pull against
each other, the case in which they do, and the resolution the design
chooses and why. A tension left unresolved is a decision still to make.]

## Axioms

The same axioms support all the intents, from different angles.

1. **[Axiom 1, as a short imperative or claim.]** [One to three sentences:
   the principle and the consequence it has in practice.]

2. **[Axiom 2.]** [...]

3. **[Axiom 3.]** [...]

## Guiding questions

When making a decision, these are the questions to keep answering:

- [A question a proposal must answer well to belong; one per intent at
  least.]
- [...]

## What [Project] is not

- **Not [a thing it could be mistaken for].** [Why not, in a sentence.]
- **Not [another].** [...]

---
<sub>© [year] [Author] · Licensed under [CC-BY-4.0](../LICENSES/CC-BY-4.0.txt)</sub>
