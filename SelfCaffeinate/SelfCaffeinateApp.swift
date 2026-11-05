import SwiftUI
import AppKit

@main
struct SelfCaffeinateApp: App {
    @StateObject private var caffeine = CaffeineController()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            Text(caffeine.mode.accessibilityLabel)

            Divider()

            ForEach(CaffeineMode.allCases, id: \.self) { mode in
                Button {
                    caffeine.setMode(mode)
                } label: {
                    Label {
                        HStack(spacing: 6) {
                            Image(mode.menuBarImageName)
                                .renderingMode(.template)
                            Text(mode.title)
                        }
                    } icon: {
                        // Keep leading checkmark column aligned for all rows.
                        Image(systemName: "checkmark")
                            .opacity(caffeine.mode == mode ? 1 : 0)
                    }
                }
            }

            if let lastError = caffeine.lastError {
                Divider()
                Text("Error: \(lastError)")
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Quit") {
                caffeine.uncaffeinate()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(caffeine.mode.menuBarImageName)
                .renderingMode(.template)
                .accessibilityLabel(caffeine.mode.accessibilityLabel)
                .onAppear {
                    appDelegate.attach(caffeine: caffeine)
                }
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeys = CaffeineHotkeys()
    private(set) var caffeine: CaffeineController?

    func attach(caffeine: CaffeineController) {
        self.caffeine = caffeine
        hotkeys.install(caffeine: caffeine)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeys.uninstall()
        caffeine?.uncaffeinate()
    }
}
