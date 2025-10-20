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
@testable import KinjoCore

extension Reminder {
    /// Creates a test reminder without requiring EventKit.
    ///
    /// This initialiser is only for use in tests and creates a Reminder
    /// directly using the internal test initialiser, avoiding any EventKit dependencies.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for this reminder.
    ///   - title: The title of the reminder.
    ///   - notes: Optional notes associated with the reminder.
    ///   - startDate: The start date for this reminder, if set.
    ///   - dueDate: The due date for this reminder, if set.
    ///   - priority: The priority level of the reminder.
    ///   - isCompleted: Whether this reminder has been completed.
    ///   - creationDate: The date when this reminder was created.
    ///   - lastModifiedDate: The date when this reminder was last modified.
    ///   - completionDate: The date when this reminder was completed, if it has been completed.
    ///   - calendarID: The reminder list (calendar) this reminder belongs to.
    ///   - url: The URL associated with the reminder, if specified.
    ///   - recurrenceRules: The recurrence rules for this reminder.
    ///   - alarms: The alarms configured for this reminder.
    ///   - location: The location associated with this reminder.
    static func makeTest(
        id: String = UUID().uuidString,
        title: String,
        notes: String? = nil,
        startDate: Date? = nil,
        dueDate: Date? = nil,
        priority: Priority = .none,
        isCompleted: Bool = false,
        creationDate: Date? = Date(),
        lastModifiedDate: Date? = Date(),
        completionDate: Date? = nil,
        calendarID: String = "test-calendar",
        url: URL? = nil,
        recurrenceRules: [RecurrenceRule]? = nil,
        alarms: [Alarm]? = nil,
        location: String? = nil
    ) -> Reminder {
        // Use the internal test initialiser directly
        return Reminder(
            id: id,
            title: title,
            notes: notes,
            startDate: startDate,
            dueDate: dueDate,
            priority: priority,
            isCompleted: isCompleted,
            creationDate: creationDate,
            lastModifiedDate: lastModifiedDate,
            completionDate: completionDate,
            calendarID: calendarID,
            url: url,
            recurrenceRules: recurrenceRules,
            alarms: alarms,
            location: location
        )
    }
}
