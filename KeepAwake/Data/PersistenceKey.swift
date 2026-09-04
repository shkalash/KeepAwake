//
//  PersistenceKey.swift
//  KeepAwake
//

import Foundation

/// A type-safe name for a persisted value.
///
/// Responsibilities:
/// - Pair a defaults key string with the type stored under it, so a read cannot
///   silently disagree with the corresponding write.
/// - Keep every literal defaults key in one place rather than scattered at call sites.
///
/// The `Value` parameter is phantom — it exists only to constrain
/// `SettingsStoring`'s generic methods.
struct PersistenceKey<Value>: Sendable {
    let name: String
}

extension PersistenceKey {
    /// Whether the app was holding the Mac awake when it last quit.
    static var isAwake: PersistenceKey<Bool> { .init(name: "isAwake") }
    /// The sleep policy the toggle applies.
    static var sleepScope: PersistenceKey<SleepScope> { .init(name: "sleepScope") }
}
