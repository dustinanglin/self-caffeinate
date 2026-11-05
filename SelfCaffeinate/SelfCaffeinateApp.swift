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
                    if caffeine.mode == mode {
                        Label(mode.title, systemImage: "checkmark")
                    } else {
                        Text(mode.title)
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
