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

import EventKit
import Foundation

/// A model representing an event from EventKit.
///
/// This type wraps `EKEvent` to provide a clean, Swift-native interface
/// for working with calendar events throughout the application.
public struct Event: Identifiable, Sendable, Hashable {

    // MARK: - Properties

    /// The unique identifier for this event.
    public let id: String

    /// The title of the event.
    public let title: String

    /// Optional notes associated with the event.
    public let notes: String?

    /// The start date and time of the event.
    public let startDate: Date

    /// The end date and time of the event.
    public let endDate: Date

    /// Whether this event lasts all day.
    public let isAllDay: Bool

    /// The location of the event, if specified.
    public let location: String?

    /// The calendar this event belongs to.
    public let calendarID: String

    /// The URL associated with the event, if specified.
    public let url: URL?

    // MARK: - Meeting Detection

    /// Whether this event is a Microsoft Teams meeting.
    ///
    /// This property checks both the event's URL field and notes for Teams meeting links.
    /// Recognised patterns include `teams.microsoft.com` and `teams.live.com`.
    public var isTeamsMeeting: Bool {
        // Check URL field
        if let url = url, let host = url.host?.lowercased() {
            if host.contains("teams.microsoft.com") || host.contains("teams.live.com") {
                return true
            }
        }

        // Check notes for embedded URLs
        if let notes = notes {
            let urls = extractURLs(from: notes)
            if containsHost(urls, host: "teams.microsoft.com") || containsHost(urls, host: "teams.live.com") {
                return true
            }
        }

        return false
    }

    /// Whether this event is a Google Meet meeting.
    ///
    /// This property checks both the event's URL field and notes for Google Meet links.
    /// Recognised pattern: `meet.google.com`.
    public var isGoogleMeetMeeting: Bool {
        // Check URL field
        if let url = url, let host = url.host?.lowercased() {
            if host.contains("meet.google.com") {
                return true
            }
        }

        // Check notes for embedded URLs
        if let notes = notes {
            let urls = extractURLs(from: notes)
            if containsHost(urls, host: "meet.google.com") {
                return true
            }
        }

        return false
    }

    /// Whether this event is a Zoom meeting.
    ///
    /// This property checks both the event's URL field and notes for Zoom meeting links.
    /// Recognised patterns include `zoom.us` and `zoomgov.com`.
    public var isZoomMeeting: Bool {
        // Check URL field
        if let url = url, let host = url.host?.lowercased() {
            if host.contains("zoom.us") || host.contains("zoomgov.com") {
                return true
            }
        }

        // Check notes for embedded URLs
        if let notes = notes {
            let urls = extractURLs(from: notes)
            if containsHost(urls, host: "zoom.us") || containsHost(urls, host: "zoomgov.com") {
                return true
            }
        }

        return false
    }

    // MARK: - Initialisation

    /// Creates an event from an EventKit event.
    ///
    /// - Parameter event: The EventKit event.
    public init(from event: EKEvent) {
        // Use calendarItemIdentifier for consistency with EKReminder
        // For unsaved events, this will be a unique temporary identifier
        self.id = event.calendarItemIdentifier
        self.title = event.title ?? ""
        self.notes = event.notes
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.isAllDay = event.isAllDay
        self.location = event.location
        self.calendarID = event.calendar?.calendarIdentifier ?? ""
        self.url = event.url
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Private Helpers

    /// Extracts URLs from a given text string.
    ///
    /// - Parameter text: The text to search for URLs.
    /// - Returns: An array of URLs found in the text.
    private func extractURLs(from text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }

        let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text),
                  let url = URL(string: String(text[range])) else {
                return nil
            }
            return url
        }
    }

    /// Checks if any URL in the provided array contains the specified host.
    ///
    /// - Parameters:
    ///   - urls: Array of URLs to check.
    ///   - host: The host string to search for (case-insensitive).
    /// - Returns: `true` if any URL contains the host, otherwise `false`.
    private func containsHost(_ urls: [URL], host: String) -> Bool {
        urls.contains { url in
            url.host?.lowercased().contains(host.lowercased()) ?? false
        }
    }
}
