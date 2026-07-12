---
name: init
description: Install EnterpriseCrew's per-project enforcement layer into the current project — the Stop-hook review gate, the SessionStart hooks, the state directory, and the CLAUDE.md conventions. Run this once per project after installing the EnterpriseCrew plugin. The agents (away-team, data, geordi) and other skills are already global via the plugin; this adds the project-scoped pieces that can't be global.
---

# Commissioning a project (init)

The EnterpriseCrew plugin ships the stack-independent pieces globally: the
agents (away-team, data, geordi) and the skills (away-team, red-alert,
commission, end-of-shift). Those work in every project with no per-project
setup.

What is deliberately *not* global is the **enforcement layer**: the Stop
hook that blocks finishing on an unreviewed non-trivial change, the
SessionStart hooks, the `.claude/state/` review marker, and the CLAUDE.md
conventions. A review gate firing in every git repo you happen to open
would be exactly the un-earned ceremony this harness exists to avoid. So
you opt a project in by running this once.

## What to do

Work against the **project root** (the directory Claude Code was started
in — `$CLAUDE_PROJECT_DIR`, falling back to the current working
directory). Do not assume a subdirectory.

### 1. Confirm this is a git repo
Run `git rev-parse --is-inside-work-tree`. If it is **not** a git repo,
stop and tell the user: the `require-review.sh` Stop hook keys off
`git diff` and silently no-ops outside a repo, so the enforcement layer
would be inert. Let them decide whether to `git init` first.

### 2. Create the directories
Create `.claude/hooks/` and `.claude/state/` under the project root if they
don't already exist. Create `.claude/state/.gitkeep` (empty).

### 3. Write the three hook scripts
Write these verbatim into `.claude/hooks/`, then mark them executable
(`chmod +x .claude/hooks/*.sh`). If a file already exists with identical
content, leave it. If it exists but differs, show the diff and ask before
overwriting.

**`.claude/hooks/check-standing-orders.sh`**
```bash
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
```

**`.claude/hooks/show-handoff.sh`**
```bash
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
```

**`.claude/hooks/require-review.sh`**
```bash
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
echo "This change is $LINES_CHANGED lines across $FILES_CHANGED file(s) — above the routine threshold and not yet reviewed. Dispatch the 'data' subagent to review the current diff before finishing. Data will record the review automatically once it completes (see the data agent). If Data has already run but this still blocks, the diff changed since — re-run Data on the current state." >&2
exit 2
```

### 4. Write / merge `.claude/settings.json`
If the project has **no** `.claude/settings.json`, write this:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/check-standing-orders.sh" },
          { "type": "command", "command": "bash .claude/hooks/show-handoff.sh" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/require-review.sh" }
        ]
      }
    ]
  }
}
```
If a `settings.json` already exists, **merge** — add the three hook entries
into the existing `SessionStart` / `Stop` arrays without dropping anything
already there. Never blindly overwrite it. Validate the result parses
(`python -m json.tool` or `jq . `).

### 5. Merge `.gitignore`
Append these two lines if they are not already present (do not rewrite the
file):
```
.claude/state/handoff.md
.claude/state/last-review.json
```
The `.claude/state/` files are session-local. Everything else under
`.claude/` (hooks, settings, agents/skills if any are project-local) is
meant to be committed.

### 6. Merge `CLAUDE.md`
- If there is **no** `CLAUDE.md`, create one from the template below.
- If one **exists**, leave the project's own content intact and append the
  "Standing Orders" and "Review discipline" sections under a clear
  `# EnterpriseCrew` heading if they aren't already there. Do not duplicate
  sections that already exist.

Template (only the harness-relevant sections — keep any existing project
content above it):
```markdown
## Standing Orders (fill in for your project)
- Stack: [languages, frameworks]
- How to run tests: [command]
- How to run the app locally: [command]
- Things Claude keeps getting wrong that aren't worth a full log entry yet:
  [short list, promote to a log entry once it recurs]

## Review discipline
- No non-trivial change (roughly 15+ lines) is "done" until the `data`
  agent has reviewed it in a fresh context. This is enforced by the
  `require-review.sh` Stop hook — it can't be silently skipped under
  deadline pressure. Small changes pass through with no friction.
- away-team reports are investigation findings, not verified facts.
  Anything a report claims about existing behavior gets checked against
  the actual code before anyone builds on it.
```

### 7. Check `jq`
Run `command -v jq`. If missing, tell the user the Stop hook **fails open**
(blocks nothing) until `jq` is installed — `winget install jqlang.jq` on
Windows, `brew install jq` on macOS, `apt install jq` on Debian/Ubuntu.
Don't install a system package without asking.

### 8. Point them at `commission`
The Standing Orders you just wrote (or the placeholder) need the project's
real stack/test/dev commands. Tell the user to run `commission` next (or
run it now if the stack is obvious from the repo). The SessionStart hook
will nag about placeholder Standing Orders until commission fills them in.

## Done when
- `.claude/hooks/` has all three scripts, executable
- `.claude/settings.json` wires 2 SessionStart hooks + 1 Stop hook
- `.claude/state/` exists with `.gitkeep`
- `.gitignore` ignores the two state files
- `CLAUDE.md` has Standing Orders + Review discipline
- `jq` confirmed (or the user warned it's missing)
