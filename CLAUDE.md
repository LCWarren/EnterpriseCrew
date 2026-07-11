# Captain's Log — Project Conventions

Rule for this file: an entry earns its place only after something actually
went wrong and a rule was written to prevent it happening again. Nothing
aspirational goes here. If a line hasn't paid for itself with a real
incident, cut it.

## Standing Orders (fill in for your project)
- Stack: [languages, frameworks]
- How to run tests: [command]
- How to run the app locally: [command]
- Things Claude keeps getting wrong that aren't worth a full log entry yet:
  [short list, promote to a log entry once it recurs]

## Log Entries
<!-- Format: date — what happened — the rule that prevents it -->
<!-- Example:
2026-07-11 — Agent marked an auth change "complete" without running the
integration suite, it silently broke session refresh — Rule: Data (the
reviewer) must confirm targeted tests actually ran before a change is
called done, not just that they exist.
-->

## Review discipline
- No non-trivial change (roughly 15+ lines) is "done" until Data
  (`.claude/agents/data.md`) has reviewed it in a fresh context. This isn't
  just a rule stated here — `.claude/hooks/require-review.sh` enforces it
  as a Stop hook, so it can't be silently skipped under deadline pressure.
  Small changes pass through with no friction.
- Away team reports (`.claude/agents/away-team.md`) are investigation
  findings, not verified facts. Anything a report claims about existing
  behavior gets checked against the actual code before anyone builds on it.
