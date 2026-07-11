---
name: end-of-shift
description: Seal session context before ending — write a short handoff note (what was done, what's in progress, what to check next) to .claude/state/handoff.md so the next session picks up cleanly instead of reconstructing context from scratch. Use when the user signals they're wrapping up, or offer it proactively near the end of a substantial work session.
---

# End of Shift

Context is ephemeral until it's written to disk. This writes the minimum
that actually helps the next session, not a full transcript.

## Write to `.claude/state/handoff.md`, overwriting what's there:

```markdown
# Handoff — <date>

## What got done
<2-4 bullet points, plain language, no ceremony>

## In progress / not finished
<what's half-done, and specifically what "finishing it" looks like>

## Things to check next session
<anything uncertain that needs a human decision or a look before
proceeding — e.g. "Data flagged X as unresolved," "waiting on which
approach for Y">
```

Keep it short. A handoff that takes longer to read than to just re-derive
from the diff isn't doing its job. If nothing meaningful happened this
session, don't write a note for the sake of writing one.

This file gets surfaced automatically at the start of the next session via
the SessionStart hook — you don't need to tell the user to go read it.
