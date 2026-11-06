import Foundation
import ServiceManagement

/// Wraps `SMAppService.mainApp` so the app can add or remove itself as a login item (macOS 13+).
///
/// Registration is tied to the bundle on disk. Register from the installed copy in /Applications,
/// not the Xcode build in DerivedData, or the login item will point at a path that changes on
/// every rebuild.
final class LoginItemController {
    private var service: SMAppService { .mainApp }

    var isEnabled: Bool {
        service.status == .enabled
    }

    /// True when the user turned the item off in System Settings; macOS will not re-enable it
    /// programmatically and must be pointed at the Login Items pane instead.
    var requiresApproval: Bool {
        service.status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try service.register()
            if requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
        } else {
            try service.unregister()
        }
    }
}
