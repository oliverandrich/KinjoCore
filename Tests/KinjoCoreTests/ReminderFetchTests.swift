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

@Suite("Reminder Fetching Tests")
struct ReminderFetchTests {

    @Test("Reminder model initialises from EKReminder")
    func reminderInitialisesFromEKReminder() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        // Create a test reminder in memory (won't be saved)
        guard let calendar = store.calendars(for: .reminder).first else {
            // Skip test if no calendars available
            return
        }

        let ekReminder = EKReminder(eventStore: store)
        ekReminder.calendar = calendar
        ekReminder.title = "Test Reminder"
        ekReminder.notes = "Test notes"
        ekReminder.priority = 1

        let reminder = Reminder(from: ekReminder)

        #expect(reminder.title == "Test Reminder")
        #expect(reminder.notes == "Test notes")
        #expect(reminder.priority == 1)
        #expect(!reminder.id.isEmpty)
        #expect(!reminder.calendarID.isEmpty)
    }

    @Test("Reminder model handles optional fields")
    func reminderHandlesOptionalFields() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        let ekReminder = EKReminder(eventStore: store)
        ekReminder.calendar = calendar
        ekReminder.title = "Minimal Reminder"
        // Don't set notes, dueDate, or other optional fields

        let reminder = Reminder(from: ekReminder)

        #expect(reminder.title == "Minimal Reminder")
        #expect(reminder.notes == nil)
        #expect(reminder.dueDate == nil)
        #expect(reminder.isCompleted == false)
    }

    @Test("Reminder model includes lastModifiedDate and completionDate")
    func reminderIncludesTimestamps() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        // Create a new reminder
        let ekReminder = EKReminder(eventStore: store)
        ekReminder.calendar = calendar
        ekReminder.title = "Test Timestamps"

        let reminder = Reminder(from: ekReminder)

        // Verify the new properties exist and can be accessed
        // Note: Unsaved reminders may have nil timestamps
        _ = reminder.creationDate
        _ = reminder.lastModifiedDate
        _ = reminder.completionDate

        // completionDate should be nil when not completed
        #expect(reminder.isCompleted == false)
        #expect(reminder.completionDate == nil)
    }

    @Test("ReminderFilter enum has all cases")
    func reminderFilterHasAllCases() {
        let allFilter: ReminderFilter = .all
        let completedFilter: ReminderFilter = .completed
        let incompleteFilter: ReminderFilter = .incomplete

        #expect(allFilter == .all)
        #expect(completedFilter == .completed)
        #expect(incompleteFilter == .incomplete)
    }

    @Test("ReminderSortOption enum has all cases")
    func reminderSortOptionHasAllCases() {
        let titleSort: ReminderSortOption = .title
        let dueDateSort: ReminderSortOption = .dueDate(ascending: true)
        let prioritySort: ReminderSortOption = .priority
        let creationDateSort: ReminderSortOption = .creationDate(ascending: false)

        #expect(titleSort == .title)
        #expect(dueDateSort == .dueDate(ascending: true))
        #expect(prioritySort == .priority)
        #expect(creationDateSort == .creationDate(ascending: false))
    }

    @Test("ReminderService can fetch reminders with permission")
    @MainActor
    func serviceCanFetchRemindersWithPermission() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        // Only run if we have permission
        guard permissionService.hasReminderAccess else {
            return
        }

        // Fetch all reminders
        let reminders = try await reminderService.fetchReminders()

        // Verify the result is an array (may be empty if no reminders exist)
        #expect(reminders is [Reminder])
    }

    @Test("ReminderService throws permission error when denied")
    @MainActor
    func serviceThrowsPermissionErrorWhenDenied() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        // If we don't have permission, fetching should throw an error
        if !permissionService.hasReminderAccess {
            await #expect(throws: ReminderServiceError.permissionDenied) {
                try await reminderService.fetchReminders()
            }
        }
    }

    @Test("ReminderServiceError provides descriptions")
    func reminderServiceErrorProvidesDescriptions() {
        let permissionError = ReminderServiceError.permissionDenied
        let listNotFoundError = ReminderServiceError.listNotFound

        #expect(permissionError.errorDescription != nil)
        #expect(listNotFoundError.errorDescription != nil)
        #expect(permissionError.errorDescription?.contains("Permission") == true)
        #expect(listNotFoundError.errorDescription?.contains("list") == true)
    }
}
