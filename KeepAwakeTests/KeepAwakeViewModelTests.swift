//
//  KeepAwakeViewModelTests.swift
//  KeepAwakeTests
//

import Foundation
import Testing
@testable import KeepAwake

@MainActor
@Suite("KeepAwakeViewModel")
struct KeepAwakeViewModelTests {
    /// Assembles a view model over spies, returning all of them so a test can
    /// assert on both the observable state and the side effects it produced.
    private func makeSUT(
        storeSeed: [String: Any] = [:],
        loginEnabled: Bool = false
    ) -> (
        sut: KeepAwakeViewModel,
        sleep: SpySleepPreventer,
        login: SpyLoginItemManager,
        store: InMemorySettingsStore
    ) {
        let sleep = SpySleepPreventer()
        let login = SpyLoginItemManager(isEnabled: loginEnabled)
        let store = InMemorySettingsStore(seed: storeSeed)
        let sut = KeepAwakeViewModel(sleepPreventer: sleep, loginItems: login, store: store)
        return (sut, sleep, login, store)
    }

    // MARK: - Toggling

    @Test("starts off and holds no assertion")
    func startsOff() {
        let (sut, sleep, _, _) = makeSUT()
        #expect(sut.isAwake == false)
        #expect(sleep.engagedScopes.isEmpty)
    }

    @Test("toggling on engages exactly once with the current scope")
    func toggleOnEngages() {
        let (sut, sleep, _, store) = makeSUT()
        sut.toggle()

        #expect(sut.isAwake)
        #expect(sleep.engagedScopes == [.displayAndSystem])
        #expect(store.value(for: .isAwake, default: false))
    }

    @Test("toggling off disengages and persists the off state")
    func toggleOffDisengages() {
        let (sut, sleep, _, store) = makeSUT()
        sut.toggle()
        sut.toggle()

        #expect(sut.isAwake == false)
        #expect(sleep.disengageCount >= 1)
        #expect(store.value(for: .isAwake, default: true) == false)
    }

    @Test("a refused assertion leaves the state off rather than lying")
    func failedEngageStaysOff() {
        let (sut, sleep, _, store) = makeSUT()
        sleep.errorToThrow = .creationFailed(assertionType: "test", status: -1)

        sut.toggle()

        #expect(sut.isAwake == false)
        #expect(sleep.engagedScopes.isEmpty)
        // The persisted state must not claim awake either, or the next launch
        // would try to restore a state that never existed.
        #expect(store.value(for: .isAwake, default: true) == false)
    }

    // MARK: - Scope

    @Test("changing scope while awake re-engages with the new scope")
    func scopeChangeWhileAwakeReEngages() {
        let (sut, sleep, _, _) = makeSUT()
        sut.toggle()
        sut.select(scope: .systemOnly)

        #expect(sut.scope == .systemOnly)
        #expect(sut.isAwake)
        #expect(sleep.engagedScopes == [.displayAndSystem, .systemOnly])
    }

    @Test("changing scope while off persists but engages nothing")
    func scopeChangeWhileOffDoesNotEngage() {
        let (sut, sleep, _, store) = makeSUT()
        sut.select(scope: .systemOnly)

        #expect(sut.scope == .systemOnly)
        #expect(sut.isAwake == false)
        #expect(sleep.engagedScopes.isEmpty)
        #expect(store.value(for: .sleepScope, default: .displayAndSystem) == .systemOnly)
    }

    @Test("selecting the scope already in use is a no-op")
    func redundantScopeChangeDoesNothing() {
        let (sut, sleep, _, _) = makeSUT()
        sut.toggle()
        sut.select(scope: .displayAndSystem)

        #expect(sleep.engagedScopes == [.displayAndSystem])
    }

    @Test("toggling on after a scope change uses the new scope")
    func toggleUsesSelectedScope() {
        let (sut, sleep, _, _) = makeSUT()
        sut.select(scope: .systemOnly)
        sut.toggle()

        #expect(sleep.engagedScopes == [.systemOnly])
    }

    // MARK: - Launch restore

    @Test("restore re-engages with the persisted scope when it was awake")
    func restoreReEngages() {
        let (sut, sleep, _, _) = makeSUT(storeSeed: [
            "isAwake": true,
            "sleepScope": SleepScope.systemOnly,
        ])
        sut.restoreOnLaunch()

        #expect(sut.isAwake)
        #expect(sut.scope == .systemOnly)
        #expect(sleep.engagedScopes == [.systemOnly])
    }

    @Test("restore engages nothing when it was off")
    func restoreStaysOff() {
        let (sut, sleep, _, _) = makeSUT(storeSeed: ["isAwake": false])
        sut.restoreOnLaunch()

        #expect(sut.isAwake == false)
        #expect(sleep.engagedScopes.isEmpty)
    }

    @Test("restore falls back to the default scope on an empty store")
    func restoreDefaultsScope() {
        let (sut, _, _, _) = makeSUT()
        sut.restoreOnLaunch()

        #expect(sut.scope == .displayAndSystem)
    }

    @Test("restore reads the live login item state")
    func restoreReadsLoginItemState() {
        let (sut, _, _, _) = makeSUT(loginEnabled: true)
        sut.restoreOnLaunch()

        #expect(sut.launchesAtLogin)
    }

    // MARK: - Login item

    @Test("enabling the login item reflects the new state")
    func enableLoginItem() {
        let (sut, _, login, _) = makeSUT()
        sut.setLaunchAtLogin(true)

        #expect(sut.launchesAtLogin)
        #expect(login.isEnabled)
    }

    @Test("a refused registration leaves the flag showing the real state")
    func refusedLoginItemRegistration() {
        let (sut, _, login, _) = makeSUT()
        login.errorToThrow = PowerAssertionError.creationFailed(assertionType: "test", status: -1)

        sut.setLaunchAtLogin(true)

        #expect(sut.launchesAtLogin == false)
        #expect(login.isEnabled == false)
    }
}
