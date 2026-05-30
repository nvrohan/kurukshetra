# Attributions

Kurukshetra ships only assets under **CC0** or **CC-BY**. This file is the
authoritative manifest of every third-party asset in the repo, with source,
license, and attribution required by the original creator.

> **Hard rule:** any file in `assets/`, `maps/`, or `resources/` that has no
> entry below MUST fail the CI attribution check. See
> `tools/build_attributions.py` (deliverable 3+).

The MVP asset budget is documented in `docs/ARCHITECTURE.md` §5.

## v0.1 status

**No third-party assets imported yet.** The repo currently contains:

| File | License | Author | Notes |
|---|---|---|---|
| `icon.svg` | CC0 | Kurukshetra contributors | Drawn for this project (chakra placeholder) |

When deliverable 3 begins, every Kenney FPS Pack model, Freesound clip,
OpenGameArt texture, and Kenney UI sprite will be added to the table below
in this format:

```
| assets/models/weapon_pistol_p1.glb | CC0 | Kenney (kenney.nl) | Kenney FPS Pack v1.2 |
```

## License rules

| License | Allowed? | Attribution required in this file? |
|---|---|---|
| CC0 / Public Domain | Yes | No (we credit anyway as good practice) |
| CC-BY 3.0 / 4.0 | Yes | **Yes** — author + source URL + license URL |
| CC-BY-SA | **No** | — viral copyleft conflicts with MIT codebase + redistribution |
| CC-BY-NC | **No** | — non-commercial blocks Play Store / monetization later |
| CC-BY-ND | **No** | — no-derivatives blocks remixing/retexturing |
| GPL textures/audio | **No** | — keeps repo MIT-clean |
| "Free for personal use" | **No** | — too vague; ambiguous redistribution rights |
| Ripped from PUBG / BGMI / Free Fire / Krafton | **Absolutely no** | — non-negotiable |

## Trusted sources

- **Kenney.nl** — CC0, professional quality, recommended primary.
- **Freesound.org** — CC0 + CC-BY mix; filter to CC0 first.
- **OpenGameArt.org** — CC0 + CC-BY mix; check each asset.
- **ambientCG.com** — CC0 PBR textures.
- **Mixkit** — Free assets but check license per file (some are CC-BY-NC, skip those).

## Attribution format example (for CC-BY assets)

```
| assets/audio/wind_loop.ogg | CC-BY 4.0 | Erokia (freesound.org/people/Erokia) | https://freesound.org/s/123456/ |
```
