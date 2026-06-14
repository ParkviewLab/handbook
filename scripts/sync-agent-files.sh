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
#   --base DIR    org root to scan for repos (default: parent of the handbook repo)
#   TARGET_DIR…   explicit repo working-dirs to write into (skips auto-discovery)
#
# Auto-discovery: for each immediate child REPO of --base (excluding this
# handbook), the first existing of REPO/develop, REPO/worktrees/develop,
# REPO/main, REPO/worktrees/main, or REPO itself (flat clone) is the target.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDBOOK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$HANDBOOK_ROOT/templates/AGENTS.md.template"

BEGIN_MARK="PARKVIEWLAB:BEGIN"
END_MARK="PARKVIEWLAB:END"

DRY_RUN=0
BASE="$(cd "$HANDBOOK_ROOT/.." && pwd)"
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --base) BASE="$2"; shift 2 ;;
    -h|--help) sed -n '2,23p' "$0"; exit 0 ;;
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

# Resolve the write target inside a repo (handles new + old layouts + flat clone).
resolve_target() {  # $1 = repo dir -> prints target working-dir or nothing
  local repo="$1" c
  for c in develop worktrees/develop main worktrees/main ""; do
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
    [[ "$repo" == "$HANDBOOK_ROOT" ]] && continue   # skip the handbook itself by default? no — include it.
    t="$(resolve_target "$repo")"
    [[ -n "$t" ]] && TARGETS+=("$t")
  done
  # include the handbook's own root too (it follows its own conventions)
  TARGETS+=("$HANDBOOK_ROOT")
fi

[[ "$DRY_RUN" == 1 ]] && echo "(dry run — no files will be written)"
echo "managed block source: $TEMPLATE"
echo

for t in "${TARGETS[@]}"; do
  echo "→ $t"
  write_one "$t"
done

echo
echo "done. ${#TARGETS[@]} target dir(s)."
[[ "$DRY_RUN" == 1 ]] && echo "re-run without --dry-run to apply."
exit 0
