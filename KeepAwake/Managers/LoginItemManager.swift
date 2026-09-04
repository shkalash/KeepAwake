//
//  LoginItemManager.swift
//  KeepAwake
//

import Foundation
import ServiceManagement

/// Registers the app as a login item through `SMAppService`.
///
/// `SMAppService.mainApp` is the modern replacement for the deprecated
/// `SMLoginItemSetEnabled` helper-bundle dance: no separate helper target is
/// needed, and the registration surfaces to the user in System Settings under
/// General > Login Items.
@MainActor
final class LoginItemManager: LoginItemManaging {
    private let service = SMAppService.mainApp

    /// Queried live rather than cached, because the user can revoke the login
    /// item in System Settings while the app is running and the menu must not
    /// keep showing a stale checkmark.
    var isEnabled: Bool { service.status == .enabled }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }
}
