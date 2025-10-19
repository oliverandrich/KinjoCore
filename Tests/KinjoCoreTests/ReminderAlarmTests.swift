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

@Suite("Reminder Alarm Integration Tests")
struct ReminderAlarmTests {

    @Test("ReminderService can create reminder with absolute alarm")
    @MainActor
    func createReminderWithAbsoluteAlarm() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        let alarmDate = Date().addingTimeInterval(3600) // 1 hour from now
        let reminder = try await reminderService.createReminder(
            title: "Meeting",
            alarms: [.absolute(date: alarmDate)],
            in: firstList
        )

        #expect(reminder.hasAlarms == true)
        #expect(reminder.alarms?.count == 1)

        if case .absolute(let date) = reminder.alarms?.first {
            #expect(date == alarmDate)
        } else {
            Issue.record("Expected absolute alarm")
        }

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can create reminder with relative alarms")
    @MainActor
    func createReminderWithRelativeAlarms() async throws {
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
            title: "Important Task",
            dueDate: Date().addingTimeInterval(86400), // Tomorrow
            alarms: [
                .relative(minutes: -15),  // 15 minutes before
                .relative(hours: -1)      // 1 hour before
            ],
            in: firstList
        )

        #expect(reminder.hasAlarms == true)
        #expect(reminder.alarms?.count == 2)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can create reminder with location-based alarm")
    @MainActor
    func createReminderWithLocationAlarm() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        let officeLocation = StructuredLocation.location(
            title: "Office",
            latitude: 52.520008,
            longitude: 13.404954,
            radius: 100
        )

        let reminder = try await reminderService.createReminder(
            title: "Take laptop home",
            alarms: [.location(location: officeLocation, proximity: .leave)],
            in: firstList
        )

        #expect(reminder.hasAlarms == true)
        #expect(reminder.alarms?.count == 1)

        if case .location(let location, let proximity) = reminder.alarms?.first {
            #expect(location.title == "Office")
            #expect(proximity == .leave)
        } else {
            Issue.record("Expected location alarm")
        }

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can create reminder with multiple alarm types")
    @MainActor
    func createReminderWithMultipleAlarmTypes() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        let alarmDate = Date().addingTimeInterval(7200)
        let location = StructuredLocation.named("Home")

        let reminder = try await reminderService.createReminder(
            title: "Complex Task",
            alarms: [
                .absolute(date: alarmDate),
                .relative(days: -1),
                .location(location: location, proximity: .enter)
            ],
            in: firstList
        )

        #expect(reminder.hasAlarms == true)
        #expect(reminder.alarms?.count == 3)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderService can update reminder to add alarms")
    @MainActor
    func updateReminderToAddAlarms() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create reminder without alarms
        let reminder = try await reminderService.createReminder(
            title: "Task",
            in: firstList
        )

        #expect(reminder.hasAlarms == false)

        // Update to add alarms
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            alarms: [.relative(minutes: -30)]
        )

        #expect(updatedReminder.hasAlarms == true)
        #expect(updatedReminder.alarms?.count == 1)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("ReminderService can update reminder to change alarms")
    @MainActor
    func updateReminderToChangeAlarms() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create reminder with one alarm
        let reminder = try await reminderService.createReminder(
            title: "Task",
            alarms: [.relative(minutes: -15)],
            in: firstList
        )

        #expect(reminder.alarms?.count == 1)

        // Update to different alarms
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            alarms: [.relative(hours: -1), .relative(days: -1)]
        )

        #expect(updatedReminder.alarms?.count == 2)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("ReminderService can update reminder to remove alarms")
    @MainActor
    func updateReminderToRemoveAlarms() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create reminder with alarms
        let reminder = try await reminderService.createReminder(
            title: "Task",
            alarms: [.relative(minutes: -15), .relative(hours: -1)],
            in: firstList
        )

        #expect(reminder.hasAlarms == true)

        // Update to remove alarms (pass empty array)
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            alarms: []
        )

        #expect(updatedReminder.hasAlarms == false)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("ReminderService preserves alarms when updating other properties")
    @MainActor
    func preserveAlarmsWhenUpdatingOtherProperties() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create reminder with alarms
        let reminder = try await reminderService.createReminder(
            title: "Original",
            alarms: [.relative(minutes: -30)],
            in: firstList
        )

        #expect(reminder.hasAlarms == true)

        // Update title without touching alarms (pass nil)
        let updatedReminder = try await reminderService.updateReminder(
            reminder.id,
            title: "Updated"
        )

        #expect(updatedReminder.title == "Updated")
        #expect(updatedReminder.hasAlarms == true)
        #expect(updatedReminder.alarms?.count == 1)

        // Clean up
        try await reminderService.deleteReminder(updatedReminder)
    }

    @Test("Reminder.hasAlarms returns false when no alarms")
    @MainActor
    func hasAlarmsReturnsFalse() async throws {
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
            title: "No alarms",
            in: firstList
        )

        #expect(reminder.hasAlarms == false)
        #expect(reminder.alarms == nil || reminder.alarms?.isEmpty == true)

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }

    @Test("Reminder with alarms and location can be created")
    @MainActor
    func createReminderWithAlarmsAndLocation() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        let office = StructuredLocation.named("Office")

        let reminder = try await reminderService.createReminder(
            title: "Task at office",
            alarms: [
                .relative(minutes: -15),
                .location(location: office, proximity: .enter)
            ],
            location: "Office", // Simple text location
            in: firstList
        )

        #expect(reminder.hasAlarms == true)
        #expect(reminder.alarms?.count == 2)
        #expect(reminder.hasLocation == true)
        #expect(reminder.location == "Office")

        // Clean up
        try await reminderService.deleteReminder(reminder)
    }
}
