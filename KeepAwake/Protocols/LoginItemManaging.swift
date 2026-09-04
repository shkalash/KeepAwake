//
//  LoginItemManaging.swift
//  KeepAwake
//

import Foundation

/// Registers and unregisters the app as a login item.
///
/// Abstracted from `SMAppService` because registration touches real system state
/// that tests must not mutate.
@MainActor
protocol LoginItemManaging: AnyObject {
    /// Whether the app is currently registered to launch at login.
    ///
    /// Read from the system rather than cached, since the user can revoke the
    /// registration in System Settings while the app is running.
    var isEnabled: Bool { get }

    /// Register or unregister the app as a login item.
    /// - Throws: whatever the underlying service reports; registration can fail
    ///   for an unsigned app or one running from a transient location.
    func setEnabled(_ enabled: Bool) throws
}
