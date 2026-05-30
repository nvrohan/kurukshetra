# 0004 — Godot's built-in MultiplayerAPI, not custom netcode

**Status:** Pending architecture approval (locked once deliverable 1 is approved)
**Date:** 2026-05-30

## Context

Network layer for the game can be:

1. **Godot's built-in MultiplayerAPI** — `MultiplayerSpawner`,
   `MultiplayerSynchronizer`, `@rpc` annotations, ENet/WebSocket transports.
2. **Custom netcode on raw UDP/TCP** — design our own packet format,
   replication, RPC system, etc.
3. **A third-party Godot plugin** (Nakama, Mirror-style ports).

## Decision

Godot's built-in MultiplayerAPI. ENet for LAN. WebSocket (WSS) over TLS
for WAN, terminating at the dedicated server's reverse proxy or
Cloudflare tunnel.

## Rationale

- **Built-in is good enough for 16 players at 30 Hz.** Godot's
  MultiplayerAPI handles spawning, replication, RPC, and authority
  marking out of the box. Confirmed by official Godot multiplayer demos
  and several community-shipped 16+ player games.
- **Custom netcode is a rabbit hole.** A correct, lag-tolerant,
  cheat-resistant netcode stack is months of work on its own. Not
  justified for an MVP.
- **Third-party plugins (Nakama etc.)** add a heavyweight backend that
  conflicts with our $0/month and self-host-a-VM constraint.
- **WebSocket over TLS for WAN** is the cleanest path through Indian
  mobile NATs. ENet-over-UDP is more efficient but more likely to be
  blocked or rate-limited by carrier middleboxes.

## Alternatives considered

- **ENet only.** Rejected for WAN: works in most cases but not all,
  especially CGNAT and corporate WiFi.
- **WebSocket only.** Rejected for LAN: ENet is materially lower latency
  on a clean network and we already have it for free.
- **Steam Networking / Epic OSS / Photon Fusion.** Rejected: not FOSS,
  vendor lock-in, often have Indian-region cost issues.

## Consequences

- We accept Godot's MultiplayerAPI quirks and limitations. If we hit a
  hard wall (e.g. need rollback netcode), we revisit in v0.2+, not v0.1.
- Server binary listens on both ENet (UDP) and WSS (TCP/443) and routes
  internally to the same authority logic.
- Cloudflare in front of WSS is free and gives us TLS termination + DDoS
  shield. Fall back to direct WSS on a Let's Encrypt cert if Cloudflare
  ever becomes unavailable.
