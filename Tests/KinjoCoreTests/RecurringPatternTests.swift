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

import Testing
@testable import KinjoCore

@Suite("RecurringPattern Tests")
struct RecurringPatternTests {

    // MARK: - Factory Method Tests

    @Test("RecurringPattern.daily creates daily pattern")
    func recurringPatternDailyCreatesPattern() {
        let pattern = RecurringPattern.daily()

        #expect(pattern.frequency == .daily)
        #expect(pattern.interval == 1)
        #expect(pattern.daysOfWeek == nil)
        #expect(pattern.dayOfMonth == nil)
        #expect(pattern.weekOfMonth == nil)
    }

    @Test("RecurringPattern.daily with interval creates pattern")
    func recurringPatternDailyWithIntervalCreatesPattern() {
        let pattern = RecurringPattern.daily(interval: 3)

        #expect(pattern.frequency == .daily)
        #expect(pattern.interval == 3)
        #expect(pattern.daysOfWeek == nil)
        #expect(pattern.dayOfMonth == nil)
        #expect(pattern.weekOfMonth == nil)
    }

    @Test("RecurringPattern.weekly creates weekly pattern")
    func recurringPatternWeeklyCreatesPattern() {
        let pattern = RecurringPattern.weekly(daysOfWeek: [.monday, .wednesday])

        #expect(pattern.frequency == .weekly)
        #expect(pattern.interval == 1)
        #expect(pattern.daysOfWeek == [.monday, .wednesday])
        #expect(pattern.dayOfMonth == nil)
        #expect(pattern.weekOfMonth == nil)
    }

    @Test("RecurringPattern.weekly with interval creates pattern")
    func recurringPatternWeeklyWithIntervalCreatesPattern() {
        let pattern = RecurringPattern.weekly(interval: 2, daysOfWeek: [.friday])

        #expect(pattern.frequency == .weekly)
        #expect(pattern.interval == 2)
        #expect(pattern.daysOfWeek == [.friday])
        #expect(pattern.dayOfMonth == nil)
        #expect(pattern.weekOfMonth == nil)
    }

    @Test("RecurringPattern.monthly with dayOfMonth creates pattern")
    func recurringPatternMonthlyDayOfMonthCreatesPattern() {
        let pattern = RecurringPattern.monthly(dayOfMonth: 15)

        #expect(pattern.frequency == .monthly)
        #expect(pattern.interval == 1)
        #expect(pattern.daysOfWeek == nil)
        #expect(pattern.dayOfMonth == 15)
        #expect(pattern.weekOfMonth == nil)
    }

    @Test("RecurringPattern.monthly with dayOfMonth and interval creates pattern")
    func recurringPatternMonthlyDayOfMonthWithIntervalCreatesPattern() {
        let pattern = RecurringPattern.monthly(interval: 3, dayOfMonth: 1)

        #expect(pattern.frequency == .monthly)
        #expect(pattern.interval == 3)
        #expect(pattern.daysOfWeek == nil)
        #expect(pattern.dayOfMonth == 1)
        #expect(pattern.weekOfMonth == nil)
    }

    @Test("RecurringPattern.monthly with weekday creates pattern")
    func recurringPatternMonthlyWeekdayCreatesPattern() {
        let pattern = RecurringPattern.monthly(weekday: .monday, weekOfMonth: 1)

        #expect(pattern.frequency == .monthly)
        #expect(pattern.interval == 1)
        #expect(pattern.daysOfWeek == [.monday])
        #expect(pattern.dayOfMonth == nil)
        #expect(pattern.weekOfMonth == 1)
    }

    @Test("RecurringPattern.monthly with weekday and interval creates pattern")
    func recurringPatternMonthlyWeekdayWithIntervalCreatesPattern() {
        let pattern = RecurringPattern.monthly(interval: 2, weekday: .friday, weekOfMonth: -1)

        #expect(pattern.frequency == .monthly)
        #expect(pattern.interval == 2)
        #expect(pattern.daysOfWeek == [.friday])
        #expect(pattern.dayOfMonth == nil)
        #expect(pattern.weekOfMonth == -1)
    }

    @Test("RecurringPattern.yearly creates yearly pattern")
    func recurringPatternYearlyCreatesPattern() {
        let pattern = RecurringPattern.yearly()

        #expect(pattern.frequency == .yearly)
        #expect(pattern.interval == 1)
        #expect(pattern.daysOfWeek == nil)
        #expect(pattern.dayOfMonth == nil)
        #expect(pattern.weekOfMonth == nil)
    }

    @Test("RecurringPattern.yearly with interval creates pattern")
    func recurringPatternYearlyWithIntervalCreatesPattern() {
        let pattern = RecurringPattern.yearly(interval: 2)

        #expect(pattern.frequency == .yearly)
        #expect(pattern.interval == 2)
        #expect(pattern.daysOfWeek == nil)
        #expect(pattern.dayOfMonth == nil)
        #expect(pattern.weekOfMonth == nil)
    }

    // MARK: - Initialiser Tests

    @Test("RecurringPattern init enforces minimum interval of 1")
    func recurringPatternInitEnforcesMinimumInterval() {
        let pattern = RecurringPattern(frequency: .daily, interval: 0)

        #expect(pattern.interval == 1)
    }

