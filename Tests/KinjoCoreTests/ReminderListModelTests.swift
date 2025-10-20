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

@Suite("ReminderList Model Tests")
struct ReminderListModelTests {

    // MARK: - Initialisation Tests

    @Test("ReminderList initialises with all properties")
    func reminderListInitialisesWithAllProperties() {
        let reminderList = ReminderList.makeTest(title: "Work Tasks")

        #expect(!reminderList.id.isEmpty)
        #expect(reminderList.title == "Work Tasks")
        #expect(!reminderList.sourceName.isEmpty)
        #expect(!reminderList.sourceID.isEmpty)
    }

    // MARK: - Hashable Tests

    @Test("ReminderList hash is based on id")
    func reminderListHashIsBasedOnID() {
        let id = "test-list-id"
        let list1 = ReminderList.makeTest(id: id, title: "List 1")
        let list2 = ReminderList.makeTest(id: id, title: "List 2")

        #expect(list1.hashValue == list2.hashValue)
    }

    // MARK: - Equatable Tests

    @Test("ReminderList equality is based on id")
    func reminderListEqualityIsBasedOnID() {
        let id = "test-list-id"
        let list1 = ReminderList.makeTest(id: id, title: "List 1")
        let list2 = ReminderList.makeTest(id: id, title: "List 2")

        #expect(list1 == list2)
    }

    @Test("ReminderList inequality works for different lists")
    func reminderListInequalityWorksForDifferent() {
        let list1 = ReminderList.makeTest(id: "list-1", title: "Work")
        let list2 = ReminderList.makeTest(id: "list-2", title: "Personal")

        #expect(list1 != list2)
    }
}
