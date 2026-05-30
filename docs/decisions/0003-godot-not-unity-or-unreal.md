# 0003 — Godot 4.3+, not Unity or Unreal

**Status:** Pending architecture approval (locked once deliverable 1 is approved)
**Date:** 2026-05-30

## Context

Three credible engine choices for a 3D Android multiplayer shooter in 2026:
Godot 4.3+, Unity 6, Unreal Engine 5.

## Decision

Godot 4.3+. GDScript primary, GDExtension/C++ available for hot paths
(probably none in v0.1).

## Rationale

| Axis | Godot 4.3+ | Unity 6 | Unreal 5 |
|---|---|---|---|
| License | MIT, free forever | proprietary, runtime fee saga 2023-24 | EULA, 5% revenue share over $1M |
| Source available | full | partial (paid) | partial (under EULA) |
| Android APK overhead | ~30 MB | ~80 MB | ~150 MB |
| Builtin multiplayer | MultiplayerAPI (ENet, WebSocket) | Netcode for GameObjects (decent), historically fragmented | Replication graph (powerful, complex) |
| Mid-range Android perf | great with Vulkan + GLES3 fallback | fine | tight; requires aggressive feature trimming |
| Editor on Linux dev VM | first-class | second-class (works) | painful |
| FOSS alignment with Rohan's stack | yes | no | no |

For a 16-player squad shooter on mid-range Android, all three are
*technically* capable. Godot wins on every other axis that matters for
this project: licensing, APK size, FOSS principle, dev-machine support.

## Alternatives considered

- **Unity 6** — runtime fee retreat plus deeper-than-Godot mobile tooling.
  Rejected on licensing principle and APK overhead. We don't want to be
  one policy change away from refactoring.
- **Unreal 5** — best-in-class graphics, overkill for a CC0-art BR. APK
  size and battery drain on mid-range Android phones is the deal-breaker.
- **Custom engine / raylib / bgfx** — rejected as scope explosion.
- **Godot 3.x** — rejected: 3D and networking are materially weaker than 4.x.

## Consequences

- Pin to a specific Godot 4.x version in CI. Upgrade deliberately, with a
  branch. Don't auto-upgrade on patch releases.
- Android export templates must match the engine version exactly. Bake
  this into the build script.
- If we ever need GDExtension/C++ for a hot path (unlikely in v0.1), we
  pay the cross-compile cost for ARM Android then.
- We can't use Unity Asset Store / Unreal Marketplace assets (license
  incompatible with FOSS distribution anyway). All assets come from
  CC0/CC-BY sources per § 5 of the architecture doc.
