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

@Suite("ReminderService Tests")
struct ReminderServiceTests {

    @Test("ReminderService initialises correctly with PermissionService")
    @MainActor
    func initialisesCorrectly() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        #expect(reminderService.reminderLists.isEmpty)
    }

    @Test("ReminderService throws permission error when access is denied")
    @MainActor
    func throwsPermissionErrorWhenAccessDenied() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        // If we don't have permission, fetching should throw an error
        if !permissionService.hasReminderAccess {
            await #expect(throws: ReminderServiceError.permissionDenied) {
                try await reminderService.fetchReminderLists()
            }
        }
    }

    @Test("ReminderList model initialises from EKCalendar")
    func reminderListInitialisesFromCalendar() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasReminderAccess else {
            // Skip test if no permission
            return
        }

        let calendars = permissionService.eventStore.calendars(for: .reminder)

        if let firstCalendar = calendars.first {
            let reminderList = ReminderList(from: firstCalendar)

            #expect(!reminderList.id.isEmpty)
            #expect(!reminderList.title.isEmpty)
            #expect(!reminderList.sourceName.isEmpty)
            #expect(!reminderList.sourceID.isEmpty)
        }
    }

    @Test("ReminderList is Identifiable")
    func reminderListIsIdentifiable() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasReminderAccess else {
            // Skip test if no permission
            return
        }

        let calendars = permissionService.eventStore.calendars(for: .reminder)

        if let firstCalendar = calendars.first {
            let reminderList = ReminderList(from: firstCalendar)

            // Verify id property is accessible (required by Identifiable)
            let id: String = reminderList.id
            #expect(!id.isEmpty)
        }
    }

    @Test("ReminderList equality is based on ID")
    func reminderListEqualityBasedOnID() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasReminderAccess else {
            // Skip test if no permission
            return
        }

        let calendars = permissionService.eventStore.calendars(for: .reminder)

        if let firstCalendar = calendars.first {
            let list1 = ReminderList(from: firstCalendar)
            let list2 = ReminderList(from: firstCalendar)

            #expect(list1 == list2)
            #expect(list1.hashValue == list2.hashValue)
        }
    }

    @Test("ReminderServiceError provides localised description")
    func reminderServiceErrorProvidesDescription() async throws {
        let error = ReminderServiceError.permissionDenied

        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("Permission") == true)
    }
}
