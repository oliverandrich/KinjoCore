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
import EventKit
@testable import KinjoCore

@Suite("ReminderListSelection Tests")
struct ReminderListSelectionTests {

    @Test("ReminderListSelection.all case exists")
    func allCaseExists() {
        let selection = ReminderListSelection.all
        #expect(selection == .all)
    }

    @Test("ReminderListSelection.specific case works with single list")
    func specificCaseWorksWithSingleList() {
        let permissionService = PermissionService()
        let calendars = permissionService.eventStore.calendars(for: .reminder)

        if let firstCalendar = calendars.first {
            let list = ReminderList(from: firstCalendar)
            let selection = ReminderListSelection.specific([list])

            if case .specific(let lists) = selection {
                #expect(lists.count == 1)
                #expect(lists.first == list)
            } else {
                #expect(Bool(false), "Expected .specific case")
            }
        }
    }

    @Test("ReminderListSelection.specific case works with multiple lists")
    func specificCaseWorksWithMultipleLists() {
        let permissionService = PermissionService()
        let calendars = permissionService.eventStore.calendars(for: .reminder)

        if calendars.count >= 2 {
            let list1 = ReminderList(from: calendars[0])
            let list2 = ReminderList(from: calendars[1])
            let selection = ReminderListSelection.specific([list1, list2])

            if case .specific(let lists) = selection {
                #expect(lists.count == 2)
                #expect(lists.contains(list1))
                #expect(lists.contains(list2))
            } else {
                #expect(Bool(false), "Expected .specific case")
            }
        }
    }

    @Test("ReminderListSelection.specific case works with empty array")
    func specificCaseWorksWithEmptyArray() {
        let selection = ReminderListSelection.specific([])

        if case .specific(let lists) = selection {
            #expect(lists.isEmpty)
        } else {
            #expect(Bool(false), "Expected .specific case")
        }
    }

    @Test("ReminderListSelection enum equality works correctly")
    func enumEqualityWorksCorrectly() {
        #expect(ReminderListSelection.all == ReminderListSelection.all)

        let permissionService = PermissionService()
        let calendars = permissionService.eventStore.calendars(for: .reminder)

        if let firstCalendar = calendars.first {
            let list = ReminderList(from: firstCalendar)
            let selection1 = ReminderListSelection.specific([list])
            let selection2 = ReminderListSelection.specific([list])

            #expect(selection1 == selection2)
            #expect(ReminderListSelection.all != selection1)
        }
    }

    @Test("ReminderListSelection is Hashable")
    func selectionIsHashable() {
        var set = Set<ReminderListSelection>()
        set.insert(.all)

        #expect(set.count == 1)

        // Adding the same value again shouldn't increase count
        set.insert(.all)
        #expect(set.count == 1)
    }

    @Test("ReminderService fetches from specific single list")
    @MainActor
    func serviceFetchesFromSpecificSingleList() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            // Skip test if no permission
            return
        }

        // Fetch all lists first
        try await reminderService.fetchReminderLists()

        if let firstList = reminderService.reminderLists.first {
            // Fetch reminders from specific list
            let reminders = try await reminderService.fetchReminders(from: .specific([firstList]))

            // Verify the fetch succeeded (array may be empty)
            _ = reminders
        }
    }

    @Test("ReminderService fetches from multiple lists")
    @MainActor
    func serviceFetchesFromMultipleLists() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            // Skip test if no permission
            return
        }

        // Fetch all lists first
        try await reminderService.fetchReminderLists()

        if reminderService.reminderLists.count >= 2 {
            let list1 = reminderService.reminderLists[0]
            let list2 = reminderService.reminderLists[1]

            // Fetch reminders from two lists
            let reminders = try await reminderService.fetchReminders(from: .specific([list1, list2]))

            // Verify the fetch succeeded (array may be empty)
            _ = reminders
        }
    }

    @Test("ReminderService treats empty array as all lists")
    @MainActor
    func serviceTreatsEmptyArrayAsAllLists() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            // Skip test if no permission
            return
        }

        // Fetch with empty array
        let remindersFromEmpty = try await reminderService.fetchReminders(from: .specific([]))

        // Fetch with .all
        let remindersFromAll = try await reminderService.fetchReminders(from: .all)

        // Both should return the same results
        #expect(remindersFromEmpty.count == remindersFromAll.count)
    }

    @Test("ReminderListSelection.excluding excludes specified lists")
    @MainActor
    func excludingCaseExcludesSpecifiedLists() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard reminderService.reminderLists.count >= 2 else {
            // Need at least 2 lists for this test
            return
        }

        let list1 = reminderService.reminderLists[0]
        let list2 = reminderService.reminderLists[1]

        // Create reminders in different lists
        let reminder1 = try await reminderService.createReminder(
            title: "Task in List 1",
            in: list1
        )
        let reminder2 = try await reminderService.createReminder(
            title: "Task in List 2",
            in: list2
        )

        // Fetch excluding list2 (should only get list1's reminder)
        let results = try await reminderService.fetchReminders(
            from: .excluding([list2])
        )

        #expect(results.contains { $0.id == reminder1.id })
        #expect(!results.contains { $0.id == reminder2.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder1)
        try? await reminderService.deleteReminder(reminder2)
    }

    @Test("ReminderListSelection.excluding with empty array acts as .all")
    @MainActor
    func excludingWithEmptyArrayActsAsAll() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create test reminder
        let reminder = try await reminderService.createReminder(
            title: "Test",
            in: firstList
        )

        // Fetch excluding empty array (should get all)
        let results = try await reminderService.fetchReminders(
            from: .excluding([])
        )

        #expect(results.contains { $0.id == reminder.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("ReminderListSelection.excluding with multiple lists")
    @MainActor
    func excludingWithMultipleLists() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard reminderService.reminderLists.count >= 3 else {
            // Need at least 3 lists for this test
            return
        }

        let list1 = reminderService.reminderLists[0]
        let list2 = reminderService.reminderLists[1]
        let list3 = reminderService.reminderLists[2]

        // Create reminders in different lists
        let reminder1 = try await reminderService.createReminder(
            title: "Task 1",
            in: list1
        )
        let reminder2 = try await reminderService.createReminder(
            title: "Task 2",
            in: list2
        )
        let reminder3 = try await reminderService.createReminder(
            title: "Task 3",
            in: list3
        )

        // Fetch excluding list1 and list3 (should only get list2's reminder)
        let results = try await reminderService.fetchReminders(
            from: .excluding([list1, list3])
        )

        #expect(!results.contains { $0.id == reminder1.id })
        #expect(results.contains { $0.id == reminder2.id })
        #expect(!results.contains { $0.id == reminder3.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder1)
        try? await reminderService.deleteReminder(reminder2)
        try? await reminderService.deleteReminder(reminder3)
    }

    @Test("ReminderListSelection.excluding equality works correctly")
    func excludingEqualityWorksCorrectly() {
        let permissionService = PermissionService()
        let calendars = permissionService.eventStore.calendars(for: .reminder)

        if calendars.count >= 2 {
            let list1 = ReminderList(from: calendars[0])
            let list2 = ReminderList(from: calendars[1])

            let selection1 = ReminderListSelection.excluding([list1])
            let selection2 = ReminderListSelection.excluding([list1])
            let selection3 = ReminderListSelection.excluding([list2])

            #expect(selection1 == selection2)
            #expect(selection1 != selection3)
            #expect(ReminderListSelection.all != selection1)
            #expect(ReminderListSelection.specific([list1]) != selection1)
        }
    }
}
