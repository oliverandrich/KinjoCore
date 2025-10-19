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

@Suite("ReminderList CRUD Operations Tests")
struct ReminderListCRUDTests {

    // MARK: - Create Tests

    @Test("ReminderService can create a reminder list with just a title")
    @MainActor
    func serviceCanCreateReminderListWithTitle() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Skip if no EventKit source is available (e.g., no iCloud account configured)
        guard !permissionService.eventStore.sources.isEmpty else {
            return
        }

        // Create a new reminder list
        let list = try await reminderService.createReminderList(
            title: "Test List \(UUID().uuidString)"
        )

        // Verify it was created
        #expect(!list.id.isEmpty)
        #expect(list.title.contains("Test List"))

        // Clean up
        try? await reminderService.deleteReminderList(list)
    }

    @Test("ReminderService can create a reminder list with title and colour")
    @MainActor
    func serviceCanCreateReminderListWithTitleAndColour() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Skip if no EventKit source is available (e.g., no iCloud account configured)
        guard !permissionService.eventStore.sources.isEmpty else {
            return
        }

        // Create a new reminder list with a red colour
        let red = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let list = try await reminderService.createReminderList(
            title: "Coloured List \(UUID().uuidString)",
            color: red
        )

        // Verify it was created
        #expect(!list.id.isEmpty)
        #expect(list.title.contains("Coloured List"))

        // Clean up
        try? await reminderService.deleteReminderList(list)
    }

    @Test("ReminderService throws error when creating list with empty title")
    @MainActor
    func serviceThrowsErrorWhenCreatingListWithEmptyTitle() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Skip if no EventKit source is available (e.g., no iCloud account configured)
        guard !permissionService.eventStore.sources.isEmpty else {
            return
        }

        // Attempt to create a list with empty title
        await #expect(throws: ReminderServiceError.invalidListTitle) {
            try await reminderService.createReminderList(title: "")
        }

        // Attempt with whitespace-only title
        await #expect(throws: ReminderServiceError.invalidListTitle) {
            try await reminderService.createReminderList(title: "   ")
        }
    }

    @Test("ReminderService throws permission error when creating list without access")
    @MainActor
    func serviceThrowsPermissionErrorWhenCreatingList() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        if !permissionService.hasReminderAccess {
            await #expect(throws: ReminderServiceError.permissionDenied) {
                try await reminderService.createReminderList(title: "Test")
            }
        }
    }

    // MARK: - Update Tests

    @Test("ReminderService can update reminder list title")
    @MainActor
    func serviceCanUpdateReminderListTitle() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Skip if no EventKit source is available (e.g., no iCloud account configured)
        guard !permissionService.eventStore.sources.isEmpty else {
            return
        }

        // Create a list
        let list = try await reminderService.createReminderList(
            title: "Original Title \(UUID().uuidString)"
        )

        // Update the title
        let newTitle = "Updated Title \(UUID().uuidString)"
        let updatedList = try await reminderService.updateReminderList(
            list.id,
            title: newTitle
        )

        // Verify the update
        #expect(updatedList.id == list.id)
        #expect(updatedList.title == newTitle)

        // Clean up
        try? await reminderService.deleteReminderList(list)
    }

    @Test("ReminderService can update reminder list colour")
    @MainActor
    func serviceCanUpdateReminderListColour() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Skip if no EventKit source is available (e.g., no iCloud account configured)
        guard !permissionService.eventStore.sources.isEmpty else {
            return
        }

        // Create a list
        let list = try await reminderService.createReminderList(
            title: "Colour Test \(UUID().uuidString)"
        )

        // Update the colour to green
        let green = CGColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        let updatedList = try await reminderService.updateReminderList(
            list.id,
            color: green
        )

        // Verify the update
        #expect(updatedList.id == list.id)

        // Clean up
        try? await reminderService.deleteReminderList(list)
    }

    @Test("ReminderService can update reminder list using object")
    @MainActor
    func serviceCanUpdateReminderListUsingObject() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Skip if no EventKit source is available (e.g., no iCloud account configured)
        guard !permissionService.eventStore.sources.isEmpty else {
            return
        }

        // Create a list
        let list = try await reminderService.createReminderList(
            title: "Object Update Test \(UUID().uuidString)"
        )

        // Update using the list object
        let newTitle = "Updated via Object \(UUID().uuidString)"
        let updatedList = try await reminderService.updateReminderList(
            list,
            title: newTitle
        )

        // Verify the update
        #expect(updatedList.id == list.id)
        #expect(updatedList.title == newTitle)

        // Clean up
        try? await reminderService.deleteReminderList(list)
    }

    @Test("ReminderService throws error when updating list with empty title")
    @MainActor
    func serviceThrowsErrorWhenUpdatingListWithEmptyTitle() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Skip if no EventKit source is available (e.g., no iCloud account configured)
        guard !permissionService.eventStore.sources.isEmpty else {
            return
        }

        // Create a list
        let list = try await reminderService.createReminderList(
            title: "Valid Title \(UUID().uuidString)"
        )

        // Attempt to update with empty title
        await #expect(throws: ReminderServiceError.invalidListTitle) {
            try await reminderService.updateReminderList(list.id, title: "")
        }

        // Clean up
        try? await reminderService.deleteReminderList(list)
    }

    @Test("ReminderService throws error when updating non-existent list")
    @MainActor
    func serviceThrowsErrorWhenUpdatingNonExistentList() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Skip if no EventKit source is available (e.g., no iCloud account configured)
        guard !permissionService.eventStore.sources.isEmpty else {
            return
        }

        // Attempt to update a list that doesn't exist
        await #expect(throws: ReminderServiceError.listNotFound) {
            try await reminderService.updateReminderList(
                "non-existent-id",
                title: "New Title"
            )
        }
    }

    // MARK: - Delete Tests

    @Test("ReminderService can delete reminder list by ID")
    @MainActor
    func serviceCanDeleteReminderListByID() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Skip if no EventKit source is available (e.g., no iCloud account configured)
        guard !permissionService.eventStore.sources.isEmpty else {
            return
        }

        // Create a list
        let list = try await reminderService.createReminderList(
            title: "To Delete \(UUID().uuidString)"
        )

        // Delete it
        try await reminderService.deleteReminderList(list.id)

        // Verify it's gone by trying to fetch it
        let calendar = permissionService.eventStore.calendar(withIdentifier: list.id)
        #expect(calendar == nil)
    }

    @Test("ReminderService can delete reminder list by object")
    @MainActor
    func serviceCanDeleteReminderListByObject() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Skip if no EventKit source is available (e.g., no iCloud account configured)
        guard !permissionService.eventStore.sources.isEmpty else {
            return
        }

        // Create a list
        let list = try await reminderService.createReminderList(
            title: "To Delete Object \(UUID().uuidString)"
        )

        // Delete it using the object
        try await reminderService.deleteReminderList(list)

        // Verify it's gone
        let calendar = permissionService.eventStore.calendar(withIdentifier: list.id)
        #expect(calendar == nil)
    }

    @Test("ReminderService throws error when deleting non-existent list")
    @MainActor
    func serviceThrowsErrorWhenDeletingNonExistentList() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Skip if no EventKit source is available (e.g., no iCloud account configured)
        guard !permissionService.eventStore.sources.isEmpty else {
            return
        }

        // Attempt to delete a list that doesn't exist
        await #expect(throws: ReminderServiceError.listNotFound) {
            try await reminderService.deleteReminderList("non-existent-id")
        }
    }

    @Test("ReminderService throws permission error when deleting list without access")
    @MainActor
    func serviceThrowsPermissionErrorWhenDeletingList() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        if !permissionService.hasReminderAccess {
            await #expect(throws: ReminderServiceError.permissionDenied) {
                try await reminderService.deleteReminderList("any-id")
            }
        }
    }

    // MARK: - Error Description Tests

    @Test("ReminderServiceError provides descriptions for list errors")
    func reminderServiceErrorProvidesDescriptionsForListErrors() {
        let listImmutableError = ReminderServiceError.listImmutable
        let invalidListTitleError = ReminderServiceError.invalidListTitle
        let sourceNotFoundError = ReminderServiceError.sourceNotFound

        #expect(listImmutableError.errorDescription != nil)
        #expect(invalidListTitleError.errorDescription != nil)
        #expect(sourceNotFoundError.errorDescription != nil)

        #expect(listImmutableError.errorDescription?.contains("read-only") == true)
        #expect(invalidListTitleError.errorDescription?.contains("title") == true)
        #expect(sourceNotFoundError.errorDescription?.contains("source") == true)
    }
}
