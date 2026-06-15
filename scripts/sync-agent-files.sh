#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# sync-agent-files.sh — write/refresh the ParkviewLab AGENTS.md + CLAUDE.md
# pointer files into each repo under the org, from the canonical managed block in
# this handbook's templates. See docs/ai-collaboration.md.
#
# Both files get the SAME managed block (so any agent tool picks up the same
# rules). The block is delimited by PARKVIEWLAB:BEGIN / PARKVIEWLAB:END markers;
# anything a repo has written *below* the END marker is preserved. Idempotent:
# re-running with no template change makes no edits.
#
# Usage:
#   scripts/sync-agent-files.sh [--dry-run] [--base DIR] [TARGET_DIR ...]
#
#   --dry-run     show what would change; write nothing
#   --base DIR    org root to scan for repos (default: the handbook's org root)
#   TARGET_DIR…   explicit repo working-dirs to write into (skips auto-discovery)
#
# Auto-discovery: for each immediate child REPO container of --base, write into the
# repo's integration worktree (or production, or a flat clone) — the first existing of, in order:
#   REPO/<name>-develop, REPO/develop, REPO/worktrees/develop,
#   REPO/<name>-staging, REPO/staging,                  (website repos — see docs/website.md)
#   REPO/<name>-main, REPO/main, REPO/worktrees/main,
#   REPO/<name>-live, REPO/live, or REPO itself (flat clone),
# where <name> is the container's basename (the contained, repo-prefixed layout).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDBOOK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$HANDBOOK_ROOT/templates/AGENTS.md.template"

BEGIN_MARK="PARKVIEWLAB:BEGIN"
END_MARK="PARKVIEWLAB:END"

# Default BASE = the org root = the parent of the handbook's CONTAINER. In the
# contained/bare worktree layouts the script lives in a worktree one level below the
# container (e.g. handbook/handbook-develop/scripts), so the container is HANDBOOK_ROOT's
# parent and the org root is its grandparent; for a flat clone HANDBOOK_ROOT *is* the
# container. Detect the worktree case by a sibling bare repo (<name>.git or .bare).
DRY_RUN=0
_parent="$(cd "$HANDBOOK_ROOT/.." && pwd)"
if [[ -d "$_parent/$(basename "$_parent").git" || -d "$_parent/.bare" ]]; then
  _container="$_parent"          # HANDBOOK_ROOT is a worktree; its parent is the container
else
  _container="$HANDBOOK_ROOT"    # flat clone: HANDBOOK_ROOT is the container
fi
BASE="$(cd "$_container/.." && pwd)"
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --base) BASE="$2"; shift 2 ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) TARGETS+=("$1"); shift ;;
  esac
done

[[ -f "$TEMPLATE" ]] || { echo "error: template not found: $TEMPLATE" >&2; exit 2; }
grep -q "$BEGIN_MARK" "$TEMPLATE" && grep -q "$END_MARK" "$TEMPLATE" || {
  echo "error: template missing $BEGIN_MARK/$END_MARK markers" >&2; exit 2; }

# Canonical managed block (BEGIN..END inclusive) and the new-file footer (after END).
NEW_BLOCK="$(awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
  $0 ~ b {p=1} p {print} $0 ~ e {p=0}' "$TEMPLATE")"
TEMPLATE_FOOTER="$(awk -v e="$END_MARK" '
  seen {print} $0 ~ e {seen=1}' "$TEMPLATE")"

# Render the full intended content for a (possibly existing) target file.
render() {  # $1 = existing file path (may not exist)
  local f="$1"
  if [[ -f "$f" ]] && grep -q "$BEGIN_MARK" "$f" && grep -q "$END_MARK" "$f"; then
    # Replace BEGIN..END in place; preserve prefix (before BEGIN) and suffix (after END).
    awk -v b="$BEGIN_MARK" -v e="$END_MARK" -v blockfile=/dev/stdin '
      BEGIN { while ((getline line < blockfile) > 0) block = block line "\n" }
      $0 ~ b { inblk=1; printf "%s", block; next }
      $0 ~ e { inblk=0; next }
      !inblk { print }
    ' "$f" <<<"$NEW_BLOCK"
  elif [[ -f "$f" ]]; then
    # File exists without markers: put the managed block on top, keep old content.
    printf '%s\n\n' "$NEW_BLOCK"
    cat "$f"
  else
    # New file: managed block + the template footer.
    printf '%s\n%s\n' "$NEW_BLOCK" "$TEMPLATE_FOOTER"
  fi
}

write_one() {  # $1 = target dir
  local dir="$1" name
  for name in AGENTS.md CLAUDE.md; do
    local f="$dir/$name" new
    new="$(render "$f")"
    # Compare/write with a single trailing newline so the result is stable even
    # if a pre-commit end-of-file fixer appends one (otherwise: perpetual diff).
    if [[ -f "$f" ]] && diff -q <(printf '%s\n' "$new") "$f" >/dev/null 2>&1; then
      echo "  = $name (unchanged)"
      continue
    fi
    local verb="update"; [[ -f "$f" ]] || verb="create"
    if [[ "$DRY_RUN" == 1 ]]; then
      echo "  ~ would $verb $name"
    else
      printf '%s\n' "$new" > "$f"
      echo "  ✓ $verb $name"
    fi
  done
}

# Resolve the write target inside a repo container (new contained, bare+children,
# old nested, and flat clone layouts all handled).
resolve_target() {  # $1 = repo container dir -> prints target working-dir or nothing
  local repo="$1" name c
  name="$(basename "$repo")"
  # develop/main = package & docs repos; staging/live = website repos (docs/website.md).
  for c in "$name-develop" develop worktrees/develop \
           "$name-staging" staging \
           "$name-main" main worktrees/main \
           "$name-live" live ""; do
    if [[ -n "$c" && -d "$repo/$c" ]]; then echo "$repo/$c"; return; fi
    if [[ -z "$c" && ( -f "$repo/pyproject.toml" || -f "$repo/package.json" || -f "$repo/README.md" ) ]]; then
      echo "$repo"; return
    fi
  done
}

# Build target list.
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  [[ -d "$BASE" ]] || { echo "error: base not found: $BASE" >&2; exit 2; }
  for repo in "$BASE"/*/; do
    repo="${repo%/}"
    t="$(resolve_target "$repo")"   # resolves the handbook itself uniformly too
    [[ -n "$t" ]] && TARGETS+=("$t")
  done
fi

[[ "$DRY_RUN" == 1 ]] && echo "(dry run — no files will be written)"
echo "managed block source: $TEMPLATE"
echo "org root (base):      $BASE"
echo

for t in "${TARGETS[@]}"; do
  echo "→ $t"
  write_one "$t"
done

echo
echo "done. ${#TARGETS[@]} target dir(s)."
[[ "$DRY_RUN" == 1 ]] && echo "re-run without --dry-run to apply."
exit 0
