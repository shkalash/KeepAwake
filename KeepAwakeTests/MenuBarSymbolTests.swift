//
//  MenuBarSymbolTests.swift
//  KeepAwakeTests
//

import AppKit
import Testing
@testable import KeepAwake

/// Guards the one failure mode that would leave the app with an invisible menu
/// bar item: `NSImage(systemSymbolName:)` returns nil for a symbol that does not
/// exist on the running OS, and `NSStatusItem` renders nothing rather than
/// complaining. A typo in a symbol name would otherwise ship silently.
@MainActor
@Suite("MenuBarSymbol")
struct MenuBarSymbolTests {
    @Test("both state symbols resolve to a real image",
          arguments: [MenuBarSymbol.awake, MenuBarSymbol.asleep])
    func symbolResolves(name: String) throws {
        let image = try #require(
            NSImage(systemSymbolName: name, accessibilityDescription: nil),
            "SF Symbol '\(name)' does not exist on this macOS version"
        )
        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
    }

    /// The user-facing requirement is two *visually* different icons, so compare
    /// rendered pixels rather than just the two name strings — a pair of symbols
    /// could differ by name and still be near-indistinguishable at menu bar size.
    @Test("the two states render to visibly different images")
    func statesAreVisuallyDistinct() throws {
        #expect(MenuBarSymbol.awake != MenuBarSymbol.asleep)

        let awake = try #require(
            NSImage(systemSymbolName: MenuBarSymbol.awake, accessibilityDescription: nil)
                .flatMap(\.tiffRepresentation)
        )
        let asleep = try #require(
            NSImage(systemSymbolName: MenuBarSymbol.asleep, accessibilityDescription: nil)
                .flatMap(\.tiffRepresentation)
        )
        #expect(awake != asleep)
    }
}
