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

/// The end condition for a recurrence rule.
///
/// This type wraps `EKRecurrenceEnd` to provide a clean, Swift-native interface
/// for specifying when a recurring reminder should stop repeating.
public enum RecurrenceEnd: Sendable, Hashable {

    /// The recurrence never ends.
    case never

    /// The recurrence ends after a specific date.
    ///
    /// - Parameter date: The end date. The recurrence will stop after this date.
    case afterDate(Date)

    /// The recurrence ends after a specific number of occurrences.
    ///
    /// - Parameter count: The number of occurrences. Must be greater than 0.
    case afterOccurrences(Int)

    // MARK: - Initialisation

    /// Creates a recurrence end from an EventKit recurrence end.
    ///
    /// - Parameter recurrenceEnd: The EventKit recurrence end, or `nil` for never-ending recurrence.
    public init(from recurrenceEnd: EKRecurrenceEnd?) {
        guard let recurrenceEnd = recurrenceEnd else {
            self = .never
            return
        }

        if let endDate = recurrenceEnd.endDate {
            self = .afterDate(endDate)
        } else if recurrenceEnd.occurrenceCount > 0 {
            self = .afterOccurrences(recurrenceEnd.occurrenceCount)
        } else {
            self = .never
        }
    }

    // MARK: - Conversion

    /// Converts this recurrence end to an EventKit recurrence end.
    ///
    /// - Returns: The corresponding `EKRecurrenceEnd` object, or `nil` for `.never`.
    public func toEKRecurrenceEnd() -> EKRecurrenceEnd? {
        switch self {
        case .never:
            return nil

        case .afterDate(let date):
            return EKRecurrenceEnd(end: date)

        case .afterOccurrences(let count):
            return EKRecurrenceEnd(occurrenceCount: count)
        }
    }
}
