//
//  SleepPreventing.swift
//  KeepAwake
//

import Foundation

/// Holds off idle sleep for as long as it is engaged.
///
/// Abstracted from IOKit so the view model's state machine can be tested without
/// touching real power assertions, and so an alternative backend could be
/// substituted without changing any calling code.
@MainActor
protocol SleepPreventing: AnyObject {
    /// Whether assertions are currently held.
    var isEngaged: Bool { get }

    /// Acquire the assertions for `scope`, replacing any currently held.
    ///
    /// Implementations must be idempotent by replacement: calling this while
    /// already engaged releases the previous assertions before taking the new
    /// ones, which is what a scope change during an active session needs.
    ///
    /// - Throws: `PowerAssertionError` if the system refused an assertion. On
    ///   throw the implementation must leave nothing held, so a failure cannot
    ///   leak a partially-applied scope.
    func engage(scope: SleepScope) throws

    /// Release every held assertion. Safe to call when nothing is held.
    func disengage()
}
