#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# install-agents.sh — link the handbook's agent definitions (templates/agents/*.md)
# and skills (templates/skills/<name>/) into the user-level Claude Code directories,
# ~/.claude/agents/ and ~/.claude/skills/, so every session on this machine can use
# them whatever directory it starts in. See docs/agents.md and docs/parallel-work.md.
#
# Symlinks by default, like dev-tools' install.sh: an edited definition is picked up
# on the next `git pull` with no re-run; a brand-new file needs one more run.
# The source defaults to the RELEASED handbook (the sibling <container>/handbook-main
# worktree, when it has templates/agents); otherwise this checkout, with a warning.
#
# Usage:
#   scripts/install-agents.sh [--dry-run] [--copy] [--source DIR] [--uninstall]
#
#   --dry-run      show what would change; write nothing
#   --copy         copy files instead of linking (no automatic updates)
#   --source DIR   handbook checkout to install from (default: released main, see above)
#   --uninstall    remove the links this script made (copied files are left alone)
#
# Idempotent: re-running with nothing changed makes no edits. An existing regular
# file or directory that this script did not create is never overwritten.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDBOOK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENTS_DIR="${HOME}/.claude/agents"
SKILLS_DIR="${HOME}/.claude/skills"

DRY_RUN=0; COPY=0; UNINSTALL=0; SOURCE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --copy) COPY=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --source) SOURCE="$2"; shift 2 ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

# Resolve the source: the released handbook by default. In the contained layout this
# script runs from a worktree one level below the container, whose sibling
# handbook-main is the released checkout.
if [[ -z "$SOURCE" ]]; then
  _parent="$(cd "$HANDBOOK_ROOT/.." && pwd)"
  for c in "$_parent/handbook-main" "$_parent/main"; do
    if [[ -d "$c/templates/agents" ]]; then SOURCE="$c"; break; fi
  done
  if [[ -z "$SOURCE" ]]; then
    SOURCE="$HANDBOOK_ROOT"
    echo "warning: no released handbook (handbook-main) with templates/agents beside this checkout; installing from $SOURCE" >&2
  fi
fi
SOURCE="$(cd "$SOURCE" && pwd)"
[[ -d "$SOURCE/templates/agents" ]] || { echo "error: $SOURCE has no templates/agents" >&2; exit 2; }

echo "source: $SOURCE"
[[ "$DRY_RUN" == 1 ]] && echo "(dry run — nothing will be written)"

made=(); unchanged=(); skipped=(); removed=()

# link_one SRC DST — make DST point at SRC (or copy SRC to DST with --copy).
link_one() {
  local src="$1" dst="$2" name
  name="$(basename "$dst")"
  if [[ -L "$dst" ]]; then
    if [[ "$(readlink "$dst")" == "$src" && "$COPY" == 0 ]]; then unchanged+=("$name"); return; fi
    [[ "$DRY_RUN" == 1 ]] || rm "$dst"
  elif [[ -e "$dst" ]]; then
    if [[ "$COPY" == 1 && -f "$dst" && -f "$src" ]] && cmp -s "$src" "$dst"; then unchanged+=("$name"); return; fi
    skipped+=("$name (exists and is not a link this script made)"); return
  fi
  if [[ "$DRY_RUN" == 1 ]]; then made+=("$name"); return; fi
  if [[ "$COPY" == 1 ]]; then cp -R "$src" "$dst"; else ln -s "$src" "$dst"; fi
  made+=("$name")
}

# unlink_one DST — remove DST if it is a link into a handbook templates directory.
unlink_one() {
  local dst="$1" target
  [[ -L "$dst" ]] || return 0
  target="$(readlink "$dst")"
  case "$target" in
    */templates/agents/*|*/templates/skills/*)
      [[ "$DRY_RUN" == 1 ]] || rm "$dst"
      removed+=("$(basename "$dst")") ;;
  esac
}

if [[ "$UNINSTALL" == 1 ]]; then
  for f in "$AGENTS_DIR"/*.md; do [[ -e "$f" || -L "$f" ]] && unlink_one "$f"; done
  for d in "$SKILLS_DIR"/*; do [[ -e "$d" || -L "$d" ]] && unlink_one "$d"; done
  echo "removed: ${removed[*]:-nothing}"
  exit 0
fi

[[ "$DRY_RUN" == 1 ]] || mkdir -p "$AGENTS_DIR" "$SKILLS_DIR"
for f in "$SOURCE"/templates/agents/*.md; do
  [[ -f "$f" ]] && link_one "$f" "$AGENTS_DIR/$(basename "$f")"
done
if [[ -d "$SOURCE/templates/skills" ]]; then
  for d in "$SOURCE"/templates/skills/*/; do
    d="${d%/}"; [[ -f "$d/SKILL.md" ]] && link_one "$d" "$SKILLS_DIR/$(basename "$d")"
  done
fi

(( ${#made[@]} )) && echo "installed: ${made[*]}"
(( ${#unchanged[@]} )) && echo "already installed: ${unchanged[*]}"
(( ${#skipped[@]} )) && echo "skipped: ${skipped[*]}"
echo "→ $AGENTS_DIR, $SKILLS_DIR"
exit 0
