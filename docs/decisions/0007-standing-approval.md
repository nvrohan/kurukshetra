# 0007 — Standing approval mode (D3 → D6 autonomous)

**Status:** Accepted
**Date:** 2026-05-30
**Decided by:** Rohan

## Decision

Rohan grants **standing approval** for deliverables 3 through 6. The agent
executes them autonomously, pushing commits as it goes, and reports back
only when v0.1 is shipped (or when genuinely blocked on something
unrecoverable — paid-only tool, license conflict, infrastructure block).

**Verbatim from Rohan (2026-05-30):**

> *"From now on till its shipped consider as GO ..dont wait for my approval..
> complete the whole project and get back to me"*

## What this changes

The pre-existing working-style rule —

> *"After each deliverable, give me a short 'what's done / what's next /
> what's risky' summary, then wait for me to say 'go' before the next."*

— is **suspended for D3-D6**. Status summaries still get written (in commit
messages and a `STATUS.md` updated each deliverable), but the per-deliverable
human approval gate is removed.

## What this does NOT change

- Free-and-open-source-first rule still binding.
- All assets still must be CC0 / CC-BY (no exceptions).
- All decisions still get logged in `docs/decisions/000N-*.md`.
- ADR 0006 prototype scope still binding for D3.
- If the agent wants to do something off-scope of an existing ADR, it must
  write a new ADR justifying the change (no silent scope creep — this is
  load-bearing). New ADRs are auto-Accepted under this standing approval
  unless they involve paid services or proprietary dependencies.
- Agent must run real validation (Godot --headless tests) before declaring
  a deliverable done. No "should work" — must demonstrate it does.

## Cron continuation

To keep momentum across agent sessions (each turn caps long before D3-D6
fits), the agent will register a Hermes cron job that re-fires the goal
prompt every few hours. Each cron run reads STATUS.md, finds the next
incomplete deliverable, and continues.

The cron job stops itself after D6 ships (writes a "shipped" sentinel that
the cron prompt checks for).

## Reversibility

Rohan can cancel standing approval at any time by replying "hold" or
"stop" to a Telegram update. The cron continuation is also pausable via
`cronjob` action='pause'.
