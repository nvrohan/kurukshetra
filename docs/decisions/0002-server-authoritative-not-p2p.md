# 0002 — Server-authoritative, not peer-to-peer

**Status:** Pending architecture approval (locked once deliverable 1 is approved)
**Date:** 2026-05-30

## Context

For 16-player BR matches, two networking models are realistic:

1. **Server-authoritative dedicated server** — one process owns game state,
   clients send inputs, server simulates and broadcasts snapshots.
2. **Peer-to-peer with one host as authority** — host's machine runs the
   sim, other clients connect directly to the host.

## Decision

Server-authoritative dedicated server, hosted on Oracle Cloud Always Free
(ARM A1 instance, 2 OCPU + 12 GB RAM, $0/month forever). Fly.io free tier
as fallback. LAN mode reuses the same server binary running on a phone or
laptop on the local network.

## Rationale

- **Cheating posture.** P2P trusts the host completely. With a dedicated
  server we at least gate teleport, speed, ammo, and damage cheats at the
  server, even if client-side wallhacks still get through in v0.1.
- **NAT traversal.** P2P over the open internet needs STUN/TURN. Free TURN
  relays don't exist at consumer scale; running our own costs money.
  Indian mobile carriers (Jio, Airtel) increasingly use CGNAT, which makes
  hole-punching unreliable — exactly the audience we're targeting.
- **Host migration.** P2P needs host migration on disconnect; this is
  multi-week engineering on its own. Dedicated server: host disconnect is
  irrelevant.
- **Free hosting exists.** OCI Always Free gives us 4 OCPU + 24 GB RAM ARM
  forever. A 30 Hz Godot headless server for 16 players uses well under
  half of that. Free tier policy includes "always free" guarantee per
  Oracle's published terms.
- **Bandwidth math.** 16 players × ~25 KB/s downstream × 3600s = 1.4 GB/h.
  OCI free tier includes 10 TB/mo egress. ~7000 match-hours/month before
  hitting cap. Not a real constraint.

## Alternatives considered

- **P2P with relay fallback.** Rejected: relay costs money or is unreliable.
- **Listen server (one player's phone hosts).** Rejected for WAN use:
  Indian mobile uplinks don't sustain 400 KB/s combined egress reliably,
  and the host's match experience would degrade. Acceptable for **LAN
  only** mode — the same server binary runs locally.
- **Authoritative client + lockstep.** Rejected: works for RTS, not for
  twitch shooters with travel-time bullets. Adds rollback complexity we
  don't want for v0.1.

## Consequences

- We must keep the server build green for `linuxbsd_arm64` from day 1.
- We must build a "match manager" parent process by v0.2 if we want
  multiple concurrent matches per VM (v0.1 = one match per process, one
  process per port).
- LAN-mode UX: one player picks "Host LAN match"; their phone or laptop
  runs the server; others enter the local IP. No internet needed.
- We accept that v0.1 has minimal anti-cheat and document it openly in
  the architecture doc.
