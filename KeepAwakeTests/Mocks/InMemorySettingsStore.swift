//
//  InMemorySettingsStore.swift
//  KeepAwakeTests
//

import Foundation
@testable import KeepAwake

/// A settings store backed by a dictionary, giving each test a clean slate
/// without touching the real `UserDefaults` domain.
@MainActor
final class InMemorySettingsStore: SettingsStoring {
    private var storage: [String: Any] = [:]

    init(seed: [String: Any] = [:]) {
        self.storage = seed
    }

    func value<Value: Codable>(for key: PersistenceKey<Value>, default defaultValue: Value) -> Value {
        storage[key.name] as? Value ?? defaultValue
    }

    func set<Value: Codable>(_ value: Value, for key: PersistenceKey<Value>) {
        storage[key.name] = value
    }
}
