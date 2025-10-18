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

@Suite("Event Meeting Link Detection Tests")
struct EventMeetingLinkTests {

    // MARK: - Teams Meeting Tests

    @Test("Event detects Teams meeting from URL field")
    func eventDetectsTeamsMeetingFromURL() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Teams Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://teams.microsoft.com/l/meetup-join/19%3ameeting_abc123")

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == true)
        #expect(event.isGoogleMeetMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    @Test("Event detects Teams meeting from notes field")
    func eventDetectsTeamsMeetingFromNotes() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Teams Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.notes = "Join the meeting: https://teams.microsoft.com/l/meetup-join/19%3ameeting_xyz789"

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == true)
        #expect(event.isGoogleMeetMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    @Test("Event detects Teams Live meeting")
    func eventDetectsTeamsLiveMeeting() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Teams Live Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://teams.live.com/meet/123456")

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == true)
    }

    // MARK: - Google Meet Tests

    @Test("Event detects Google Meet meeting from URL field")
    func eventDetectsGoogleMeetFromURL() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Google Meet"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://meet.google.com/abc-defg-hij")

        let event = Event(from: ekEvent)

        #expect(event.isGoogleMeetMeeting == true)
        #expect(event.isTeamsMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    @Test("Event detects Google Meet meeting from notes field")
    func eventDetectsGoogleMeetFromNotes() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Google Meet"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.notes = "Click here to join: https://meet.google.com/xyz-qwer-tyu"

        let event = Event(from: ekEvent)

        #expect(event.isGoogleMeetMeeting == true)
        #expect(event.isTeamsMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    // MARK: - Zoom Meeting Tests

    @Test("Event detects Zoom meeting from URL field")
    func eventDetectsZoomMeetingFromURL() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Zoom Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://zoom.us/j/123456789")

        let event = Event(from: ekEvent)

        #expect(event.isZoomMeeting == true)
        #expect(event.isTeamsMeeting == false)
        #expect(event.isGoogleMeetMeeting == false)
    }

    @Test("Event detects Zoom meeting from notes field")
    func eventDetectsZoomMeetingFromNotes() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Zoom Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.notes = "Join Zoom Meeting: https://zoom.us/j/987654321?pwd=abc123"

        let event = Event(from: ekEvent)

        #expect(event.isZoomMeeting == true)
        #expect(event.isTeamsMeeting == false)
        #expect(event.isGoogleMeetMeeting == false)
    }

    @Test("Event detects Zoom Gov meeting")
    func eventDetectsZoomGovMeeting() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Zoom Gov Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://zoomgov.com/j/123456789")

        let event = Event(from: ekEvent)

        #expect(event.isZoomMeeting == true)
    }

    // MARK: - No Meeting Link Tests

    @Test("Event without meeting links returns false for all")
    func eventWithoutMeetingLinksReturnsFalse() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Regular Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.notes = "This is a regular meeting without any video conference links."

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == false)
        #expect(event.isGoogleMeetMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    @Test("Event with non-meeting URL returns false for all")
    func eventWithNonMeetingURLReturnsFalse() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Event with Website"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://www.example.com")
        ekEvent.notes = "Check out our website: https://www.example.com"

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == false)
        #expect(event.isGoogleMeetMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    // MARK: - Multiple Meeting Links Tests

    @Test("Event with multiple meeting links in notes detects all")
    func eventWithMultipleMeetingLinksDetectsAll() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Multi-Platform Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.notes = """
        Teams: https://teams.microsoft.com/l/meetup-join/123
        Zoom: https://zoom.us/j/456
        Google Meet: https://meet.google.com/abc-def-ghi
        """

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == true)
        #expect(event.isGoogleMeetMeeting == true)
        #expect(event.isZoomMeeting == true)
    }

    // MARK: - Case Sensitivity Tests

    @Test("Event detects meeting links case-insensitively")
    func eventDetectsMeetingLinksCaseInsensitively() async throws {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .event).first else {
            return
        }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = "Case Test Meeting"
        ekEvent.startDate = Date()
        ekEvent.endDate = Date(timeIntervalSinceNow: 3600)
        ekEvent.url = URL(string: "https://TEAMS.MICROSOFT.COM/l/meetup-join/123")

        let event = Event(from: ekEvent)

        #expect(event.isTeamsMeeting == true)
    }
}
