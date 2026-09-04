//
//  KeepAwakeViewModel.swift
//  KeepAwake
//

import Foundation
import Observation
import os

/// The single source of truth for whether the Mac is being kept awake, under
/// which policy, and whether the app launches at login.
///
/// Responsibilities:
/// - Own the app's observable state and expose intents that mutate it.
/// - Keep the real power assertion in step with `isAwake` and `scope`.
/// - Persist and restore that state across launches.
///
/// State is only ever changed after the corresponding side effect succeeds, so
/// the menu bar icon cannot claim the Mac is awake when no assertion is held.
@MainActor
@Observable
final class KeepAwakeViewModel {
    /// Whether sleep is currently being prevented.
    private(set) var isAwake: Bool = false
    /// Which kinds of sleep the toggle holds off.
    private(set) var scope: SleepScope = .displayAndSystem
    /// Whether the app is registered to launch at login.
    private(set) var launchesAtLogin: Bool = false

    @ObservationIgnored private let sleepPreventer: any SleepPreventing
    @ObservationIgnored private let loginItems: any LoginItemManaging
    @ObservationIgnored private let store: any SettingsStoring
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "KeepAwake",
        category: "KeepAwakeViewModel"
    )

    init(
        sleepPreventer: any SleepPreventing,
        loginItems: any LoginItemManaging,
        store: any SettingsStoring
    ) {
        self.sleepPreventer = sleepPreventer
        self.loginItems = loginItems
        self.store = store
    }

    // MARK: - Lifecycle

    /// Load persisted state and re-acquire the assertion if the app was awake
    /// when it last quit. Call once, after the status item exists.
    func restoreOnLaunch() {
        scope = store.value(for: .sleepScope, default: scope)
        launchesAtLogin = loginItems.isEnabled

        let wasAwake = store.value(for: .isAwake, default: false)
        guard wasAwake else { return }
        applyAwake(true)
    }

    // MARK: - Intents

    /// Flip between preventing and allowing sleep.
    func toggle() {
        applyAwake(!isAwake)
    }

    /// Change the sleep policy, re-arming the assertion if one is already held.
    func select(scope newScope: SleepScope) {
        guard newScope != scope else { return }
        scope = newScope
        store.set(newScope, for: .sleepScope)

        // Only touch the assertion if one is actually held; otherwise the new
        // scope simply applies the next time the user toggles on.
        guard isAwake else { return }
        applyAwake(true)
    }

    /// Register or unregister the app as a login item.
    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItems.setEnabled(enabled)
        } catch {
            logger.error("Failed to set login item to \(enabled): \(error.localizedDescription)")
        }
        // Read back rather than assuming success: registration can be refused
        // for an unsigned build or one running from a transient location, and
        // the checkmark must reflect what the system actually did.
        launchesAtLogin = loginItems.isEnabled
    }

    // MARK: - Private

    /// Drive the assertion to `awake` and adopt the resulting state.
    ///
    /// `isAwake` is set from the outcome of the side effect, never ahead of it,
    /// so a refused assertion leaves the UI showing "off" — which is the truth.
    private func applyAwake(_ awake: Bool) {
        if awake {
            do {
                try sleepPreventer.engage(scope: scope)
                isAwake = true
            } catch {
                logger.error("Failed to engage sleep prevention: \(error.localizedDescription)")
                sleepPreventer.disengage()
                isAwake = false
            }
        } else {
            sleepPreventer.disengage()
            isAwake = false
        }
        store.set(isAwake, for: .isAwake)
    }
}
