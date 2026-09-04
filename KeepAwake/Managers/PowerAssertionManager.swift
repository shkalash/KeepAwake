//
//  PowerAssertionManager.swift
//  KeepAwake
//

import Foundation
import IOKit.pwr_mgt
import os

/// Holds IOKit power assertions to keep the Mac awake.
///
/// Responsibilities:
/// - Acquire one assertion per type required by the active `SleepScope`.
/// - Release them on request, on deinit, and before acquiring a different scope.
/// - Report acquisition failure rather than silently pretending to be engaged.
///
/// Assertions are process-scoped: the kernel drops them when the process exits,
/// so a crash cannot leave the machine permanently awake. Explicit release on
/// quit is still done for hygiene and so `pmset` reflects reality immediately.
@MainActor
final class PowerAssertionManager: SleepPreventing {
    private var assertionIDs: [IOPMAssertionID] = []
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "KeepAwake",
                                category: "PowerAssertion")

    var isEngaged: Bool { !assertionIDs.isEmpty }

    func engage(scope: SleepScope) throws {
        // Replace rather than accumulate, so switching scope mid-session cannot
        // strand the previous scope's assertions.
        disengage()

        for assertionType in scope.assertionTypes {
            var assertionID = IOPMAssertionID(0)
            let status = IOPMAssertionCreateWithName(
                assertionType as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                AppConstants.assertionReason as CFString,
                &assertionID
            )

            guard status == kIOReturnSuccess else {
                // Unwind the assertions already taken for this scope so a partial
                // failure leaves nothing held.
                disengage()
                throw PowerAssertionError.creationFailed(assertionType: assertionType,
                                                         status: status)
            }
            assertionIDs.append(assertionID)
        }
    }

    func disengage() {
        for assertionID in assertionIDs {
            let status = IOPMAssertionRelease(assertionID)
            if status != kIOReturnSuccess {
                // Nothing actionable at the call site: the assertion still dies
                // with the process. Worth recording because a release failure
                // means pmset will disagree with the UI until quit.
                logger.error("Failed to release power assertion \(assertionID): \(status)")
            }
        }
        assertionIDs.removeAll()
    }

    deinit {
        // Not routed through disengage(): deinit is nonisolated, and the kernel
        // reclaims the assertions at process exit regardless.
        for assertionID in assertionIDs {
            IOPMAssertionRelease(assertionID)
        }
    }
}
