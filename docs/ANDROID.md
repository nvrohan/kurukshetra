# Android sideload guide

> Kurukshetra ships v0.1 as a **debug-signed APK** for sideload onto a stock
> Android phone. There is no Play Store listing yet — see
> [ADR 0010](decisions/0010-android-debug-keystore.md) for the rationale.

## Supported devices

| Spec            | Minimum                          |
|-----------------|----------------------------------|
| Android version | 5.0 Lollipop (API 21)            |
| Architecture    | arm64-v8a *or* armeabi-v7a       |
| RAM             | 2 GiB                            |
| Storage         | ≈100 MiB free                    |
| Network         | Wi-Fi or mobile data (UDP 30000) |

## Build the APK

On a Linux dev machine with Godot 4.3 + Android SDK + JDK 17 installed:

```bash
# One-time setup
./tools/gen-debug-keystore.sh

# Build
./tools/build-apk.sh
```

Output: `build/kurukshetra-debug.apk` (~47 MiB). The build script asserts
`aapt dump badging` succeeds and that the manifest reports
`package=dev.kurukshetra.app`, label `Kurukshetra`, and the four MVP
permissions (`INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`,
`VIBRATE`, `WAKE_LOCK`).

### Build prerequisites

| Tool                  | Notes                                                                  |
|-----------------------|------------------------------------------------------------------------|
| Godot 4.3             | `~/tools/godot/godot` or on PATH                                       |
| Godot export templates| `~/.local/share/godot/export_templates/4.3.stable/android_debug.apk`   |
| Android SDK           | `cmdline-tools` + `platform-tools` + `platforms;android-34` + `build-tools;34.0.0` |
| OpenJDK 17            | `sudo apt-get install default-jdk` (or equivalent)                     |
| Debug keystore        | `~/.local/share/godot/keystores/debug.keystore` (run `gen-debug-keystore.sh`) |

The build script reads `ANDROID_HOME` / `JAVA_HOME` env vars; defaults are
sensible for the project's reference VM.

## Sideload to your phone

### 1. Enable sideloading

On the phone:

1. **Settings → About phone → Build number** — tap 7 times to unlock
   *Developer options*.
2. **Settings → System → Developer options → USB debugging** — turn on.
3. **Settings → Security → Install unknown apps** — for whichever browser
   or file manager you'll use to open the APK, allow it.

### 2. Transfer the APK

Pick **one** transfer method:

- **adb (USB)** — fastest, works on any phone with USB debugging on:
  ```bash
  adb install -r build/kurukshetra-debug.apk
  ```
- **scp + file manager** — copy `kurukshetra-debug.apk` to the phone over
  Wi-Fi (Termux + sshd, KDE Connect, Snapdrop, Google Drive, etc.) and tap
  it in your file manager.
- **Email/cloud** — email the APK to yourself, download on the phone, tap.

### 3. Install + launch

- Tap the APK in the file manager → "Install".
- Android may warn "Play Protect couldn't scan this app" → tap *Install
  anyway*. (This is the expected behaviour for any non-Play-Store sideload;
  the APK is debug-signed by you, not by Google.)
- Find **Kurukshetra** in your launcher. Tap to launch.

### 4. Connect to a server

On the main menu, tap **Join match** → enter the server's IP or room code.
For local LAN play, both phones must be on the same Wi-Fi.

## Touch controls

- **Left joystick** (bottom-left) — move (analog).
- **Right joystick** (bottom-right) — look / aim (drag to rotate camera).
- **FIRE** (right side, bottom-right) — shoot the equipped weapon.
- **JUMP** — jump from standing or crouch (not from prone).
- **RELOAD** — reload current weapon.
- **[E]** — interact: pick up loot, hold to revive a downed teammate (5 s).
- **CROUCH** / **PRONE** (left side, above move stick) — toggle stance.

The touch HUD only renders on mobile / touch builds — on desktop dev
builds it auto-hides so it doesn't intercept mouse clicks.

## Troubleshooting

| Symptom                                              | Fix                                                                                       |
|------------------------------------------------------|-------------------------------------------------------------------------------------------|
| "App not installed"                                  | Uninstall any previous `dev.kurukshetra.app` build first, then retry.                     |
| "Parse error"                                        | The APK is corrupt or for a different architecture. Rebuild with `./tools/build-apk.sh`.  |
| Black screen on launch                               | Phone GPU may not support OpenGL ES 3 GL Compatibility profile. v0.1 targets ES 3.       |
| Touch controls don't respond                         | File a bug. Confirm by toggling *Settings → Developer options → Show taps* — taps must register on the on-screen widgets. |
| Server connection times out                          | Server must expose UDP 30000 (router NAT or OCI security list).                          |
| `adb install` says `INSTALL_FAILED_VERSION_DOWNGRADE`| Pass `-d` to `adb install` to allow downgrade, or uninstall first.                       |
| `aapt: command not found`                            | Add `$ANDROID_HOME/build-tools/34.0.0` to PATH, or set `ANDROID_HOME` for the build script. |

## Release-signing (post-MVP, not in v0.1)

The current APK uses the standard Android *debug* keystore (alias
`androiddebugkey`, password `android`). Per ADR 0010, this is fine for
sideloading but **not** acceptable for the Play Store or F-Droid. When v0.2+
is ready for distribution, generate a real keystore with `keytool` (24-year
validity), store it offline, and add a `release.keystore` lookup to
`build-apk.sh` gated on a `RELEASE=1` env var.
