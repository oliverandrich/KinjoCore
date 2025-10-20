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
@testable import KinjoCore

@Suite("FilterCriteria Conversion Tests")
struct FilterCriteriaTests {

    // MARK: - Helper Method

    /// Creates ReminderList objects for testing (requires EventKit permissions)
    func createTestReminderLists() -> [ReminderList]? {
        let permissionService = PermissionService()

        guard permissionService.hasReminderAccess else {
            return nil
        }

        let calendars = permissionService.eventStore.calendars(for: .reminder)
        guard calendars.count >= 2 else {
            return nil
        }

        return calendars.prefix(3).map { ReminderList(from: $0) }
    }

    // MARK: - toReminderListSelection Tests

    @Test("FilterCriteria toReminderListSelection converts .all correctly")
    func filterCriteriaConvertsAllCorrectly() {
        guard let lists = createTestReminderLists() else {
            return // Skip if no permissions or insufficient lists
        }

        let criteria = FilterCriteria(listSelection: .all)
        let selection = criteria.toReminderListSelection(availableLists: lists)

        switch selection {
        case .all:
            #expect(true) // Success
        default:
            Issue.record("Expected .all selection")
        }
    }

    @Test("FilterCriteria toReminderListSelection converts .specific correctly")
    func filterCriteriaConvertsSpecificCorrectly() {
        guard let lists = createTestReminderLists(), lists.count >= 2 else {
            return
        }

        let ids = [lists[0].id, lists[1].id]
        let criteria = FilterCriteria(listSelection: .specific(ids))
        let selection = criteria.toReminderListSelection(availableLists: lists)

        switch selection {
        case .specific(let selectedLists):
            #expect(selectedLists.count == 2)
            #expect(selectedLists.contains { $0.id == lists[0].id })
            #expect(selectedLists.contains { $0.id == lists[1].id })
        default:
            Issue.record("Expected .specific selection")
        }
    }

    @Test("FilterCriteria toReminderListSelection converts .excluding correctly")
    func filterCriteriaConvertsExcludingCorrectly() {
        guard let lists = createTestReminderLists(), lists.count >= 1 else {
            return
        }

        let criteria = FilterCriteria(listSelection: .excluding([lists[0].id]))
        let selection = criteria.toReminderListSelection(availableLists: lists)

        switch selection {
        case .excluding(let excludedLists):
            #expect(excludedLists.count == 1)
            #expect(excludedLists.first?.id == lists[0].id)
        default:
            Issue.record("Expected .excluding selection")
        }
    }

    @Test("FilterCriteria toReminderListSelection handles empty specific IDs")
    func filterCriteriaHandlesEmptySpecificIDs() {
        guard let lists = createTestReminderLists() else {
            return
        }

        let criteria = FilterCriteria(listSelection: .specific([]))
        let selection = criteria.toReminderListSelection(availableLists: lists)

        switch selection {
        case .specific(let selectedLists):
            #expect(selectedLists.isEmpty)
        default:
            Issue.record("Expected .specific selection with empty list")
        }
    }

    @Test("FilterCriteria toReminderListSelection handles non-existent IDs")
    func filterCriteriaHandlesNonExistentIDs() {
        guard let lists = createTestReminderLists() else {
            return
        }

        let criteria = FilterCriteria(listSelection: .specific(["non-existent-id"]))
        let selection = criteria.toReminderListSelection(availableLists: lists)

        switch selection {
        case .specific(let selectedLists):
            #expect(selectedLists.isEmpty) // No matching lists
        default:
            Issue.record("Expected .specific selection")
        }
    }

    @Test("FilterCriteria toReminderListSelection handles empty available lists")
    func filterCriteriaHandlesEmptyAvailableLists() {
        let criteria = FilterCriteria(listSelection: .specific(["list-1"]))
        let emptyLists: [ReminderList] = []

        let selection = criteria.toReminderListSelection(availableLists: emptyLists)

        switch selection {
        case .specific(let selectedLists):
            #expect(selectedLists.isEmpty)
        default:
            Issue.record("Expected .specific selection")
        }
    }

    // MARK: - listSelectionFrom Tests

    @Test("FilterCriteria listSelectionFrom converts .all correctly")
    func filterCriteriaListSelectionFromConvertsAll() {
        let selection = ReminderListSelection.all

        let criteria = FilterCriteria.listSelectionFrom(selection)

        switch criteria {
        case .all:
            #expect(true) // Success
        default:
            Issue.record("Expected .all criteria")
        }
    }

    @Test("FilterCriteria listSelectionFrom converts .specific correctly")
    func filterCriteriaListSelectionFromConvertsSpecific() {
        guard let lists = createTestReminderLists(), lists.count >= 2 else {
            return
        }

        let selection = ReminderListSelection.specific([lists[0], lists[1]])
        let criteria = FilterCriteria.listSelectionFrom(selection)

        switch criteria {
        case .specific(let ids):
            #expect(ids.count == 2)
            #expect(ids.contains(lists[0].id))
            #expect(ids.contains(lists[1].id))
        default:
            Issue.record("Expected .specific criteria")
        }
    }

