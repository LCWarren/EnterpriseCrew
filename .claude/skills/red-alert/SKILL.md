---
name: red-alert
description: Assess whether a task is routine or high-risk before starting work. High-risk tasks (multi-file changes, architecture decisions, unfamiliar code, anything touching auth/billing/data integrity) get a written plan first. Routine tasks (typos, config tweaks, single-function fixes) skip straight to execution.
---

# Red Alert Assessment

Classify the task before starting anything non-trivial.

**Yellow — routine, no plan needed:**
- Single-function change with a clear, bounded scope
- Typo, copy, config value
- Confined to one file, no ripple effects into other modules

**Red alert — write a short plan before touching code:**
- Multi-file or cross-service change
- Touches auth, billing, data integrity, or anything with real blast radius
- You're not confident you understand the existing behavior
- The task description is ambiguous about what "done" actually means

If Red Alert: write a short plan with an explicit, testable definition of
done *before* writing code. A vague plan is worse than no plan at all — if
you can't state a concrete success condition, that's a signal to dispatch
the away team and investigate further, not a reason to skip planning
altogether.

If Yellow: just do the work. Don't manufacture ceremony for a one-line fix
— that's how a harness becomes slower than no harness at all.
