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

/// A recurrence rule for repeating reminders.
///
/// This type wraps `EKRecurrenceRule` to provide a clean, Swift-native interface
/// for specifying how and when a reminder should repeat.
///
/// ## Examples
///
/// ```swift
/// // Every day
/// let daily = RecurrenceRule(frequency: .daily)
///
/// // Every 2 weeks
/// let biweekly = RecurrenceRule(frequency: .weekly, interval: 2)
///
/// // Every Monday and Friday
/// let weekdays = RecurrenceRule(
///     frequency: .weekly,
///     daysOfTheWeek: [.every(.monday), .every(.friday)]
/// )
///
/// // First Monday of every month, 12 times
/// let firstMonday = RecurrenceRule(
///     frequency: .monthly,
///     daysOfTheWeek: [.first(.monday)],
///     end: .afterOccurrences(12)
/// )
///
/// // Last Friday of every month
/// let lastFriday = RecurrenceRule(
///     frequency: .monthly,
///     daysOfTheWeek: [.last(.friday)]
/// )
/// ```
public struct RecurrenceRule: Sendable, Hashable {

    // MARK: - Properties

    /// The frequency of the recurrence (daily, weekly, monthly, yearly).
    public let frequency: RecurrenceFrequency

    /// The interval between recurrences.
    ///
    /// For example, an interval of 2 with a weekly frequency means "every 2 weeks".
    /// Must be greater than 0. Defaults to 1.
    public let interval: Int

    /// The end condition for the recurrence.
    ///
    /// Defaults to `.never` (infinite recurrence).
    public let end: RecurrenceEnd

    /// The days of the week on which the reminder recurs.
    ///
    /// Only applicable for weekly, monthly, and yearly frequencies.
    /// For example: `[.every(.monday), .every(.friday)]` for every Monday and Friday.
    /// Use positional values like `.first(.monday)` for "first Monday of the month".
    public let daysOfTheWeek: [RecurrenceDayOfWeek]?

    /// The days of the month on which the reminder recurs.
    ///
    /// Only applicable for monthly and yearly frequencies.
    /// Valid values: 1-31 for specific days, -1 to -31 for counting from the end.
    /// For example: `[1, 15]` for the 1st and 15th of each month, `[-1]` for the last day.
    public let daysOfTheMonth: [Int]?

    /// The months of the year in which the reminder recurs.
    ///
    /// Only applicable for yearly frequency.
    /// Valid values: 1-12 (1 = January, 12 = December).
    /// For example: `[1, 7]` for January and July.
    public let monthsOfTheYear: [Int]?

    /// The weeks of the year in which the reminder recurs.
    ///
    /// Only applicable for yearly frequency.
    /// Valid values: 1-53 for specific weeks, -1 to -53 for counting from the end.
    /// For example: `[1, 26, 52]` for weeks 1, 26, and 52.
    public let weeksOfTheYear: [Int]?

    /// The days of the year on which the reminder recurs.
    ///
    /// Only applicable for yearly frequency.
    /// Valid values: 1-366 for specific days, -1 to -366 for counting from the end.
    /// For example: `[1]` for New Year's Day, `[100]` for the 100th day of the year.
    public let daysOfTheYear: [Int]?

    /// Filters which occurrences to include.
    ///
    /// Used in conjunction with other properties to specify which matching dates to include.
    /// Positive values select from the beginning, negative from the end.
    /// For example, with monthly frequency and `daysOfTheWeek: [.monday]`:
    /// - `setPositions: [1]` = first Monday of the month
    /// - `setPositions: [-1]` = last Monday of the month
    /// - `setPositions: [1, -1]` = first and last Monday of the month
    public let setPositions: [Int]?

    // MARK: - Initialisation

