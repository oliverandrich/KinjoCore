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

@Suite("Reminder Location Tests")
struct ReminderLocationTests {

    @Test("ReminderService can create reminder with location string")
    @MainActor
    func createReminderWithLocation() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        let reminder = try await reminderService.createReminder(
            title: "Buy milk",
            location: "Supermarket",
            in: firstList
        )

        #expect(reminder.location == "Supermarket")
        #expect(reminder.hasLocation == true)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can create reminder without location")
    @MainActor
    func createReminderWithoutLocation() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        let reminder = try await reminderService.createReminder(
            title: "Generic task",
            in: firstList
        )

        #expect(reminder.location == nil)
        #expect(reminder.hasLocation == false)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can update reminder to add location")
    @MainActor
    func updateReminderToAddLocation() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create reminder without location
        let reminder = try await reminderService.createReminder(
            title: "Task",
            in: firstList
        )

        #expect(reminder.hasLocation == false)

        // Update to add location
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            location: "Office"
        )

        #expect(updatedReminder.location == "Office")
        #expect(updatedReminder.hasLocation == true)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("ReminderService can update reminder location")
    @MainActor
    func updateReminderLocation() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create reminder with location
        let reminder = try await reminderService.createReminder(
            title: "Task",
            location: "Office",
            in: firstList
        )

        #expect(reminder.location == "Office")

        // Update location
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            location: "Home"
        )

        #expect(updatedReminder.location == "Home")
        #expect(updatedReminder.hasLocation == true)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("ReminderService can clear reminder location with empty string")
    @MainActor
    func clearReminderLocation() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create reminder with location
        let reminder = try await reminderService.createReminder(
            title: "Task",
            location: "Office",
            in: firstList
        )

        #expect(reminder.hasLocation == true)

        // Clear location
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            location: ""
        )

        #expect(updatedReminder.location == nil)
        #expect(updatedReminder.hasLocation == false)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("ReminderService preserves location when updating other properties")
    @MainActor
    func preserveLocationWhenUpdatingOtherProperties() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create reminder with location
        let reminder = try await reminderService.createReminder(
            title: "Original",
            location: "Gym",
            in: firstList
        )

        #expect(reminder.location == "Gym")

        // Update title without touching location (pass nil)
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            title: "Updated"
        )

        #expect(updatedReminder.title == "Updated")
        #expect(updatedReminder.location == "Gym")
        #expect(updatedReminder.hasLocation == true)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("Reminder.hasLocation returns false for empty location")
    @MainActor
    func hasLocationReturnsFalseForEmpty() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        let reminder = try await reminderService.createReminder(
            title: "Task",
            in: firstList
        )

        #expect(reminder.hasLocation == false)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("Reminder.hasLocation returns true for non-empty location")
    @MainActor
    func hasLocationReturnsTrueForNonEmpty() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        let reminder = try await reminderService.createReminder(
            title: "Task",
            location: "Anywhere",
            in: firstList
        )

        #expect(reminder.hasLocation == true)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }
}
