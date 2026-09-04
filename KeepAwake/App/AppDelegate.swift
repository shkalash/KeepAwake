//
//  AppDelegate.swift
//  KeepAwake
//

import AppKit

/// Composition root and application lifecycle owner.
///
/// Responsibilities:
/// - Construct the object graph in dependency order.
/// - Create the status item once the app has finished launching.
/// - Release power assertions on quit.
///
/// This is the only place concrete manager types are named; everything below it
/// depends on the protocols instead.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let sleepPreventer = PowerAssertionManager()
    private lazy var viewModel = KeepAwakeViewModel(
        sleepPreventer: sleepPreventer,
        loginItems: LoginItemManager(),
        store: UserDefaultsSettingsStore()
    )
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The controller renders from the view model, so it must exist before
        // restore populates that state.
        statusItemController = StatusItemController(viewModel: viewModel)
        viewModel.restoreOnLaunch()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // The kernel drops process-scoped assertions at exit anyway; releasing
        // explicitly makes `pmset -g assertions` agree with reality immediately
        // rather than after the process is reaped.
        sleepPreventer.disengage()
    }
}
