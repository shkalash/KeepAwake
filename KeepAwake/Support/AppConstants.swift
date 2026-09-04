//
//  AppConstants.swift
//  KeepAwake
//

import Foundation

/// Non-user-facing constants shared across the app.
enum AppConstants {
    /// Human-readable reason attached to every power assertion.
    ///
    /// This exact text is what `pmset -g assertions` prints next to the assertion,
    /// so it is the primary way to confirm from a terminal that the app is the one
    /// holding the machine awake.
    static let assertionReason = "KeepAwake - user requested"
}
