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
import Foundation
@testable import KinjoCore

@Suite("DateRangeFilter Tests")
struct DateRangeFilterTests {

    @Test("DateRangeFilter.all returns nil date range")
    func allReturnsNilDateRange() {
        let filter = DateRangeFilter.all
        let range = filter.dateRange()

        #expect(range == nil)
    }

    @Test("DateRangeFilter.today returns today's date range")
    func todayReturnsCorrectDateRange() {
        let filter = DateRangeFilter.today
        let range = filter.dateRange()

        #expect(range != nil)

        if let range = range {
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

            #expect(range.start == startOfToday)
            #expect(range.end == startOfTomorrow)
        }
    }

    @Test("DateRangeFilter.tomorrow returns tomorrow's date range")
    func tomorrowReturnsCorrectDateRange() {
        let filter = DateRangeFilter.tomorrow
        let range = filter.dateRange()

        #expect(range != nil)

        if let range = range {
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
            let startOfDayAfter = calendar.date(byAdding: .day, value: 2, to: startOfToday)!

            #expect(range.start == startOfTomorrow)
            #expect(range.end == startOfDayAfter)
        }
    }

    @Test("DateRangeFilter.thisWeek returns this week's date range")
    func thisWeekReturnsCorrectDateRange() {
        let filter = DateRangeFilter.thisWeek
        let range = filter.dateRange()

        #expect(range != nil)

        if let range = range {
            // Should span 7 days
            let calendar = Calendar.current
            let daysDifference = calendar.dateComponents([.day], from: range.start, to: range.end).day

            #expect(daysDifference == 7)
        }
    }

    @Test("DateRangeFilter.thisMonth returns this month's date range")
    func thisMonthReturnsCorrectDateRange() {
        let filter = DateRangeFilter.thisMonth
        let range = filter.dateRange()

        #expect(range != nil)

        if let range = range {
            let calendar = Calendar.current
            let now = Date()

            // Start should be the first of the current month
            let startComponents = calendar.dateComponents([.year, .month, .day], from: range.start)
            #expect(startComponents.day == 1)

            // End should be the first of next month
            let endComponents = calendar.dateComponents([.year, .month, .day], from: range.end)
            let nowComponents = calendar.dateComponents([.year, .month], from: now)

            // Verify the month progression
            if nowComponents.month == 12 {
                // December -> January
                #expect(endComponents.month == 1)
                #expect(endComponents.year == (nowComponents.year ?? 0) + 1)
            } else {
                // Normal month progression
                #expect(endComponents.month == (nowComponents.month ?? 0) + 1)
            }
        }
    }

    @Test("DateRangeFilter.custom returns custom date range")
    func customReturnsCorrectDateRange() {
        let calendar = Calendar.current
        let fromDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let toDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 20))!

        let filter = DateRangeFilter.custom(from: fromDate, to: toDate)
        let range = filter.dateRange()

        #expect(range != nil)

        if let range = range {
            let expectedStart = calendar.startOfDay(for: fromDate)
            let expectedEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: toDate))!

            #expect(range.start == expectedStart)
            #expect(range.end == expectedEnd)
        }
    }

    @Test("DateRangeFilter enum equality works correctly")
    func enumEqualityWorksCorrectly() {
        #expect(DateRangeFilter.all == DateRangeFilter.all)
        #expect(DateRangeFilter.today == DateRangeFilter.today)
        #expect(DateRangeFilter.tomorrow == DateRangeFilter.tomorrow)
        #expect(DateRangeFilter.thisWeek == DateRangeFilter.thisWeek)
        #expect(DateRangeFilter.thisMonth == DateRangeFilter.thisMonth)

        let date1 = Date()
        let date2 = Date(timeIntervalSinceNow: 3600)
        let custom1 = DateRangeFilter.custom(from: date1, to: date2)
        let custom2 = DateRangeFilter.custom(from: date1, to: date2)
        let custom3 = DateRangeFilter.custom(from: date2, to: date1)

        #expect(custom1 == custom2)
        #expect(custom1 != custom3)

        // Different cases should not be equal
        #expect(DateRangeFilter.all != DateRangeFilter.today)
        #expect(DateRangeFilter.today != DateRangeFilter.tomorrow)
    }

    @Test("DateRangeFilter is Hashable")
    func filterIsHashable() {
        var set = Set<DateRangeFilter>()
        set.insert(.all)
        set.insert(.today)
        set.insert(.tomorrow)
        set.insert(.thisWeek)
        set.insert(.thisMonth)

        #expect(set.count == 5)

        // Adding the same value again shouldn't increase count
        set.insert(.today)
        #expect(set.count == 5)
    }
}
