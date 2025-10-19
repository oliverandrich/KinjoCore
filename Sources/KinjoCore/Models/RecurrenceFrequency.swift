// Copyright (C) 2025 KinjoCore Contributors
//
// Licensed under the EUPL, Version 1.2 or – as soon they will be approved by
// the European Commission - subsequent versions of the EUPL (the "Licence");
// You may not use this work except in compliance with the Licence.
// You may obtain a copy of the Licence at:
//
// https://joinup.ec.europa.eu/software/page/eupl
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the Licence is distributed on an "AS IS" basis,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the Licence for the specific language governing permissions and
// limitations under the Licence.

import EventKit
import Foundation

/// The frequency of a recurrence rule.
///
/// This type wraps `EKRecurrenceFrequency` to provide a clean, Swift-native interface
/// for specifying how often a reminder repeats.
public enum RecurrenceFrequency: Int, Sendable, Hashable, CaseIterable {

    /// The reminder repeats daily.
    case daily = 0

    /// The reminder repeats weekly.
    case weekly = 1

    /// The reminder repeats monthly.
    case monthly = 2

    /// The reminder repeats yearly.
    case yearly = 3

    // MARK: - Initialisation

    /// Creates a recurrence frequency from an EventKit recurrence frequency.
    ///
    /// - Parameter frequency: The EventKit recurrence frequency.
    public init(from frequency: EKRecurrenceFrequency) {
        switch frequency {
        case .daily:
            self = .daily
        case .weekly:
            self = .weekly
        case .monthly:
            self = .monthly
        case .yearly:
            self = .yearly
        @unknown default:
            // Default to daily for unknown future cases
            self = .daily
        }
    }

    // MARK: - Conversion

    /// Converts this recurrence frequency to an EventKit recurrence frequency.
    ///
    /// - Returns: The corresponding `EKRecurrenceFrequency` value.
    public func toEKRecurrenceFrequency() -> EKRecurrenceFrequency {
        switch self {
        case .daily:
            return .daily
        case .weekly:
            return .weekly
        case .monthly:
            return .monthly
        case .yearly:
            return .yearly
        }
    }
}
