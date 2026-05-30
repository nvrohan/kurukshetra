# 0006 — Deliverable 3 prototype scope (frozen)

**Status:** Accepted (ratified by Rohan 2026-05-30 via standing approval — "consider as GO till shipped")
**Date:** 2026-05-30
**Decided by:** Rohan

## Decision

Deliverable 3 (the local-multiplayer prototype) is scoped to **the smallest
end-to-end loop that proves authority + simulation + shrink mechanics work**
with **two clients on the same machine**, with **zero third-party assets**.

Anything not on this list is deferred to D5+.

### IN scope (D3)

| # | Feature | Acceptance criterion |
|---|---|---|
| 1 | `NetworkManager.host_match()` real impl | ENetMultiplayerPeer listens on port 30000; logs "host listening" |
| 2 | `NetworkManager.join_match("127.0.0.1", 30000)` | Second client connects; `peer_connected` signal fires on both sides |
| 3 | `Player.tscn` (CharacterBody3D) | Capsule body, third-person `SpringArm3D` camera, gravity, runs at 4 m/s walk / 7 m/s sprint |
| 4 | Multiplayer-replicated player position | Movement on client A is visible to client B within ≤ 100 ms (LAN, no prediction yet) |
| 5 | One weapon (`Weapon_Stub`) | Hitscan raycast on `fire`; rate-limited server-side to 600 RPM; deals 25 damage |
| 6 | Damage + HP | Each Player has 100 HP server-authoritative; reaching 0 → "dead" state (input disabled, no respawn yet) |
| 7 | `ZoneManager` (server-only) | Shrinking circle XZ-plane; phases 0–2 only (full → 350 m → 220 m), 90 s wait + 60 s shrink each. Phases 3–6 deferred. |
| 8 | Damage outside zone | 1 HP/s in phase 1, 2 HP/s in phase 2 — server-tick'd |
| 9 | Playground map | 200 × 200 m flat plane, 4 cubes as cover, 4 spawn points (one per cardinal direction). NO Kenney assets yet. |
| 10 | Two-process local launch script | `tools/run-prototype.sh` opens server-headless + 2 clients pointed at 127.0.0.1 |

### OUT of scope (deferred to D4+)

- Crouch / prone / jump (only walk + sprint in D3)
- Loot / crates / rarity tiers
- Knockdown / revive / squads
- Stamina
- Recoil / spread / range falloff
- Phases 3–6 of zone shrink
- Touch controls (D5)
- Kenney FPS Pack models (D5 — D3 uses Godot primitives)
- ATTRIBUTIONS.md asset entries (no third-party assets in D3)
- Audio
- HUD / kill feed / damage numbers
- WAN networking / dedicated server (D4)
- Anti-cheat beyond "server runs the simulation"
- Client-side prediction (basic snapshot interpolation only)
- Animation blending (capsules don't animate)

## Why this scope

- **Validates the loop** per the brief: "moveable character + one weapon + zone shrink" — exactly what's listed.
- **Two clients on `127.0.0.1`** removes every external variable (no router, no firewall, no friend availability). If the loop works locally, LAN-on-WiFi works trivially in D5 testing; if it doesn't, we'd burn weeks chasing a network issue that's actually a logic bug.
- **No third-party assets** keeps `ATTRIBUTIONS.md` simple and lets us iterate on logic without redownloading 200 MB of Kenney FBXes every git clone. Capsules-and-cubes is honest "prototype phase" art.
- **Phases 0–2 only** of the zone proves the manager works without forcing us to balance damage curves for all 6 phases before we've felt the pacing once.
- **No knockdown/revive in D3** because that's a 3-player minimum mechanic; we're doing 2-client validation.

## Acceptance criterion for "D3 done"

```
1. Run tools/run-prototype.sh
2. Server window opens (headless), both client windows show the playground
3. Both capsules can move; A sees B move; B sees A move
4. A can shoot B (hitscan ray + HP decrement)
5. After 90 s, blue zone visibly starts shrinking; capsule outside
   ring takes damage at 1 HP/s; phase 2 transition fires at ~150 s
6. Closing one client doesn't crash the other or the server
```

When that 6-step checklist passes locally, D3 ships.

## Estimated commit count

- 1: NetworkManager real impl + tools/run-prototype.sh
- 2: Player.tscn + player.gd + camera
- 3: Movement replication + tests
- 4: Weapon stub + raycast + damage
- 5: ZoneManager phases 0–2
- 6: Playground map + spawn points
- 7: D3 done summary

~7 commits, can be a single PR or main-pushes per your preference.

## What this ADR locks in

If during D3 implementation we want to add anything outside the IN-scope list,
we **stop, write ADR 0007**, get Rohan's approval, then continue. No silent
scope creep.

## Alternatives considered

| Approach | Why rejected |
|---|---|
| Full §4 player controller (sprint/crouch/prone/jump + stamina) in D3 | 3× the work for D3; nothing about it is needed to validate networking. Defer. |
| Use Kenney FPS Pack assets in D3 | Adds asset-pipeline work + ATTRIBUTIONS gating to a sprint that's about netcode. Defer to D5 where APK + assets land together. |
| Full 6-phase zone in D3 | Phases 3–6 require proper damage tuning that's hard to do without all weapons + armor in. Defer. |
| Skip zone entirely in D3, do only movement + shooting | Brief explicitly lists zone shrink in D3. Keep it, but truncate to phases 0–2. |
| Real LAN test with two phones in D3 | Touch controls aren't ready until D5. Two desktop clients on 127.0.0.1 is the cheapest validation path. |

---

**Awaits Rohan's "go" before any code is written.**
