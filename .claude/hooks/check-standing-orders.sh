#!/bin/bash
# SessionStart hook — checks whether CLAUDE.md's Standing Orders are still
# placeholder text. If so, this is surfaced as context so filling them in
# becomes the first thing the harness prioritizes, before any other work.

CLAUDE_MD="${CLAUDE_PROJECT_DIR:-.}/CLAUDE.md"

if [ ! -f "$CLAUDE_MD" ]; then
  exit 0
fi

if grep -qE '\[(languages, frameworks|command|fill in)' "$CLAUDE_MD" 2>/dev/null; then
  echo "NOTICE: This project's Standing Orders in CLAUDE.md are still placeholder text — stack, test command, and dev command are not filled in. Before doing substantive work, run the 'commission' skill to detect the stack and fill these in (ask the user to confirm anything you can't infer from the repo, like non-obvious test setup). Don't guess at commands and proceed as if this section were filled in."
fi

exit 0
