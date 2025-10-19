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
import Foundation
@testable import KinjoCore

@Suite("Reminder Recurrence Integration Tests")
struct ReminderRecurrenceTests {

    @Test("ReminderService can create a daily recurring reminder")
    @MainActor
    func createDailyRecurringReminder() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            // Skip test if no permission
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            // Skip test if no lists available
            return
        }

        // Create a daily recurring reminder
        let dailyRule = RecurrenceRule.daily()
        let reminder = try await reminderService.createReminder(
            title: "Daily Task",
            recurrenceRules: [dailyRule],
            in: firstList
        )

        #expect(reminder.title == "Daily Task")
        #expect(reminder.hasRecurrenceRules == true)
        #expect(reminder.recurrenceRules?.count == 1)
        #expect(reminder.recurrenceRules?.first?.frequency == .daily)
        #expect(reminder.recurrenceRules?.first?.interval == 1)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can create a weekly recurring reminder on specific days")
    @MainActor
    func createWeeklyRecurringReminderOnSpecificDays() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a weekly reminder on Monday, Wednesday, and Friday
        let weeklyRule = RecurrenceRule.weekly(
            daysOfWeek: [.every(.monday), .every(.wednesday), .every(.friday)]
        )
        let reminder = try await reminderService.createReminder(
            title: "MWF Workout",
            recurrenceRules: [weeklyRule],
            in: firstList
        )

        #expect(reminder.hasRecurrenceRules == true)
        #expect(reminder.recurrenceRules?.first?.frequency == .weekly)
        #expect(reminder.recurrenceRules?.first?.daysOfTheWeek?.count == 3)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can create a monthly recurring reminder on first Monday")
    @MainActor
    func createMonthlyRecurringReminderOnFirstMonday() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a monthly reminder on the first Monday
        let monthlyRule = RecurrenceRule.monthly(daysOfWeek: [.first(.monday)])
        let reminder = try await reminderService.createReminder(
            title: "Monthly Team Meeting",
            recurrenceRules: [monthlyRule],
            in: firstList
        )

        #expect(reminder.hasRecurrenceRules == true)
        #expect(reminder.recurrenceRules?.first?.frequency == .monthly)
        #expect(reminder.recurrenceRules?.first?.daysOfTheWeek?.first?.dayOfWeek == .monday)
        #expect(reminder.recurrenceRules?.first?.daysOfTheWeek?.first?.weekNumber == 1)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can create a monthly recurring reminder on last Friday")
    @MainActor
    func createMonthlyRecurringReminderOnLastFriday() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a monthly reminder on the last Friday
        let monthlyRule = RecurrenceRule.monthly(daysOfWeek: [.last(.friday)])
        let reminder = try await reminderService.createReminder(
            title: "Monthly Review",
            recurrenceRules: [monthlyRule],
            in: firstList
        )

        #expect(reminder.hasRecurrenceRules == true)
        #expect(reminder.recurrenceRules?.first?.frequency == .monthly)
        #expect(reminder.recurrenceRules?.first?.daysOfTheWeek?.first?.dayOfWeek == .friday)
        #expect(reminder.recurrenceRules?.first?.daysOfTheWeek?.first?.weekNumber == -1)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can create a reminder with end date")
    @MainActor
    func createRecurringReminderWithEndDate() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a daily reminder that ends in 30 days
        let endDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
        let dailyRule = RecurrenceRule.daily(end: .afterDate(endDate))
        let reminder = try await reminderService.createReminder(
            title: "30-Day Challenge",
            recurrenceRules: [dailyRule],
            in: firstList
        )

        #expect(reminder.hasRecurrenceRules == true)
        if case .afterDate = reminder.recurrenceRules?.first?.end {
            // Success - we have an end date
        } else {
            Issue.record("Expected .afterDate end condition")
        }

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can create a reminder with occurrence count")
    @MainActor
    func createRecurringReminderWithOccurrenceCount() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a weekly reminder for 8 weeks
        let weeklyRule = RecurrenceRule.weekly(end: .afterOccurrences(8))
        let reminder = try await reminderService.createReminder(
            title: "8-Week Program",
            recurrenceRules: [weeklyRule],
            in: firstList
        )

        #expect(reminder.hasRecurrenceRules == true)
        if case .afterOccurrences(let count) = reminder.recurrenceRules?.first?.end {
            #expect(count == 8)
        } else {
            Issue.record("Expected .afterOccurrences end condition")
        }

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can update a reminder to add recurrence")
    @MainActor
    func updateReminderToAddRecurrence() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a non-recurring reminder
        let reminder = try await reminderService.createReminder(
            title: "One-time Task",
            in: firstList
        )

        #expect(reminder.hasRecurrenceRules == false)

        // Update it to be recurring
        let dailyRule = RecurrenceRule.daily()
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            recurrenceRules: [dailyRule]
        )

        #expect(updatedReminder.hasRecurrenceRules == true)
        #expect(updatedReminder.recurrenceRules?.first?.frequency == .daily)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("ReminderService can update a reminder to change recurrence")
    @MainActor
    func updateReminderToChangeRecurrence() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a daily recurring reminder
        let dailyRule = RecurrenceRule.daily()
        let reminder = try await reminderService.createReminder(
            title: "Recurring Task",
            recurrenceRules: [dailyRule],
            in: firstList
        )

        #expect(reminder.recurrenceRules?.first?.frequency == .daily)

        // Update to weekly
        let weeklyRule = RecurrenceRule.weekly()
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            recurrenceRules: [weeklyRule]
        )

        #expect(updatedReminder.hasRecurrenceRules == true)
        #expect(updatedReminder.recurrenceRules?.first?.frequency == .weekly)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("ReminderService can update a reminder to remove recurrence")
    @MainActor
    func updateReminderToRemoveRecurrence() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a daily recurring reminder
        let dailyRule = RecurrenceRule.daily()
        let reminder = try await reminderService.createReminder(
            title: "Recurring Task",
            recurrenceRules: [dailyRule],
            in: firstList
        )

        #expect(reminder.hasRecurrenceRules == true)

        // Update to remove recurrence by passing empty array
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            recurrenceRules: []
        )

        #expect(updatedReminder.hasRecurrenceRules == false)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("ReminderService can create a reminder with multiple recurrence rules")
    @MainActor
    func createReminderWithMultipleRecurrenceRules() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a reminder with multiple rules
        let weekdayRule = RecurrenceRule.weekly(
            daysOfWeek: [.every(.monday), .every(.tuesday), .every(.wednesday), .every(.thursday), .every(.friday)]
        )
        let weekendRule = RecurrenceRule.weekly(
            daysOfWeek: [.every(.saturday), .every(.sunday)]
        )

        let reminder = try await reminderService.createReminder(
            title: "Multi-rule Task",
            recurrenceRules: [weekdayRule, weekendRule],
            in: firstList
        )

        #expect(reminder.hasRecurrenceRules == true)
        #expect(reminder.recurrenceRules?.count == 2)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService preserves recurrence when updating other properties")
    @MainActor
    func preserveRecurrenceWhenUpdatingOtherProperties() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a daily recurring reminder
        let dailyRule = RecurrenceRule.daily()
        let reminder = try await reminderService.createReminder(
            title: "Recurring Task",
            recurrenceRules: [dailyRule],
            in: firstList
        )

        #expect(reminder.hasRecurrenceRules == true)

        // Update title without changing recurrence (pass nil for recurrenceRules)
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            title: "Updated Recurring Task"
        )

        #expect(updatedReminder.title == "Updated Recurring Task")
        #expect(updatedReminder.hasRecurrenceRules == true)
        #expect(updatedReminder.recurrenceRules?.first?.frequency == .daily)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("ReminderService can create complex bi-weekly reminder")
    @MainActor
    func createComplexBiweeklyReminder() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a reminder every 2 weeks on Monday and Friday, for 12 occurrences
        let biweeklyRule = RecurrenceRule(
            frequency: .weekly,
            interval: 2,
            end: .afterOccurrences(12),
            daysOfTheWeek: [.every(.monday), .every(.friday)]
        )

        let reminder = try await reminderService.createReminder(
            title: "Bi-weekly Check-in",
            recurrenceRules: [biweeklyRule],
            in: firstList
        )

        #expect(reminder.hasRecurrenceRules == true)
        #expect(reminder.recurrenceRules?.first?.frequency == .weekly)
        #expect(reminder.recurrenceRules?.first?.interval == 2)
        #expect(reminder.recurrenceRules?.first?.daysOfTheWeek?.count == 2)

        if case .afterOccurrences(let count) = reminder.recurrenceRules?.first?.end {
            #expect(count == 12)
        } else {
            Issue.record("Expected .afterOccurrences end condition")
        }

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("Reminder.hasRecurrenceRules returns false for non-recurring reminder")
    @MainActor
    func hasRecurrenceRulesReturnsFalseForNonRecurring() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a non-recurring reminder
        let reminder = try await reminderService.createReminder(
            title: "One-time Task",
            in: firstList
        )

        #expect(reminder.hasRecurrenceRules == false)
        #expect(reminder.recurrenceRules == nil)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }
}
