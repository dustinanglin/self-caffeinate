import SwiftUI
import AppKit

@main
struct SelfCaffeinateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu bar UI is AppKit (`StatusBarController`) so cup images + checkmarks work.
        // Settings scene keeps the SwiftUI app lifecycle without a Dock window.
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let caffeine = CaffeineController()
    private let hotkeys = CaffeineHotkeys()
    private var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBar = StatusBarController(caffeine: caffeine)
        hotkeys.install(caffeine: caffeine)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeys.uninstall()
        caffeine.uncaffeinate()
        statusBar?.remove()
        statusBar = nil
    }
}
