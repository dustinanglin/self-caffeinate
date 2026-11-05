import Foundation
import Combine

/// Owns a `/usr/bin/caffeinate -d` child process while caffeinated.
final class CaffeineController: ObservableObject {
    @Published private(set) var isCaffeinated = false
    @Published private(set) var lastError: String?

    private var process: Process?

    func caffeinate() {
        guard !isCaffeinated else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-d"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            self.process = process
            isCaffeinated = true
            lastError = nil

            process.terminationHandler = { [weak self] finished in
                DispatchQueue.main.async {
                    guard let self else { return }
                    // Ignore if user already uncaffeinated or started a new process.
                    guard self.process === finished else { return }
                    self.process = nil
                    self.isCaffeinated = false
                }
            }
        } catch {
            lastError = error.localizedDescription
            self.process = nil
            isCaffeinated = false
        }
    }

    func uncaffeinate() {
        guard let process else {
            isCaffeinated = false
            return
        }
        if process.isRunning {
            process.terminate()
        }
        // Clear immediately so the menu updates; terminationHandler is a no-op once process is nil.
        self.process = nil
        isCaffeinated = false
    }
}
