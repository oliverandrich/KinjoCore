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
import Foundation
@testable import KinjoCore

@Suite("Event Meeting Link Detection Tests")
struct EventMeetingLinkTests {

    // MARK: - Teams Meeting Tests

    @Test("Event detects Teams meeting from URL field")
    func eventDetectsTeamsMeetingFromURL() {
        let event = Event.makeTest(
            title: "Teams Meeting",
            url: URL(string: "https://teams.microsoft.com/l/meetup-join/19%3ameeting_abc123")
        )

        #expect(event.isTeamsMeeting == true)
        #expect(event.isGoogleMeetMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    @Test("Event detects Teams meeting from notes field")
    func eventDetectsTeamsMeetingFromNotes() {
        let event = Event.makeTest(
            title: "Teams Meeting",
            notes: "Join the meeting: https://teams.microsoft.com/l/meetup-join/19%3ameeting_xyz789"
        )

        #expect(event.isTeamsMeeting == true)
        #expect(event.isGoogleMeetMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    @Test("Event detects Teams Live meeting")
    func eventDetectsTeamsLiveMeeting() {
        let event = Event.makeTest(
            title: "Teams Live Meeting",
            url: URL(string: "https://teams.live.com/meet/123456")
        )

        #expect(event.isTeamsMeeting == true)
    }

    // MARK: - Google Meet Tests

    @Test("Event detects Google Meet meeting from URL field")
    func eventDetectsGoogleMeetFromURL() {
        let event = Event.makeTest(
            title: "Google Meet",
            url: URL(string: "https://meet.google.com/abc-defg-hij")
        )

        #expect(event.isGoogleMeetMeeting == true)
        #expect(event.isTeamsMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    @Test("Event detects Google Meet meeting from notes field")
    func eventDetectsGoogleMeetFromNotes() {
        let event = Event.makeTest(
            title: "Google Meet",
            notes: "Click here to join: https://meet.google.com/xyz-qwer-tyu"
        )

        #expect(event.isGoogleMeetMeeting == true)
        #expect(event.isTeamsMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    // MARK: - Zoom Meeting Tests

    @Test("Event detects Zoom meeting from URL field")
    func eventDetectsZoomMeetingFromURL() {
        let event = Event.makeTest(
            title: "Zoom Meeting",
            url: URL(string: "https://zoom.us/j/123456789")
        )

        #expect(event.isZoomMeeting == true)
        #expect(event.isTeamsMeeting == false)
        #expect(event.isGoogleMeetMeeting == false)
    }

    @Test("Event detects Zoom meeting from notes field")
    func eventDetectsZoomMeetingFromNotes() {
        let event = Event.makeTest(
            title: "Zoom Meeting",
            notes: "Join Zoom Meeting: https://zoom.us/j/987654321?pwd=abc123"
        )

        #expect(event.isZoomMeeting == true)
        #expect(event.isTeamsMeeting == false)
        #expect(event.isGoogleMeetMeeting == false)
    }

    @Test("Event detects Zoom Gov meeting")
    func eventDetectsZoomGovMeeting() {
        let event = Event.makeTest(
            title: "Zoom Gov Meeting",
            url: URL(string: "https://zoomgov.com/j/123456789")
        )

        #expect(event.isZoomMeeting == true)
    }

    // MARK: - No Meeting Link Tests

    @Test("Event without meeting links returns false for all")
    func eventWithoutMeetingLinksReturnsFalse() {
        let event = Event.makeTest(
            title: "Regular Meeting",
            notes: "This is a regular meeting without any video conference links."
        )

        #expect(event.isTeamsMeeting == false)
        #expect(event.isGoogleMeetMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    @Test("Event with non-meeting URL returns false for all")
    func eventWithNonMeetingURLReturnsFalse() {
        let event = Event.makeTest(
            title: "Event with Website",
            notes: "Check out our website: https://www.example.com",
            url: URL(string: "https://www.example.com")
        )

        #expect(event.isTeamsMeeting == false)
        #expect(event.isGoogleMeetMeeting == false)
        #expect(event.isZoomMeeting == false)
    }

    // MARK: - Multiple Meeting Links Tests

    @Test("Event with multiple meeting links in notes detects all")
    func eventWithMultipleMeetingLinksDetectsAll() {
        let event = Event.makeTest(
            title: "Multi-Platform Meeting",
            notes: """
            Teams: https://teams.microsoft.com/l/meetup-join/123
            Zoom: https://zoom.us/j/456
            Google Meet: https://meet.google.com/abc-def-ghi
            """
        )

        #expect(event.isTeamsMeeting == true)
        #expect(event.isGoogleMeetMeeting == true)
        #expect(event.isZoomMeeting == true)
    }

    // MARK: - Case Sensitivity Tests

    @Test("Event detects meeting links case-insensitively")
    func eventDetectsMeetingLinksCaseInsensitively() {
        let event = Event.makeTest(
            title: "Case Test Meeting",
            url: URL(string: "https://TEAMS.MICROSOFT.COM/l/meetup-join/123")
        )

        #expect(event.isTeamsMeeting == true)
    }
}
