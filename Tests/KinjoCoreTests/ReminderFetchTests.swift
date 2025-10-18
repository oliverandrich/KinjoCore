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
        #expect(reminder.priority == .high)
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

    @Test("Reminder hasTags returns correct value")
    func reminderHasTagsReturnsCorrectValue() {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        // Reminder with tags
        let ekReminder1 = EKReminder(eventStore: store)
        ekReminder1.calendar = calendar
        ekReminder1.title = "Test"
        ekReminder1.notes = "Meeting #work #important"

        let reminder1 = Reminder(from: ekReminder1)
        #expect(reminder1.hasTags == true)

        // Reminder without tags
        let ekReminder2 = EKReminder(eventStore: store)
        ekReminder2.calendar = calendar
        ekReminder2.title = "Test"
        ekReminder2.notes = "Just regular notes"

        let reminder2 = Reminder(from: ekReminder2)
        #expect(reminder2.hasTags == false)

        // Reminder with nil notes
        let ekReminder3 = EKReminder(eventStore: store)
        ekReminder3.calendar = calendar
        ekReminder3.title = "Test"
        ekReminder3.notes = nil

        let reminder3 = Reminder(from: ekReminder3)
        #expect(reminder3.hasTags == false)
    }

    @Test("Reminder hasNote returns correct value")
    func reminderHasNoteReturnsCorrectValue() {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        // Reminder with notes
        let ekReminder1 = EKReminder(eventStore: store)
        ekReminder1.calendar = calendar
        ekReminder1.title = "Test"
        ekReminder1.notes = "Some notes"

        let reminder1 = Reminder(from: ekReminder1)
        #expect(reminder1.hasNote == true)

        // Reminder with nil notes
        let ekReminder2 = EKReminder(eventStore: store)
        ekReminder2.calendar = calendar
        ekReminder2.title = "Test"
        ekReminder2.notes = nil

        let reminder2 = Reminder(from: ekReminder2)
        #expect(reminder2.hasNote == false)

        // Reminder with empty/whitespace-only notes
        let ekReminder3 = EKReminder(eventStore: store)
        ekReminder3.calendar = calendar
        ekReminder3.title = "Test"
        ekReminder3.notes = "   "

        let reminder3 = Reminder(from: ekReminder3)
        #expect(reminder3.hasNote == false)
    }

    @Test("Reminder hasURL detects URLs in title")
    func reminderHasURLDetectsURLsInTitle() {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        // Reminder with URL in title
        let ekReminder1 = EKReminder(eventStore: store)
        ekReminder1.calendar = calendar
        ekReminder1.title = "Check https://example.com for info"
        ekReminder1.notes = nil

        let reminder1 = Reminder(from: ekReminder1)
        #expect(reminder1.hasURL == true)

        // Reminder without URL
        let ekReminder2 = EKReminder(eventStore: store)
        ekReminder2.calendar = calendar
        ekReminder2.title = "Regular reminder"
        ekReminder2.notes = nil

        let reminder2 = Reminder(from: ekReminder2)
        #expect(reminder2.hasURL == false)
    }

    @Test("Reminder hasURL detects URLs in notes")
    func reminderHasURLDetectsURLsInNotes() {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        // Reminder with URL in notes
        let ekReminder1 = EKReminder(eventStore: store)
        ekReminder1.calendar = calendar
        ekReminder1.title = "Check documentation"
        ekReminder1.notes = "See https://docs.example.com for details"

        let reminder1 = Reminder(from: ekReminder1)
        #expect(reminder1.hasURL == true)

        // Reminder with URL in both title and notes
        let ekReminder2 = EKReminder(eventStore: store)
        ekReminder2.calendar = calendar
        ekReminder2.title = "Visit https://example.com"
        ekReminder2.notes = "Also check https://docs.example.com"

        let reminder2 = Reminder(from: ekReminder2)
        #expect(reminder2.hasURL == true)
    }

    @Test("Priority enum converts from EventKit values")
    func priorityEnumConvertsFromEventKitValues() {
        #expect(Priority(eventKitValue: 0) == .none)
        #expect(Priority(eventKitValue: 1) == .high)
        #expect(Priority(eventKitValue: 2) == .high)
        #expect(Priority(eventKitValue: 3) == .high)
        #expect(Priority(eventKitValue: 4) == .high)
        #expect(Priority(eventKitValue: 5) == .medium)
        #expect(Priority(eventKitValue: 6) == .low)
        #expect(Priority(eventKitValue: 7) == .low)
        #expect(Priority(eventKitValue: 8) == .low)
        #expect(Priority(eventKitValue: 9) == .low)
        #expect(Priority(eventKitValue: 99) == .none)  // Out of range
    }

    @Test("Priority enum converts to EventKit values")
    func priorityEnumConvertsToEventKitValues() {
        #expect(Priority.none.eventKitValue == 0)
        #expect(Priority.high.eventKitValue == 1)
        #expect(Priority.medium.eventKitValue == 5)
        #expect(Priority.low.eventKitValue == 9)
    }

    @Test("Priority enum is comparable")
    func priorityEnumIsComparable() {
        // high < medium < low < none
        #expect(Priority.high < Priority.medium)
        #expect(Priority.medium < Priority.low)
        #expect(Priority.low < Priority.none)

        #expect(Priority.high < Priority.none)
        #expect(Priority.medium < Priority.none)

        // Equality
        #expect(Priority.high == Priority.high)
        #expect(!(Priority.high < Priority.high))
    }

    @Test("Priority enum is hashable")
    func priorityEnumIsHashable() {
        var set = Set<Priority>()
        set.insert(.none)
        set.insert(.high)
        set.insert(.medium)
        set.insert(.low)

        #expect(set.count == 4)

        // Adding same value shouldn't increase count
        set.insert(.high)
        #expect(set.count == 4)
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
