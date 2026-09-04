//
//  SpySleepPreventer.swift
//  KeepAwakeTests
//

@testable import KeepAwake

/// Records every engage/disengage call so tests can assert on the exact sequence
/// of side effects, and can be told to fail on demand.
@MainActor
final class SpySleepPreventer: SleepPreventing {
    /// One entry per call, in order, so a test can distinguish "re-armed with the
    /// new scope" from "never touched".
    private(set) var engagedScopes: [SleepScope] = []
    private(set) var disengageCount = 0
    /// When set, the next `engage` throws this instead of succeeding.
    var errorToThrow: PowerAssertionError?

    private(set) var isEngaged = false

    func engage(scope: SleepScope) throws {
        if let errorToThrow {
            throw errorToThrow
        }
        engagedScopes.append(scope)
        isEngaged = true
    }

    func disengage() {
        disengageCount += 1
        isEngaged = false
    }
}
