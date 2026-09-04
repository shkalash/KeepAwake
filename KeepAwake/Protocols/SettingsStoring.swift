//
//  SettingsStoring.swift
//  KeepAwake
//

import Foundation

/// Reads and writes small persisted values addressed by `PersistenceKey`.
///
/// Abstracted from `UserDefaults` so tests get a clean store per case instead of
/// sharing (and having to clean up) the real defaults domain.
@MainActor
protocol SettingsStoring: AnyObject {
    /// The stored value for `key`, or `defaultValue` if nothing has been stored.
    func value<Value: Codable>(for key: PersistenceKey<Value>, default defaultValue: Value) -> Value
    /// Store `value` under `key`.
    func set<Value: Codable>(_ value: Value, for key: PersistenceKey<Value>)
}
