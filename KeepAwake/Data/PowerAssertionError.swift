//
//  PowerAssertionError.swift
//  KeepAwake
//

import Foundation

/// Failures raised while acquiring or releasing an IOKit power assertion.
///
/// Modelled as a typed error so the view model can distinguish "the user asked to
/// stay awake" from "the system actually agreed", and refuse to show the awake
/// icon when the assertion did not take.
enum PowerAssertionError: Error, Equatable {
    /// `IOPMAssertionCreateWithName` returned a non-success `IOReturn` for the
    /// given assertion type. The associated value is the raw `IOReturn` code.
    case creationFailed(assertionType: String, status: Int32)
}