    @Test("FilterCriteria listSelectionFrom converts .excluding correctly")
    func filterCriteriaListSelectionFromConvertsExcluding() {
        guard let lists = createTestReminderLists(), lists.count >= 1 else {
            return
        }

        let selection = ReminderListSelection.excluding([lists[0]])
        let criteria = FilterCriteria.listSelectionFrom(selection)

        switch criteria {
        case .excluding(let ids):
            #expect(ids.count == 1)
            #expect(ids.contains(lists[0].id))
        default:
            Issue.record("Expected .excluding criteria")
        }
    }

    @Test("FilterCriteria listSelectionFrom handles empty specific lists")
    func filterCriteriaListSelectionFromHandlesEmptySpecific() {
        let selection = ReminderListSelection.specific([])

        let criteria = FilterCriteria.listSelectionFrom(selection)

        switch criteria {
        case .specific(let ids):
            #expect(ids.isEmpty)
        default:
            Issue.record("Expected .specific criteria with empty IDs")
        }
    }

    @Test("FilterCriteria listSelectionFrom handles empty excluding lists")
    func filterCriteriaListSelectionFromHandlesEmptyExcluding() {
        let selection = ReminderListSelection.excluding([])

        let criteria = FilterCriteria.listSelectionFrom(selection)

        switch criteria {
        case .excluding(let ids):
            #expect(ids.isEmpty)
        default:
            Issue.record("Expected .excluding criteria with empty IDs")
        }
    }

    // MARK: - Round-trip Conversion Tests

    @Test("FilterCriteria round-trip conversion for .all")
    func filterCriteriaRoundTripAll() {
        guard let lists = createTestReminderLists() else {
            return
        }

        let originalSelection = ReminderListSelection.all
        let criteria = FilterCriteria.listSelectionFrom(originalSelection)
        let reconstructed = FilterCriteria(listSelection: criteria).toReminderListSelection(availableLists: lists)

        #expect(reconstructed == originalSelection)
    }

    @Test("FilterCriteria round-trip conversion for .specific")
    func filterCriteriaRoundTripSpecific() {
        guard let lists = createTestReminderLists(), lists.count >= 2 else {
            return
        }

        let originalSelection = ReminderListSelection.specific([lists[0], lists[1]])
        let criteria = FilterCriteria.listSelectionFrom(originalSelection)
        let reconstructed = FilterCriteria(listSelection: criteria).toReminderListSelection(availableLists: lists)

        #expect(reconstructed == originalSelection)
    }

    @Test("FilterCriteria round-trip conversion for .excluding")
    func filterCriteriaRoundTripExcluding() {
        guard let lists = createTestReminderLists(), lists.count >= 1 else {
            return
        }

        let originalSelection = ReminderListSelection.excluding([lists[0]])
        let criteria = FilterCriteria.listSelectionFrom(originalSelection)
        let reconstructed = FilterCriteria(listSelection: criteria).toReminderListSelection(availableLists: lists)

        #expect(reconstructed == originalSelection)
    }

    // MARK: - Initialisation Tests

    @Test("FilterCriteria default initialisation has expected defaults")
    func filterCriteriaDefaultInitHasDefaults() {
        let criteria = FilterCriteria()

        switch criteria.listSelection {
        case .all:
            #expect(true)
        default:
            Issue.record("Expected .all for listSelection")
        }

        #expect(criteria.completionFilter == .all)
        #expect(criteria.dateRangeFilter == .all)
        #expect(criteria.tagFilter == .none)
        #expect(criteria.textSearch == .none)
        #expect(criteria.sortBy == .title)
    }

    @Test("FilterCriteria custom initialisation sets values correctly")
    func filterCriteriaCustomInitSetsValues() {
        let criteria = FilterCriteria(
            listSelection: .specific(["list-1"]),
            completionFilter: .incomplete,
            dateRangeFilter: .today,
            tagFilter: .hasTag("work"),
            textSearch: .contains("meeting"),
            sortBy: .dueDate(ascending: true)
        )

        switch criteria.listSelection {
        case .specific(let ids):
            #expect(ids == ["list-1"])
        default:
            Issue.record("Expected .specific for listSelection")
        }

        #expect(criteria.completionFilter == .incomplete)
        #expect(criteria.dateRangeFilter == .today)
    }

    // MARK: - Hashable Tests

    @Test("FilterCriteria equality works correctly")
    func filterCriteriaEqualityWorks() {
        let criteria1 = FilterCriteria(
            listSelection: .specific(["list-1"]),
            completionFilter: .incomplete
        )

        let criteria2 = FilterCriteria(
            listSelection: .specific(["list-1"]),
            completionFilter: .incomplete
        )

        #expect(criteria1 == criteria2)
    }

    @Test("FilterCriteria inequality works correctly")
    func filterCriteriaInequalityWorks() {
        let criteria1 = FilterCriteria(completionFilter: .incomplete)
        let criteria2 = FilterCriteria(completionFilter: .completed)

        #expect(criteria1 != criteria2)
    }

    @Test("FilterCriteria hash values are consistent")
    func filterCriteriaHashValuesConsistent() {
        let criteria1 = FilterCriteria(dateRangeFilter: .today)
        let criteria2 = FilterCriteria(dateRangeFilter: .today)

        #expect(criteria1.hashValue == criteria2.hashValue)
    }
}
