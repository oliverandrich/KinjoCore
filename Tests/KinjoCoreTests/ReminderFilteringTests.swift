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
import MockingKit
@testable import KinjoCore

@Suite("ReminderService Filtering Tests")
@MainActor
struct ReminderFilteringTests {

    // MARK: - Helper function to create mock permission service

    func createMockPermissionService() -> MockPermissionService {
        let mock = MockPermissionService()
        // No permissions needed for filter tests - they work with in-memory data
        // Permissions are set to false to prevent eventStore access
        return mock
    }

    // MARK: - Helper function to create test reminders

    func createTestReminders() -> [Reminder] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return [
            // Completed reminder
            Reminder.makeTest(
                title: "Completed Task",
                isCompleted: true,
                completionDate: Date()
            ),

            // Incomplete reminder with high priority
            Reminder.makeTest(
                title: "High Priority Task",
                priority: .high,
                isCompleted: false
            ),

            // Incomplete reminder with tags
            Reminder.makeTest(
                title: "Tagged Task",
                notes: "Meeting #work #urgent",
                isCompleted: false
            ),

            // Reminder with due date today
            Reminder.makeTest(
                title: "Due Today",
                dueDate: today,
                isCompleted: false
            ),

            // Reminder with due date tomorrow
            Reminder.makeTest(
                title: "Due Tomorrow",
                dueDate: tomorrow,
                isCompleted: false
            )
        ]
    }

    // MARK: - Completion Filter Tests

    @Test("ReminderService applyFilter filters by completion status - all")
    func applyFilterShowsAllReminders() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyFilter(ReminderFilter.all, to: testReminders)

        #expect(filtered.count == testReminders.count)
    }

    @Test("ReminderService applyFilter filters by completion status - completed only")
    func applyFilterShowsCompletedOnly() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyFilter(ReminderFilter.completed, to: testReminders)

        #expect(filtered.allSatisfy { $0.isCompleted })
        #expect(filtered.count == 1) // We have exactly 1 completed reminder
    }

    @Test("ReminderService applyFilter filters by completion status - incomplete only")
    func applyFilterShowsIncompleteOnly() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyFilter(ReminderFilter.incomplete, to: testReminders)

        #expect(filtered.allSatisfy { !$0.isCompleted })
        #expect(filtered.count == 4) // We have exactly 4 incomplete reminders
    }

    // MARK: - Date Filter Tests

    @Test("ReminderService applyDateFilter returns all when filter is .all")
    func applyDateFilterAllReturnsAll() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyDateFilter(DateRangeFilter.all, to: testReminders)

        #expect(filtered.count == testReminders.count)
    }

    @Test("ReminderService applyDateFilter filters by today")
    func applyDateFilterToday() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyDateFilter(DateRangeFilter.today, to: testReminders)

        // Should include at least the "Due Today" reminder
        #expect(filtered.contains(where: { $0.title == "Due Today" }))
        // Should not include "Due Tomorrow" reminder
        #expect(!filtered.contains(where: { $0.title == "Due Tomorrow" }))
    }

    @Test("ReminderService applyDateFilter filters by tomorrow")
    func applyDateFilterTomorrow() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyDateFilter(DateRangeFilter.tomorrow, to: testReminders)

        // Should include the "Due Tomorrow" reminder
        #expect(filtered.contains(where: { $0.title == "Due Tomorrow" }))
        // Should not include "Due Today" reminder
        #expect(!filtered.contains(where: { $0.title == "Due Today" }))
    }

    // MARK: - Tag Filter Tests

    @Test("ReminderService applyTagFilter .none returns all reminders")
    func applyTagFilterNoneReturnsAll() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyTagFilter(TagFilter.none, to: testReminders)

        #expect(filtered.count == testReminders.count)
    }

    @Test("ReminderService applyTagFilter .hasTag filters by single tag")
    func applyTagFilterHasTag() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyTagFilter(TagFilter.hasTag("work"), to: testReminders)

        // Should only include reminders with #work tag
        #expect(filtered.allSatisfy { $0.tags.contains("work") })
        #expect(filtered.contains(where: { $0.title == "Tagged Task" }))
    }

    @Test("ReminderService applyTagFilter .hasAnyTag filters with OR logic")
    func applyTagFilterHasAnyTag() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyTagFilter(TagFilter.hasAnyTag(["work", "personal"]), to: testReminders)

        // Should include reminders with either #work or #personal
        #expect(filtered.allSatisfy { reminder in
            reminder.tags.contains("work") || reminder.tags.contains("personal")
        })
    }

    @Test("ReminderService applyTagFilter .hasAllTags filters with AND logic")
    func applyTagFilterHasAllTags() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyTagFilter(TagFilter.hasAllTags(["work", "urgent"]), to: testReminders)

        // Should only include reminders with both #work AND #urgent
        #expect(filtered.allSatisfy { reminder in
            reminder.tags.contains("work") && reminder.tags.contains("urgent")
        })
        #expect(filtered.contains(where: { $0.title == "Tagged Task" }))
    }

    // MARK: - Text Search Filter Tests

    @Test("ReminderService applyTextFilter searches in title")
    func applyTextFilterSearchesTitle() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyTextFilter(TextSearchFilter.contains("High"), to: testReminders)

        #expect(filtered.contains(where: { $0.title == "High Priority Task" }))
    }

    @Test("ReminderService applyTextFilter searches in notes")
    func applyTextFilterSearchesNotes() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyTextFilter(TextSearchFilter.contains("Meeting"), to: testReminders)

        #expect(filtered.contains(where: { $0.title == "Tagged Task" }))
    }

    @Test("ReminderService applyTextFilter is case insensitive")
    func applyTextFilterCaseInsensitive() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let filtered = reminderService.applyTextFilter(TextSearchFilter.contains("high"), to: testReminders)

        #expect(filtered.contains(where: { $0.title == "High Priority Task" }))
    }

    // MARK: - Sort Tests

    @Test("ReminderService applySort sorts by title")
    func applySortByTitle() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let sorted = reminderService.applySort(ReminderSortOption.title, to: testReminders)

        // Verify alphabetical order
        for i in 0..<sorted.count-1 {
            #expect(sorted[i].title <= sorted[i+1].title)
        }
    }

    @Test("ReminderService applySort sorts by priority")
    func applySortByPriority() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let sorted = reminderService.applySort(ReminderSortOption.priority, to: testReminders)

        // High priority should come first
        #expect(sorted.first?.title == "High Priority Task")
    }

    @Test("ReminderService applySort sorts by due date ascending")
    func applySortByDueDateAscending() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let sorted = reminderService.applySort(ReminderSortOption.dueDate(ascending: true), to: testReminders)

        // Verify ascending order (earlier dates first)
        var lastDueDate: Date? = nil
        for reminder in sorted where reminder.dueDate != nil {
            if let prevDate = lastDueDate, let currentDate = reminder.dueDate {
                #expect(prevDate <= currentDate)
            }
            lastDueDate = reminder.dueDate
        }
    }

    @Test("ReminderService applySort sorts by due date descending")
    func applySortByDueDateDescending() async throws {
        let mockPermissionService = createMockPermissionService()
        let reminderService = ReminderService(permissionService: mockPermissionService)

        let testReminders = createTestReminders()
        let sorted = reminderService.applySort(ReminderSortOption.dueDate(ascending: false), to: testReminders)

        // Verify descending order (later dates first)
        var lastDueDate: Date? = Date.distantFuture
        for reminder in sorted where reminder.dueDate != nil {
            if let prevDate = lastDueDate, let currentDate = reminder.dueDate {
                #expect(prevDate >= currentDate)
            }
            lastDueDate = reminder.dueDate
        }
    }
}
