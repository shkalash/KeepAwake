//
//  UserDefaultsSettingsStore.swift
//  KeepAwake
//

import Foundation

/// Persists settings in `UserDefaults`, encoding values as JSON.
///
/// Everything goes through `Codable` rather than the typed `UserDefaults`
/// accessors so that primitives and enums share one code path — the alternative
/// is a separate overload per storable type, which the protocol's generic
/// signature is specifically there to avoid.
@MainActor
final class UserDefaultsSettingsStore: SettingsStoring {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func value<Value: Codable>(for key: PersistenceKey<Value>, default defaultValue: Value) -> Value {
        guard let data = defaults.data(forKey: key.name),
              let decoded = try? decoder.decode(Value.self, from: data)
        else {
            // Covers both "never written" and "written by an older, incompatible
            // build"; in either case the default is the safe answer.
            return defaultValue
        }
        return decoded
    }

    func set<Value: Codable>(_ value: Value, for key: PersistenceKey<Value>) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key.name)
    }
}
