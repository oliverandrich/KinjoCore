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
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
}
