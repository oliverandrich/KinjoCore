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

@Suite("Calendar Model Tests")
struct CalendarModelTests {

    // MARK: - Initialisation Tests

    @Test("Calendar initialises with all properties")
    func calendarInitialisesWithAllProperties() {
        let calendar = KinjoCore.Calendar.makeTest(title: "Work Calendar")

        #expect(!calendar.id.isEmpty)
        #expect(calendar.title == "Work Calendar")
        #expect(!calendar.sourceName.isEmpty)
        #expect(!calendar.sourceID.isEmpty)
    }

    // MARK: - Hashable Tests

    @Test("Calendar hash is based on id")
    func calendarHashIsBasedOnID() {
        let id = "test-calendar-id"
        let calendar1 = KinjoCore.Calendar.makeTest(id: id, title: "Calendar 1")
        let calendar2 = KinjoCore.Calendar.makeTest(id: id, title: "Calendar 2")

        #expect(calendar1.hashValue == calendar2.hashValue)
    }

    // MARK: - Equatable Tests

    @Test("Calendar equality is based on id")
    func calendarEqualityIsBasedOnID() {
        let id = "test-calendar-id"
        let calendar1 = KinjoCore.Calendar.makeTest(id: id, title: "Calendar 1")
        let calendar2 = KinjoCore.Calendar.makeTest(id: id, title: "Calendar 2")

        #expect(calendar1 == calendar2)
    }

    @Test("Calendar inequality works for different calendars")
    func calendarInequalityWorksForDifferent() {
        let calendar1 = KinjoCore.Calendar.makeTest(id: "calendar-1", title: "Work")
        let calendar2 = KinjoCore.Calendar.makeTest(id: "calendar-2", title: "Personal")

        #expect(calendar1 != calendar2)
    }
}
