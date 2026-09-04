//
//  StatusItemControllerTests.swift
//  KeepAwakeTests
//

import AppKit
import Testing
@testable import KeepAwake

/// Covers the menu bar rendering path.
///
/// The click routing itself needs a real mouse event and Accessibility
/// permission, so it is not covered here; what is covered is everything the
/// click leads to — the menu's structure and the icon/checkmark state that has
/// to track the view model.
@MainActor
@Suite("StatusItemController", .serialized)
struct StatusItemControllerTests {
    private func makeSUT(
        storeSeed: [String: Any] = [:],
        loginEnabled: Bool = false
    ) -> (controller: StatusItemController, viewModel: KeepAwakeViewModel) {
        let viewModel = KeepAwakeViewModel(
            sleepPreventer: SpySleepPreventer(),
            loginItems: SpyLoginItemManager(isEnabled: loginEnabled),
            store: InMemorySettingsStore(seed: storeSeed)
        )
        return (StatusItemController(viewModel: viewModel), viewModel)
    }

    /// Status items live in the system-wide menu bar, so a test that creates one
    /// must remove it again or it lingers for the life of the test process.
    private func tearDown(_ controller: StatusItemController) {
        NSStatusBar.system.removeStatusItem(controller.statusItem)
    }

    @Test("the button shows a template image so the menu bar can tint it")
    func buttonHasTemplateImage() throws {
        let (controller, _) = makeSUT()
        defer { tearDown(controller) }

        let image = try #require(controller.statusItem.button?.image)
        #expect(image.isTemplate)
    }

    @Test("the menu offers every scope, plus launch at login and quit")
    func menuStructure() {
        let (controller, _) = makeSUT()
        defer { tearDown(controller) }

        let scopeItems = controller.menu.items.compactMap { $0.representedObject as? SleepScope }
        #expect(scopeItems == SleepScope.allCases)
        #expect(controller.loginMenuItem != nil)
        #expect(controller.menu.items.contains { $0.action == #selector(NSApplication.terminate(_:)) })
    }

    @Test("exactly the active scope is checkmarked")
    func activeScopeIsChecked() {
        let (controller, viewModel) = makeSUT(storeSeed: ["sleepScope": SleepScope.systemOnly])
        defer { tearDown(controller) }

        viewModel.restoreOnLaunch()
        controller.render()

        let checked = controller.menu.items
            .filter { $0.state == .on }
            .compactMap { $0.representedObject as? SleepScope }
        #expect(checked == [.systemOnly])
    }

    @Test("the icon changes between the awake and asleep states")
    func iconReflectsAwakeState() throws {
        let (controller, viewModel) = makeSUT()
        defer { tearDown(controller) }

        let offDescription = controller.statusItem.button?.toolTip
        let offPixels = controller.statusItem.button?.image?.tiffRepresentation

        viewModel.toggle()
        controller.render()

        #expect(viewModel.isAwake)
        // Compared by rendered pixels rather than by object identity or name:
        // symbol images are unnamed, and pixels are the only evidence that the
        // two states are actually *visually* distinguishable in the menu bar.
        #expect(offPixels != nil)
        #expect(offPixels != controller.statusItem.button?.image?.tiffRepresentation)
        #expect(offDescription != controller.statusItem.button?.toolTip)
    }

    @Test("the login item checkmark tracks the view model")
    func loginCheckmarkTracksState() throws {
        let (controller, viewModel) = makeSUT(loginEnabled: true)
        defer { tearDown(controller) }

        viewModel.restoreOnLaunch()
        controller.render()
        #expect(controller.loginMenuItem?.state == .on)

        viewModel.setLaunchAtLogin(false)
        controller.render()
        #expect(controller.loginMenuItem?.state == .off)
    }

    @Test("observation re-renders the icon without an explicit render call")
    func observationDrivesRender() async throws {
        let (controller, viewModel) = makeSUT()
        defer { tearDown(controller) }

        let offPixels = controller.statusItem.button?.image?.tiffRepresentation
        viewModel.toggle()
        // The observation callback hops through a Task, so yield to let the
        // main actor drain it before asserting.
        await Task.yield()

        #expect(controller.statusItem.button?.image?.tiffRepresentation != offPixels)
    }
}
