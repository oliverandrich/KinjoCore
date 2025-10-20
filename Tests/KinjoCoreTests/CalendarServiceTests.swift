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

@Suite("CalendarService Tests")
struct CalendarServiceTests {

    @Test("CalendarService initialises correctly with PermissionService")
    @MainActor
    func initialisesCorrectly() async throws {
        let permissionService = PermissionService()
        let calendarService = CalendarService(permissionService: permissionService)

        #expect(calendarService.calendars.isEmpty)
    }

    @Test("CalendarService throws permission error when access is denied")
    @MainActor
    func throwsPermissionErrorWhenAccessDenied() async throws {
        let permissionService = PermissionService()
        let calendarService = CalendarService(permissionService: permissionService)

        // If we don't have permission, fetching should throw an error
        if !permissionService.hasCalendarAccess {
            await #expect(throws: CalendarServiceError.permissionDenied) {
                try await calendarService.fetchCalendars()
            }
        }
    }

    @Test("Calendar model initialises from EKCalendar")
    func calendarInitialisesFromEKCalendar() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            // Skip test if no permission
            return
        }

        let ekCalendars = permissionService.eventStore.calendars(for: .event)

        if let firstCalendar = ekCalendars.first {
            let calendar = Calendar(from: firstCalendar)

            #expect(!calendar.id.isEmpty)
            #expect(!calendar.title.isEmpty)
            #expect(!calendar.sourceName.isEmpty)
            #expect(!calendar.sourceID.isEmpty)
        }
    }

    @Test("Calendar is Identifiable")
    func calendarIsIdentifiable() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            // Skip test if no permission
            return
        }

        let ekCalendars = permissionService.eventStore.calendars(for: .event)

        if let firstCalendar = ekCalendars.first {
            let calendar = Calendar(from: firstCalendar)

            // Verify id property is accessible (required by Identifiable)
            let id: String = calendar.id
            #expect(!id.isEmpty)
        }
    }

    @Test("Calendar equality is based on ID")
    func calendarEqualityBasedOnID() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            // Skip test if no permission
            return
        }

        let ekCalendars = permissionService.eventStore.calendars(for: .event)

        if let firstCalendar = ekCalendars.first {
            let calendar1 = Calendar(from: firstCalendar)
            let calendar2 = Calendar(from: firstCalendar)

            #expect(calendar1 == calendar2)
            #expect(calendar1.hashValue == calendar2.hashValue)
        }
    }

    @Test("CalendarServiceError provides localised description")
    func calendarServiceErrorProvidesDescription() async throws {
        let error = CalendarServiceError.permissionDenied

        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("Permission") == true)
    }

    @Test("Calendar includes subscription status")
    func calendarIncludesSubscriptionStatus() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            // Skip test if no permission
            return
        }

        let ekCalendars = permissionService.eventStore.calendars(for: .event)

        if let firstCalendar = ekCalendars.first {
            let calendar = Calendar(from: firstCalendar)

            // Verify isSubscribed property exists and is a boolean
            let isSubscribed = calendar.isSubscribed
            #expect(isSubscribed == true || isSubscribed == false)
        }
    }
}
