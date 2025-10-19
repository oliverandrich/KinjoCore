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

import Foundation

/// Represents a recurrence pattern for repeating tasks.
///
/// This type defines how often and on which days a task repeats.
/// It can express simple patterns like "daily" or "weekly", as well as
/// complex patterns like "every first Monday" or "every 3 days".
///
/// ## Examples
///
/// ```swift
/// // Daily
/// RecurringPattern(frequency: .daily, interval: 1)
///
/// // Every 3 days
/// RecurringPattern(frequency: .daily, interval: 3)
///
/// // Every Monday
/// RecurringPattern(frequency: .weekly, daysOfWeek: [.monday])
///
/// // Every Monday and Wednesday
/// RecurringPattern(frequency: .weekly, daysOfWeek: [.monday, .wednesday])
///
/// // Every first Monday of the month
/// RecurringPattern(frequency: .monthly, daysOfWeek: [.monday], weekOfMonth: 1)
///
/// // Every last Friday of the month
/// RecurringPattern(frequency: .monthly, daysOfWeek: [.friday], weekOfMonth: -1)
///
/// // Monthly on the 1st
/// RecurringPattern(frequency: .monthly, dayOfMonth: 1)
/// ```
public struct RecurringPattern: Sendable, Equatable {

    // MARK: - Frequency

    /// The base frequency of the recurrence.
    public enum Frequency: String, Sendable, Equatable {
        /// Repeats daily.
        case daily

        /// Repeats weekly.
        case weekly

        /// Repeats monthly.
        case monthly

        /// Repeats yearly.
        case yearly
    }

    /// Days of the week for weekly recurrence patterns.
    public enum Weekday: Int, Sendable, Equatable, CaseIterable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }

    // MARK: - Properties

    /// The frequency of the recurrence (daily, weekly, monthly, yearly).
    public let frequency: Frequency

    /// The interval between recurrences.
    ///
    /// For example, an interval of 2 with a daily frequency means "every 2 days".
    /// An interval of 3 with a weekly frequency means "every 3 weeks".
    /// Defaults to 1.
    public let interval: Int

    /// The days of the week on which the task recurs.
    ///
    /// Only applicable for weekly and monthly frequencies.
    /// For example: `[.monday, .wednesday]` for every Monday and Wednesday.
    public let daysOfWeek: [Weekday]?

    /// The day of the month on which the task recurs (1-31).
    ///
    /// Only applicable for monthly frequency.
    /// For example: `1` for the 1st of each month, `15` for the 15th.
    /// Use `-1` for the last day of the month.
    public let dayOfMonth: Int?

    /// The week of the month for positional recurrence (1-5, or -1 for last).
    ///
    /// Only applicable for monthly frequency combined with `daysOfWeek`.
    /// For example: `1` for "first Monday", `2` for "second Tuesday",
    /// `-1` for "last Friday".
    public let weekOfMonth: Int?

    // MARK: - Initialisation

    /// Creates a new recurring pattern.
    ///
    /// - Parameters:
    ///   - frequency: The frequency of the recurrence. Required.
    ///   - interval: The interval between recurrences. Defaults to 1.
    ///   - daysOfWeek: Optional days of the week for weekly/monthly patterns.
    ///   - dayOfMonth: Optional day of the month for monthly patterns.
    ///   - weekOfMonth: Optional week of the month for positional monthly patterns.
    public init(
        frequency: Frequency,
        interval: Int = 1,
        daysOfWeek: [Weekday]? = nil,
        dayOfMonth: Int? = nil,
        weekOfMonth: Int? = nil
    ) {
        self.frequency = frequency
        self.interval = max(1, interval) // Ensure interval is at least 1
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.weekOfMonth = weekOfMonth
    }

    // MARK: - Convenience Factory Methods

    /// Creates a daily recurrence pattern.
    ///
    /// - Parameter interval: How many days between recurrences. Defaults to 1 (every day).
    /// - Returns: A daily recurrence pattern.
    public static func daily(interval: Int = 1) -> RecurringPattern {
        RecurringPattern(frequency: .daily, interval: interval)
    }

    /// Creates a weekly recurrence pattern.
    ///
    /// - Parameters:
    ///   - interval: How many weeks between recurrences. Defaults to 1 (every week).
    ///   - daysOfWeek: Which days of the week to recur on. Required for weekly patterns.
    /// - Returns: A weekly recurrence pattern.
    public static func weekly(interval: Int = 1, daysOfWeek: [Weekday]) -> RecurringPattern {
        RecurringPattern(frequency: .weekly, interval: interval, daysOfWeek: daysOfWeek)
    }

    /// Creates a monthly recurrence pattern on a specific day of the month.
    ///
    /// - Parameters:
    ///   - interval: How many months between recurrences. Defaults to 1 (every month).
    ///   - dayOfMonth: Which day of the month to recur on (1-31, or -1 for last day).
    /// - Returns: A monthly recurrence pattern.
    public static func monthly(interval: Int = 1, dayOfMonth: Int) -> RecurringPattern {
        RecurringPattern(frequency: .monthly, interval: interval, dayOfMonth: dayOfMonth)
    }

    /// Creates a monthly recurrence pattern on a specific weekday (e.g., "first Monday").
    ///
    /// - Parameters:
    ///   - interval: How many months between recurrences. Defaults to 1 (every month).
    ///   - weekday: Which day of the week to recur on.
    ///   - weekOfMonth: Which week of the month (1-5 for first-fifth, -1 for last).
    /// - Returns: A monthly recurrence pattern.
    public static func monthly(interval: Int = 1, weekday: Weekday, weekOfMonth: Int) -> RecurringPattern {
        RecurringPattern(frequency: .monthly, interval: interval, daysOfWeek: [weekday], weekOfMonth: weekOfMonth)
    }

    /// Creates a yearly recurrence pattern.
    ///
    /// - Parameter interval: How many years between recurrences. Defaults to 1 (every year).
    /// - Returns: A yearly recurrence pattern.
    public static func yearly(interval: Int = 1) -> RecurringPattern {
        RecurringPattern(frequency: .yearly, interval: interval)
    }
}
