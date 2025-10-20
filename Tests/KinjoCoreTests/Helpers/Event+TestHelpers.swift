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
@testable import KinjoCore

extension Event {
    /// Creates a test event without requiring EventKit.
    ///
    /// This initialiser is only for use in tests and creates an Event
    /// directly using the internal test initialiser, avoiding any EventKit dependencies.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for this event.
    ///   - title: The title of the event.
    ///   - notes: Optional notes associated with the event.
    ///   - startDate: The start date and time of the event.
    ///   - endDate: The end date and time of the event.
    ///   - isAllDay: Whether this event lasts all day.
    ///   - location: The location of the event, if specified.
    ///   - calendarID: The calendar this event belongs to.
    ///   - url: The URL associated with the event, if specified.
    static func makeTest(
        id: String = UUID().uuidString,
        title: String,
        notes: String? = nil,
        startDate: Date = Date(),
        endDate: Date = Date(timeIntervalSinceNow: 3600),
        isAllDay: Bool = false,
        location: String? = nil,
        calendarID: String = "test-calendar",
        url: URL? = nil
    ) -> Event {
        // Use the internal test initialiser directly
        return Event(
            id: id,
            title: title,
            notes: notes,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: location,
            calendarID: calendarID,
            url: url
        )
    }
}
