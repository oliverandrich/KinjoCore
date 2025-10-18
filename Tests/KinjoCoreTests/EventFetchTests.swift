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

@Suite("Event Fetching Tests")
struct EventFetchTests {

    @Test("Event model initialises from EKEvent")
    func eventInitialisesFromEKEvent() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            // Skip test if no calendars available
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Test Event"
        ekEvent.notes = "Test notes"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600) // 1 hour later
        ekEvent.location = "Test Location"

        let event = Event(from: ekEvent)

        #expect(event.title == "Test Event")
        #expect(event.notes == "Test notes")
        #expect(event.location == "Test Location")
        #expect(!event.id.isEmpty)
        #expect(!event.calendarID.isEmpty)
        #expect(event.startDate == ekEvent.startDate)
        #expect(event.endDate == ekEvent.endDate)
    }

    @Test("Event model handles all-day events")
    func eventHandlesAllDayEvents() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "All Day Event"
        ekEvent.isAllDay = true
        ekEvent.startDate = Date()
        ekEvent.endDate = Date()

        let event = Event(from: ekEvent)

        #expect(event.isAllDay == true)
        #expect(event.title == "All Day Event")
    }

    @Test("Event model handles optional fields")
    func eventHandlesOptionalFields() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Minimal Event"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date()
        // Don't set notes or location

        let event = Event(from: ekEvent)

        #expect(event.title == "Minimal Event")
        #expect(event.notes == nil)
        #expect(event.location == nil)
    }

    @Test("CalendarSelection enum has all cases")
    func calendarSelectionHasAllCases() {
        let allSelection: CalendarSelection = .all
        let specificSelection: CalendarSelection = .specific([])

        #expect(allSelection == .all)
        if case .specific(let calendars) = specificSelection {
            #expect(calendars.isEmpty)
        }
    }

    @Test("CalendarSelection enum equality works correctly")
    func calendarSelectionEqualityWorksCorrectly() {
        #expect(CalendarSelection.all == CalendarSelection.all)

        let permissionService = PermissionService()
        let ekCalendars = permissionService.eventStore.calendars(for: .event)

        if let firstCalendar = ekCalendars.first {
            let calendar = Calendar(from: firstCalendar)
            let selection1 = CalendarSelection.specific([calendar])
            let selection2 = CalendarSelection.specific([calendar])

            #expect(selection1 == selection2)
            #expect(CalendarSelection.all != selection1)
        }
    }

    @Test("CalendarSelection is Hashable")
    func calendarSelectionIsHashable() {
        var set = Set<CalendarSelection>()
        set.insert(.all)

        #expect(set.count == 1)

        // Adding the same value again shouldn't increase count
        set.insert(.all)
        #expect(set.count == 1)
    }

    @Test("CalendarService throws error when date range is .all")
    @MainActor
    func serviceThrowsErrorWhenDateRangeIsAll() async throws {
        let permissionService = PermissionService()
        let calendarService = CalendarService(permissionService: permissionService)

        guard permissionService.hasCalendarAccess else {
            // Skip test if no permission
            return
        }

        // Fetching with .all date range should throw an error
        await #expect(throws: CalendarServiceError.dateRangeRequired) {
            try await calendarService.fetchEvents(dateRange: .all)
        }
    }

    @Test("CalendarService can fetch events with date range")
    @MainActor
    func serviceCanFetchEventsWithDateRange() async throws {
        let permissionService = PermissionService()
        let calendarService = CalendarService(permissionService: permissionService)

        guard permissionService.hasCalendarAccess else {
            // Skip test if no permission
            return
        }

        // Fetch events for today (should work even if no events exist)
        let events = try await calendarService.fetchEvents(dateRange: .today)

        // Verify the result is an array (may be empty)
        #expect(events is [Event])
    }

    @Test("CalendarService sorts events chronologically")
    @MainActor
    func serviceSortsEventsChronologically() async throws {
        let permissionService = PermissionService()
        let calendarService = CalendarService(permissionService: permissionService)

        guard permissionService.hasCalendarAccess else {
            // Skip test if no permission
            return
        }

        // Fetch events for this week
        let events = try await calendarService.fetchEvents(dateRange: .thisWeek)

        // If there are multiple events, verify they are sorted
        if events.count >= 2 {
            for i in 0..<events.count-1 {
                #expect(events[i].startDate <= events[i+1].startDate)
            }
        }
    }

    @Test("CalendarService throws permission error when denied")
    @MainActor
    func serviceThrowsPermissionErrorWhenDenied() async throws {
        let permissionService = PermissionService()
        let calendarService = CalendarService(permissionService: permissionService)

        // If we don't have permission, fetching should throw an error
        if !permissionService.hasCalendarAccess {
            await #expect(throws: CalendarServiceError.permissionDenied) {
                try await calendarService.fetchEvents(dateRange: .today)
            }
        }
    }

    @Test("CalendarServiceError provides descriptions")
    func calendarServiceErrorProvidesDescriptions() {
        let permissionError = CalendarServiceError.permissionDenied
        let calendarNotFoundError = CalendarServiceError.calendarNotFound
        let dateRangeRequiredError = CalendarServiceError.dateRangeRequired

        #expect(permissionError.errorDescription != nil)
        #expect(calendarNotFoundError.errorDescription != nil)
        #expect(dateRangeRequiredError.errorDescription != nil)
        #expect(permissionError.errorDescription?.contains("Permission") == true)
        #expect(calendarNotFoundError.errorDescription?.contains("calendar") == true)
        #expect(dateRangeRequiredError.errorDescription?.contains("date range") == true)
    }
}
