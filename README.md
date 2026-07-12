# EnterpriseCrew

A small Claude Code harness built around one rule: ceremony has to earn its
keep. Every piece below exists because it maps to something with actual
evidence behind it — not because it made the workflow feel more thorough.

## Why this exists

Most "AI engineering discipline" harnesses add a lot of process (personas,
mandatory multi-phase pipelines, big rosters of specialized agents) without
much evidence it improves outcomes, and some of it demonstrably makes
things slower on tasks that didn't need it. This harness is the opposite
bet: keep it thin, gate ceremony behind actual task risk, and only include
a piece if there's a real mechanism for why it should help.

## What's in here and why

| Piece | File | What it does | Why |
|---|---|---|---|
| Picard | (you, the main agent) | Sole write authority. Nothing downstream acts unilaterally. | Reports from sub-agents are investigation, not authorization — someone has to own the decision to act on them. |
| Init | `.claude/skills/init/SKILL.md` | Installs the per-project enforcement layer (hooks, `settings.json`, `state/`) and merges `CLAUDE.md` into whatever project you run it in. | The plugin makes agents/skills global; this is the seam that opts a single project into the hook-enforced review gate, so ceremony only runs where you asked for it. |
| Commission | `.claude/skills/commission/SKILL.md` | Detects the stack from the repo itself and fills in `CLAUDE.md`'s Standing Orders — the one part of this harness that's project-specific by design. | Everything else here is stack-independent. This is the deliberate seam where it meets a real codebase, and it has to happen before anything else is useful. |
| Away team | `.claude/agents/away-team.md`, `.claude/skills/away-team/SKILL.md` | Read-only investigation, dispatched for bounded recon tasks, reports back. | Delegating read-heavy exploration to an isolated context is the one multi-agent pattern with real evidence behind it — it's how Anthropic's own research system beat single-agent performance. It's explicitly a poor fit for tightly-coupled write work, so it's kept read-only here on purpose. |
| Data | `.claude/agents/data.md` | Independent review of a proposed change, in a fresh context, scoped to logic/security/regressions only. Records the review so the Stop hook recognizes it. | The single best-evidenced idea in this space: a separate evaluator catches what a self-reviewing agent won't. Scoped narrow on purpose — mixing in style feedback tanks signal-to-noise and gets ignored. |
| Geordi | `.claude/agents/geordi.md` | Maps a change to the tests that actually exercise it, runs those, reports back. | Generic "write tests" instructions without the right context don't help and can make things worse. Impact-mapped, targeted verification is what actually reduces regressions. |
| Red alert | `.claude/skills/red-alert/SKILL.md` | Gates planning behind actual task risk instead of running it on everything. | A bad plan is worse than no plan, and forcing planning ceremony on trivial tasks is pure overhead. Gate it — and gate it inline, not with a dedicated sub-agent, since the classification itself is a one-line judgment call that doesn't need its own context window. |
| End of shift | `.claude/skills/end-of-shift/SKILL.md` | Writes a short handoff note to `.claude/state/handoff.md` before a session ends. | Context is ephemeral until it's on disk. A fresh session with a good handoff beats a compacted one with a degraded summary. |
| Captain's log | `CLAUDE.md` | Project memory, ratchet-style: an entry only earns its place after a real incident. | Long, aspirational memory files get skimmed past. Keep it short and tied to things that actually happened. |

### Hooks (the enforcement layer)

Instructions in `CLAUDE.md` are a request — a model can skip them under
pressure. Hooks are a guarantee — they run regardless of what the model
decides. That distinction is the whole reason this section exists.

| Hook | Event | What it does |
|---|---|---|
| `check-standing-orders.sh` | `SessionStart` | Detects placeholder text in Standing Orders and surfaces a notice to run `commission` first, before other work. |
| `show-handoff.sh` | `SessionStart` | Surfaces the last session's handoff note, if one exists. |
| `require-review.sh` | `Stop` | Blocks finishing on changes of 15+ lines that haven't been reviewed by Data. Small changes pass through with zero friction — this is not blanket ceremony, it's gated to the size of change that's actually shown to benefit from review. Fails open (doesn't block) if `jq` isn't installed, rather than silently blocking work over a missing dependency. |

## What's deliberately *not* in here

- No persona layer beyond naming — nothing suggests a character framing
  improves outcomes, it's cost without payoff.
- No mandatory phase sequence. Nothing forces every task through
  scope → plan → build → verify regardless of size.
- No multi-agent roster for the write path. Sub-agents here investigate;
  they don't get to make claims that go straight into a shipped change
  without Data checking them.
- No dedicated risk-classification agent (a "Worf"). Deciding whether a
  task is routine or high-risk is a one-line judgment call — giving it its
  own sub-agent would add latency and cost for something that doesn't need
  isolated context.

## Using it

EnterpriseCrew installs as a Claude Code **plugin** served from this repo
as a **marketplace**. That's what makes the agents and skills global —
available in every project, namespaced `/enterprise-crew:*`, the same way
any marketplace plugin works. The enforcement layer (hooks, review marker,
CLAUDE.md conventions) is deliberately *not* global — you opt a project in
with a one-time `init`, so a review gate never fires in a repo you didn't
choose to run it in.

### Install once (global)

```
/plugin marketplace add LCWarren/EnterpriseCrew
/plugin install enterprise-crew@enterprise-crew
```

Now `away-team`, `data`, `geordi`, and the skills are available in every
project. Requires `jq` for the review-enforcement hook — `winget install
jqlang.jq` (Windows), `brew install jq` (macOS), `apt install jq` (Debian).

### Per project (opt in)

1. In the project you want to use it on, run `/enterprise-crew:init`. It
   installs the hooks, `settings.json`, and `.claude/state/` into that
   project and merges its `CLAUDE.md` — without clobbering anything already
   there.
2. Run `commission`. The `check-standing-orders` hook notices the Standing
   Orders are still placeholders and prompts it; it detects your stack from
   the repo itself and fills in the real test/dev/lint commands, confirming
   with you only where it's genuinely ambiguous.
3. Work normally. `away-team` and `red-alert` auto-invoke when the context
   matches; call them explicitly if you want to force it.
4. On any change of real size, the `require-review` hook blocks you from
   finishing until you dispatch `data` to review the diff. Small changes
   never hit this — the threshold matches red-alert's own Yellow/Red split.
5. Before ending a session, run `end-of-shift` (or let Claude offer it) to
   write a handoff note. It surfaces automatically at the start of the next
   session.

> Prefer the old no-plugin flow? You can still drop `.claude/` and
> `CLAUDE.md` straight into a project root — the plugin layer is additive,
> not required.

**Note:** `.claude/state/` holds session-local files (`handoff.md`,
`last-review.json`). Add it to your project's `.gitignore` unless you
specifically want review/handoff history committed to the repo.

## Measuring whether it's actually helping

Don't track PR count or lines shipped — both inflate under AI assistance
without telling you anything useful. Track cycle time, defect/rework rate,
and review time on harness-assisted changes vs. a baseline. If review time
or defect rate climbs without a cycle-time win, strip the harness back
further rather than adding more process.
