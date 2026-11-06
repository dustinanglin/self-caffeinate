# Setup details

## Requirements

- macOS 13+
- Xcode 15+ (SwiftUI app lifecycle, `SMAppService`)

## Install as a standalone app

```bash
scripts/install.sh            # build, install to /Applications, launch
scripts/install.sh --no-open  # build and install only
```

The script quits any running copy first, replaces `/Applications/SelfCaffeinate.app`, and relaunches it. Re-run it after pulling changes.

Signing is "Sign to Run Locally" (ad-hoc). That is enough for an app you build on your own Mac: Gatekeeper only quarantines downloaded files, so no notarization is needed. The hotkeys use Carbon `RegisterEventHotKey` and need no Accessibility permission.

## Launch at login

1. Run the **installed** copy from `/Applications`, not the Xcode build. The login item records the bundle's path, and the DerivedData path changes on every rebuild.
2. Cup menu → **Launch at Login**. macOS shows a one-time notification that the app was added to login items.
3. To check or remove it outside the app: System Settings → General → Login Items & Extensions.

If the toggle shows an error or stays unchecked, the item was probably disabled in System Settings. Selecting it again opens that pane so you can re-enable it there.

## Run from Xcode

1. `open SelfCaffeinate.xcodeproj`
2. Scheme **SelfCaffeinate**, destination **My Mac**
3. Signing & Capabilities → Team = your Apple ID, or leave "Sign to Run Locally"; leave Sandbox **off**
4. Run (⌘R). The app is menu-bar only (`LSUIElement`).

Quit the installed copy before running from Xcode, or you will get two cup icons and two `caffeinate` processes.

## Verify

1. Menu bar cup → **Full** → status **Caffeinated**, filled cup.
2. Terminal: `pgrep -lf '/usr/bin/caffeinate'` shows a process with `-d`.
3. **Off** → process gone; status **Uncaffeinated**.
4. Caffeinate again, then **Quit** → process must exit.
5. `pmset -g assertions` also shows the active assertion while caffeinated.

## Notes

- `caffeinate -d` prevents **display** sleep; without `-d` it prevents idle sleep only.
- The child process is owned by the app; quitting always calls `terminate()`.
- App Sandbox is off so the app can spawn `/usr/bin/caffeinate`.
- Possible later change: IOKit `IOPMAssertion` instead of a subprocess.
