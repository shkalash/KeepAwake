//
//  PowerAssertionManagerTests.swift
//  KeepAwakeTests
//

import Foundation
import IOKit.pwr_mgt
import Testing
@testable import KeepAwake

/// Integration tests against real IOKit rather than a mock.
///
/// The whole point of this type is that the system actually grants the
/// assertion, which a mock cannot demonstrate. Each test asserts against
/// `IOPMCopyAssertionsByProcess`, the same data `pmset -g assertions` prints.
@MainActor
@Suite("PowerAssertionManager", .serialized)
struct PowerAssertionManagerTests {
    /// The assertion types this process currently holds with KeepAwake's reason string.
    private func heldAssertionTypes() -> Set<String> {
        var assertionsByPID: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&assertionsByPID) == kIOReturnSuccess,
              let dictionary = assertionsByPID?.takeRetainedValue() as? [NSNumber: [[String: Any]]]
        else {
            return []
        }

        let pid = NSNumber(value: ProcessInfo.processInfo.processIdentifier)
        let ours = dictionary[pid] ?? []
        return Set(
            ours
                .filter { $0[kIOPMAssertionNameKey] as? String == AppConstants.assertionReason }
                .compactMap { $0[kIOPMAssertionTypeKey] as? String }
        )
    }

    @Test("engaging displayAndSystem registers both assertions with the system",
          arguments: SleepScope.allCases)
    func engageRegistersRealAssertions(scope: SleepScope) throws {
        let sut = PowerAssertionManager()
        defer { sut.disengage() }

        try sut.engage(scope: scope)

        #expect(sut.isEngaged)
        #expect(heldAssertionTypes() == Set(scope.assertionTypes))
    }

    @Test("disengaging releases every assertion")
    func disengageReleasesAssertions() throws {
        let sut = PowerAssertionManager()
        try sut.engage(scope: .displayAndSystem)
        #expect(!heldAssertionTypes().isEmpty)

        sut.disengage()

        #expect(sut.isEngaged == false)
        #expect(heldAssertionTypes().isEmpty)
    }

    @Test("re-engaging with a different scope replaces rather than accumulates")
    func reEngageReplacesScope() throws {
        let sut = PowerAssertionManager()
        defer { sut.disengage() }

        try sut.engage(scope: .displayAndSystem)
        try sut.engage(scope: .systemOnly)

        // The display assertion from the first call must be gone, or the user
        // would silently keep a policy they switched away from.
        #expect(heldAssertionTypes() == Set(SleepScope.systemOnly.assertionTypes))
    }

    @Test("disengaging when nothing is held is safe")
    func disengageWhenIdleIsSafe() {
        let sut = PowerAssertionManager()
        sut.disengage()
        #expect(sut.isEngaged == false)
    }
}
