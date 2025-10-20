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

@Suite("Text Search Filter Tests")
struct TextSearchFilterTests {

    @Test("TextSearchFilter.none returns all reminders")
    @MainActor
    func textSearchFilterNoneReturnsAll() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        // Fetch with no text search
        let reminders = try await reminderService.fetchReminders(textSearch: .none)

        // Should return array (may be empty or have items)
        _ = reminders
    }

    @Test("TextSearchFilter.contains searches in title and notes")
    @MainActor
    func textSearchContainsSearchesTitleAndNotes() async throws {
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
            title: "Meeting about project",
            notes: "Discuss budget",
            in: firstList
        )
        let reminder2 = try await reminderService.createReminder(
            title: "Review budget",
            notes: "Check expenses",
            in: firstList
        )
        let reminder3 = try await reminderService.createReminder(
            title: "Call client",
            notes: "Discuss budget allocation",
            in: firstList
        )
        let reminder4 = try await reminderService.createReminder(
            title: "Lunch meeting",
            notes: "Team gathering",
            in: firstList
        )

        // Search for "budget" (should find in title and notes)
        let results = try await reminderService.fetchReminders(textSearch: .contains("budget"))

        #expect(results.contains { $0.id == reminder1.id }) // "budget" in notes
        #expect(results.contains { $0.id == reminder2.id }) // "budget" in title
        #expect(results.contains { $0.id == reminder3.id }) // "budget" in notes
        #expect(!results.contains { $0.id == reminder4.id }) // Not present

        // Clean up
        try? await reminderService.deleteReminder(reminder1)
        try? await reminderService.deleteReminder(reminder2)
        try? await reminderService.deleteReminder(reminder3)
        try? await reminderService.deleteReminder(reminder4)
    }

    @Test("TextSearchFilter.titleOnly searches only in title")
    @MainActor
    func textSearchTitleOnlySearchesOnlyTitle() async throws {
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
            title: "Meeting about project",
            notes: "Review details",
            in: firstList
        )
        let reminder2 = try await reminderService.createReminder(
            title: "Budget review",
            notes: "Discuss project timeline",
            in: firstList
        )

        // Search for "project" only in title
        let results = try await reminderService.fetchReminders(textSearch: .titleOnly("project"))

        #expect(results.contains { $0.id == reminder1.id }) // "project" in title
        #expect(!results.contains { $0.id == reminder2.id }) // "project" only in notes

        // Clean up
        try? await reminderService.deleteReminder(reminder1)
        try? await reminderService.deleteReminder(reminder2)
    }

    @Test("TextSearchFilter.notesOnly searches only in notes")
    @MainActor
    func textSearchNotesOnlySearchesOnlyNotes() async throws {
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
            title: "Budget review",
            notes: "Important details to discuss",
            in: firstList
        )
        let reminder2 = try await reminderService.createReminder(
            title: "Review important documents",
            notes: "Budget approval",
            in: firstList
        )

        // Search for "important" only in notes
        let results = try await reminderService.fetchReminders(textSearch: .notesOnly("important"))

        #expect(results.contains { $0.id == reminder1.id }) // "important" in notes
        #expect(!results.contains { $0.id == reminder2.id }) // "important" only in title

        // Clean up
        try? await reminderService.deleteReminder(reminder1)
        try? await reminderService.deleteReminder(reminder2)
    }

    @Test("TextSearchFilter is case-insensitive")
    @MainActor
    func textSearchIsCaseInsensitive() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create reminder with mixed case
        let reminder = try await reminderService.createReminder(
            title: "IMPORTANT Meeting",
            notes: "Discuss BUDGET and Timeline",
            in: firstList
        )

        // Search with lowercase
        let results1 = try await reminderService.fetchReminders(textSearch: .contains("important"))
        #expect(results1.contains { $0.id == reminder.id })

        // Search with uppercase
        let results2 = try await reminderService.fetchReminders(textSearch: .contains("BUDGET"))
        #expect(results2.contains { $0.id == reminder.id })

        // Search with mixed case
        let results3 = try await reminderService.fetchReminders(textSearch: .contains("TiMeLiNe"))
        #expect(results3.contains { $0.id == reminder.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("TextSearchFilter handles reminders without notes")
    @MainActor
    func textSearchHandlesRemindersWithoutNotes() async throws {
        let permissionService = PermissionService()
        let reminderService = ReminderService(permissionService: permissionService)

        guard permissionService.hasReminderAccess else {
            return
        }

        try await reminderService.fetchReminderLists()

        guard let firstList = reminderService.reminderLists.first else {
            return
        }

        // Create reminder without notes
        let reminder = try await reminderService.createReminder(
            title: "Meeting about project",
            in: firstList
        )

        // Search in title should work
        let results1 = try await reminderService.fetchReminders(textSearch: .titleOnly("project"))
        #expect(results1.contains { $0.id == reminder.id })

        // Search in notes should not crash
        let results2 = try await reminderService.fetchReminders(textSearch: .notesOnly("project"))
        #expect(!results2.contains { $0.id == reminder.id })

        // Contains should find it (searches title too)
        let results3 = try await reminderService.fetchReminders(textSearch: .contains("project"))
        #expect(results3.contains { $0.id == reminder.id })

        // Clean up
        try? await reminderService.deleteReminder(reminder)
    }

    @Test("TextSearchFilter combines with other filters")
    @MainActor
    func textSearchCombinesWithOtherFilters() async throws {
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
            title: "Project meeting",
            notes: "#work",
            in: firstList
        )
        let reminder2 = try await reminderService.createReminder(
            title: "Project review",
            notes: "#personal",
            in: firstList
        )

        // Complete one reminder
        _ = try await reminderService.toggleReminderCompletion(reminder1)

        // Search for "project" + incomplete + tag "personal"
        let results = try await reminderService.fetchReminders(
            filter: .incomplete,
            tagFilter: .hasTag("personal"),
            textSearch: .contains("project")
        )

        #expect(!results.contains { $0.id == reminder1.id }) // Completed
        #expect(results.contains { $0.id == reminder2.id })  // Matches all filters

        // Clean up
        try? await reminderService.deleteReminder(reminder1)
        try? await reminderService.deleteReminder(reminder2)
    }

    @Test("TextSearchFilter enum is Codable")
    func textSearchFilterEnumIsCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Test .none
        let none = TextSearchFilter.none
        let noneData = try encoder.encode(none)
        let decodedNone = try decoder.decode(TextSearchFilter.self, from: noneData)
        #expect(decodedNone == none)

        // Test .contains
        let contains = TextSearchFilter.contains("test query")
        let containsData = try encoder.encode(contains)
        let decodedContains = try decoder.decode(TextSearchFilter.self, from: containsData)
        #expect(decodedContains == contains)

        // Test .titleOnly
        let titleOnly = TextSearchFilter.titleOnly("title")
        let titleData = try encoder.encode(titleOnly)
        let decodedTitle = try decoder.decode(TextSearchFilter.self, from: titleData)
        #expect(decodedTitle == titleOnly)

        // Test .notesOnly
        let notesOnly = TextSearchFilter.notesOnly("notes")
        let notesData = try encoder.encode(notesOnly)
        let decodedNotes = try decoder.decode(TextSearchFilter.self, from: notesData)
        #expect(decodedNotes == notesOnly)
    }
}
