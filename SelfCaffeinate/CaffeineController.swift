import Foundation
import Combine

/// Caffeination level for the menu-bar app.
enum CaffeineMode: Equatable, Hashable, CaseIterable {
    /// No `caffeinate` child process.
    case off
    /// `/usr/bin/caffeinate` with no flags (prevents idle sleep; display may sleep).
    case half
    /// `/usr/bin/caffeinate -d` (display stays on).
    case full

    var title: String {
        switch self {
        case .off: return "Off / Uncaffeinated"
        case .half: return "Half-caf"
        case .full: return "Full / Caffeinated"
        }
    }

    var menuBarImageName: String {
        switch self {
        case .off: return "MenuBarCupEmpty"
        case .half: return "MenuBarCupHalf"
        case .full: return "MenuBarCupFilled"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .off: return "Uncaffeinated"
        case .half: return "Half-caf"
        case .full: return "Caffeinated"
        }
    }

    /// Arguments passed to `/usr/bin/caffeinate`, or `nil` when no process should run.
    var caffeinateArguments: [String]? {
        switch self {
        case .off: return nil
        case .half: return []
        case .full: return ["-d"]
        }
    }
}

/// Owns a `/usr/bin/caffeinate` child process while half-caf or fully caffeinated.
final class CaffeineController: ObservableObject {
    @Published private(set) var mode: CaffeineMode = .off
    @Published private(set) var lastError: String?

    private var process: Process?

    func setMode(_ newMode: CaffeineMode) {
        guard newMode != mode else { return }

        stopProcess()
        mode = newMode
        lastError = nil

        guard let arguments = newMode.caffeinateArguments else { return }
        startProcess(arguments: arguments)
    }

    /// Terminates any child process and returns to Off. Used by Quit and app termination.
    func uncaffeinate() {
        setMode(.off)
    }

    private func stopProcess() {
        guard let process else { return }
        // Nil first so terminationHandler is a no-op when we intentionally stop/switch.
        self.process = nil
        if process.isRunning {
            process.terminate()
        }
    }

    private func startProcess(arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            self.process = process

            process.terminationHandler = { [weak self] finished in
                DispatchQueue.main.async {
                    guard let self else { return }
                    // Ignore if user already switched modes or stopped.
                    guard self.process === finished else { return }
                    self.process = nil
                    self.mode = .off
                }
            }
        } catch {
            lastError = error.localizedDescription
            self.process = nil
            mode = .off
        }
    }
}
