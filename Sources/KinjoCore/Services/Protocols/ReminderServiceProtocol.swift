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

import EventKit
import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Protocol for managing reminders and reminder lists.
///
/// This protocol defines the interface for CRUD operations on reminders and
/// reminder lists, as well as filtering and sorting capabilities.
@MainActor
public protocol ReminderServiceProtocol {

    // MARK: - Properties

    /// The currently loaded reminder lists.
    var reminderLists: [ReminderList] { get }

    /// The currently loaded reminders.
    var reminders: [Reminder] { get }

    // MARK: - Reminder List Operations

    /// Fetches all reminder lists from EventKit.
    @discardableResult
    func fetchReminderLists() async throws -> [ReminderList]

    /// Creates a new reminder list in EventKit.
    @discardableResult
    func createReminderList(
        title: String,
        color: CGColor?,
        sourceType: EKSourceType?
    ) async throws -> ReminderList

    /// Updates an existing reminder list.
    @discardableResult
    func updateReminderList(
        _ listId: String,
        title: String?,
        color: CGColor?
    ) async throws -> ReminderList

    /// Updates an existing reminder list by its model object.
    @discardableResult
    func updateReminderList(
        _ list: ReminderList,
        title: String?,
        color: CGColor?
    ) async throws -> ReminderList

    /// Deletes a reminder list by its identifier.
    func deleteReminderList(_ listId: String) async throws

    /// Deletes a reminder list by its model object.
    func deleteReminderList(_ list: ReminderList) async throws

    // MARK: - Reminder Operations

    /// Fetches reminders from EventKit with optional filtering and sorting.
    @discardableResult
    func fetchReminders(
        from: ReminderListSelection,
        filter: ReminderFilter,
        dateRange: DateRangeFilter,
        tagFilter: TagFilter,
        textSearch: TextSearchFilter,
        sortBy: ReminderSortOption
    ) async throws -> [Reminder]

    /// Creates a new reminder.
    func createReminder(
        title: String,
        notes: String?,
        startDate: Date?,
        dueDate: Date?,
        priority: Priority,
        recurrenceRules: [RecurrenceRule]?,
        alarms: [Alarm]?,
        location: String?,
        in list: ReminderList
    ) async throws -> Reminder

    /// Updates an existing reminder.
    @discardableResult
    func updateReminder(
        _ reminderId: String,
        title: String?,
        notes: String?,
        startDate: Date?,
        dueDate: Date?,
        priority: Priority?,
        recurrenceRules: [RecurrenceRule]?,
        alarms: [Alarm]?,
        location: String?,
        moveTo list: ReminderList?
    ) async throws -> Reminder

    /// Deletes a reminder by its identifier.
    func deleteReminder(_ reminderId: String) async throws

    /// Deletes a reminder by its model object.
    func deleteReminder(_ reminder: Reminder) async throws

    /// Toggles the completion status of a reminder by its identifier.
    func toggleReminderCompletion(_ reminderId: String) async throws -> Reminder

    /// Toggles the completion status of a reminder by its model object.
    func toggleReminderCompletion(_ reminder: Reminder) async throws -> Reminder

    // MARK: - Filter & Sort Operations

    /// Applies a completion filter to a collection of reminders.
    func applyFilter(_ filter: ReminderFilter, to reminders: [Reminder]) -> [Reminder]

    /// Applies a date range filter to a collection of reminders.
    func applyDateFilter(_ dateFilter: DateRangeFilter, to reminders: [Reminder]) -> [Reminder]

    /// Applies a tag filter to a collection of reminders.
    func applyTagFilter(_ tagFilter: TagFilter, to reminders: [Reminder]) -> [Reminder]

    /// Applies a text search filter to a collection of reminders.
    func applyTextFilter(_ textFilter: TextSearchFilter, to reminders: [Reminder]) -> [Reminder]

    /// Applies a sort option to a collection of reminders.
    func applySort(_ sortOption: ReminderSortOption, to reminders: [Reminder]) -> [Reminder]
}
