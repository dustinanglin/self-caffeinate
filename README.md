# Self Caffeinate

macOS menu-bar app with three caffeine modes (Off, Half-caf, Full). Coffee-cup icon in the status bar; no Dock icon.

Cloud agents cannot push to `brexhq-private/self-caffeinate`. **Copy these files into a local clone, open in Xcode, Run, then push from your Mac.**

Repo: https://github.com/brexhq-private/self-caffeinate

## Quick start (under 5 minutes)

1. On your Mac, clone (or pull) the repo:
   ```bash
   git clone https://github.com/brexhq-private/self-caffeinate.git
   cd self-caffeinate
   ```
2. Copy **everything** from this `docs/self-caffeinate/` folder into the clone root (merge; keep existing README if you prefer, but keep the Xcode project and `SelfCaffeinate/` sources). From the Project Context / this folder:
   ```bash
   # Example: if you downloaded or synced the scaffold next to the clone
   cp -R SelfCaffeinate SelfCaffeinate.xcodeproj SETUP.md ./path/to/self-caffeinate/
   # Also copy this README if the repo README is empty
   ```
3. Open the project:
   ```bash
   open SelfCaffeinate.xcodeproj
   ```
4. In Xcode: select the **SelfCaffeinate** scheme → **My Mac** → press **Run** (⌘R).
5. Look in the menu bar for the cup icon. Click → choose **Off**, **Half-caf**, or **Full**. Confirm with `pgrep -lf caffeinate` / `pmset -g assertions`.

Signing: use your personal team / “Sign to Run Locally”. App Sandbox is **off** so spawning `caffeinate` works.

More detail / File → New fallback: [SETUP.md](./SETUP.md)

## Behavior

| Mode | Process | Display |
|------|---------|---------|
| **Off / Uncaffeinated** | none | normal sleep |
| **Half-caf** | `/usr/bin/caffeinate` (no `-d`) | may sleep; idle sleep prevented |
| **Full / Caffeinated** | `/usr/bin/caffeinate -d` | stays on |

Menu (AppKit `NSMenu`) lists all three with the matching cup icon before each label and a checkmark on the active mode only; switching kills any current child and starts the new one (or none for Off). **Quit** cleans up the child process.

Global hotkeys (work while unfocused): **Ctrl+Option+=** increase (Off→Half→Full), **Ctrl+Option+-** decrease (reverse). Clamped at the ends; keypad ± also works.

Icons: `MenuBarCupEmpty` / `MenuBarCupHalf` / `MenuBarCupFilled`. `LSUIElement` = true → no Dock icon.

## Layout

```
SelfCaffeinate.xcodeproj/     ← open this in Xcode
SelfCaffeinate/
  SelfCaffeinateApp.swift     ← MenuBarExtra UI + quit cleanup
  CaffeineController.swift    ← Process start/stop
  Info.plist                  ← LSUIElement
  SelfCaffeinate.entitlements ← sandbox off
  Assets.xcassets/
```
