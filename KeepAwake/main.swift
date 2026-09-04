//
//  main.swift
//  KeepAwake
//
//  Top-level entry point rather than `@main` on an `App` type: this is a pure
//  AppKit agent with no SwiftUI scene, and `NSApplication` has to be configured
//  as an accessory app before any window machinery is touched.
//

import AppKit

let application = NSApplication.shared
// Belt and braces with INFOPLIST_KEY_LSUIElement: no Dock icon, no menu bar
// application menu, no window on launch.
application.setActivationPolicy(.accessory)

let delegate = AppDelegate()
application.delegate = delegate
application.run()
