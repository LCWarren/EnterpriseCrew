#!/bin/bash
# SessionStart hook — surfaces the last session's handoff note, if one
# exists, so a fresh session doesn't start blind.

HANDOFF="${CLAUDE_PROJECT_DIR:-.}/.claude/state/handoff.md"

if [ -f "$HANDOFF" ]; then
  echo "--- Handoff from last session ---"
  cat "$HANDOFF"
  echo "--- End handoff ---"
fi

exit 0
