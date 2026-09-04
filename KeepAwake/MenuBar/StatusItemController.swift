//
//  StatusItemController.swift
//  KeepAwake
//

import AppKit
import Observation

/// Owns the menu bar item and renders `KeepAwakeViewModel` into it.
///
/// Responsibilities:
/// - Present the two-state icon and keep it in step with the view model.
/// - Route a left-click to the toggle intent and a right-click to the menu.
/// - Build the menu and forward its items to view model intents.
///
/// AppKit is used rather than SwiftUI's `MenuBarExtra` because `MenuBarExtra`
/// cannot distinguish a left-click from a right-click: it either owns the click
/// to open a menu/popover or it does nothing. A single-click toggle *and* a
/// right-click menu on the same item requires `NSStatusItem.button` with
/// `sendAction(on:)`.
///
/// Data flows one way: intents go to the view model, and the view model's
/// observed changes come back through `render()`. The controller never mutates
/// its own displayed state directly.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let viewModel: KeepAwakeViewModel
    // Internal rather than private so `@testable` tests can inspect what was
    // actually rendered; there is no other way to verify menu bar UI, which has
    // no preview and cannot be driven without Accessibility permission.
    let statusItem: NSStatusItem
    let menu = NSMenu()

    init(viewModel: KeepAwakeViewModel) {
        self.viewModel = viewModel
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureButton()
        buildMenu()
        observeViewModel()
        render()
    }

    // MARK: - Setup

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(statusItemClicked)
        // Without this the button only reports left-clicks, and a right-click
        // would fall through to the system with no action at all.
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func buildMenu() {
        menu.delegate = self
        menu.autoenablesItems = false

        for scope in SleepScope.allCases {
            let item = NSMenuItem(
                title: String(localized: scope.menuTitleKey),
                action: #selector(scopeSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            // Carries the scope to the action, avoiding a tag-to-enum lookup.
            item.representedObject = scope
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let loginItem = NSMenuItem(
            title: String(localized: "menu.launchAtLogin"),
            action: #selector(launchAtLoginToggled),
            keyEquivalent: ""
        )
        loginItem.target = self
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: String(localized: "menu.quit"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
    }

    /// Re-render whenever any observed property the last render read changes.
    ///
    /// `withObservationTracking` fires once per change, so the closure
    /// re-registers itself. This is the standard bridge from `@Observable` to
    /// AppKit, which has no equivalent of SwiftUI's automatic dependency tracking.
    private func observeViewModel() {
        withObservationTracking {
            _ = viewModel.isAwake
            _ = viewModel.scope
            _ = viewModel.launchesAtLogin
        } onChange: { [weak self] in
            // onChange fires *before* the value is committed, so the re-render
            // and the re-subscription both have to wait for the next main-actor turn.
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.render()
                self.observeViewModel()
            }
        }
    }

    // MARK: - Rendering

    func render() {
        guard let button = statusItem.button else { return }
        let isAwake = viewModel.isAwake
        let symbolName = isAwake ? MenuBarSymbol.awake : MenuBarSymbol.asleep
        let description = String(localized: isAwake
            ? "status.accessibility.awake"
            : "status.accessibility.asleep")

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
        // Template rendering lets the menu bar tint the glyph, so it stays legible
        // in light and dark menu bars and while the item is highlighted.
        image?.isTemplate = true
        button.image = image
        button.toolTip = description

        for item in menu.items {
            if let scope = item.representedObject as? SleepScope {
                item.state = (scope == viewModel.scope) ? .on : .off
            }
        }
        loginMenuItem?.state = viewModel.launchesAtLogin ? .on : .off
    }

    var loginMenuItem: NSMenuItem? {
        menu.items.first { $0.action == #selector(launchAtLoginToggled) }
    }

    // MARK: - Actions

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
        // Control-click is the documented equivalent of a right-click on macOS,
        // and is the only way to reach the menu on a single-button mouse.
        let isControlClick = event?.modifierFlags.contains(.control) ?? false

        if isRightClick || isControlClick {
            presentMenu()
        } else {
            viewModel.toggle()
        }
    }

    /// Show the menu for this click only.
    ///
    /// The menu is attached, clicked open, then detached in `menuDidClose`.
    /// Leaving `statusItem.menu` permanently assigned would make AppKit open the
    /// menu on every click and the left-click toggle would never fire.
    /// `NSStatusItem.popUpMenu(_:)` would do this in one call but is deprecated.
    private func presentMenu() {
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    @objc private func scopeSelected(_ sender: NSMenuItem) {
        guard let scope = sender.representedObject as? SleepScope else { return }
        viewModel.select(scope: scope)
    }

    @objc private func launchAtLoginToggled() {
        viewModel.setLaunchAtLogin(!viewModel.launchesAtLogin)
    }
}
