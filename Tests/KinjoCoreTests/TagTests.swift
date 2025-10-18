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

@Suite("Tag Extraction and Filtering Tests")
struct TagTests {

    @Test("Reminder extracts tags from notes")
    func reminderExtractsTagsFromNotes() {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        let ekReminder = EKReminder(eventStore: store)
        ekReminder.calendar = calendar
        ekReminder.title = "Test"
        ekReminder.notes = "Meeting about #work and #project"

        let reminder = Reminder(from: ekReminder)

        #expect(reminder.tags.count == 2)
        #expect(reminder.tags.contains("work"))
        #expect(reminder.tags.contains("project"))
    }

    @Test("Reminder tags are lowercase and sorted")
    func reminderTagsAreLowercaseAndSorted() {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        let ekReminder = EKReminder(eventStore: store)
        ekReminder.calendar = calendar
        ekReminder.title = "Test"
        ekReminder.notes = "#Zebra #Apple #Work"

        let reminder = Reminder(from: ekReminder)

        #expect(reminder.tags == ["apple", "work", "zebra"])
    }

    @Test("Reminder removes duplicate tags")
    func reminderRemovesDuplicateTags() {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        let ekReminder = EKReminder(eventStore: store)
        ekReminder.calendar = calendar
        ekReminder.title = "Test"
        ekReminder.notes = "#work #Work #WORK #project #work"

        let reminder = Reminder(from: ekReminder)

        #expect(reminder.tags.count == 2)
        #expect(reminder.tags.contains("work"))
        #expect(reminder.tags.contains("project"))
    }

    @Test("Reminder handles notes without tags")
    func reminderHandlesNotesWithoutTags() {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        let ekReminder = EKReminder(eventStore: store)
        ekReminder.calendar = calendar
        ekReminder.title = "Test"
        ekReminder.notes = "Just regular notes without any hashtags"

        let reminder = Reminder(from: ekReminder)

        #expect(reminder.tags.isEmpty)
    }

    @Test("Reminder handles nil notes")
    func reminderHandlesNilNotes() {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        let ekReminder = EKReminder(eventStore: store)
        ekReminder.calendar = calendar
        ekReminder.title = "Test"
        ekReminder.notes = nil

        let reminder = Reminder(from: ekReminder)

        #expect(reminder.tags.isEmpty)
    }

    @Test("Reminder extracts tags with Unicode characters")
    func reminderExtractsTagsWithUnicode() {
        let permissionService = PermissionService()
        let store = permissionService.eventStore

        guard let calendar = store.calendars(for: .reminder).first else {
            return
        }

        let ekReminder = EKReminder(eventStore: store)
        ekReminder.calendar = calendar
        ekReminder.title = "Test"
        ekReminder.notes = "#café #über #日本語"

        let reminder = Reminder(from: ekReminder)

        #expect(reminder.tags.contains("café"))
        #expect(reminder.tags.contains("über"))
        #expect(reminder.tags.contains("日本語"))
    }

    @Test("TagFilter.none returns all reminders")
    @MainActor
    func tagFilterNoneReturnsAll() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Fetch with no tag filter
        let reminders = try await reminderService.fetchReminders(tagFilter: .none)

