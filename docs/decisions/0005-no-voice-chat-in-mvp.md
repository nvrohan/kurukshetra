# 0005 — No in-game voice chat in v0.1

**Status:** Pending architecture approval (locked once deliverable 1 is approved)
**Date:** 2026-05-30

## Context

Squad shooters live or die on coordination, which usually means voice.
Options for voice in v0.1:

1. Build it in. Capture mic, encode (Opus), forward via the game server,
   decode and play on each squadmate's client.
2. Use an external app. Players join a Discord call or Mumble server and
   the game stays silent.
3. Skip voice entirely.

## Decision

Skip voice in v0.1. **Recommend Discord/Mumble out-of-band.** Add native
voice no earlier than v0.2.

## Rationale

- Voice is its own engineering project: capture permissions on Android,
  Opus codec, push-to-talk UX, voice activity detection, mute/squad
  channels, bandwidth budget, echo cancellation on phone speakers.
- Our audience already uses Discord. Friends-with-friends is exactly the
  group that has a Discord call going anyway.
- Server bandwidth headroom: native voice would add ~12 KB/s per active
  speaker. Manageable, but not for free — and adds a non-trivial server
  CPU cost (mixing, rebroadcast).
- Doing voice badly is worse than not doing it. Half-broken voice with
  echo and dropouts will ruin matches. Discord just works.

## Alternatives considered

- **WebRTC SFU (e.g. mediasoup).** Rejected: another service to host,
  another dependency, free-tier-unfriendly.
- **Mumble bridge.** Interesting but adds an external server users have to
  configure. Same friction as "join a Discord call."
- **In-game voice via Godot AudioServer + custom RPC.** This is what we'd
  build in v0.2 if voice is requested. Defer.

## Consequences

- v0.1 README and lobby screen tell players to use Discord/Mumble.
- We do **not** request `RECORD_AUDIO` permission in the v0.1 APK. Cleaner
  install warning, less scary for friends sideloading.
- v0.2 voice is on the post-MVP list and will need its own architecture
  decision record.
