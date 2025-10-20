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
import EventKit
@testable import KinjoCore

@Suite("Smart Filter Tests")
struct SmartFilterTests {

    @Test("FilterCriteria is Codable")
    func filterCriteriaIsCodable() throws {
        let criteria = FilterCriteria(
            listSelection: .specific(["list1", "list2"]),
            completionFilter: .incomplete,
            dateRangeFilter: .today,
            tagFilter: .hasTag("work"),
            textSearch: .contains("meeting"),
            sortBy: .dueDate(ascending: true)
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(criteria)
        let decoded = try decoder.decode(FilterCriteria.self, from: data)

        #expect(decoded == criteria)
    }

    @Test("ListSelectionCriteria is Codable")
    func listSelectionCriteriaIsCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Test .all
        let all = ListSelectionCriteria.all
        let allData = try encoder.encode(all)
        let decodedAll = try decoder.decode(ListSelectionCriteria.self, from: allData)
        #expect(decodedAll == all)

        // Test .specific
        let specific = ListSelectionCriteria.specific(["list1", "list2"])
        let specificData = try encoder.encode(specific)
        let decodedSpecific = try decoder.decode(ListSelectionCriteria.self, from: specificData)
        #expect(decodedSpecific == specific)

        // Test .excluding
        let excluding = ListSelectionCriteria.excluding(["list3"])
        let excludingData = try encoder.encode(excluding)
        let decodedExcluding = try decoder.decode(ListSelectionCriteria.self, from: excludingData)
        #expect(decodedExcluding == excluding)
    }

    @Test("FilterCriteria creates ListSelectionCriteria from ReminderListSelection")
    @MainActor
    func filterCriteriaCreatesListSelectionFromReminderListSelection() async throws {
        let permissionService = PermissionService()

        guard permissionService.hasReminderAccess else {
            // Skip if no permission
            return
        }

        let calendars = permissionService.eventStore.calendars(for: .reminder)

        guard calendars.count >= 2 else {
            // Skip if not enough calendars
            return
        }

        let list1 = ReminderList(from: calendars[0])
        let list2 = ReminderList(from: calendars[1])

        // Test .all
        let criteriaAll = FilterCriteria.listSelectionFrom(.all)
        #expect(criteriaAll == .all)

        // Test .specific
        let criteriaSpecific = FilterCriteria.listSelectionFrom(.specific([list1, list2]))
        if case .specific(let ids) = criteriaSpecific {
            #expect(ids.count == 2)
            #expect(ids.contains(list1.id))
            #expect(ids.contains(list2.id))
        } else {
            Issue.record("Expected .specific")
        }

        // Test .excluding
        let criteriaExcluding = FilterCriteria.listSelectionFrom(.excluding([list1]))
        if case .excluding(let ids) = criteriaExcluding {
            #expect(ids == [list1.id])
        } else {
            Issue.record("Expected .excluding")
        }
    }

    @Test("SmartFilter built-in filters are created correctly")
    func smartFilterBuiltInFiltersCreatedCorrectly() {
        let builtInFilters = SmartFilter.builtInFilters()

        #expect(builtInFilters.count == 6)

        // Verify all are marked as built-in
        #expect(builtInFilters.allSatisfy { $0.isBuiltIn })

        // Verify names
        let names = builtInFilters.map { $0.name }
        #expect(names.contains("All"))
        #expect(names.contains("Today"))
        #expect(names.contains("Tomorrow"))
        #expect(names.contains("This Week"))
        #expect(names.contains("Flagged"))
        #expect(names.contains("Completed"))

        // Verify sort order
        #expect(builtInFilters[0].sortOrder == 0)
        #expect(builtInFilters[1].sortOrder == 1)
        #expect(builtInFilters[2].sortOrder == 2)
        #expect(builtInFilters[3].sortOrder == 3)
        #expect(builtInFilters[4].sortOrder == 4)
        #expect(builtInFilters[5].sortOrder == 5)

        // Verify All filter has correct criteria (no filters applied)
        if let allFilter = builtInFilters.first(where: { $0.name == "All" }) {
            #expect(allFilter.criteria.completionFilter == .all)
            #expect(allFilter.criteria.dateRangeFilter == .all)
        } else {
            Issue.record("All filter not found")
        }

        // Verify Today filter has correct criteria
        if let todayFilter = builtInFilters.first(where: { $0.name == "Today" }) {
            #expect(todayFilter.criteria.dateRangeFilter == .today)
            #expect(todayFilter.criteria.completionFilter == .incomplete)
        } else {
            Issue.record("Today filter not found")
        }

        // Verify Tomorrow filter has correct criteria
        if let tomorrowFilter = builtInFilters.first(where: { $0.name == "Tomorrow" }) {
            #expect(tomorrowFilter.criteria.dateRangeFilter == .tomorrow)
            #expect(tomorrowFilter.criteria.completionFilter == .incomplete)
        } else {
            Issue.record("Tomorrow filter not found")
        }

        // Verify Completed filter has correct criteria
        if let completedFilter = builtInFilters.first(where: { $0.name == "Completed" }) {
            #expect(completedFilter.criteria.completionFilter == .completed)
        } else {
            Issue.record("Completed filter not found")
        }
    }

    @Test("SmartFilterService can create filter")
    @MainActor
    func smartFilterServiceCanCreateFilter() async throws {
        let service = SmartFilterService(groupIdentifier: "test.smartfilter.create", isInMemory: true)

        let criteria = FilterCriteria(
            completionFilter: .incomplete,
            tagFilter: .hasTag("work")
        )

        let filter = try await service.createFilter(
            name: "Work Tasks",
            iconName: "briefcase.fill",
            tintColor: "#0066CC",
            criteria: criteria
        )

        #expect(filter.name == "Work Tasks")
        #expect(filter.iconName == "briefcase.fill")
        #expect(filter.tintColor == "#0066CC")
        #expect(filter.isBuiltIn == false)
        #expect(filter.criteria == criteria)

        // Clean up
        try await service.deleteFilter(filter.id)
    }

