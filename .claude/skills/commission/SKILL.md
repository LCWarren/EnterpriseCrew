---
name: commission
description: Detect this project's stack and fill in the Standing Orders section of CLAUDE.md — test command, dev command, lint/typecheck, anything the harness needs to actually operate here. Run this first in any new project before other harness skills are useful. Auto-invokes when Standing Orders are still placeholder text.
---

# Commissioning

The harness itself (Data, Geordi, away-team, red-alert) is stack-independent
by design — none of it should ever need to change per project. Standing
Orders in `CLAUDE.md` is the one deliberate exception: it's the seam where
the general harness meets a specific codebase, and it has to be filled in
before the harness is actually useful here.

## What to do

1. **Detect the stack from the repo itself, don't ask first.** Look for
   `package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`,
   `go.mod`, `Gemfile`, `composer.json`, etc. Read the scripts/targets
   already defined there — most projects already declare their own test
   and dev commands, you're surfacing them, not inventing them.
2. **Infer, then confirm, don't guess silently.** If a test command is
   genuinely ambiguous (multiple test configs, monorepo with per-package
   scripts, no scripts section at all) ask the user rather than picking
   one arbitrarily. A wrong test command silently accepted here means
   Geordi runs the wrong thing for the life of the project.
3. **Keep it to the boring, load-bearing facts only:**
   - Language(s) and framework(s)
   - Exact command to run tests
   - Exact command to run the app locally, and any required setup (env
     vars, local services) to get there
   - Lint/typecheck command, if one exists
   - Any parts of the repo that need a flag, e.g. "don't touch the legacy
     directory without asking" — only if there's a real reason, not
     hypothetically
4. **Write it into the Standing Orders section of `CLAUDE.md`**, replacing
   the placeholder brackets. Keep it to the five or so lines this actually
   needs — this section is meant to stay short.
5. Do not add anything else to `CLAUDE.md` while you're in here. Log
   entries get added only after a real incident, not during setup.
