//
//  MenuBarSymbol.swift
//  KeepAwake
//

import Foundation

/// SF Symbol names for the status item's two states.
///
/// Kept apart from the view code so the icon pair can be changed in one place.
/// The two symbols are chosen for silhouette contrast: at menu bar size a filled
/// sun and a crescent-with-zzz are distinguishable at a glance, where a
/// filled/outline pair of the same glyph would not be.
enum MenuBarSymbol {
    /// Shown while sleep is being prevented.
    static let awake = "sun.max.fill"
    /// Shown while the Mac is free to sleep normally.
    static let asleep = "moon.zzz.fill"
}
