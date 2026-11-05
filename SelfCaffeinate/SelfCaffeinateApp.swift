import SwiftUI
import AppKit

@main
struct SelfCaffeinateApp: App {
    @StateObject private var caffeine = CaffeineController()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            Text(caffeine.isCaffeinated ? "Caffeinated" : "Uncaffeinated")

            Divider()

            if caffeine.isCaffeinated {
                Button("Uncaffeinate") {
                    caffeine.uncaffeinate()
                }
            } else {
                Button("Caffeinate") {
                    caffeine.caffeinate()
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
            Image(caffeine.isCaffeinated ? "MenuBarCupFilled" : "MenuBarCupEmpty")
                .renderingMode(.template)
                .accessibilityLabel(caffeine.isCaffeinated ? "Caffeinated" : "Uncaffeinated")
                .onAppear {
                    appDelegate.caffeine = caffeine
                }
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var caffeine: CaffeineController?

    func applicationWillTerminate(_ notification: Notification) {
        caffeine?.uncaffeinate()
    }
}