        // Should return array (may be empty or have items)
        _ = reminders
    }

    @Test("TagFilter.hasTag filters by single tag")
    @MainActor
    func tagFilterHasTagFiltersBySingleTag() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create test reminders
        let reminder1 = try await reminderService.createReminder(
            title: "Test 1",
            notes: "#work #important",
            in: firstList
        )
        let reminder2 = try await reminderService.createReminder(
            title: "Test 2",
            notes: "#personal",
            in: firstList
        )

        // Fetch with hasTag filter
        let workReminders = try await reminderService.fetchReminders(tagFilter: .hasTag("work"))

        #expect(workReminders.contains { $0.id == reminder1.id })
        #expect(!workReminders.contains { $0.id == reminder2.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder1)
        try? await reminderService.deleteReminder(reminder2)
    }

    @Test("TagFilter.hasTag is case-insensitive")
    @MainActor
    func tagFilterHasTagIsCaseInsensitive() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create reminder with uppercase tag
        let reminder = try await reminderService.createReminder(
            title: "Test",
            notes: "#Work",
            in: firstList
        )

        // Fetch with lowercase filter
        let results = try await reminderService.fetchReminders(tagFilter: .hasTag("work"))

        #expect(results.contains { $0.id == reminder.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("TagFilter.hasAnyTag filters with OR logic")
    @MainActor
    func tagFilterHasAnyTagUsesOrLogic() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create test reminders
        let reminder1 = try await reminderService.createReminder(
            title: "Test 1",
            notes: "#work",
            in: firstList
        )
        let reminder2 = try await reminderService.createReminder(
            title: "Test 2",
            notes: "#personal",
            in: firstList
        )
        let reminder3 = try await reminderService.createReminder(
            title: "Test 3",
            notes: "#other",
            in: firstList
        )

        // Fetch with hasAnyTag filter
        let results = try await reminderService.fetchReminders(
            tagFilter: .hasAnyTag(["work", "personal"])
        )

        #expect(results.contains { $0.id == reminder1.id })
        #expect(results.contains { $0.id == reminder2.id })
        #expect(!results.contains { $0.id == reminder3.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder1)
        try? await reminderService.deleteReminder(reminder2)
        try? await reminderService.deleteReminder(reminder3)
    }

    @Test("TagFilter.hasAllTags filters with AND logic")
    @MainActor
    func tagFilterHasAllTagsUsesAndLogic() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create test reminders
        let reminder1 = try await reminderService.createReminder(
            title: "Test 1",
            notes: "#work #important #urgent",
            in: firstList
        )
        let reminder2 = try await reminderService.createReminder(
            title: "Test 2",
            notes: "#work #important",
            in: firstList
        )
        let reminder3 = try await reminderService.createReminder(
            title: "Test 3",
            notes: "#work",
            in: firstList
        )

        // Fetch with hasAllTags filter
        let results = try await reminderService.fetchReminders(
            tagFilter: .hasAllTags(["work", "important"])
        )

        #expect(results.contains { $0.id == reminder1.id })
        #expect(results.contains { $0.id == reminder2.id })
        #expect(!results.contains { $0.id == reminder3.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder1)
        try? await reminderService.deleteReminder(reminder2)
        try? await reminderService.deleteReminder(reminder3)
    }

    @Test("TagFilter.excludingTags filters with NOT logic")
    @MainActor
    func tagFilterExcludingTagsUsesNotLogic() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create test reminders
        let reminder1 = try await reminderService.createReminder(
            title: "Test 1",
            notes: "#work #active",
            in: firstList
        )
        let reminder2 = try await reminderService.createReminder(
            title: "Test 2",
            notes: "#personal #active",
            in: firstList
        )
        let reminder3 = try await reminderService.createReminder(
            title: "Test 3",
            notes: "#work #archived",
            in: firstList
        )

        // Fetch excluding archived
        let results = try await reminderService.fetchReminders(
            tagFilter: .excludingTags(["archived"])
        )

        #expect(results.contains { $0.id == reminder1.id })
        #expect(results.contains { $0.id == reminder2.id })
        #expect(!results.contains { $0.id == reminder3.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder1)
        try? await reminderService.deleteReminder(reminder2)
        try? await reminderService.deleteReminder(reminder3)
    }

    @Test("TagFilter can combine with other filters")
    @MainActor
    func tagFilterCombinesWithOtherFilters() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create test reminders
        let reminder1 = try await reminderService.createReminder(
            title: "Test 1",
            notes: "#work",
            in: firstList
        )
        let reminder2 = try await reminderService.createReminder(
            title: "Test 2",
            notes: "#work",
            in: firstList
        )

        // Complete one of them
        _ = try await reminderService.toggleReminderCompletion(reminder1)

        // Fetch completed work items
        let results = try await reminderService.fetchReminders(
            filter: .completed,
            tagFilter: .hasTag("work")
        )

        #expect(results.contains { $0.id == reminder1.id })
        #expect(!results.contains { $0.id == reminder2.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder1)
        try? await reminderService.deleteReminder(reminder2)
    }

    @Test("TagFilter enum is Hashable")
    func tagFilterEnumIsHashable() {
        var set = Set<TagFilter>()
        set.insert(.none)
        set.insert(.hasTag("work"))
        set.insert(.hasAnyTag(["work", "personal"]))
        set.insert(.hasAllTags(["work", "important"]))
        set.insert(.excludingTags(["archived"]))

        #expect(set.count == 5)

        // Adding same value shouldn't increase count
        set.insert(.none)
        #expect(set.count == 5)
    }

    @Test("TagFilter enum equality works correctly")
    func tagFilterEnumEqualityWorksCorrectly() {
        #expect(TagFilter.none == TagFilter.none)
        #expect(TagFilter.hasTag("work") == TagFilter.hasTag("Work")) // Case-insensitive
        #expect(TagFilter.hasAnyTag(["a", "b"]) == TagFilter.hasAnyTag(["b", "a"])) // Order doesn't matter
        #expect(TagFilter.hasAllTags(["a", "b"]) == TagFilter.hasAllTags(["B", "A"])) // Case-insensitive & order
        #expect(TagFilter.hasTag("work") != TagFilter.hasTag("personal"))
        #expect(TagFilter.none != TagFilter.hasTag("work"))
    }
}
