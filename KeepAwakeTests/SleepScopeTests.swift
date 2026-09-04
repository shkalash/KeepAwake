//
//  SleepScopeTests.swift
//  KeepAwakeTests
//

import Foundation
import IOKit.pwr_mgt
import Testing
@testable import KeepAwake

@Suite("SleepScope")
struct SleepScopeTests {
    @Test("displayAndSystem holds both the display and system assertions")
    func displayAndSystemAssertionTypes() {
        #expect(SleepScope.displayAndSystem.assertionTypes == [
            kIOPMAssertionTypePreventUserIdleDisplaySleep,
            kIOPMAssertionTypePreventUserIdleSystemSleep,
        ])
    }

    @Test("systemOnly holds the system assertion and not the display one")
    func systemOnlyAssertionTypes() {
        #expect(SleepScope.systemOnly.assertionTypes == [
            kIOPMAssertionTypePreventUserIdleSystemSleep,
        ])
        #expect(!SleepScope.systemOnly.assertionTypes
            .contains(kIOPMAssertionTypePreventUserIdleDisplaySleep))
    }

    @Test("raw values are stable, since they are the persistence format",
          arguments: zip(SleepScope.allCases, ["displayAndSystem", "systemOnly"]))
    func rawValuesAreStable(scope: SleepScope, expected: String) {
        #expect(scope.rawValue == expected)
    }

    @Test("round trips through Codable", arguments: SleepScope.allCases)
    func codableRoundTrip(scope: SleepScope) throws {
        let data = try JSONEncoder().encode(scope)
        #expect(try JSONDecoder().decode(SleepScope.self, from: data) == scope)
    }

    /// Proves the string catalog is actually built into the host app. An
    /// unresolved key falls back to the key itself, so a title still carrying
    /// the "menu." namespace prefix means the catalog never shipped.
    @Test("every menu title resolves out of the string catalog",
          arguments: SleepScope.allCases)
    func menuTitleResolves(scope: SleepScope) {
        let title = String(localized: scope.menuTitleKey)
        #expect(!title.hasPrefix("menu."))
        #expect(!title.isEmpty)
    }

    @Test("menu titles are distinct across cases")
    func menuTitlesAreDistinct() {
        let titles = SleepScope.allCases.map { String(localized: $0.menuTitleKey) }
        #expect(Set(titles).count == SleepScope.allCases.count)
    }
}
