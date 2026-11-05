import Foundation
import Combine
import Darwin

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
    /// PID of the child we spawned, kept so we can still reap it if `Process` state races.
    private var ownedPID: pid_t?

    func setMode(_ newMode: CaffeineMode) {
        guard newMode != mode else { return }

        // Always fully stop any owned child before changing mode or spawning.
        stopOwnedCaffeinate()
        mode = newMode
        lastError = nil

        guard let arguments = newMode.caffeinateArguments else { return }
        startProcess(arguments: arguments)
    }

    /// Terminates any child process and returns to Off. Used by Quit and app termination.
    func uncaffeinate() {
        setMode(.off)
    }

    /// Terminate the Process we spawned (and its stored PID), waiting until it is gone.
    private func stopOwnedCaffeinate() {
        let existing = process
        let pid = ownedPID ?? existing?.processIdentifier

        // Drop references first so terminationHandler is a no-op for intentional stops.
        process = nil
        ownedPID = nil

        if let existing, existing.isRunning {
            existing.terminate() // SIGTERM
            waitUntilNotRunning(existing, timeout: 0.4)
            if existing.isRunning {
                let fallbackPID = pid ?? existing.processIdentifier
                forceKill(fallbackPID)
                waitUntilNotRunning(existing, timeout: 0.2)
            }
        } else if let pid {
            // Process object already gone / not running — still reap our stored PID if alive.
            forceKillIfAlive(pid, escalateAfter: 0.25)
        }
    }

    private func startProcess(arguments: [String]) {
        // Belt-and-suspenders: never spawn while we still track a child.
        stopOwnedCaffeinate()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            self.process = process
            self.ownedPID = process.processIdentifier

            process.terminationHandler = { [weak self] finished in
                DispatchQueue.main.async {
                    guard let self else { return }
                    // Ignore if user already switched modes or stopped.
                    guard self.process === finished else { return }
                    self.process = nil
                    self.ownedPID = nil
                    self.mode = .off
                }
            }
        } catch {
            lastError = error.localizedDescription
            self.process = nil
            self.ownedPID = nil
            mode = .off
        }
    }

    private func waitUntilNotRunning(_ process: Process, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.01)
        }
    }

    private func forceKill(_ pid: pid_t?) {
        guard let pid, pid > 0 else { return }
        Darwin.kill(pid, SIGKILL)
    }

    private func forceKillIfAlive(_ pid: pid_t, escalateAfter: TimeInterval) {
        guard pid > 0 else { return }
        // kill(pid, 0) == 0 means a process with that PID still exists.
        if Darwin.kill(pid, 0) != 0 { return }
        Darwin.kill(pid, SIGTERM)
        let deadline = Date().addingTimeInterval(escalateAfter)
        while Darwin.kill(pid, 0) == 0, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.01)
        }
        if Darwin.kill(pid, 0) == 0 {
            Darwin.kill(pid, SIGKILL)
        }
    }
}
