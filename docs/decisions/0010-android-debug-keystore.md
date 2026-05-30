# ADR 0010 — Android: debug-keystore self-signed APK for v0.1

Date: 2026-05-30
Status: Accepted
Supersedes: —
Superseded by: —

## Context

Deliverable 5 (D5) ships an Android APK so Rohan can playtest on a real
phone. The APK has to be signed (Android refuses to install unsigned APKs
since 4.0 / 2011). There are three common signing paths for a fresh hobby
project:

1. **Debug keystore** — the same `androiddebugkey` / password `android`
   that Android Studio auto-generates for every dev. Self-signed, instant,
   no cost.
2. **Release keystore** — a one-off RSA keypair generated with `keytool`
   and held offline by the developer. Required for Play Store and most
   F-Droid distribution paths. Loss = permanent loss of the ability to
   ship updates under the same package name.
3. **Play App Signing / F-Droid signing** — Google or F-Droid hold the
   release key; you upload an unsigned bundle. Lower key-loss risk, but
   requires a Play Console (~$25 one-time) or F-Droid metadata PR.

## Decision

For **v0.1 only**, ship a **debug-keystore self-signed APK** named
`kurukshetra-debug.apk`. Every dev / CI runner generates their own debug
keystore via `tools/gen-debug-keystore.sh` (idempotent; output not
committed). The APK is intended for **sideload only** (USB ADB or
file-transfer + tap-to-install).

The release-signing flow is explicitly out of scope until at least v0.2:

- No Play Store listing (would need a release keystore + Play Console
  account + crash-free Android-policy review).
- No F-Droid listing (would need a stable release keystore, reproducible
  build metadata, and an F-Droid PR — fine post-MVP, premature now).
- A release keystore *will* be generated when v0.2 release-readiness work
  starts; the keystore lives outside the repo, the APK build script will
  grow a `RELEASE=1` env-flag path that swaps to it, and the public-key
  fingerprint will be pinned in this ADR.

## Consequences

### Positive

- Zero cost. No Play Console fee, no F-Droid PR, no manual key-rotation
  policy yet.
- Reproducible: anyone can clone the repo, run two scripts, and produce
  an APK byte-for-byte equivalent (modulo the keystore, which is
  per-machine).
- The standard debug keystore credentials are public knowledge, so no
  secret-management is needed for v0.1.

### Negative

- Users must enable *Install unknown apps* on their phone, which Google
  flags as a security warning. Documented in `docs/ANDROID.md`.
- Play Protect will warn "couldn't scan this app". Same root cause; same
  doc.
- Cannot publish to Play Store or F-Droid without changing keystores.
  Acceptable: v0.1 is for Rohan's personal playtest, not a public launch.
- Updates from v0.1 → v0.2 will require an uninstall + reinstall on the
  phone (because the release keystore signature won't match the v0.1
  debug-keystore signature). That's a once-in-the-project's-lifetime
  break; documented in this ADR for posterity.

## References

- Android signing docs: https://developer.android.com/studio/publish/app-signing
- Godot Android export: https://docs.godotengine.org/en/4.3/tutorials/export/exporting_for_android.html
- ADR 0007 (standing approval): the debug-keystore choice falls under the
  "free, open-source, no paid tools" rule.
- ADR 0008 (manual handoffs): release-keystore generation is the next
  manual handoff Rohan owns; tracked there for v0.2 planning.