    @Test("RecurringPattern init enforces minimum interval with negative value")
    func recurringPatternInitEnforcesMinimumIntervalNegative() {
        let pattern = RecurringPattern(frequency: .daily, interval: -5)

        #expect(pattern.interval == 1)
    }

    @Test("RecurringPattern init allows valid interval")
    func recurringPatternInitAllowsValidInterval() {
        let pattern = RecurringPattern(frequency: .daily, interval: 7)

        #expect(pattern.interval == 7)
    }

    // MARK: - Weekday Tests

    @Test("RecurringPattern Weekday rawValue matches expected values")
    func recurringPatternWeekdayRawValueMatchesExpected() {
        #expect(RecurringPattern.Weekday.sunday.rawValue == 1)
        #expect(RecurringPattern.Weekday.monday.rawValue == 2)
        #expect(RecurringPattern.Weekday.tuesday.rawValue == 3)
        #expect(RecurringPattern.Weekday.wednesday.rawValue == 4)
        #expect(RecurringPattern.Weekday.thursday.rawValue == 5)
        #expect(RecurringPattern.Weekday.friday.rawValue == 6)
        #expect(RecurringPattern.Weekday.saturday.rawValue == 7)
    }

    @Test("RecurringPattern Weekday allCases contains all weekdays")
    func recurringPatternWeekdayAllCasesContainsAll() {
        let allWeekdays = RecurringPattern.Weekday.allCases

        #expect(allWeekdays.count == 7)
        #expect(allWeekdays.contains(.sunday))
        #expect(allWeekdays.contains(.monday))
        #expect(allWeekdays.contains(.tuesday))
        #expect(allWeekdays.contains(.wednesday))
        #expect(allWeekdays.contains(.thursday))
        #expect(allWeekdays.contains(.friday))
        #expect(allWeekdays.contains(.saturday))
    }

    // MARK: - Equatable Tests

    @Test("RecurringPattern equality works for identical patterns")
    func recurringPatternEqualityWorksForIdentical() {
        let pattern1 = RecurringPattern.daily(interval: 3)
        let pattern2 = RecurringPattern.daily(interval: 3)

        #expect(pattern1 == pattern2)
    }

    @Test("RecurringPattern inequality works for different patterns")
    func recurringPatternInequalityWorksForDifferent() {
        let pattern1 = RecurringPattern.daily(interval: 1)
        let pattern2 = RecurringPattern.daily(interval: 2)

        #expect(pattern1 != pattern2)
    }

    @Test("RecurringPattern equality works for complex patterns")
    func recurringPatternEqualityWorksForComplex() {
        let pattern1 = RecurringPattern.monthly(interval: 2, weekday: .monday, weekOfMonth: 1)
        let pattern2 = RecurringPattern.monthly(interval: 2, weekday: .monday, weekOfMonth: 1)

        #expect(pattern1 == pattern2)
    }

    @Test("RecurringPattern inequality works for different weekdays")
    func recurringPatternInequalityWorksForDifferentWeekdays() {
        let pattern1 = RecurringPattern.weekly(daysOfWeek: [.monday, .wednesday])
        let pattern2 = RecurringPattern.weekly(daysOfWeek: [.tuesday, .thursday])

        #expect(pattern1 != pattern2)
    }

    // MARK: - Edge Case Tests

    @Test("RecurringPattern handles last day of month")
    func recurringPatternHandlesLastDayOfMonth() {
        let pattern = RecurringPattern.monthly(dayOfMonth: -1)

        #expect(pattern.frequency == .monthly)
        #expect(pattern.dayOfMonth == -1)
    }

    @Test("RecurringPattern handles last week of month")
    func recurringPatternHandlesLastWeekOfMonth() {
        let pattern = RecurringPattern.monthly(weekday: .friday, weekOfMonth: -1)

        #expect(pattern.frequency == .monthly)
        #expect(pattern.daysOfWeek == [.friday])
        #expect(pattern.weekOfMonth == -1)
    }

    @Test("RecurringPattern handles multiple weekdays")
    func recurringPatternHandlesMultipleWeekdays() {
        let pattern = RecurringPattern(
            frequency: .weekly,
            daysOfWeek: [.monday, .wednesday, .friday]
        )

        #expect(pattern.daysOfWeek?.count == 3)
        #expect(pattern.daysOfWeek?.contains(.monday) == true)
        #expect(pattern.daysOfWeek?.contains(.wednesday) == true)
        #expect(pattern.daysOfWeek?.contains(.friday) == true)
    }

    @Test("RecurringPattern handles first week of month")
    func recurringPatternHandlesFirstWeekOfMonth() {
        let pattern = RecurringPattern.monthly(weekday: .monday, weekOfMonth: 1)

        #expect(pattern.weekOfMonth == 1)
        #expect(pattern.daysOfWeek == [.monday])
    }

    @Test("RecurringPattern handles fifth week of month")
    func recurringPatternHandlesFifthWeekOfMonth() {
        let pattern = RecurringPattern.monthly(weekday: .tuesday, weekOfMonth: 5)

        #expect(pattern.weekOfMonth == 5)
        #expect(pattern.daysOfWeek == [.tuesday])
    }
}
