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

@Suite("Event Computed Properties Tests")
struct EventPropertiesTests {

    // MARK: - Teams Meeting Detection Tests

    @Test("Event detects Teams meeting URL in url field")
    func eventDetectsTeamsMeetingInURL() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Test Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://teams.microsoft.com/l/meetup-join/123")

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == true)
        #expect(event.isGoogleMeetMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    @Test("Event detects Teams meeting URL in notes")
    func eventDetectsTeamsMeetingInNotes() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Test Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.notes = "Join here: https://teams.microsoft.com/l/meetup-join/abc"

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == true)
    }

    @Test("Event detects Teams Live meeting")
    func eventDetectsTeamsLiveMeeting() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Test Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://teams.live.com/meet/123")

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == true)
    }

    // MARK: - Google Meet Detection Tests

    @Test("Event detects Google Meet URL in url field")
    func eventDetectsGoogleMeetInURL() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Test Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://meet.google.com/abc-defg-hij")

        let event = Event(from: ekEvent)

        #expect(event.isGoogleMeetMeeting == true)
        #expect(event.isTeamsMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    @Test("Event detects Google Meet URL in notes")
    func eventDetectsGoogleMeetInNotes() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Test Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.notes = "Link: https://meet.google.com/xyz-qwer-tyu"

        let event = Event(from: ekEvent)

        #expect(event.isGoogleMeetMeeting == true)
    }

    // MARK: - Zoom Meeting Detection Tests

    @Test("Event detects Zoom meeting URL in url field")
    func eventDetectsZoomMeetingInURL() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Test Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://zoom.us/j/123456789")

        let event = Event(from: ekEvent)

        #expect(event.isZoomMeeting == true)
        #expect(event.isTeamsMeeting == false)
        #expect(event.isGoogleMeetMeeting == false)
    }

    @Test("Event detects Zoom meeting URL in notes")
    func eventDetectsZoomMeetingInNotes() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Test Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.notes = "Join: https://zoom.us/j/987654321?pwd=abc"

        let event = Event(from: ekEvent)

        #expect(event.isZoomMeeting == true)
    }

    @Test("Event detects ZoomGov meeting")
    func eventDetectsZoomGovMeeting() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Test Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://zoomgov.com/j/123456789")

        let event = Event(from: ekEvent)

        #expect(event.isZoomMeeting == true)
    }

    // MARK: - No Meeting Link Tests

    @Test("Event with no meeting links returns false for all")
    func eventWithNoMeetingLinksReturnsFalseForAll() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Regular Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.notes = "In-person meeting at the office"

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == false)
        #expect(event.isGoogleMeetMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    @Test("Event with non-meeting URL returns false for all")
    func eventWithNonMeetingURLReturnsFalseForAll() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Event with Link"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://www.example.com/agenda")

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == false)
        #expect(event.isGoogleMeetMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    // MARK: - Multiple Meeting Links Tests

    @Test("Event with multiple meeting URLs detects all")
    func eventWithMultipleMeetingURLsDetectsAll() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Multi-platform Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.notes = """
        Teams: https://teams.microsoft.com/l/meetup-join/123
        Zoom: https://zoom.us/j/456
        Meet: https://meet.google.com/abc
        """

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == true)
        #expect(event.isGoogleMeetMeeting == true)
        #expect(event.isZoomMeeting == true)
    }

    // MARK: - Case Insensitivity Tests

    @Test("Event detects meeting URLs case-insensitively")
    func eventDetectsMeetingURLsCaseInsensitively() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasCalendarAccess else {
            return
        }

        let store = permissionService.eventStore
        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Case Test"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://TEAMS.MICROSOFT.COM/l/meetup-join/123")

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == true)
    }
}
