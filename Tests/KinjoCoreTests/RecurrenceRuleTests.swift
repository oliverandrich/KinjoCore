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
import EventKit
@testable import KinjoCore

@Suite("Recurrence Rule Tests")
struct RecurrenceRuleTests {

    // MARK: - RecurrenceFrequency Tests

    @Test("RecurrenceFrequency converts to and from EventKit frequency")
    func frequencyConversion() {
        let frequencies: [(RecurrenceFrequency, EKRecurrenceFrequency)] = [
            (.daily, .daily),
            (.weekly, .weekly),
            (.monthly, .monthly),
            (.yearly, .yearly)
        ]

        for (kinjoFreq, ekFreq) in frequencies {
            // Test conversion to EKRecurrenceFrequency
            #expect(kinjoFreq.toEKRecurrenceFrequency() == ekFreq)

            // Test conversion from EKRecurrenceFrequency
            let converted = RecurrenceFrequency(from: ekFreq)
            #expect(converted == kinjoFreq)
        }
    }

    // MARK: - RecurrenceEnd Tests

    @Test("RecurrenceEnd.never converts correctly")
    func endNeverConversion() {
        let end = RecurrenceEnd.never
        let ekEnd = end.toEKRecurrenceEnd()

        #expect(ekEnd == nil)

        // Test reverse conversion
        let converted = RecurrenceEnd(from: nil)
        #expect(converted == .never)
    }

    @Test("RecurrenceEnd.afterDate converts correctly")
    func endAfterDateConversion() {
        let testDate = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let end = RecurrenceEnd.afterDate(testDate)
        let ekEnd = end.toEKRecurrenceEnd()

        #expect(ekEnd != nil)
        #expect(ekEnd?.endDate == testDate)

        // Test reverse conversion
        let converted = RecurrenceEnd(from: ekEnd)
        if case .afterDate(let date) = converted {
            #expect(date == testDate)
        } else {
            Issue.record("Expected .afterDate case")
        }
    }

    @Test("RecurrenceEnd.afterOccurrences converts correctly")
    func endAfterOccurrencesConversion() {
        let end = RecurrenceEnd.afterOccurrences(12)
        let ekEnd = end.toEKRecurrenceEnd()

        #expect(ekEnd != nil)
        #expect(ekEnd?.occurrenceCount == 12)

        // Test reverse conversion
        let converted = RecurrenceEnd(from: ekEnd)
        if case .afterOccurrences(let count) = converted {
            #expect(count == 12)
        } else {
            Issue.record("Expected .afterOccurrences case")
        }
    }

    // MARK: - Weekday Tests

    @Test("Weekday converts to and from EKWeekday")
    func weekdayConversion() {
        let weekdays: [(Weekday, EKWeekday)] = [
            (.sunday, .sunday),
            (.monday, .monday),
            (.tuesday, .tuesday),
            (.wednesday, .wednesday),
            (.thursday, .thursday),
            (.friday, .friday),
            (.saturday, .saturday)
        ]

        for (kinjoDay, ekDay) in weekdays {
            // Test conversion to EKWeekday
            #expect(kinjoDay.toEKWeekday() == ekDay)

            // Test conversion from EKWeekday
            let converted = Weekday(from: ekDay)
            #expect(converted == kinjoDay)
        }
    }

    // MARK: - RecurrenceDayOfWeek Tests

    @Test("RecurrenceDayOfWeek without week number converts correctly")
    func dayOfWeekWithoutWeekNumber() {
        let dayOfWeek = RecurrenceDayOfWeek(.monday, weekNumber: nil)
        let ekDayOfWeek = dayOfWeek.toEKRecurrenceDayOfWeek()

        #expect(ekDayOfWeek.dayOfTheWeek == .monday)
        #expect(ekDayOfWeek.weekNumber == 0)

        // Test reverse conversion
        let converted = RecurrenceDayOfWeek(from: ekDayOfWeek)
        #expect(converted.dayOfWeek == .monday)
        #expect(converted.weekNumber == nil)
    }

    @Test("RecurrenceDayOfWeek with positive week number converts correctly")
    func dayOfWeekWithPositiveWeekNumber() {
        let dayOfWeek = RecurrenceDayOfWeek(.monday, weekNumber: 1)
        let ekDayOfWeek = dayOfWeek.toEKRecurrenceDayOfWeek()

        #expect(ekDayOfWeek.dayOfTheWeek == .monday)
        #expect(ekDayOfWeek.weekNumber == 1)

        // Test reverse conversion
        let converted = RecurrenceDayOfWeek(from: ekDayOfWeek)
        #expect(converted.dayOfWeek == .monday)
        #expect(converted.weekNumber == 1)
    }

    @Test("RecurrenceDayOfWeek with negative week number converts correctly")
    func dayOfWeekWithNegativeWeekNumber() {
        let dayOfWeek = RecurrenceDayOfWeek(.friday, weekNumber: -1)
        let ekDayOfWeek = dayOfWeek.toEKRecurrenceDayOfWeek()

        #expect(ekDayOfWeek.dayOfTheWeek == .friday)
        #expect(ekDayOfWeek.weekNumber == -1)

        // Test reverse conversion
        let converted = RecurrenceDayOfWeek(from: ekDayOfWeek)
        #expect(converted.dayOfWeek == .friday)
        #expect(converted.weekNumber == -1)
    }

