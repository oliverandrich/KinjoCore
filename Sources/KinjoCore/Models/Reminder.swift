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

/// A model representing a reminder from EventKit.
///
/// This type wraps `EKReminder` to provide a clean, Swift-native interface
/// for working with reminders throughout the application.
public struct Reminder: Identifiable, Sendable, Hashable {

    // MARK: - Properties

    /// The unique identifier for this reminder.
    public let id: String

    /// The title of the reminder.
    public let title: String

    /// Optional notes associated with the reminder.
    public let notes: String?

    /// The due date for this reminder, if set.
    public let dueDate: Date?

    /// The priority level of the reminder (0 = none, 1-4 = high, 5 = medium, 6-9 = low).
    public let priority: Int

    /// Whether this reminder has been completed.
    public let isCompleted: Bool

    /// The date when this reminder was created.
    public let creationDate: Date?

    /// The reminder list (calendar) this reminder belongs to.
    public let calendarID: String

    // MARK: - Initialisation

    /// Creates a reminder from an EventKit reminder.
    ///
    /// - Parameter reminder: The EventKit reminder.
    public init(from reminder: EKReminder) {
        self.id = reminder.calendarItemIdentifier
        self.title = reminder.title ?? ""
        self.notes = reminder.notes
        self.dueDate = reminder.dueDateComponents?.date
        self.priority = reminder.priority
        self.isCompleted = reminder.isCompleted
        self.creationDate = reminder.creationDate
        self.calendarID = reminder.calendar?.calendarIdentifier ?? ""
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Reminder, rhs: Reminder) -> Bool {
        lhs.id == rhs.id
    }
}
