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

import Foundation

/// Represents a task parsed from natural language input.
///
/// This model contains all the information extracted from a natural language string,
/// such as "Bericht schreiben morgen, bis Freitag fertig p1 @Arbeit #wichtig".
/// It distinguishes between scheduled dates (when you plan to work on it) and
/// deadlines (when it must be completed).
///
/// ## Example Usage
///
/// ```swift
/// let parser = TaskParser()
/// let task = try parser.parse("Meeting morgen 14:00 p1 @Arbeit")
///
/// print(task.title)           // "Meeting"
/// print(task.scheduledDate)   // Tomorrow's date
/// print(task.time)            // 14:00
/// print(task.priority)        // 1
/// print(task.project)         // "Arbeit"
/// ```
public struct ParsedTask: Sendable, Equatable {

    // MARK: - Properties

    /// The original natural language input provided by the user.
    public let originalInput: String

    /// The cleaned task title with temporal and metadata markers removed.
    ///
    /// For example, "Bericht schreiben morgen bis Freitag p1 @Arbeit"
    /// becomes "Bericht schreiben".
    public var title: String

    /// The scheduled date when work on this task is planned to begin.
    ///
    /// This represents when you intend to work on the task, as opposed to when
    /// it must be completed (see `deadline`). For example, "Bericht schreiben morgen"
    /// sets `scheduledDate` to tomorrow.
    public var scheduledDate: Date?

    /// The deadline by which this task must be completed.
    ///
    /// This represents the final due date for the task. For example,
    /// "Bericht abgeben bis Freitag" sets `deadline` to next Friday.
    /// A task can have both `scheduledDate` and `deadline` set.
    public var deadline: Date?

    /// The time component for scheduled tasks.
    ///
    /// Contains hour and minute components (e.g., 14:00). This applies to
    /// the `scheduledDate` if both are set. For example, "Meeting morgen 14:00"
    /// sets `scheduledDate` to tomorrow and `time` to 14:00.
    public var time: DateComponents?

    /// The priority level of the task (1-4, where 1 is highest).
    ///
    /// Priorities can be specified using "p1" through "p4" or using exclamation marks:
    /// - p1 / !!! = Priority 1 (highest)
    /// - p2 / !! = Priority 2 (high)
    /// - p3 / ! = Priority 3 (normal)
    /// - p4 = Priority 4 (low)
    public var priority: Int?

    /// The project this task belongs to, extracted from @-tags.
    ///
    /// For example, "@Arbeit" sets `project` to "Arbeit".
    /// Only one project per task is supported.
    public var project: String?

    /// Labels or tags associated with this task, extracted from #-tags.
    ///
    /// For example, "#wichtig #dringend" sets `labels` to ["wichtig", "dringend"].
    /// Multiple labels are supported.
    public var labels: [String]

    /// The recurrence pattern if this is a recurring task.
    ///
    /// For example, "jeden Montag" or "täglich" defines a recurrence pattern.
    /// If `nil`, the task does not recur.
    public var recurring: RecurringPattern?

    /// Text annotations mapping parts of the original input to parsed values.
    ///
    /// These annotations enable UI implementations to highlight which parts of
    /// the input text correspond to which task properties.
    public var annotations: [Annotation]

    // MARK: - Initialisation

    /// Creates a new parsed task.
    ///
    /// - Parameters:
    ///   - originalInput: The original natural language input.
    ///   - title: The cleaned task title.
    ///   - scheduledDate: The scheduled date when work is planned.
    ///   - deadline: The deadline by which the task must be completed.
    ///   - time: The time component for scheduled tasks.
    ///   - priority: The priority level (1-4).
    ///   - project: The project name.
    ///   - labels: Associated labels/tags.
    ///   - recurring: The recurrence pattern.
    ///   - annotations: Text annotations for UI highlighting.
    public init(
        originalInput: String,
        title: String,
        scheduledDate: Date? = nil,
        deadline: Date? = nil,
        time: DateComponents? = nil,
        priority: Int? = nil,
        project: String? = nil,
        labels: [String] = [],
        recurring: RecurringPattern? = nil,
        annotations: [Annotation] = []
    ) {
        self.originalInput = originalInput
        self.title = title
        self.scheduledDate = scheduledDate
        self.deadline = deadline
        self.time = time
        self.priority = priority
        self.project = project
        self.labels = labels
        self.recurring = recurring
        self.annotations = annotations
    }
}
