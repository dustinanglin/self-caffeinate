import AppKit
import Combine

/// AppKit status item + `NSMenu` so cup template images and per-row checkmarks render correctly.
/// (SwiftUI `MenuBarExtra` menus collapse custom icons and treat opacity-0 checkmarks as present.)
final class StatusBarController: NSObject {
    private let caffeine: CaffeineController
    private let loginItem = LoginItemController()
    private var loginItemError: String?
    private let statusItem: NSStatusItem
    private var cancellables = Set<AnyCancellable>()

    init(caffeine: CaffeineController) {
        self.caffeine = caffeine
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.imageScaling = .scaleProportionallyDown
            button.setAccessibilityRole(.menuButton)
        }

        caffeine.$mode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        caffeine.$lastError
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        refresh()
    }

    func remove() {
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func refresh() {
        updateStatusButton()
        rebuildMenu()
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else { return }
        let mode = caffeine.mode
        if let image = NSImage(named: mode.menuBarImageName)?.copy() as? NSImage {
            image.isTemplate = true
            button.image = image
        }
        button.toolTip = mode.accessibilityLabel
        button.setAccessibilityTitle(mode.accessibilityLabel)
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let status = NSMenuItem(
            title: caffeine.mode.accessibilityLabel,
            action: nil,
            keyEquivalent: ""
        )
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        for mode in CaffeineMode.allCases {
            let item = NSMenuItem(
                title: mode.title,
                action: #selector(selectMode(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = mode.menuTag
            // Native menu checkmark — only the active mode is `.on`.
            item.state = caffeine.mode == mode ? .on : .off
            if let image = NSImage(named: mode.menuBarImageName)?.copy() as? NSImage {
                image.isTemplate = true
                item.image = image
            }
            menu.addItem(item)
        }

        if let lastError = caffeine.lastError {
            menu.addItem(.separator())
            let errorItem = NSMenuItem(
                title: "Error: \(lastError)",
                action: nil,
                keyEquivalent: ""
            )
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        menu.addItem(.separator())

        let launchAtLogin = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchAtLogin.target = self
        launchAtLogin.state = loginItem.isEnabled ? .on : .off
        if loginItem.requiresApproval {
            launchAtLogin.toolTip = "Disabled in System Settings › Login Items. Select to open that pane."
        }
        menu.addItem(launchAtLogin)

        if let loginItemError {
            let errorItem = NSMenuItem(
                title: "Error: \(loginItemError)",
                action: nil,
                keyEquivalent: ""
            )
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard let mode = CaffeineMode.from(menuTag: sender.tag) else { return }
        caffeine.setMode(mode)
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            try loginItem.setEnabled(!loginItem.isEnabled)
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
        }
        rebuildMenu()
    }

    @objc private func quitApp(_ sender: NSMenuItem) {
        caffeine.uncaffeinate()
        NSApplication.shared.terminate(nil)
    }
}

private extension CaffeineMode {
    var menuTag: Int {
        switch self {
        case .off: return 0
        case .half: return 1
        case .full: return 2
        }
    }

    static func from(menuTag: Int) -> CaffeineMode? {
        switch menuTag {
        case 0: return .off
        case 1: return .half
        case 2: return .full
        default: return nil
        }
    }
}