    @Test("RecurrenceDayOfWeek convenience factory methods work correctly")
    func dayOfWeekConvenienceMethods() {
        // Test .every()
        let everyMonday = RecurrenceDayOfWeek.every(.monday)
        #expect(everyMonday.dayOfWeek == .monday)
        #expect(everyMonday.weekNumber == nil)

        // Test .first()
        let firstMonday = RecurrenceDayOfWeek.first(.monday)
        #expect(firstMonday.dayOfWeek == .monday)
        #expect(firstMonday.weekNumber == 1)

        // Test .last()
        let lastFriday = RecurrenceDayOfWeek.last(.friday)
        #expect(lastFriday.dayOfWeek == .friday)
        #expect(lastFriday.weekNumber == -1)

        // Test .second()
        let secondTuesday = RecurrenceDayOfWeek.second(.tuesday)
        #expect(secondTuesday.dayOfWeek == .tuesday)
        #expect(secondTuesday.weekNumber == 2)
    }

    // MARK: - Simple RecurrenceRule Tests

    @Test("RecurrenceRule daily rule converts correctly")
    func dailyRuleConversion() {
        let rule = RecurrenceRule.daily()
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.frequency == .daily)
        #expect(ekRule.interval == 1)
        #expect(ekRule.recurrenceEnd == nil)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.frequency == .daily)
        #expect(converted.interval == 1)
        #expect(converted.end == .never)
    }

    @Test("RecurrenceRule weekly rule converts correctly")
    func weeklyRuleConversion() {
        let rule = RecurrenceRule.weekly()
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.frequency == .weekly)
        #expect(ekRule.interval == 1)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.frequency == .weekly)
        #expect(converted.interval == 1)
    }

    @Test("RecurrenceRule monthly rule converts correctly")
    func monthlyRuleConversion() {
        let rule = RecurrenceRule.monthly()
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.frequency == .monthly)
        #expect(ekRule.interval == 1)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.frequency == .monthly)
        #expect(converted.interval == 1)
    }

    @Test("RecurrenceRule yearly rule converts correctly")
    func yearlyRuleConversion() {
        let rule = RecurrenceRule.yearly()
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.frequency == .yearly)
        #expect(ekRule.interval == 1)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.frequency == .yearly)
        #expect(converted.interval == 1)
    }

    // MARK: - Complex RecurrenceRule Tests

    @Test("RecurrenceRule with interval converts correctly")
    func ruleWithInterval() {
        let rule = RecurrenceRule.weekly(interval: 2)
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.frequency == .weekly)
        #expect(ekRule.interval == 2)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.interval == 2)
    }

    @Test("RecurrenceRule with end date converts correctly")
    func ruleWithEndDate() {
        let endDate = Date(timeIntervalSince1970: 1735689600) // 2025-01-01 00:00:00 UTC
        let rule = RecurrenceRule.daily(end: .afterDate(endDate))
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.recurrenceEnd?.endDate == endDate)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        if case .afterDate(let date) = converted.end {
            #expect(date == endDate)
        } else {
            Issue.record("Expected .afterDate end")
        }
    }

    @Test("RecurrenceRule with occurrence count converts correctly")
    func ruleWithOccurrenceCount() {
        let rule = RecurrenceRule.daily(end: .afterOccurrences(10))
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.recurrenceEnd?.occurrenceCount == 10)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        if case .afterOccurrences(let count) = converted.end {
            #expect(count == 10)
        } else {
            Issue.record("Expected .afterOccurrences end")
        }
    }

    @Test("RecurrenceRule with days of week converts correctly")
    func ruleWithDaysOfWeek() {
        let rule = RecurrenceRule.weekly(
            daysOfWeek: [.every(.monday), .every(.wednesday), .every(.friday)]
        )
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.daysOfTheWeek?.count == 3)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.daysOfTheWeek?.count == 3)
        #expect(converted.daysOfTheWeek?.contains { $0.dayOfWeek == .monday } == true)
        #expect(converted.daysOfTheWeek?.contains { $0.dayOfWeek == .wednesday } == true)
        #expect(converted.daysOfTheWeek?.contains { $0.dayOfWeek == .friday } == true)
    }

    @Test("RecurrenceRule with first Monday of month converts correctly")
    func ruleWithFirstMondayOfMonth() {
        let rule = RecurrenceRule.monthly(daysOfWeek: [.first(.monday)])
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.frequency == .monthly)
        #expect(ekRule.daysOfTheWeek?.count == 1)
        #expect(ekRule.daysOfTheWeek?.first?.dayOfTheWeek == .monday)
        #expect(ekRule.daysOfTheWeek?.first?.weekNumber == 1)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.daysOfTheWeek?.first?.dayOfWeek == .monday)
        #expect(converted.daysOfTheWeek?.first?.weekNumber == 1)
    }

    @Test("RecurrenceRule with last Friday of month converts correctly")
    func ruleWithLastFridayOfMonth() {
        let rule = RecurrenceRule.monthly(daysOfWeek: [.last(.friday)])
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.frequency == .monthly)
        #expect(ekRule.daysOfTheWeek?.count == 1)
        #expect(ekRule.daysOfTheWeek?.first?.dayOfTheWeek == .friday)
        #expect(ekRule.daysOfTheWeek?.first?.weekNumber == -1)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.daysOfTheWeek?.first?.dayOfWeek == .friday)
        #expect(converted.daysOfTheWeek?.first?.weekNumber == -1)
    }

    @Test("RecurrenceRule with days of month converts correctly")
    func ruleWithDaysOfMonth() {
        let rule = RecurrenceRule.monthly(daysOfMonth: [1, 15])
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.daysOfTheMonth?.count == 2)
        #expect(ekRule.daysOfTheMonth?.contains(NSNumber(value: 1)) == true)
        #expect(ekRule.daysOfTheMonth?.contains(NSNumber(value: 15)) == true)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.daysOfTheMonth?.contains(1) == true)
        #expect(converted.daysOfTheMonth?.contains(15) == true)
    }

    @Test("RecurrenceRule with last day of month converts correctly")
    func ruleWithLastDayOfMonth() {
        let rule = RecurrenceRule.monthly(daysOfMonth: [-1])
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.daysOfTheMonth?.count == 1)
        #expect(ekRule.daysOfTheMonth?.contains(NSNumber(value: -1)) == true)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.daysOfTheMonth?.contains(-1) == true)
    }

    @Test("RecurrenceRule with months of year converts correctly")
    func ruleWithMonthsOfYear() {
        let rule = RecurrenceRule.yearly(monthsOfYear: [1, 7, 12]) // January, July, December
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.monthsOfTheYear?.count == 3)
        #expect(ekRule.monthsOfTheYear?.contains(NSNumber(value: 1)) == true)
        #expect(ekRule.monthsOfTheYear?.contains(NSNumber(value: 7)) == true)
        #expect(ekRule.monthsOfTheYear?.contains(NSNumber(value: 12)) == true)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.monthsOfTheYear?.contains(1) == true)
        #expect(converted.monthsOfTheYear?.contains(7) == true)
        #expect(converted.monthsOfTheYear?.contains(12) == true)
    }

    @Test("RecurrenceRule interval enforces minimum of 1")
    func ruleIntervalMinimum() {
        // Try creating a rule with interval 0
        let rule = RecurrenceRule(frequency: .daily, interval: 0)

        // Should be clamped to 1
        #expect(rule.interval == 1)

        // Try with negative interval
        let negativeRule = RecurrenceRule(frequency: .daily, interval: -5)
        #expect(negativeRule.interval == 1)
    }

    // MARK: - Complex Scenarios

    @Test("RecurrenceRule with every Monday and Friday, every 2 weeks, 12 times")
    func complexWeeklyRule() {
        let rule = RecurrenceRule(
            frequency: .weekly,
            interval: 2,
            end: .afterOccurrences(12),
            daysOfTheWeek: [.every(.monday), .every(.friday)]
        )
        let ekRule = rule.toEKRecurrenceRule()

        #expect(ekRule.frequency == .weekly)
        #expect(ekRule.interval == 2)
        #expect(ekRule.recurrenceEnd?.occurrenceCount == 12)
        #expect(ekRule.daysOfTheWeek?.count == 2)

        // Test reverse conversion
        let converted = RecurrenceRule(from: ekRule)
        #expect(converted.frequency == .weekly)
        #expect(converted.interval == 2)
        if case .afterOccurrences(let count) = converted.end {
            #expect(count == 12)
        } else {
            Issue.record("Expected .afterOccurrences end")
        }
        #expect(converted.daysOfTheWeek?.count == 2)
    }

    @Test("RecurrenceRule roundtrip conversion preserves all properties")
    func roundtripConversion() {
        let originalRule = RecurrenceRule(
            frequency: .monthly,
            interval: 3,
            end: .afterOccurrences(24),
            daysOfTheWeek: [.first(.monday), .last(.friday)],
            daysOfTheMonth: [1, 15, -1]
        )

        // Convert to EKRecurrenceRule and back
        let ekRule = originalRule.toEKRecurrenceRule()
        let convertedRule = RecurrenceRule(from: ekRule)

        // Verify all properties match
        #expect(convertedRule.frequency == originalRule.frequency)
        #expect(convertedRule.interval == originalRule.interval)
        #expect(convertedRule.daysOfTheWeek?.count == originalRule.daysOfTheWeek?.count)
        #expect(convertedRule.daysOfTheMonth?.count == originalRule.daysOfTheMonth?.count)

        if case .afterOccurrences(let count) = convertedRule.end {
            #expect(count == 24)
        } else {
            Issue.record("Expected .afterOccurrences end")
        }
    }
}
