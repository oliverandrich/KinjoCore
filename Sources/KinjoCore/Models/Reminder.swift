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

    /// The start date for this reminder, if set.
    ///
    /// Represents when work on this reminder is planned to begin.
    /// When both `startDate` and `dueDate` are set, `startDate` indicates the planned start time
    /// and `dueDate` indicates the deadline. Use `plannedDate` to get the effective planning date.
    public let startDate: Date?

    /// The due date for this reminder, if set.
    ///
    /// Represents the deadline by which this reminder should be completed.
    /// When only `dueDate` is set (without `startDate`), it serves as both the planned date
    /// and the deadline. This matches the behaviour of Apple's Reminders app.
    public let dueDate: Date?

    /// The priority level of the reminder.
    public let priority: Priority

    /// Whether this reminder has been completed.
    public let isCompleted: Bool

    /// The date when this reminder was created.
    public let creationDate: Date?

    /// The date when this reminder was last modified.
    public let lastModifiedDate: Date?

    /// The date when this reminder was completed, if it has been completed.
    public let completionDate: Date?

    /// The reminder list (calendar) this reminder belongs to.
    public let calendarID: String

    /// The URL associated with the reminder, if specified.
    public let url: URL?

    /// The recurrence rules for this reminder.
    ///
    /// Contains one or more recurrence rules if the reminder repeats, or `nil`/empty array if it doesn't.
    /// Multiple rules can be combined to create complex recurrence patterns.
    public let recurrenceRules: [RecurrenceRule]?

    /// The alarms configured for this reminder.
    ///
    /// Alarms trigger notifications at specific times or locations. A reminder can have
    /// multiple alarms (e.g., one day before, one hour before, 15 minutes before).
    public let alarms: [Alarm]?

    /// The location associated with this reminder as a simple text string.
    ///
    /// This is a basic location descriptor like "Office", "Home", or "Supermarket".
    /// For location-based triggers and geofencing, use location-based alarms instead
    /// (via the `alarms` property with `.location` alarm type).
    public let location: String?

    /// Tags extracted from the notes field.
    ///
    /// Tags are identified by the # prefix (e.g., #work, #important).
    /// The returned array contains lowercase tag names without the # prefix,
    /// sorted alphabetically with duplicates removed.
    ///
    /// Example: notes = "Meeting #Work #Important #work" → tags = ["important", "work"]
    public var tags: [String] {
        guard let notes = notes else { return [] }

        // Regex to match #hashtags (Unicode word characters)
        let pattern = #"#(\w+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsRange = NSRange(notes.startIndex..., in: notes)
        let matches = regex.matches(in: notes, options: [], range: nsRange)

        // Extract tags, convert to lowercase, remove duplicates, and sort
        let extractedTags = matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: notes) else { return nil }
            return String(notes[range]).lowercased()
        }

        return Array(Set(extractedTags)).sorted()
    }

    /// Whether this reminder has any tags in its notes.
    public var hasTags: Bool {
        !tags.isEmpty
    }

    /// Whether this reminder has notes.
    public var hasNote: Bool {
        guard let notes = notes else { return false }
        return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether this reminder has recurrence rules (repeats).
    public var hasRecurrenceRules: Bool {
        guard let rules = recurrenceRules else { return false }
        return !rules.isEmpty
    }

    /// Whether this reminder has any alarms configured.
    public var hasAlarms: Bool {
        guard let alarms = alarms else { return false }
        return !alarms.isEmpty
    }

    /// Whether this reminder has location information.
    ///
    /// Returns `true` if `location` is set and not empty.
    public var hasLocation: Bool {
        guard let location = location else { return false }
        return !location.isEmpty
    }

    /// The effective planned date for this reminder.
    ///
    /// Returns `startDate` if set, otherwise falls back to `dueDate`.
    /// Use this property when you want to know "when is this task planned for?"
    /// regardless of whether it has a separate deadline.
    public var plannedDate: Date? {
        startDate ?? dueDate
    }

    /// Whether this reminder has both a start date and a due date.
    ///
    /// When `true`, `startDate` represents the planned start time and `dueDate` represents
    /// the deadline. When `false`, only `dueDate` is set (or neither), and `dueDate` serves
    /// as the single date reference.
    public var hasDeadline: Bool {
        startDate != nil && dueDate != nil
    }

    /// Whether this reminder contains a URL.
    ///
    /// Checks the URL field first, then uses `NSDataDetector` to detect URLs
    /// in both the title and notes fields.
    public var hasURL: Bool {
        // Check URL field first
        if url != nil {
            return true
        }

        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

        // Check title for URLs
        let titleRange = NSRange(title.startIndex..., in: title)
        if let match = detector?.firstMatch(in: title, options: [], range: titleRange) {
            if match.resultType == .link {
                return true
            }
        }

        // Check notes for URLs
        if let notes = notes {
            let notesRange = NSRange(notes.startIndex..., in: notes)
            if let match = detector?.firstMatch(in: notes, options: [], range: notesRange) {
                if match.resultType == .link {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Initialisation

    /// Creates a reminder from an EventKit reminder.
    ///
    /// - Parameter reminder: The EventKit reminder.
    public init(from reminder: EKReminder) {
        self.id = reminder.calendarItemIdentifier
        self.title = reminder.title ?? ""
        self.notes = reminder.notes
        self.startDate = reminder.startDateComponents?.date
        self.dueDate = reminder.dueDateComponents?.date
        self.priority = Priority(eventKitValue: reminder.priority)
        self.isCompleted = reminder.isCompleted
        self.creationDate = reminder.creationDate
        self.lastModifiedDate = reminder.lastModifiedDate
        self.completionDate = reminder.completionDate
        self.calendarID = reminder.calendar?.calendarIdentifier ?? ""
        self.url = reminder.url

        // Convert recurrence rules
        if let ekRules = reminder.recurrenceRules, !ekRules.isEmpty {
            self.recurrenceRules = ekRules.map { RecurrenceRule(from: $0) }
        } else {
            self.recurrenceRules = nil
        }

        // Convert alarms
        if let ekAlarms = reminder.alarms, !ekAlarms.isEmpty {
            self.alarms = ekAlarms.compactMap { Alarm(from: $0) }
        } else {
            self.alarms = nil
        }

        // Convert location
        self.location = reminder.location
    }

    /// Internal initialiser for testing purposes.
    ///
    /// This initialiser allows creating a Reminder directly without requiring EventKit.
    /// It is intended for use in tests only.
    internal init(
        id: String,
        title: String,
        notes: String? = nil,
        startDate: Date? = nil,
        dueDate: Date? = nil,
        priority: Priority = .none,
        isCompleted: Bool = false,
        creationDate: Date? = nil,
        lastModifiedDate: Date? = nil,
        completionDate: Date? = nil,
        calendarID: String,
        url: URL? = nil,
        recurrenceRules: [RecurrenceRule]? = nil,
        alarms: [Alarm]? = nil,
        location: String? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.creationDate = creationDate
        self.lastModifiedDate = lastModifiedDate
        self.completionDate = completionDate
        self.calendarID = calendarID
        self.url = url
        self.recurrenceRules = recurrenceRules
        self.alarms = alarms
        self.location = location
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Reminder, rhs: Reminder) -> Bool {
        lhs.id == rhs.id
    }
}
