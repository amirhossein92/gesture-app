# GestureTabs

Switch browser/editor tabs with a trackpad gesture on macOS.

A free, open-source, lightweight alternative to apps like MiddleClick and
BetterTouchTool — it does one thing (tab switching from a trackpad tap) in a
tiny menu-bar agent, with no subscription and no bundled feature bloat.

- **Hold one finger, tap to its right** → next tab (`Ctrl+Tab`)
- **Hold one finger, tap to its left** → previous tab (`Ctrl+Shift+Tab`)

It lives in the menu bar (no dock icon) and posts the keystroke to whatever app
is frontmost, so it works anywhere `Ctrl+Tab` / `Ctrl+Shift+Tab` cycles tabs —
Chrome, Safari, VS Code, terminals, and more.

## Requirements

- macOS 11 (Big Sur) or later
- A trackpad (built-in or Magic Trackpad)
- Swift toolchain (Xcode or the Command Line Tools) to build

## How it works

- Reads raw per-finger trackpad positions from Apple's private
  `MultitouchSupport.framework`. The public `NSTouch` API only sees touches
  inside your own focused window, which is no good for a global listener.
- The first finger down is the **anchor**. A second finger that briefly taps and
  lifts beside it triggers a switch, based on which side of the anchor it tapped.
- Everything runs in a single process (the menu-bar app), so exactly one app
  needs Accessibility permission to post the keystrokes.

### What does *not* trigger it

- Two-finger taps, scrolls, and drags (the anchor lifts or both fingers stay
  down).
- Three- and four-finger swipes (any third finger disqualifies the gesture until
  the whole hand lifts).
- Swipes and scrolls in general (a swiping anchor drifts too far to count as
  "held").

> **Note:** `MultitouchSupport.framework` is a private Apple framework. That is
> fine for personal use and how tools like BetterTouchTool work, but it means
> this app cannot be shipped on the Mac App Store.

## Download

Prebuilt `GestureTabs.app.zip` is attached to each
[GitHub Release](../../releases) (built automatically on every push to `main`).
It is ad-hoc signed, not notarized, so on first launch either right-click →
**Open** or run `xattr -dr com.apple.quarantine /Applications/GestureTabs.app`.

To build it yourself instead, follow the steps below.

## Install (build from source)

```sh
git clone <this-repo> gesturetabs
cd gesturetabs
./make-icon.sh     # generate the app icon (AppIcon.icns)
./build-app.sh     # build, bundle, and ad-hoc sign
open GestureTabs.app
```

`build-app.sh` produces `GestureTabs.app`, a self-contained menu-bar agent. Move
it anywhere you like, e.g.:

```sh
cp -R GestureTabs.app /Applications/
```

### Grant Accessibility permission

Posting keystrokes requires Accessibility access. On first launch the app asks
for it; otherwise add it manually:

**System Settings → Privacy & Security → Accessibility** → enable **GestureTabs**.

Until it is granted, the app runs and detects gestures but cannot switch tabs.

### Start at login

**System Settings → General → Login Items** → add `GestureTabs.app`.

## Usage

The menu-bar item shows the state and controls the engine:

- `●` running · `○` stopped
- **Start** / **Stop** — toggle gesture detection
- **Quit**

## Tuning

Adjust the constants at the top of
[`Sources/GestureEngine/GestureEngine.swift`](Sources/GestureEngine/GestureEngine.swift):

| Constant | Meaning |
| --- | --- |
| `sideThreshold` | How far to the side the tap must land to count. |
| `tapMaxDuration` | How quick the tap must be. |
| `fireCooldown` | Debounce so one physical tap fires once. |
| `anchorMoveThreshold` | How far the anchor may drift and still count as "held". |
| `kVK_Tab` / flags in `switchTab` | Change the emitted keystroke. |

Rebuild with `./build-app.sh` after editing.

## Project layout

| Path | Role |
| --- | --- |
| `Sources/CMultitouch` | C declarations for the private `MultitouchSupport.framework`. |
| `Sources/GestureEngine` | Touch-frame gesture detection + keystroke posting. |
| `Sources/gesture-control` | Menu-bar app; runs the engine in-process. |
| `Sources/gesture-app` | Standalone CLI runner (handy for debugging in a terminal). |
| `tools/make-icon.swift` | Generates the app icon. |
| `build-app.sh`, `make-icon.sh` | Build the bundle and the icon. |

### Run from a terminal (debugging)

```sh
swift build -c release
./.build/release/gesture-app     # prints a warning if Accessibility is missing
```

## Notes and limitations

- **Ad-hoc signing:** `build-app.sh` signs with an ad-hoc identity, which changes
  on every rebuild. macOS may then ask you to re-grant Accessibility. To avoid
  that, sign with a stable self-signed or Developer ID certificate.
- Uses a private framework (see above); do not expect App Store distribution.

## License

MIT — see [LICENSE](LICENSE).
