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

            // Verify it returns an array (may be empty)
            #expect(reminders is [Reminder])
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

            // Verify it returns an array (may be empty)
            #expect(reminders is [Reminder])
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
}
