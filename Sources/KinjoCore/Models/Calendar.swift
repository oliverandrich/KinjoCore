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

/// A model representing a calendar from EventKit.
///
/// This type wraps `EKCalendar` to provide a clean, Swift-native interface
/// for working with calendars throughout the application.
public struct Calendar: Identifiable, Sendable, Hashable {

    // MARK: - Properties

    /// The unique identifier for this calendar.
    public let id: String

    /// The display title of the calendar.
    public let title: String

    /// The colour associated with this calendar.
    public let colour: CGColor

    /// The source name (e.g., "iCloud", "Local") of this calendar.
    public let sourceName: String

    /// The source identifier for this calendar.
    public let sourceID: String

    /// Whether this calendar is immutable (read-only).
    public let isImmutable: Bool

    /// Whether this calendar is subscribed (e.g., from a URL subscription).
    public let isSubscribed: Bool

    // MARK: - Initialisation

    /// Creates a calendar from an EventKit calendar.
    ///
    /// - Parameter calendar: The EventKit calendar representing an event calendar.
    public init(from calendar: EKCalendar) {
        self.id = calendar.calendarIdentifier
        self.title = calendar.title
        self.colour = calendar.cgColor
        self.sourceName = calendar.source.title
        self.sourceID = calendar.source.sourceIdentifier
        self.isImmutable = !calendar.allowsContentModifications
        self.isSubscribed = calendar.isSubscribed
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Calendar, rhs: Calendar) -> Bool {
        lhs.id == rhs.id
    }
}
