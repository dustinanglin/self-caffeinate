# Self Caffeinate

macOS menu-bar app with three caffeine modes (Off, Half-caf, Full). Coffee-cup icon in the status bar, no Dock icon, optional launch at login.

Repo: https://github.com/dustinanglin/self-caffeinate

## Install

Requires macOS 13+ and Xcode 15+.

```bash
git clone https://github.com/dustinanglin/self-caffeinate.git
cd self-caffeinate
scripts/install.sh
```

The script builds a Release copy, installs it to `/Applications/SelfCaffeinate.app`, and launches it. To start it automatically at login, open the cup menu and choose **Launch at Login**.

To develop instead, `open SelfCaffeinate.xcodeproj`, pick the **SelfCaffeinate** scheme and **My Mac**, and press Run. See [SETUP.md](./SETUP.md) for details.

## Behavior

| Mode | Process | Display |
|------|---------|---------|
| **Off / Uncaffeinated** | none | normal sleep |
| **Half-caf** | `/usr/bin/caffeinate` (no `-d`) | may sleep; idle sleep prevented |
| **Full / Caffeinated** | `/usr/bin/caffeinate -d` | stays on |

The menu (AppKit `NSMenu`) lists all three modes with a matching cup icon and a checkmark on the active one. Switching kills any current child process and starts the new one (or none for Off). **Quit** cleans up the child process.

**Launch at Login** registers the app with `SMAppService` (macOS 13+). The checkmark reflects the current state. If you turned the item off in System Settings, selecting it again opens the Login Items pane, since macOS will not re-enable it silently.

Global hotkeys (work while unfocused): **Ctrl+Option++** increase (Off→Half→Full), **Ctrl+Option+-** decrease. Clamped at the ends; keypad ± also works.

## Layout

```
SelfCaffeinate.xcodeproj/     ← open this in Xcode
SelfCaffeinate/
  SelfCaffeinateApp.swift     ← app lifecycle + quit cleanup
  StatusBarController.swift   ← status item, menu, launch-at-login toggle
  CaffeineController.swift    ← caffeinate process start/stop
  CaffeineHotkeys.swift       ← global hotkeys (Carbon)
  LoginItemController.swift   ← SMAppService wrapper
  Info.plist                  ← LSUIElement
  SelfCaffeinate.entitlements ← sandbox off
  Assets.xcassets/
scripts/
  install.sh                  ← build Release + copy to /Applications
```
