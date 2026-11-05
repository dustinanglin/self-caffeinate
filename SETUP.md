# Setup details

## Requirements

- macOS 13+
- Xcode 15+ (SwiftUI `MenuBarExtra`)
- Local git access to https://github.com/brexhq-private/self-caffeinate

## Copy into the clone

Put the scaffold at the **repo root** so paths match the Xcode project:

```
self-caffeinate/                 ← git clone root
  README.md
  SETUP.md
  SelfCaffeinate.xcodeproj/
  SelfCaffeinate/
    SelfCaffeinateApp.swift
    CaffeineController.swift
    Info.plist
    SelfCaffeinate.entitlements
    Assets.xcassets/
```

If the private repo already has files, merge carefully: keep the `SelfCaffeinate/` sources and `.xcodeproj` from this scaffold.

## Run

1. `open SelfCaffeinate.xcodeproj`
2. Scheme **SelfCaffeinate**, destination **My Mac**
3. Signing & Capabilities → Team = your Apple ID / Brex team; leave Sandbox **off**
4. Run (⌘R). App is menu-bar only (`LSUIElement`).

## Verify

1. Menu bar cup → **Caffeinate** → status **Caffeinated**, filled cup.
2. Terminal: `pgrep -lf '/usr/bin/caffeinate'` should show a process with `-d`.
3. **Uncaffeinate** → process gone; status **Uncaffeinated**.
4. Caffeinate again, then **Quit** → process must exit.

## Fallback: File → New (if `.xcodeproj` will not open)

1. Xcode → **File → New → Project → macOS → App**
2. Product Name: `SelfCaffeinate`, Interface: **SwiftUI**, Language: **Swift**
3. Replace the generated `App` file with `SelfCaffeinateApp.swift` and add `CaffeineController.swift`
4. Target → **Info**: set **Application is agent (UIElement)** / `LSUIElement` = YES (or use the provided `Info.plist`)
5. Target → **Signing & Capabilities**: remove App Sandbox if present
6. Delete any WindowGroup-only template UI; keep only `MenuBarExtra`
7. Run on My Mac

## Push from your Mac

Cloud / Cursor workers cannot access this private repo. After it runs:

```bash
git add SelfCaffeinate SelfCaffeinate.xcodeproj README.md SETUP.md
git status
git commit -m "Add SwiftUI MenuBarExtra caffeinate toggle"
git push -u origin HEAD
```

## Notes

- `caffeinate -d` prevents **display** sleep (same as Terminal).
- Child process is owned by the app; quitting always calls `terminate()`.
- Optional later: IOKit `IOPMAssertion` instead of a subprocess (see project feasibility doc).
