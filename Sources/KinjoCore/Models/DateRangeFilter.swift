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

// Disambiguate Foundation.Calendar from EventKit's EKCalendar
typealias FoundationCalendar = Foundation.Calendar

/// Filter options for filtering reminders by date range.
public enum DateRangeFilter: Sendable, Hashable, Codable {

    /// No date filtering - returns all reminders regardless of due date.
    case all

    /// Returns only reminders due today.
    case today

    /// Returns only reminders due tomorrow.
    case tomorrow

    /// Returns only reminders due this week (Monday to Sunday).
    case thisWeek

    /// Returns only reminders due this month.
    case thisMonth

    /// Returns only reminders due within a custom date range.
    /// - Parameters:
    ///   - from: The start date (inclusive)
    ///   - to: The end date (inclusive)
    case custom(from: Date, to: Date)

    // MARK: - Helper Methods

    /// Returns the date range for this filter.
    ///
    /// - Returns: A tuple containing the start and end dates, or `nil` for `.all`.
    public func dateRange() -> (start: Date, end: Date)? {
        var calendar = FoundationCalendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday

        switch self {
        case .all:
            return nil

        case .today:
            let start = calendar.startOfDay(for: Date())
            var components = DateComponents()
            components.day = 1
            let end = calendar.date(byAdding: components, to: start)!
            return (start, end)

        case .tomorrow:
            let today = calendar.startOfDay(for: Date())
            var components = DateComponents()
            components.day = 1
            let tomorrow = calendar.date(byAdding: components, to: today)!
            let dayAfterTomorrow = calendar.date(byAdding: components, to: tomorrow)!
            return (tomorrow, dayAfterTomorrow)

        case .thisWeek:
            let now = Date()
            // Get the start of the week (Monday)
            let componentSet: Set<FoundationCalendar.Component> = [.yearForWeekOfYear, .weekOfYear]
            let components = calendar.dateComponents(componentSet, from: now)
            let startOfWeek = calendar.date(from: components)!

            // Get the end of the week (7 days later)
            var weekComponents = DateComponents()
            weekComponents.day = 7
            let endOfWeek = calendar.date(byAdding: weekComponents, to: startOfWeek)!
            return (startOfWeek, endOfWeek)

        case .thisMonth:
            let now = Date()
            // Get the start of the month
            let componentSet: Set<FoundationCalendar.Component> = [.year, .month]
            let components = calendar.dateComponents(componentSet, from: now)
            let startOfMonth = calendar.date(from: components)!
            // Get the start of next month (which is the end of this month)
            var monthComponents = DateComponents()
            monthComponents.month = 1
            let startOfNextMonth = calendar.date(byAdding: monthComponents, to: startOfMonth)!
            return (startOfMonth, startOfNextMonth)

        case .custom(let from, let to):
            let start = calendar.startOfDay(for: from)
            // Add one day to 'to' to make it inclusive (end of the 'to' day)
            var components = DateComponents()
            components.day = 1
            let end = calendar.date(byAdding: components, to: calendar.startOfDay(for: to))!
            return (start, end)
        }
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .all:
            hasher.combine(0)
        case .today:
            hasher.combine(1)
        case .tomorrow:
            hasher.combine(2)
        case .thisWeek:
            hasher.combine(3)
        case .thisMonth:
            hasher.combine(4)
        case .custom(let from, let to):
            hasher.combine(5)
            hasher.combine(from)
            hasher.combine(to)
        }
    }

    public static func == (lhs: DateRangeFilter, rhs: DateRangeFilter) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all), (.today, .today), (.tomorrow, .tomorrow), (.thisWeek, .thisWeek), (.thisMonth, .thisMonth):
            return true
        case (.custom(let lhsFrom, let lhsTo), .custom(let rhsFrom, let rhsTo)):
            return lhsFrom == rhsFrom && lhsTo == rhsTo
        default:
            return false
        }
    }
}