    @Test("SmartFilterService rejects empty name")
    @MainActor
    func smartFilterServiceRejectsEmptyName() async throws {
        let service = SmartFilterService(groupIdentifier: "test.smartfilter.emptyname", isInMemory: true)

        do {
            _ = try await service.createFilter(
                name: "   ",
                iconName: "star.fill",
                criteria: FilterCriteria()
            )
            Issue.record("Should have thrown invalidName error")
        } catch let error as SmartFilterServiceError {
            #expect(error == .invalidName)
        }
    }

    @Test("SmartFilterService can update filter")
    @MainActor
    func smartFilterServiceCanUpdateFilter() async throws {
        let service = SmartFilterService(groupIdentifier: "test.smartfilter.update", isInMemory: true)

        let filter = try await service.createFilter(
            name: "Original Name",
            iconName: "star.fill",
            criteria: FilterCriteria()
        )

        let updated = try await service.updateFilter(
            filter.id,
            name: "Updated Name",
            iconName: "star.circle.fill",
            tintColor: "#FF0000"
        )

        #expect(updated.name == "Updated Name")
        #expect(updated.iconName == "star.circle.fill")
        #expect(updated.tintColor == "#FF0000")

        // Clean up
        try await service.deleteFilter(filter.id)
    }

    @Test("SmartFilterService prevents modifying built-in filters")
    @MainActor
    func smartFilterServicePreventsModifyingBuiltInFilters() async throws {
        let service = SmartFilterService(groupIdentifier: "test.smartfilter.builtin", isInMemory: true)

        try await service.ensureBuiltInFilters()
        try await service.fetchFilters()

        guard let builtInFilter = service.filters.first(where: { $0.isBuiltIn }) else {
            Issue.record("No built-in filter found")
            return
        }

        // Try to update
        do {
            _ = try await service.updateFilter(builtInFilter.id, name: "Modified")
            Issue.record("Should have thrown builtInFilterImmutable error")
        } catch let error as SmartFilterServiceError {
            #expect(error == .builtInFilterImmutable)
        }

        // Try to delete
        do {
            try await service.deleteFilter(builtInFilter.id)
            Issue.record("Should have thrown builtInFilterImmutable error")
        } catch let error as SmartFilterServiceError {
            #expect(error == .builtInFilterImmutable)
        }
    }

    @Test("SmartFilterService can reorder filters")
    @MainActor
    func smartFilterServiceCanReorderFilters() async throws {
        let service = SmartFilterService(groupIdentifier: "test.smartfilter.reorder", isInMemory: true)

        let filter1 = try await service.createFilter(
            name: "Filter 1",
            iconName: "1.circle",
            criteria: FilterCriteria()
        )
        let filter2 = try await service.createFilter(
            name: "Filter 2",
            iconName: "2.circle",
            criteria: FilterCriteria()
        )
        let filter3 = try await service.createFilter(
            name: "Filter 3",
            iconName: "3.circle",
            criteria: FilterCriteria()
        )

        // Reorder: 3, 1, 2
        try await service.reorderFilters([filter3, filter1, filter2])

        // Fetch and verify order
        try await service.fetchFilters()
        let reordered = service.filters.filter { !$0.isBuiltIn }

        #expect(reordered[0].name == "Filter 3")
        #expect(reordered[0].sortOrder == 0)
        #expect(reordered[1].name == "Filter 1")
        #expect(reordered[1].sortOrder == 1)
        #expect(reordered[2].name == "Filter 2")
        #expect(reordered[2].sortOrder == 2)

        // Clean up
        try await service.deleteFilter(filter1.id)
        try await service.deleteFilter(filter2.id)
        try await service.deleteFilter(filter3.id)
    }

    @Test("SmartFilterService ensureBuiltInFilters creates missing filters")
    @MainActor
    func smartFilterServiceEnsureBuiltInFiltersCreatesMissingFilters() async throws {
        // Use a unique identifier for each test run to ensure a clean database
        let uniqueIdentifier = "test.smartfilter.ensurebuiltin.\(UUID().uuidString)"
        let service = SmartFilterService(groupIdentifier: uniqueIdentifier, isInMemory: true)

        try await service.ensureBuiltInFilters()
        try await service.fetchFilters()

        let builtInCount = service.filters.filter { $0.isBuiltIn }.count
        #expect(builtInCount == 6)

        // Call again - should not duplicate
        try await service.ensureBuiltInFilters()
        try await service.fetchFilters()

        let builtInCountAfter = service.filters.filter { $0.isBuiltIn }.count
        #expect(builtInCountAfter == 6)
    }

    @Test("SmartFilterService applyFilter integrates with ReminderService")
    @MainActor
    func smartFilterServiceApplyFilterIntegratesWithReminderService() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)
        let filterService = SmartFilterService(groupIdentifier: "test.smartfilter.apply", isInMemory: true)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create test reminder
        let reminder = try await reminderService.createReminder(
            title: "Test Task",
            notes: "#work",
            in: firstList
        )

        // Create smart filter for work tasks
        let filter = try await filterService.createFilter(
            name: "Work Tasks",
            iconName: "briefcase.fill",
            criteria: FilterCriteria(
                completionFilter: .incomplete,
                tagFilter: .hasTag("work")
            )
        )

        // Apply filter
        let results = try await filterService.applyFilter(filter, with: reminderService)

        #expect(results.contains { $0.id == reminder.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder)
        try await filterService.deleteFilter(filter.id)
    }
}
