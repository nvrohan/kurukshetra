# 0001 — Project name: Kurukshetra

**Status:** Decided
**Date:** 2026-05-30
**Decided by:** Rohan

## Decision

The project is called **Kurukshetra** (कुरुक्षेत्र).

- GitHub repo name: `kurukshetra`
- Android package id: `com.<owner>.kurukshetra` (final owner segment chosen at deliverable 2)
- Display name in `project.godot` `application/config/name`: `Kurukshetra`
- Domain (when reserved): `kurukshetra.app` / `.in` / `.com` — to verify availability at deliverable 2 time

## Why

Kurukshetra is the legendary battlefield of the Mahabharata, where the
Kauravas and Pandavas fought their 18-day war. As a name for a battle
royale it is:

- **Thematically perfect.** A BR is a battlefield with a shrinking circle;
  Kurukshetra is *the* archetypal Indian battlefield. The whole gameplay
  loop maps onto Mahabharata imagery cleanly: 4 squads → Kuru-clan
  factions, zone shrink → Krishna's tightening discus, knockdown/revive →
  warrior fallen but not yet on the field of dharma, etc.
- **Aligned with Rohan's YT channel**, which is mythology-crime focused.
  Marketing surface area is automatic — the channel and the game promote
  each other.
- **Free of trademark risk.** Kurukshetra is (a) a real city in Haryana,
  India, and (b) a 5000-year-old mythological place name. USPTO and
  IndiaTM both reject trademark applications on generic
  geographic/mythological terms unless paired with distinctive branding
  (e.g. "Kurukshetra Studios" *might* be registrable; "Kurukshetra"
  alone is not). Two films share the name (2008 Tamil, 2019 Kannada),
  but films are a different IP class with no gaming-industry overlap.
- **Free of GitHub conflict.** Searched 2026-05-30: ~10 hobby/student
  repos exist (≤1 star each, none commercial games). Effectively wide
  open as a project name.

## Trade-offs

- **Pronounceability for non-Indian audiences.** Foreign players will
  initially mispronounce it. Mitigation: a 2-second pronunciation
  voiceover in the lobby splash, plus on-screen Devanagari + Latin
  transliteration. This is a feature, not a bug — it leans into the
  cultural identity of the game.
- **Cannot be trademarked.** We can't stop someone else from making a
  game called Kurukshetra later. Mitigation: build distinctive branding
  around it (logo, color palette, mythological squad-faction visual
  language) and trademark *those* if it ever matters. The name itself
  is shared cultural heritage — that's a feature.
- **Some Hindu-cultural resonance some players may not want.** It's a
  battlefield from the Mahabharata, which is sacred Hindu literature.
  Most Indians will read this as celebratory; a small minority may
  consider any combat reframing of Mahabharata imagery disrespectful.
  We are not depicting Krishna, Arjuna, or any specific named character
  in v0.1, only the battlefield itself — keeps the cultural footprint
  light.

## What this locks in

- GitHub repo: `<owner>/kurukshetra`
- Godot project name: `Kurukshetra`
- Android package: `com.<owner>.kurukshetra`
- All `<name>` placeholders in the architecture doc, decision logs, and
  `README.md` resolve to `kurukshetra`.

## Alternatives considered (now rejected)

| Name | Why rejected |
|---|---|
| Akhada Royale | Solid but less iconic than Kurukshetra; "Royale" has battle-royale-cliché baggage |
| Maidan Drop | Generic; doesn't carry mythological weight |
| Lokayudh | Strong but less recognizable internationally |
| Dharma Drop | Too theological for casual marketing |
| Ranbhoomi | Good but Kurukshetra is the more iconic synonym |
| FreeFire-Free Battle | Garena trademark risk; original placeholder only |
