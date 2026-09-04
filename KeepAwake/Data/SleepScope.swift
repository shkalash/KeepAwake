//
//  SleepScope.swift
//  KeepAwake
//

import Foundation
import IOKit.pwr_mgt

/// Which kinds of idle sleep the app holds off while it is engaged.
///
/// Responsibilities:
/// - Enumerate the user-selectable sleep policies.
/// - Map each policy to the concrete IOKit assertion types that implement it.
/// - Name the string-catalog key used for its menu item.
///
/// The raw value is the persistence representation, so cases must not be renamed
/// without a migration.
enum SleepScope: String, CaseIterable, Codable, Sendable {
    /// The screen stays lit and the machine stays up. Equivalent to `caffeinate -d -i`.
    case displayAndSystem
    /// The machine stays up but the display may dim and sleep. Equivalent to `caffeinate -i`.
    case systemOnly

    /// The IOKit assertion types that must be held for this scope to be in effect.
    ///
    /// `displayAndSystem` takes both assertions rather than relying on the display
    /// assertion to imply the system one. A display assertion does keep the system
    /// up in practice, but that is emergent behaviour of the power management
    /// daemon rather than a documented guarantee, and holding both states the
    /// intent explicitly in `pmset -g assertions`.
    var assertionTypes: [String] {
        switch self {
        case .displayAndSystem:
            [
                kIOPMAssertionTypePreventUserIdleDisplaySleep,
                kIOPMAssertionTypePreventUserIdleSystemSleep,
            ]
        case .systemOnly:
            [kIOPMAssertionTypePreventUserIdleSystemSleep]
        }
    }

    /// String-catalog key for this scope's menu item title.
    var menuTitleKey: String.LocalizationValue {
        switch self {
        case .displayAndSystem: "menu.scope.displayAndSystem"
        case .systemOnly: "menu.scope.systemOnly"
        }
    }
}
