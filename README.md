# Self Caffeinate

macOS menu-bar app that toggles `/usr/bin/caffeinate -d` so the display stays awake. Coffee-cup icon in the status bar; no Dock icon.

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
5. Look in the menu bar for the cup icon. Click → **Caffeinate** / **Uncaffeinate**. Confirm with Activity Monitor or `pgrep -lf caffeinate`.
6. Commit and push from your Mac:
   ```bash
   git add SelfCaffeinate SelfCaffeinate.xcodeproj README.md SETUP.md
   git commit -m "Add SwiftUI MenuBarExtra caffeinate toggle"
   git push -u origin HEAD
   ```

Signing: use your personal team / “Sign to Run Locally”. App Sandbox is **off** so spawning `caffeinate` works.

More detail / File → New fallback: [SETUP.md](./SETUP.md)

## Behavior

| Menu | Meaning |
|------|---------|
| Status: **Caffeinated** / **Uncaffeinated** | Whether the child `caffeinate -d` is running |
| **Caffeinate** | Spawn `/usr/bin/caffeinate -d` |
| **Uncaffeinate** | Terminate that process |
| **Quit** | Uncaffeinate, then exit |

Icon: `cup.and.saucer` when off, `cup.and.saucer.fill` when on. `LSUIElement` = true → no Dock icon.

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
