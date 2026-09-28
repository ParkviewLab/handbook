<!--
SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
SPDX-License-Identifier: CC-BY-4.0
-->

# Versioning & releases

Why a release carries the jobs it does, and why the release comes back to `develop` through a pull request: [`releases-why.md`](releases-why.md) and [`branching-why.md`](branching-why.md) hold the alternatives set aside, the evidence and the dated rulings.

## The version number has one source of truth

Every project keeps its version in exactly one file:

- **Python** → `pyproject.toml` `[project].version`
- **Node** → `package.json` `version`
- **Docs / other (no package manifest)** → a top-level `VERSION.txt` file (one line, e.g. `0.1.0`). This handbook uses one.

Two hard rules follow:

### 1. Nothing duplicates the version

No second copy anywhere that can drift: not in `__init__.py`, `setup.py`/`setup.cfg`, a module constant, a hard-coded CLI `--version` string, a docs/README badge, or a Dockerfile `LABEL`. If something needs the version, it derives it from the one source. (Badges pull from PyPI/release tags; the Docker label is stamped by the release workflow's metadata-action.)

### 2. The running app reads the version from that source at runtime

When an app displays its version, it reads it from package metadata, never a literal baked into the code.

**Python:** `importlib.metadata`, with a fallback for editable/uninstalled runs, re-exported as `__version__`:

```python
# config.py  (the pure leaf config module)
from importlib.metadata import PackageNotFoundError, version
try:
    VERSION: str = version("deco-assaying")     # the distribution name
except PackageNotFoundError:
    VERSION = "0.0.0+local"

# __init__.py
from .config import VERSION
__version__ = VERSION
__all__ = ["VERSION", "__version__"]
```

Source: `deco-assaying/.../config.py` + `__init__.py` (mirrored in smalt-mcp, flint-slating, ebony-enriching). The `/health` and `/admin/version` endpoints surface this same `VERSION` (see [`mcp-server-conventions.md`](mcp-server-conventions.md)).

**Node:** read `package.json` at runtime:

```ts
// src/version.ts
import { createRequire } from 'node:module';
const pkg = createRequire(import.meta.url)('../package.json') as { version: string };
export const VERSION = pkg.version;
```

Source: jonobones's `src/version.ts`.

> If you find the version duplicated somewhere, remove the duplicate and replace the read-site with the metadata lookup.

## Cutting a release

Releases are tag-driven: pushing a `v*` tag triggers CI, which publishes everything. You never type a version on the `git tag` line: the `dev-tools` helpers derive it from the source-of-truth file (see [`ci.md`](ci.md) for the helpers' home).

```bash
# in the <repo>-main worktree — the whole release runs from the CLI under one authorisation:
git pull --ff-only                   # sync main
git -C ../<repo>-develop pull --ff-only   # sync develop too — see the caution below
git merge --no-ff develop            # promote develop→main; the merge commit is the release ledger entry
git bump <patch|minor|major|release|X.Y.Z>   # edits the SoT file, commits "release v<new>"
git release                          # annotated tag v<new>, derived from the SoT
git push --follow-tags               # the tag push fires the release workflow
```

> **Sync `develop` before you promote.** `git merge --no-ff develop` merges the *local* `develop` worktree, not `origin/develop`. After any merge on GitHub (a feature PR, or the previous release's back-merge PR), that local worktree is stale, so the merge quietly promotes and tags a commit that omits the merged work. The `git -C ../<repo>-develop pull --ff-only` line above closes the gap; skip it and you ship the wrong commit. (This is why the layout sets branch upstream tracking at creation; see [`repo-layout.md`](repo-layout.md#creating-the-layout).)

- **`git bump`** bumps the version in the source of truth (`pyproject.toml` / `package.json` / `VERSION.txt`, auto-detected), stages the change (+ lockfile if touched), and commits `release v<new>`. It does not tag. `git bump release` finalizes a dev cycle (drops the `.devN`); see [Development versioning](#development-versioning). A first release is the one case without it: the version file already names the version to ship, with no dev marker (the templates start at `0.1.0`), so after the promotion `git release` alone tags it; `git bump patch` would skip a number and `git bump release` refuses.
- **`git release`** reads the version back out and makes the annotated tag `v<version>`. It refuses on a dirty tree or an existing tag. It does not push.
- **Choosing the bump kind:** the releaser reviews the changes since the last release, proposes major / minor / patch with a one-line rationale, and the engineer confirms before `git bump`. The signal is the Conventional Commit types of the pull requests on `develop`'s first-parent line since the last tag (`git log <last tag>..develop --first-parent --oneline`), not every commit in the range, which under merge commits holds the branches' own commits too. Any breaking change → major, any `feat:` → minor, otherwise (`fix:`/`perf:`) → patch. Never bump silently; never infer the kind from past cadence. See [`ai-collaboration.md`](ai-collaboration.md).
- **Docs currency:** a release publishes `main`'s documents, in the tag's tree everywhere and on the docs site where the repo has one ([`docs-site.md`](docs-site.md)). The currency check is part of the preflight ([`agents.md`](agents.md)); a stale or wrong statement it finds is fixed on `develop` before the promotion.
- **Docs-only / `VERSION.txt` repos have no Conventional-Commit signal** (it's all docs), so choose the bump by the significance of the change: a whole new convention or section → minor; a clarification, correction, or typo → patch; removing or reversing an established convention → major. (This handbook's v0.4.0 was a minor: it added the dual-license layout.)
- **`VERSION.txt`-file repos** (no `pyproject`/`package.json`, e.g. this handbook): `git bump`/`git release` are SoT-aware: they detect `VERSION.txt` and bump / tag from it just like a `pyproject` repo, so docs repos release with the same CLI flow, no hand-editing. Their release workflow is the documents assembly: the gate, then the GitHub Release, with no artifact and no `changelog` job (see [below](#what-the-release-workflow-does)).

### Version rules

- **Feature work never changes the version.** A PR into `develop` must not touch the version source-of-truth file; the bump happens only at release, on `main`. A CI check on `develop` PRs enforces this; see [`ci.md`](ci.md#version-checks).
- **The version only ever increases.** The release gate rejects a tag whose version isn't strictly greater than the last released one, a guard against forgetting to bump or going backwards (see [`ci.md`](ci.md#version-checks)).

### Branch roles & why bump+tag on `main`

`main` is the release-only surface; `develop` is the integration trunk (see [`branching.md`](branching.md)). The bump+tag happens on `main` because: clean working-branch history (no release mechanics on feature branches), a deliberate "I'm shipping" moment, and the tag is trivially reachable from `origin/main` so the CI gate passes by construction.

Promotion is `develop → main` done from the CLI with `git merge --no-ff develop`, a merge commit, so `git log --first-parent main` is a dated per-release ledger (see [`branching.md`](branching.md)). It is not a reviewed PR, for three reasons that do not depend on the merge method: `main` carries no required checks for a promotion PR to wait for (see [`ci.md`](ci.md#repo-merge-settings)), a promotion PR would add a second wait to every release, and the explicit hand the promotion needs is the release authorisation, which covers it (see [`ai-collaboration.md`](ai-collaboration.md)). What it promotes is `develop`'s tip, every commit of which reached `develop` through a pull request that passed `develop`'s checks, and what it publishes is guarded by the release gate. Pulls use `git pull --ff-only`.

### Picking a merged pull request onto the release line

Where a fix that is already merged on `develop` has to ship on its own, without the rest of `develop`, pick the pull request whole onto `main` and release it from there, as a hotfix:

```bash
# in the <repo>-main worktree, with <merge> the PR's merge commit on develop:
git pull --ff-only             # sync main
git cherry-pick -m 1 <merge>   # the pull request's whole change, as one commit
                               # (and a lagging pin's pull request picked the same way, before the bump)
git bump patch                 # edits the SoT file, commits "release v<new>"
git release                    # annotated tag v<new>, derived from the SoT
git push --follow-tags         # the tag push fires the release workflow
git back-merge                 # the release's last step, as for any release
```

`-m 1` replays the merge's whole change against its first parent, which is the pull request's change and nothing else (git refuses to pick a merge without it). The pick is a copy of a commit GitHub made, so the changelog recognises it by patch-id and lists that pull request once, by its number, in the release that ships it, and does not list it again when its merge arrives with the next promotion. Picking the branch's commits one by one instead loses that: each is listed under Direct commits, by subject and short hash ([`commits-and-changelogs.md`](commits-and-changelogs.md#how-a-releases-list-is-built)).

The pick takes the place of the promotion, and the rest of the release is the one [above](#cutting-a-release): the bump, the tag, the release workflow and its gate, then the back-merge. The preflight runs before the pick as it runs before a promotion ([`ai-collaboration.md`](ai-collaboration.md#shared-state-writes-need-explicit-authorization)), and two of its findings are dealt with otherwise, because a hotfix is released from `main`, which holds only the last release and what is picked onto it. A pin below its floor is moved by its pull request into `develop`, as before any release, and that pull request is then also picked onto `main` with `git cherry-pick -m 1`, before the hotfix's bump, so that the hotfix's own release, which runs the workflows as `main` holds them, runs the pinned script at or above its floor ([`ci.md`](ci.md#shared-dev-scripts-dev-tools)). A stale document the currency check finds is fixed on `develop` and is not picked: it reaches `main` at the next promotion, since the hotfix republishes the documents the last release already published.

The back-merge comes through the checked pull request like any other release's ([below](#the-releases-last-step-the-back-merge-pull-request)), and differs in three respects. `git back-merge` recognises the release as picked, since the part of `main` that it brings holds no promotion, so there is no promoted version to compare `develop`'s with. In a code repo it takes the project's version lines from `main`'s release, which the plain merge cannot do, since both trunks have changed them since their merge base, `main` to the hotfix's version and `develop` to its placeholder; the open-cycle commit then follows as for any release, so that after the hotfix `X.Y.(Z+1)`, `develop` reads `X.Y.(Z+2).dev0` (`X.Y.(Z+2)-dev0` where the version lives in `package.json`). And where the merge conflicts elsewhere, as it does where `develop` has changed the picked lines again since the pull request merged, `git back-merge` names the exception, the direct back-merge, and not a pull request bringing `develop` into agreement with `main` ("If the back-merge conflicts", below).

## What a release publishes

What a repo's release does is decided by what the product publishes, never by its language or by a single template. There are five publish targets, and a product publishes to one of them or to several.

| Target | Release job | Dev-build job |
|---|---|---|
| A container image on GHCR | `docker`: the multi-arch image, `latest` among its tags | `docker`: tagged `dev`, with the dev version and `sha-<commit>`, never `latest` |
| A package on PyPI | `pypi`: trusted publishing | `testpypi`: the dev version on TestPyPI, environment `testpypi` |
| A package on npm | `npm`: trusted publishing | none |
| Installers for macOS, Windows or Linux | `installers`: built on each system and attached to the GitHub Release | `installers`: unsigned, kept seven days as workflow artifacts, with no tag and no GitHub Release |
| Documents, for a `VERSION.txt` repo | `release`: the GitHub Release with GitHub's generated notes | none |

The release workflow holds the gate, the job of each of the product's targets, and the job that creates the GitHub Release (`changelog`, which writes the notes, or `release` for documents). It carries no job for a target the product does not publish. Each workflow is assembled from the handbook's parts, one part per target, by the recipe in [`ci.md`](ci.md#releaseyml-on-v-tag-push).

Dev builds are for local testing: a dev build is a candidate that CI builds for testing in the lab before its release, not a version for others to use. A repo may have dev builds or not. Where it has them, a dev build publishes the dev counterpart of each of its targets that has one, and nothing else. So a repo that publishes to PyPI publishes its dev builds to TestPyPI, and one that does not publish to PyPI never touches TestPyPI. npm has no dev counterpart, as documents have none: a package is tested locally from the working copy. A dev build that packs the package into a tarball kept as a workflow artifact is added only when a repo needs it.

A Python service may publish only an image, a Python library only to PyPI, a Node command-line tool only to npm, and an application ships installers whatever builds it. The stack decides the tooling, the tests and the file that holds the version; the targets decide the release. A documentation site ([`docs-site.md`](docs-site.md)) and a website ([`website.md`](website.md)) are published otherwise and are not release targets.

## What the release workflow does

`.github/workflows/release.yml` fires on `push: tags: ['v*']` and runs:

1. `gate` (every other job `needs: gate`, so a failure ships nothing):
   - tag (minus `v`) equals the version in the repo's one version file, read in `git bump`'s order (`pyproject.toml`, `package.json`, `VERSION.txt`), and that version carries no dev marker: the promotion brings `develop`'s `.devN` placeholder onto `main`, and `git bump release` drops it before the tag,
   - the tagged commit is reachable from `origin/main` (release tags must come from `main`), and
   - the version is strictly greater than the previous tag (monotonic, see [`ci.md`](ci.md#version-checks)). A shared gate, rather than inline checks in one publish job, means a bad tag can't slip out through the job that didn't check.
2. The job of each of the repo's publish targets, in parallel:
   - `docker`: build + push to GHCR (`ghcr.io/parkviewlab/<repo>`), multi-arch `linux/amd64,linux/arm64`, tags `{{version}}`, `{{major}}.{{minor}}`, and `latest`.
   - `pypi`: `uv build`, then PyPI trusted publishing (OIDC, `environment: pypi`).
   - `npm`: npm trusted publishing (OIDC), with an optional scoped-alias publish.
   - `installers`: electron-builder on a macOS / Windows / Linux matrix, each leg uploading its installers as `installers-<os>`.
3. `changelog` (`needs:` the gate and every target job): checks `dev-tools` out at the commit of its pinned release and runs its `generate-changelog` ([`commits-and-changelogs.md`](commits-and-changelogs.md)). `--mode=generate --reuse-committed` runs against the tag: it reads the release's history and the repo's merged pull requests, lists every pull request the release holds and every commit that reached it without one, leaving out the release's own bookkeeping, and makes the one LLM call. The job then switches to a fresh `origin/main`, runs `--mode=insert`, commits `docs(changelog): v<new> [skip ci]` back to `main`, and creates the GitHub Release from the same body. Where the release builds installers, it downloads them first and attaches them to the Release. It runs after the target jobs, so a failure of the notes never holds back what they publish.

The documents target replaces that last job with `release`, which creates the GitHub Release with GitHub's generated notes (the merged-PR titles since the previous tag, each with its link, except the back-merge pull requests: `git back-merge` labels each one `release-bookkeeping`, and `.github/release.yml` excludes that label, so the release's own bookkeeping is not listed as work). It has no `changelog` job because a documents repo keeps no `CHANGELOG.md` to generate and commit back to `main`: the generated notes are its release record, and they already list what shipped, which is why the PR-title prefix still matters there. For hand-written notes, edit the Release after the workflow has created it (`gh release edit v<new> --notes-file …`). This handbook's own `.github/workflows/release.yml` is the documents assembly, byte for byte.

Reference implementations, by target: paper-boxing (image; its three-image matrix is a documented slot), cogrind-workshop (PyPI), smalt-mcp (PyPI and image), jonobones (npm and image), pensa-grex (installers), and this handbook (documents).

## Re-running a release whose target job failed

When a target job (`docker`, `pypi`, `npm` or `installers`) fails, what it publishes is missing, and the `changelog` job, which needs every target job, does not run. Re-run the failed jobs of the tag's own release workflow run (`gh run rerun <run-id> --failed`), which GitHub allows for 30 days after the run; a re-run runs the tagged commit's workflow file. After those 30 days, or where the fix needs a change to the code or to the workflow, cut a patch release instead. No release workflow carries a manual re-publish trigger, so these are the two ways. A re-run publishes, so it needs the same explicit go-ahead as the release itself ([`ai-collaboration.md`](ai-collaboration.md#shared-state-writes-need-explicit-authorization)).

## Repairing a release whose changelog job failed

When the `changelog` job fails, the gate and the target jobs have already succeeded, so the release is published under its tag, and the tag stays. What is missing depends on the step that failed: after a failure in generating or inserting, nothing has been committed and no Release exists; after a failure in creating the Release, `CHANGELOG.md` has been committed to `main` and only the Release is missing. The back-merge waits for the repair, so that it carries the changelog commit to `develop`. A re-run or a repair writes to `main` and publishes a Release, so it needs the same explicit go-ahead as the release itself ([`ai-collaboration.md`](ai-collaboration.md#shared-state-writes-need-explicit-authorization)).

1. A transient failure, such as GitHub's API or the network (the model's call never fails the job): re-run the failed job. A re-run runs the tagged commit's workflow file, and so the same pin. The insert adds no second section for a tag already present, and the generate step, which passes `--reuse-committed`, takes a section already committed to `main` instead of calling the model again, so a re-run after a partial success duplicates nothing and creates the Release from the text in `CHANGELOG.md`.
2. A defect in the script: repair by hand, with a corrected script from a `dev-tools` worktree, the person's own `gh` login, and `ANTHROPIC_API_KEY` in the environment (without the key the paragraph is the placeholder):

   ```bash
   # a full clone of the repo at <clone>, and <repo>-main pulled up to date
   uv run --script <dev-tools>/scripts/generate-changelog --mode=generate --tag vX.Y.Z --repo <clone>
   cp <clone>/release-body.md <repo>-main/
   cd <repo>-main
   uv run --script <dev-tools>/scripts/generate-changelog --mode=insert --tag vX.Y.Z
   git add CHANGELOG.md && git commit -m "docs(changelog): vX.Y.Z [skip ci]" && git push
   gh release create vX.Y.Z --title vX.Y.Z --notes-file release-body.md --verify-tag --target main
   ```

   Where the tag's section is already on `main`, the insert writes nothing and only the last command is needed. The correction reaches the repos as a `dev-tools` patch release, and the shape of history that caused the defect becomes a new test in `dev-tools`.
3. A defect in the workflow file, such as a wrong pin or a missing permission: a re-run cannot pick up a fix, because it runs the tagged commit's workflow file. Repair by hand as in 2, with the script at the pin, then fix the workflow on `develop` and check it again at the next release.
4. Where the release builds installers, they exist only as the run's artifacts: download them with `gh run download <run-id>` and attach them to the Release when it is created, before the run's artifacts expire.

## The release's last step: the back-merge pull request

A release leaves `main` with commits `develop` doesn't have: the `release v<new>` bump and, where the release has a `changelog` job, the workflow's `docs(changelog): v<new>` auto-commit, and for a hotfix the picked pull request's commit as well. Bringing them back is mandatory, and it is the release's last step. Without it the tag stays outside `develop`'s ancestry, which the next release's preflight reports as a blocker, and a code repo's `develop` keeps the placeholder of the version just released, which sorts below that release. (After a release made by promotion, the next promotion does not conflict: `develop` has not changed the version line since the last promotion. After a hotfix, in a code repo, it does, since both trunks have changed that line since their merge base.) They come back through a pull request, so that `develop`'s required checks examine what lands there, the version guard among them:

```bash
# from any worktree of the repo, after the tag push, under the same release authorisation:
git back-merge                # the newest release tag vX.Y.Z
git back-merge v1.2.3         # a named release tag, which must be main's version
git back-merge --dry-run      # build and check in a temporary worktree; push, open, merge and pull nothing
```

`git back-merge` ([`dev-tools`](https://github.com/ParkviewLab/dev-tools)) runs the whole tail as one command. Each of its steps first tests whether it is already done, so a second run after an interruption resumes where the first stopped. In outline:

1. **It waits for the release.** Every workflow run of the tagged commit must have concluded, and where the release writes a changelog, `docs(changelog): v<new> [skip ci]` must be on `origin/main`. A release whose only failed job was `changelog` is accepted once the repair [above](#repairing-a-release-whose-changelog-job-failed) is in place (that commit on `main` and a GitHub Release for the tag), so a release repaired by hand is not refused for good.
2. **It builds the branch** `back-merge-<tag>` in a temporary worktree, from `origin/develop`, with `git merge --no-ff origin/main`. `--no-ff` is required, not merely preferred: where no PR merged during the release, `develop` is an ancestor of `main`, and a plain merge would fast-forward the branch onto `main`'s tip (the `[skip ci]` changelog commit, where the release writes one), leaving it without the merge commit of its own that `back-merge-check` requires. `develop`'s first-parent chain, the per-feature ledger [`branching.md`](branching.md#tracking-when-a-feature-was-added) describes, does not depend on this merge: GitHub's merge of the PR keeps it, as for every PR, with a merge commit whose first parent is `develop`'s tip. A release picked onto `main`, a hotfix ([above](#picking-a-merged-pull-request-onto-the-release-line)), is built otherwise. `git back-merge` counts a release as picked when the stretch of `main`'s first-parent line that the back-merge brings, from the tag down to the first commit `develop` already holds, contains no promotion, that is, no merge whose second parent `develop` holds; a first release that `main` reached without a promotion commit, by a fast-forward, counts as picked too, and its tree is the plain automatic merge. It then makes the merge commit with `git commit-tree`, its parents `origin/develop` and `origin/main`, from the tree that `back-merge-check --merge-tree` gives, so that the command and the check apply one rule. For a hotfix in a code repo, that tree is the automatic merge in which the project's own version lines of `develop` and of the merge base, in the version file and its lockfile, are first set to `main`'s released version, because the plain merge conflicts on them by construction: `main` has moved them to the hotfix's version and `develop` to its placeholder. The check gives that tree only for the version change the release flow makes, a single merge base at a release R and `develop` at R's next-patch placeholder, which R's back-merge opened. In a `VERSION.txt` repo only `main` has changed the version since the merge base, and the tree is the plain automatic merge. The command says so when it builds a picked release's branch.
3. **In a code repo it opens the next dev cycle** in the same branch, as a second commit `chore: open X.Y.(Z+1).dev0 dev cycle` (the placeholder is `X.Y.(Z+1)-dev0` where the version lives in `package.json`; [Development versioning](#development-versioning)). A `VERSION.txt` repo skips it.
4. **It verifies its own result** with `back-merge-check`, the same check the version guard runs, and pushes the branch.
5. **It opens the pull request** into `develop`, titled `chore(release): back-merge main into develop after <tag>`, labelled `release-bookkeeping` so the generated notes leave it out, and closes any open back-merge PR of an older tag, whose version can no longer equal `main`'s.
6. **It waits for `develop`'s required checks** on that head and merges with `gh pr merge <n> --merge --match-head-commit <sha>`, never with `--admin`. The release authorisation covers this merge and the force push of the command's own branch when it refreshes it, and nothing else ([`ai-collaboration.md`](ai-collaboration.md#shared-state-writes-need-explicit-authorization)); no release prompt follows it.
7. **It cleans up:** the temporary worktree goes, the branch on `origin` is deleted where GitHub has not, the local `develop` worktree is fast-forwarded, and the open working branches that do not yet contain the new `develop` are listed. It merges into none of them. A dry run fetches, builds and checks the branch in its temporary worktree, which it removes, and changes nothing else on the machine: the `develop` worktree stays where it is, and once the back-merge has landed the command says only that it would fast-forward it.

**The branch is never brought up to date with GitHub's "Update branch".** That would add a second merge commit that is not on `main`, and an update by rebase would replay `main`'s release commits as new commits; the check refuses both. A back-merge PR that `develop` has moved beyond is refreshed only by rebuilding it from the new `develop`, which `git back-merge` does itself and which a second run of the command does after an interruption. That is also why nothing is fanned out into the working branches: where a repo requires branches to be up to date, that rule already brings each one current before its PR merges, and where it does not, GitHub's merge combines the two sides.

**If `develop` moves whilst the checks run,** a head it has moved beyond is never merged. Where the repo requires branches to be up to date, `git back-merge` tests before merging that `origin/develop` is an ancestor of the head and rebuilds the branch from the new `develop` if it is not; if it asks for the merge and GitHub refuses it as out of date, it rebuilds then instead. Either way the merge that lands is of a head the checks have passed on, and after three rebuilds the command gives up and leaves the PR open. A head replaced by another push is rebuilt in the same way, since `git back-merge` alone refreshes that branch. Where the repo does not require up-to-date branches, the head is merged as it stands and GitHub's merge carries the newer `develop`: what the back-merge brings is still exactly what the check examined.

**If the back-merge conflicts,** `git back-merge` refuses before merging anything and names the repair, which depends on where the conflict lies and on whether the release was made by promotion or picked onto `main` (step 2 above):

- **On the version line:** a version change reached `develop` outside the flow. After a release made by promotion, the command finds it by comparing `develop`'s version with the version that was promoted. After a hotfix, the check finds it where `develop` holds a version other than the placeholder the release flow sets, the next-patch placeholder of the release at the merge base; after a first release that `main` reached without a promotion commit, where the merge base's version is not a release. One reviewed commit restores `develop`'s version lines (the version file and its lockfile) to the version the refusal names (after a promotion, the version that was promoted), pushed to `develop` directly, with `enforce_admins` switched off and on again where administrators are bound ([`ci.md`](ci.md#required-checks-before-merge)); then run `git back-merge` again. Under this flow no step can cause it: feature PRs never change the version, the open cycle arrives with the back-merge, dev builds commit nothing, and where a hotfix and `develop`'s placeholder have both changed the version lines, `git back-merge` takes them from `main`'s release.
- **Anywhere else, after a release made by promotion:** an ordinary pull request into `develop` brings `develop`'s side of each conflicting passage into agreement with `main`'s; once it has merged, run `git back-merge` again. Never resolve it on `main`.
- **Anywhere else, after a hotfix:** the exception below. The pull request of the previous item is not used for a hotfix: it would bring `develop`'s side of each conflicting passage into agreement with the hotfix's, and so undo whatever `develop` has changed on those lines since the picked pull request merged.
- **More than one merge base:** where `develop` and `main` have several, `git back-merge` refuses only what `back-merge-check` refuses, and names the exception for each. It refuses a hotfix whose merge the check cannot give, since the check sets the version lines to `main`'s against a single merge base only; and a release made by promotion whose version comparison finds a mismatch, since the promotion compared may then be an earlier release's, made from a `develop` that did not yet hold the back-merge that has since moved its version, so that restoring `develop`'s version would be the wrong repair. A release made by promotion whose versions agree goes through the checked pull request as usual: git's merge handles several merge bases, and the check confirms the result.
- **The exception:** where `git back-merge` refuses and neither repair of the history above applies, as in the two items above, the back-merge is made directly in the `develop` worktree and reaches `develop` in one push, with administrators unbound for it: `enforce_admins` is switched off before that push and on again after it where administrators are bound ([`ci.md`](ci.md#required-checks-before-merge)).

  ```bash
  # in the <repo>-develop worktree, with <tag> the release's tag:
  git -C ../<repo>-main pull --ff-only    # main, with the changelog auto-commit where there is one
  git pull --ff-only                      # develop as origin has it
  git merge --no-ff main -m "Back-merge: main → develop after <tag>"
  # resolve the version lines to main's release version and every other conflict by hand, and git add them
  git commit --no-edit --cleanup=strip    # the merge, committed and not pushed, without git's list of conflicts
  git dev-release --open --direct         # in a code repo: the open-cycle commit, and one push of develop carrying both
  ```

  `git dev-release --open --direct` writes the next-patch placeholder of the version the merge leaves, `main`'s release version (`X.Y.(Z+2).dev0` after the hotfix `X.Y.(Z+1)`, `X.Y.(Z+2)-dev0` where the version lives in `package.json`), commits it as the open-cycle commit, and pushes `develop`, so that the one push carries the merge and the open cycle together. `--direct` is accepted only with `--open`, and without it `--open` still refuses in a repo that has switched. A `VERSION.txt` repo skips the open cycle and `git dev-release` refuses there, so the merge is pushed on its own (`git push origin develop`).
- **Prevention:** while a release is in progress, from the promotion (for a hotfix, from the pick) to the back-merge PR's merge, no pull request that edits `CHANGELOG.md` is merged into `develop`. That file is where the release's own commit lands, so a merge there during the window is the one conflict a release made by promotion can still produce; a hotfix can also conflict wherever `develop` has changed the picked lines again since the pull request merged.

An error of the check itself, such as a git too old for `git merge-tree --merge-base` (older than 2.40), is reported as an error and names no repair. The go-ahead that the two direct pushes above need, the repair's and the exception's, is set out in [`ai-collaboration.md`](ai-collaboration.md#shared-state-writes-need-explicit-authorization).

The back-merge lands by a pull request rather than by a direct push, because a direct push reaches `develop` only by bypassing its protection, and no check, the version guard included, examines what it brings. It stays one command run at the keyboard at a moment the releaser is already there, and it is not a pull request opened by a trigger; the reasoning and the alternatives set aside are in [`branching-why.md`](branching-why.md).

## Until a repository has switched

A repository has switched when it allows merge commits as its only merge method and its `version-guard.yml` carries the back-merge mode. Its switch pull request, which brings that guard, merges before its merge settings change, so a repository that allows merge commits carries the guard too. `git back-merge` therefore reads only that setting, `allow_merge_commit`, which GitHub returns only to a caller with admin rights on the repository; where it cannot read the setting, it stops. It finds this section by its exact heading and quotes it where it refuses, so the heading is not renamed whilst any repository needs the section.

Until a repository has switched, its release ends as it always has, by direct push. Its `develop` binds administrators, as every protected `develop` does, so `enforce_admins` is switched off before the first push below and on again after the last, by the two calls in [`ci.md`](ci.md#required-checks-before-merge); like the pushes of a repair or the exception, each switch needs its own go-ahead, which the release ask does not give:

```bash
# in the <repo>-main worktree, after `gh run watch` shows the whole workflow green:
git pull --ff-only                                   # main picks up the changelog auto-commit, where there is one
git -C ../<repo>-develop pull --ff-only              # a PR may have landed while CI ran
git -C ../<repo>-develop merge --no-ff main -m "Back-merge: main → develop after $(git describe --tags --abbrev=0)" \
  && git -C ../<repo>-develop push
# then, in a code repo, from the develop worktree, open the next cycle:
cd ../<repo>-develop && git dev-release --open
# and bring each open working branch up to date: git -C ../<repo>-<branch> merge develop
```

`--no-ff` is deliberate: a fast-forward would move `develop` onto `main`'s tip and replace `develop`'s first-parent history with `main`'s release ledger. `-m` keeps the editor closed; when `develop` already equals `main`, git reports "Already up to date" and creates nothing. In a code repo `git dev-release --open` then sets `develop`'s version to the next-patch placeholder and pushes it. After a hotfix ([Picking a merged pull request onto the release line](#picking-a-merged-pull-request-onto-the-release-line)), the merge conflicts on the version lines in a code repo, since both trunks have changed them since their merge base, and the push above is not made: resolve them to `main`'s release version, commit the merge and push `develop`, and `git dev-release --open` then writes the next placeholder, as it does there after any release. Where the repo's `dev-release.yml` does not yet declare the `kind` input, a dev build there commits `chore: dev build vX.Y.Z.devN` and pushes it before dispatching the workflow; where it does, the dev build commits nothing, as after the switch. No check examines those pushes, and the version guard, which triggers on pull requests, never sees them; each, the dev build's included, is made with `enforce_admins` switched off, as above.

A branch whose pull request was squash-merged before its repository's switch is verified from that pull request rather than by the ancestry test ([`branching.md`](branching.md#remove-the-worktree-and-delete-the-branch)). A repository whose version will live in `Cargo.toml`, as pensa-forma's will (its `develop` has no version file yet), switches when its first release is prepared: the version guard reads `Cargo.toml`, but `back-merge-check` and dev-tools' `_sot.sh`, from which `git back-merge` reads the version and writes the open cycle, do not.

This section goes at the first handbook release after every repository that runs the version guard, yucca-basing apart, has switched.

## Development versioning

Between releases a repo's `develop` should carry an honest pre-release version, and an engineer should be able to cut a dev build on demand. A dev build is for local testing: a candidate that CI builds before the real release, to exercise in the lab, and never a version for others to use. It publishes the dev counterpart of each of the repo's targets that has one, and nothing else ([What a release publishes](#what-a-release-publishes)).

**1. The dev version names the *next* release, not the last one.** A dev suffix is a *pre-release*; it sorts before the version it's attached to:

```
0.3.0   <   0.3.1.dev0   <   0.3.1
```

So after shipping `0.3.0`, `develop` works toward `0.3.1.dev0`, above the last release, below the target. Never suffix a version you've already shipped: `0.3.0-dev` sorts *below* `0.3.0`, so pip/uv/Docker treat it as *older* than the release. Form: Python `X.Y.Z.devN` (PEP 440); Node/Electron `X.Y.Z-devN` (semver; `npm version` rejects the dotted PEP-440 form); the dev image carries the tags `dev`, the dev version the dev gate computed, whose N comes from the run (`0.3.1.dev101` for run 1, attempt 1; see item 3), and `sha-<commit>`, never `latest`.

**2. Open the next cycle at release time, inside the back-merge PR.** `git back-merge` sets `develop`'s SoT to the next-patch placeholder `X.Y.(Z+1).dev0` (`X.Y.(Z+1)-dev0` where the version lives in `package.json`) as the second commit of the [back-merge pull request](#the-releases-last-step-the-back-merge-pull-request), `chore: open X.Y.(Z+1).dev0 dev cycle`, so the bump is verified where it lands: the version guard's back-merge mode admits exactly that placeholder, in the version file and its lockfile and nowhere else, and only from the version just released ([`ci.md`](ci.md#version-guardyml-version-sot-unchanged-every-repo)). It therefore cannot land before the back-merge it belongs to. After the switch, the one case in which the placeholder is written otherwise is the exception's direct back-merge ([If the back-merge conflicts](#the-releases-last-step-the-back-merge-pull-request)): there `git dev-release --open --direct` writes it after the merge, and one push carries both. Feature PRs leave the version unchanged, so the guard's ordinary mode still passes; `develop` now reports e.g. `0.3.1.dev0` everywhere: `/admin/version`, a casual editable install, a deploy. A branch cut *before* the cycle was opened passes the guard as it is: the check reads the pull request's synthetic merge, in which the branch carries `develop`'s version; bringing it up to date is the up-to-date rule's business, not the guard's.

**3. Cut a dev build on demand, never per-merge, and it commits nothing.** `git dev-release <patch|minor|major>` dispatches `dev-release.yml` on `develop` with the kind as the workflow's input, and writes nothing to `develop`. The dev gate computes the version from the newest release tag, incremented by that kind, and a build number taken from the run (`github.run_number × 100 + github.run_attempt`, so a re-run never repeats a file name, which PyPI and TestPyPI refuse); before a repo's first release there is no tag to count from, so the target is the version file's own version with any dev marker removed and the kind is not used. Each building job then sets that version in its own workspace (`uv version`, or `npm version --no-git-tag-version`) before it builds. It publishes the dev counterpart of each target: the `dev` image on GHCR (+ `:X.Y.Z.devN`), `X.Y.Z.devN` on TestPyPI, unsigned installers as workflow artifacts. It creates no `v*` tag, so the real `release.yml` and its main-reachability gate are untouched. Two consequences: the kind is per build and no longer persists, so a dev build may name a different target from the placeholder `develop` reports; and which commit a build came from is read from the workflow run and the image's `sha-<commit>` tag, there being no commit on `develop` to read it from. See [`ci.md`](ci.md#dev-releaseyml-on-demand-dev-build).

**4. The real release finalizes the cycle.** Promote `develop → main`, then `git bump` drops the `.devN`; the engineer just confirms the bump kind, as always. From the placeholder `0.3.1.dev0`: `git bump patch` → `0.3.1` (ship it); `git bump minor` → `0.4.0` (it was a feature release; re-points off the last tag); `git bump release` → `0.3.1` (ship exactly the declared target, no re-point). Then `git release` + push the tag as above; the monotonic gate passes (`0.3.1 > 0.3.0`).

**Documents repos skip the open cycle.** Nothing reads a documents repo's version between releases (no app, no package, no dev build), so `develop` keeps the last released version until the next `git bump` on `main`. Documents have no dev counterpart, so there is no dev build to cut. The tooling holds the rule rather than leaving it to memory: `git dev-release` refuses in a `VERSION.txt` repo, `git back-merge` adds no open-cycle commit there, and the guard's back-merge mode refuses one.
