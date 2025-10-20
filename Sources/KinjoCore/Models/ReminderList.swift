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

/// A model representing a reminder list from EventKit.
///
/// This type wraps `EKCalendar` to provide a clean, Swift-native interface
/// for working with reminder lists throughout the application.
public struct ReminderList: Identifiable, Sendable, Hashable {

    // MARK: - Properties

    /// The unique identifier for this reminder list.
    public let id: String

    /// The display title of the reminder list.
    public let title: String

    /// The colour associated with this reminder list.
    public let colour: CGColor

    /// The source name (e.g., "iCloud", "Local") of this reminder list.
    public let sourceName: String

    /// The source identifier for this reminder list.
    public let sourceID: String

    /// Whether this reminder list is immutable (read-only).
    public let isImmutable: Bool

    // MARK: - Initialisation

    /// Creates a reminder list from an EventKit calendar.
    ///
    /// - Parameter calendar: The EventKit calendar representing a reminder list.
    public init(from calendar: EKCalendar) {
        self.id = calendar.calendarIdentifier
        self.title = calendar.title
        self.colour = calendar.cgColor
        self.sourceName = calendar.source.title
        self.sourceID = calendar.source.sourceIdentifier
        self.isImmutable = !calendar.allowsContentModifications
    }

    /// Internal initialiser for testing purposes.
    ///
    /// This initialiser allows creating a ReminderList directly without requiring EventKit.
    /// It is intended for use in tests only.
    internal init(
        id: String,
        title: String,
        colour: CGColor,
        sourceName: String,
        sourceID: String,
        isImmutable: Bool = false
    ) {
        self.id = id
        self.title = title
        self.colour = colour
        self.sourceName = sourceName
        self.sourceID = sourceID
        self.isImmutable = isImmutable
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ReminderList, rhs: ReminderList) -> Bool {
        lhs.id == rhs.id
    }
}