    /// Creates a recurrence rule with the specified parameters.
    ///
    /// - Parameters:
    ///   - frequency: The frequency of the recurrence. Required.
    ///   - interval: The interval between recurrences. Must be > 0. Defaults to 1.
    ///   - end: The end condition. Defaults to `.never`.
    ///   - daysOfTheWeek: Optional days of the week filter.
    ///   - daysOfTheMonth: Optional days of the month filter.
    ///   - monthsOfTheYear: Optional months filter.
    ///   - weeksOfTheYear: Optional weeks filter.
    ///   - daysOfTheYear: Optional days of the year filter.
    ///   - setPositions: Optional position filter.
    public init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        end: RecurrenceEnd = .never,
        daysOfTheWeek: [RecurrenceDayOfWeek]? = nil,
        daysOfTheMonth: [Int]? = nil,
        monthsOfTheYear: [Int]? = nil,
        weeksOfTheYear: [Int]? = nil,
        daysOfTheYear: [Int]? = nil,
        setPositions: [Int]? = nil
    ) {
        self.frequency = frequency
        self.interval = max(1, interval) // Ensure interval is at least 1
        self.end = end
        self.daysOfTheWeek = daysOfTheWeek
        self.daysOfTheMonth = daysOfTheMonth
        self.monthsOfTheYear = monthsOfTheYear
        self.weeksOfTheYear = weeksOfTheYear
        self.daysOfTheYear = daysOfTheYear
        self.setPositions = setPositions
    }

    /// Creates a recurrence rule from an EventKit recurrence rule.
    ///
    /// - Parameter ekRule: The EventKit recurrence rule.
    public init(from ekRule: EKRecurrenceRule) {
        self.frequency = RecurrenceFrequency(from: ekRule.frequency)
        self.interval = ekRule.interval
        self.end = RecurrenceEnd(from: ekRule.recurrenceEnd)

        // Convert days of the week
        if let ekDaysOfWeek = ekRule.daysOfTheWeek, !ekDaysOfWeek.isEmpty {
            self.daysOfTheWeek = ekDaysOfWeek.map { RecurrenceDayOfWeek(from: $0) }
        } else {
            self.daysOfTheWeek = nil
        }

        // Convert other properties
        self.daysOfTheMonth = ekRule.daysOfTheMonth?.isEmpty == false ? ekRule.daysOfTheMonth?.map { $0.intValue } : nil
        self.monthsOfTheYear = ekRule.monthsOfTheYear?.isEmpty == false ? ekRule.monthsOfTheYear?.map { $0.intValue } : nil
        self.weeksOfTheYear = ekRule.weeksOfTheYear?.isEmpty == false ? ekRule.weeksOfTheYear?.map { $0.intValue } : nil
        self.daysOfTheYear = ekRule.daysOfTheYear?.isEmpty == false ? ekRule.daysOfTheYear?.map { $0.intValue } : nil
        self.setPositions = ekRule.setPositions?.isEmpty == false ? ekRule.setPositions?.map { $0.intValue } : nil
    }

    // MARK: - Conversion

    /// Converts this recurrence rule to an EventKit recurrence rule.
    ///
    /// - Returns: The corresponding `EKRecurrenceRule` object.
    public func toEKRecurrenceRule() -> EKRecurrenceRule {
        // Convert days of the week
        let ekDaysOfWeek = daysOfTheWeek?.map { $0.toEKRecurrenceDayOfWeek() }

        // Convert other array properties to NSNumber arrays
        let ekDaysOfMonth = daysOfTheMonth?.map { NSNumber(value: $0) }
        let ekMonthsOfYear = monthsOfTheYear?.map { NSNumber(value: $0) }
        let ekWeeksOfYear = weeksOfTheYear?.map { NSNumber(value: $0) }
        let ekDaysOfYear = daysOfTheYear?.map { NSNumber(value: $0) }
        let ekSetPositions = setPositions?.map { NSNumber(value: $0) }

        // Get recurrence end
        let ekEnd = end.toEKRecurrenceEnd()

        // Create and return EKRecurrenceRule
        return EKRecurrenceRule(
            recurrenceWith: frequency.toEKRecurrenceFrequency(),
            interval: interval,
            daysOfTheWeek: ekDaysOfWeek,
            daysOfTheMonth: ekDaysOfMonth,
            monthsOfTheYear: ekMonthsOfYear,
            weeksOfTheYear: ekWeeksOfYear,
            daysOfTheYear: ekDaysOfYear,
            setPositions: ekSetPositions,
            end: ekEnd
        )
    }

    // MARK: - Convenience Factory Methods

    /// Creates a daily recurrence rule.
    ///
    /// - Parameters:
    ///   - interval: How many days between recurrences. Defaults to 1 (every day).
    ///   - end: When the recurrence should end. Defaults to `.never`.
    /// - Returns: A daily recurrence rule.
    public static func daily(interval: Int = 1, end: RecurrenceEnd = .never) -> RecurrenceRule {
        RecurrenceRule(frequency: .daily, interval: interval, end: end)
    }

    /// Creates a weekly recurrence rule.
    ///
    /// - Parameters:
    ///   - interval: How many weeks between recurrences. Defaults to 1 (every week).
    ///   - daysOfWeek: Which days of the week to recur on. If nil, uses the day of the reminder's due date.
    ///   - end: When the recurrence should end. Defaults to `.never`.
    /// - Returns: A weekly recurrence rule.
    public static func weekly(
        interval: Int = 1,
        daysOfWeek: [RecurrenceDayOfWeek]? = nil,
        end: RecurrenceEnd = .never
    ) -> RecurrenceRule {
        RecurrenceRule(frequency: .weekly, interval: interval, end: end, daysOfTheWeek: daysOfWeek)
    }

    /// Creates a monthly recurrence rule.
    ///
    /// - Parameters:
    ///   - interval: How many months between recurrences. Defaults to 1 (every month).
    ///   - daysOfWeek: Which days of the week to recur on (e.g., "first Monday").
    ///   - daysOfMonth: Which days of the month to recur on (1-31 or -1 for last day).
    ///   - end: When the recurrence should end. Defaults to `.never`.
    /// - Returns: A monthly recurrence rule.
    public static func monthly(
        interval: Int = 1,
        daysOfWeek: [RecurrenceDayOfWeek]? = nil,
        daysOfMonth: [Int]? = nil,
        end: RecurrenceEnd = .never
    ) -> RecurrenceRule {
        RecurrenceRule(
            frequency: .monthly,
            interval: interval,
            end: end,
            daysOfTheWeek: daysOfWeek,
            daysOfTheMonth: daysOfMonth
        )
    }

    /// Creates a yearly recurrence rule.
    ///
    /// - Parameters:
    ///   - interval: How many years between recurrences. Defaults to 1 (every year).
    ///   - monthsOfYear: Which months to recur in (1-12).
    ///   - daysOfMonth: Which days of the month to recur on.
    ///   - daysOfWeek: Which days of the week to recur on.
    ///   - end: When the recurrence should end. Defaults to `.never`.
    /// - Returns: A yearly recurrence rule.
    public static func yearly(
        interval: Int = 1,
        monthsOfYear: [Int]? = nil,
        daysOfMonth: [Int]? = nil,
        daysOfWeek: [RecurrenceDayOfWeek]? = nil,
        end: RecurrenceEnd = .never
    ) -> RecurrenceRule {
        RecurrenceRule(
            frequency: .yearly,
            interval: interval,
            end: end,
            daysOfTheWeek: daysOfWeek,
            daysOfTheMonth: daysOfMonth,
            monthsOfTheYear: monthsOfYear
        )
    }
}
