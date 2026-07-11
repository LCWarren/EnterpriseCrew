#!/bin/bash
# Stop hook — enforces that non-trivial changes get reviewed by Data
# before a session is considered finished. Deliberately gated by diff
# size: small changes (the "Yellow" tier from red-alert) pass through
# with zero friction. Only changes above the threshold require a
# recorded review. This is what makes review a guarantee instead of a
# request — a CLAUDE.md instruction can be skipped under deadline
# pressure, a hook cannot.

# Fail open, not closed: if jq isn't installed, don't block work over a
# missing dependency — just let it through.
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)

# Prevent infinite loop: if this hook already fired once this turn and
# Claude is stopping again, let it stop.
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# Only applies inside a git repo with real changes
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

LINES_CHANGED=$(git diff HEAD --numstat 2>/dev/null | awk '{added+=$1; removed+=$2} END {print added+removed+0}')

# Routine-sized change — same threshold spirit as red-alert's Yellow tier.
# No review required, no friction.
if [ "$LINES_CHANGED" -lt 15 ]; then
  exit 0
fi

DIFF_HASH=$(git diff HEAD 2>/dev/null | shasum | awk '{print $1}')
MARKER=".claude/state/last-review.json"

if [ -f "$MARKER" ]; then
  REVIEWED_HASH=$(jq -r '.diff_hash // ""' "$MARKER" 2>/dev/null)
  if [ "$REVIEWED_HASH" = "$DIFF_HASH" ]; then
    exit 0
  fi
fi

FILES_CHANGED=$(git diff HEAD --numstat 2>/dev/null | wc -l | tr -d ' ')
echo "This change is $LINES_CHANGED lines across $FILES_CHANGED file(s) — above the routine threshold and not yet reviewed. Dispatch the 'data' subagent to review the current diff before finishing. Data will record the review automatically once it completes (see .claude/agents/data.md). If Data has already run but this still blocks, the diff changed since — re-run Data on the current state." >&2
exit 2
