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

@Suite("Reminder CRUD Operations Tests")
struct ReminderCRUDTests {

    @Test("ReminderService can create a reminder with just a title")
    @MainActor
    func serviceCanCreateReminderWithTitle() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            // Skip test if no permission
            return
        }

        // Fetch lists first
        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            // Skip test if no lists available
            return
        }

        // Create a reminder with just a title
        let reminder = try await reminderService.createReminder(
            title: "Test Reminder",
            in: firstList
        )

        #expect(reminder.title == "Test Reminder")
        #expect(reminder.notes == nil)
        #expect(reminder.dueDate == nil)
        #expect(reminder.priority == 0)
        #expect(!reminder.isCompleted)
        #expect(!reminder.id.isEmpty)

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can create a reminder with all properties")
    @MainActor
    func serviceCanCreateReminderWithAllProperties() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        let dueDate = Date(timeIntervalSinceNow: 3600) // 1 hour from now

        let reminder = try await reminderService.createReminder(
            title: "Complete Reminder",
            notes: "Test notes",
            dueDate: dueDate,
            priority: 1,
            in: firstList
        )

        #expect(reminder.title == "Complete Reminder")
        #expect(reminder.notes == "Test notes")
        #expect(reminder.dueDate != nil)
        #expect(reminder.priority == 1)

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService throws error when creating reminder with empty title")
    @MainActor
    func serviceThrowsErrorForEmptyTitle() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Try to create with empty title
        await #expect(throws: ReminderServiceError.invalidTitle) {
            try await reminderService.createReminder(
                title: "",
                in: firstList
            )
        }

        // Try to create with whitespace-only title
        await #expect(throws: ReminderServiceError.invalidTitle) {
            try await reminderService.createReminder(
                title: "   ",
                in: firstList
            )
        }
    }

    @Test("ReminderService can update reminder title")
    @MainActor
    func serviceCanUpdateReminderTitle() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a reminder
        let reminder = try await reminderService.createReminder(
            title: "Original Title",
            in: firstList
        )

        let originalModifiedDate = reminder.lastModifiedDate

        // Update title
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            title: "Updated Title"
        )

        #expect(updatedReminder.title == "Updated Title")
        #expect(updatedReminder.id == reminder.id)

        // lastModifiedDate should be updated (or at least present)
        #expect(updatedReminder.lastModifiedDate != nil)
        // Note: We can't reliably test if it's newer than original since
        // the timestamp might be the same if update happens very quickly

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can update reminder notes and due date")
    @MainActor
    func serviceCanUpdateReminderNotesAndDueDate() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a reminder without notes or due date
        let reminder = try await reminderService.createReminder(
            title: "Test Reminder",
            in: firstList
        )

        let dueDate = Date(timeIntervalSinceNow: 7200) // 2 hours from now

        // Update notes and due date
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            notes: "Added notes",
            dueDate: dueDate
        )

        #expect(updatedReminder.notes == "Added notes")
        #expect(updatedReminder.dueDate != nil)
        #expect(updatedReminder.title == "Test Reminder") // Title unchanged

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can update reminder priority")
    @MainActor
    func serviceCanUpdateReminderPriority() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a reminder with no priority
        let reminder = try await reminderService.createReminder(
            title: "Test Reminder",
            in: firstList
        )

        // Update priority to high
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            priority: 1
        )

        #expect(updatedReminder.priority == 1)

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can move reminder to different list")
    @MainActor
    func serviceCanMoveReminderToDifferentList() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard reminderService.reminderLists.count >= 2 else {
            // Skip test if less than 2 lists
            return
        }

        let firstList = reminderService.reminderLists[0]
        let secondList = reminderService.reminderLists[1]

        // Create a reminder in first list
        let reminder = try await reminderService.createReminder(
            title: "Test Reminder",
            in: firstList
        )

        #expect(reminder.calendarID == firstList.id)

        // Move to second list
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            moveTo: secondList
        )

        #expect(updatedReminder.calendarID == secondList.id)

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService throws error when updating non-existent reminder")
    @MainActor
    func serviceThrowsErrorForNonExistentReminder() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Try to update a non-existent reminder
        await #expect(throws: ReminderServiceError.reminderNotFound) {
            try await reminderService.updateReminder(
                "non-existent-id",
                title: "Updated Title"
            )
        }
    }

    @Test("ReminderService can delete reminder by ID")
    @MainActor
    func serviceCanDeleteReminderByID() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a reminder
        let reminder = try await reminderService.createReminder(
            title: "To Be Deleted",
            in: firstList
        )

        let reminderId = reminder.id

        // Delete it
        try await reminderService.deleteReminder(reminderId)

        // Verify it's deleted by trying to update it
        await #expect(throws: ReminderServiceError.reminderNotFound) {
            try await reminderService.updateReminder(reminderId, title: "Should Fail")
        }
    }

    @Test("ReminderService can delete reminder by object")
    @MainActor
    func serviceCanDeleteReminderByObject() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a reminder
        let reminder = try await reminderService.createReminder(
            title: "To Be Deleted",
            in: firstList
        )

        let reminderId = reminder.id

        // Delete it using the object
        try await reminderService.deleteReminder(reminder)

        // Verify it's deleted
        await #expect(throws: ReminderServiceError.reminderNotFound) {
            try await reminderService.updateReminder(reminderId, title: "Should Fail")
        }
    }

    @Test("ReminderService throws error when deleting non-existent reminder")
    @MainActor
    func serviceThrowsErrorWhenDeletingNonExistentReminder() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Try to delete a non-existent reminder
        await #expect(throws: ReminderServiceError.reminderNotFound) {
            try await reminderService.deleteReminder("non-existent-id")
        }
    }

    @Test("ReminderService can toggle reminder completion by ID")
    @MainActor
    func serviceCanToggleReminderCompletionByID() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a reminder (initially incomplete)
        let reminder = try await reminderService.createReminder(
            title: "Test Toggle",
            in: firstList
        )

        #expect(!reminder.isCompleted)
        #expect(reminder.completionDate == nil)

        // Toggle to completed
        let completed = try await reminderService.toggleReminderCompletion(reminder.id)
        #expect(completed.isCompleted)
        #expect(completed.completionDate != nil) // Should have completion date

        // Toggle back to incomplete
        let incomplete = try await reminderService.toggleReminderCompletion(reminder.id)
        #expect(!incomplete.isCompleted)
        // Note: completionDate might still be set even when uncompleted

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can toggle reminder completion by object")
    @MainActor
    func serviceCanToggleReminderCompletionByObject() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create a reminder (initially incomplete)
        let reminder = try await reminderService.createReminder(
            title: "Test Toggle",
            in: firstList
        )

        #expect(!reminder.isCompleted)

        // Toggle using object
        let completed = try await reminderService.toggleReminderCompletion(reminder)
        #expect(completed.isCompleted)

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService throws error when toggling non-existent reminder")
    @MainActor
    func serviceThrowsErrorWhenTogglingNonExistentReminder() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Try to toggle a non-existent reminder
        await #expect(throws: ReminderServiceError.reminderNotFound) {
            try await reminderService.toggleReminderCompletion("non-existent-id")
        }
    }

    @Test("ReminderServiceError provides descriptions for all error cases")
    func reminderServiceErrorProvidesDescriptions() {
        let permissionError = ReminderServiceError.permissionDenied
        let listNotFoundError = ReminderServiceError.listNotFound
        let reminderNotFoundError = ReminderServiceError.reminderNotFound
        let saveFailedError = ReminderServiceError.saveFailed
        let deleteFailedError = ReminderServiceError.deleteFailed
        let invalidTitleError = ReminderServiceError.invalidTitle

        #expect(permissionError.errorDescription != nil)
        #expect(listNotFoundError.errorDescription != nil)
        #expect(reminderNotFoundError.errorDescription != nil)
        #expect(saveFailedError.errorDescription != nil)
        #expect(deleteFailedError.errorDescription != nil)
        #expect(invalidTitleError.errorDescription != nil)

        #expect(permissionError.errorDescription?.contains("Permission") == true)
        #expect(listNotFoundError.errorDescription?.contains("list") == true)
        #expect(reminderNotFoundError.errorDescription?.contains("reminder") == true)
        #expect(saveFailedError.errorDescription?.contains("save") == true)
        #expect(deleteFailedError.errorDescription?.contains("delete") == true)
        #expect(invalidTitleError.errorDescription?.contains("title") == true)
    }
}
