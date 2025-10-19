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

/// A day of the week for use in recurrence rules.
///
/// This enum represents the seven days of the week, with raw values matching
/// those used by EventKit's `EKWeekday`.
public enum Weekday: Int, Sendable, Hashable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    // MARK: - Initialisation

    /// Creates a weekday from an EventKit weekday value.
    ///
    /// - Parameter ekWeekday: The EventKit weekday value.
    public init(from ekWeekday: EKWeekday) {
        self = Weekday(rawValue: ekWeekday.rawValue) ?? .sunday
    }

    // MARK: - Conversion

    /// Converts this weekday to an EventKit weekday value.
    ///
    /// - Returns: The corresponding `EKWeekday` value.
    public func toEKWeekday() -> EKWeekday {
        EKWeekday(rawValue: self.rawValue) ?? .sunday
    }
}

/// A day of the week with an optional week number for use in recurrence rules.
///
/// This type wraps `EKRecurrenceDayOfWeek` to provide a clean, Swift-native interface
/// for specifying which days of the week a reminder should repeat on, with optional
/// positional information (e.g., "the first Monday" or "the last Friday").
public struct RecurrenceDayOfWeek: Sendable, Hashable {

    // MARK: - Properties

    /// The day of the week.
    public let dayOfWeek: Weekday

    /// The week number within the recurrence interval.
    ///
    /// - `nil`: Matches all occurrences of the day (e.g., "every Monday")
    /// - Positive values (1-5): Matches the nth occurrence (e.g., 1 = first Monday, 2 = second Monday)
    /// - Negative values (-1 to -5): Counts from the end (e.g., -1 = last Monday, -2 = second-to-last Monday)
    ///
    /// Valid range: -53...53 (excluding 0). Values outside EventKit's supported range will be clamped.
    public let weekNumber: Int?

    // MARK: - Initialisation

    /// Creates a recurrence day of the week.
    ///
    /// - Parameters:
    ///   - dayOfWeek: The day of the week.
    ///   - weekNumber: Optional week number (1-5 for first through fifth, -1 to -5 for last through fifth-to-last).
    public init(_ dayOfWeek: Weekday, weekNumber: Int? = nil) {
        self.dayOfWeek = dayOfWeek
        self.weekNumber = weekNumber
    }

    /// Creates a recurrence day of the week from an EventKit recurrence day of week.
    ///
    /// - Parameter ekDayOfWeek: The EventKit recurrence day of week.
    public init(from ekDayOfWeek: EKRecurrenceDayOfWeek) {
        self.dayOfWeek = Weekday(from: ekDayOfWeek.dayOfTheWeek)
        self.weekNumber = ekDayOfWeek.weekNumber == 0 ? nil : ekDayOfWeek.weekNumber
    }

    // MARK: - Conversion

    /// Converts this recurrence day of week to an EventKit recurrence day of week.
    ///
    /// - Returns: The corresponding `EKRecurrenceDayOfWeek` object.
    public func toEKRecurrenceDayOfWeek() -> EKRecurrenceDayOfWeek {
        if let weekNumber = weekNumber {
            return EKRecurrenceDayOfWeek(dayOfTheWeek: dayOfWeek.toEKWeekday(), weekNumber: weekNumber)
        } else {
            return EKRecurrenceDayOfWeek(dayOfWeek.toEKWeekday())
        }
    }

    // MARK: - Convenience Factory Methods

    /// Creates a recurrence day for every occurrence of the specified day.
    ///
    /// - Parameter dayOfWeek: The day of the week.
    /// - Returns: A recurrence day matching all occurrences.
    public static func every(_ dayOfWeek: Weekday) -> RecurrenceDayOfWeek {
        RecurrenceDayOfWeek(dayOfWeek, weekNumber: nil)
    }

    /// Creates a recurrence day for the first occurrence of the specified day.
    ///
    /// - Parameter dayOfWeek: The day of the week.
    /// - Returns: A recurrence day matching the first occurrence.
    public static func first(_ dayOfWeek: Weekday) -> RecurrenceDayOfWeek {
        RecurrenceDayOfWeek(dayOfWeek, weekNumber: 1)
    }

    /// Creates a recurrence day for the second occurrence of the specified day.
    ///
    /// - Parameter dayOfWeek: The day of the week.
    /// - Returns: A recurrence day matching the second occurrence.
    public static func second(_ dayOfWeek: Weekday) -> RecurrenceDayOfWeek {
        RecurrenceDayOfWeek(dayOfWeek, weekNumber: 2)
    }

    /// Creates a recurrence day for the third occurrence of the specified day.
    ///
    /// - Parameter dayOfWeek: The day of the week.
    /// - Returns: A recurrence day matching the third occurrence.
    public static func third(_ dayOfWeek: Weekday) -> RecurrenceDayOfWeek {
        RecurrenceDayOfWeek(dayOfWeek, weekNumber: 3)
    }

    /// Creates a recurrence day for the fourth occurrence of the specified day.
    ///
    /// - Parameter dayOfWeek: The day of the week.
    /// - Returns: A recurrence day matching the fourth occurrence.
    public static func fourth(_ dayOfWeek: Weekday) -> RecurrenceDayOfWeek {
        RecurrenceDayOfWeek(dayOfWeek, weekNumber: 4)
    }

    /// Creates a recurrence day for the fifth occurrence of the specified day.
    ///
    /// - Parameter dayOfWeek: The day of the week.
    /// - Returns: A recurrence day matching the fifth occurrence.
    public static func fifth(_ dayOfWeek: Weekday) -> RecurrenceDayOfWeek {
        RecurrenceDayOfWeek(dayOfWeek, weekNumber: 5)
    }

    /// Creates a recurrence day for the last occurrence of the specified day.
    ///
    /// - Parameter dayOfWeek: The day of the week.
    /// - Returns: A recurrence day matching the last occurrence.
    public static func last(_ dayOfWeek: Weekday) -> RecurrenceDayOfWeek {
        RecurrenceDayOfWeek(dayOfWeek, weekNumber: -1)
    }

    /// Creates a recurrence day for the second-to-last occurrence of the specified day.
    ///
    /// - Parameter dayOfWeek: The day of the week.
    /// - Returns: A recurrence day matching the second-to-last occurrence.
    public static func secondToLast(_ dayOfWeek: Weekday) -> RecurrenceDayOfWeek {
        RecurrenceDayOfWeek(dayOfWeek, weekNumber: -2)
    }
}
