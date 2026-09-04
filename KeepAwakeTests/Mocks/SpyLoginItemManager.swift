//
//  SpyLoginItemManager.swift
//  KeepAwakeTests
//

import Foundation
@testable import KeepAwake

/// In-memory stand-in for `SMAppService`, so tests never register a real login item.
@MainActor
final class SpyLoginItemManager: LoginItemManaging {
    private(set) var isEnabled: Bool
    /// When set, `setEnabled` throws and leaves `isEnabled` unchanged — modelling
    /// a registration the system refuses.
    var errorToThrow: (any Error)?

    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if let errorToThrow {
            throw errorToThrow
        }
        isEnabled = enabled
    }
}
