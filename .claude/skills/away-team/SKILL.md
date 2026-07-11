---
name: away-team
description: Dispatch a read-only investigation into the codebase — tracing a pattern, mapping dependencies, understanding how a module works — without making any changes. Use when you need information before deciding how to act, not when you're ready to write code.
---

# Away Team Protocol

You're coordinating reconnaissance, not engineering work. The away team's
job is to observe and report — never to engage.

## Rules

1. Dispatch the `away-team` subagent for the investigation. It has
   read-only tools; it cannot edit files.
2. Give it a bounded, specific mission. Not "understand the codebase" —
   "trace every call site of `X`" or "explain how auth flows from login to
   session creation."
3. The away team returns a report, not a verdict. Treat every claim in it —
   especially anything like "X is already implemented" or "this looks
   safe" — as something to verify against the actual code before acting on
   it, not as settled fact.
4. A confident-sounding report is not the same as a checked one. If what
   you're about to build depends on a claim in the report, check it
   yourself first.
