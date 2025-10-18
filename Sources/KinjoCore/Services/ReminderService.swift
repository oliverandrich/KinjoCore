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
import Observation

/// Service responsible for managing reminders and reminder lists.
///
/// This service provides access to reminder lists stored in EventKit and automatically
/// updates when the underlying EventKit store changes.
@Observable
@MainActor
public final class ReminderService {

    // MARK: - Properties

    /// The permission service used to access the EventKit store.
    private let permissionService: PermissionService

    /// The currently loaded reminder lists.
    public private(set) var reminderLists: [ReminderList] = []

    /// The currently loaded reminders.
    public private(set) var reminders: [Reminder] = []

    /// Observation token for EventKit store changes.
    @ObservationIgnored
    nonisolated(unsafe) private var storeChangedObserver: NSObjectProtocol?

    // MARK: - Initialisation

    /// Creates a new reminder service.
    ///
    /// - Parameter permissionService: The permission service to use for EventKit access.
    public init(permissionService: PermissionService) {
        self.permissionService = permissionService
        self.setupStoreChangeObserver()
    }

    deinit {
        if let observer = storeChangedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Methods

    /// Fetches all reminder lists from EventKit.
    ///
    /// This method requires that the app has permission to access reminders.
    /// Call `permissionService.requestReminderAccess()` first if needed.
    ///
    /// - Returns: An array of reminder lists.
    /// - Throws: An error if fetching fails or if permissions are not granted.
    @discardableResult
    public func fetchReminderLists() async throws -> [ReminderList] {
        guard permissionService.hasReminderAccess else {
            throw ReminderServiceError.permissionDenied
        }

        let calendars = permissionService.eventStore.calendars(for: .reminder)
        let lists = calendars.map { ReminderList(from: $0) }

        self.reminderLists = lists

        return lists
    }

    /// Fetches reminders from EventKit with optional filtering and sorting.
    ///
    /// This method requires that the app has permission to access reminders.
    /// Call `permissionService.requestReminderAccess()` first if needed.
    ///
    /// - Parameters:
    ///   - from: Which reminder lists to fetch from. Defaults to `.all`.
    ///   - filter: The filter to apply (all, completed, or incomplete). Defaults to `.all`.
    ///   - dateRange: The date range filter to apply. Defaults to `.all`.
    ///   - tagFilter: The tag filter to apply. Defaults to `.none`.
    ///   - sortBy: The sort option to apply. Defaults to `.title`.
    /// - Returns: An array of filtered and sorted reminders.
    /// - Throws: An error if fetching fails, if permissions are not granted, or if a specified list is not found.
    @discardableResult
    public func fetchReminders(
        from: ReminderListSelection = .all,
        filter: ReminderFilter = .all,
        dateRange: DateRangeFilter = .all,
        tagFilter: TagFilter = .none,
        sortBy: ReminderSortOption = .title
    ) async throws -> [Reminder] {
        guard permissionService.hasReminderAccess else {
            throw ReminderServiceError.permissionDenied
        }

        // Create predicate for the specified list(s)
        let calendars: [EKCalendar]

        switch from {
        case .all:
            // Fetch from all reminder lists
            calendars = permissionService.eventStore.calendars(for: .reminder)

        case .specific(let lists):
            // Empty array is treated as .all
            if lists.isEmpty {
                calendars = permissionService.eventStore.calendars(for: .reminder)
            } else {
                // Fetch reminders from specific lists
                var selectedCalendars: [EKCalendar] = []
                for list in lists {
                    guard let calendar = permissionService.eventStore.calendar(withIdentifier: list.id) else {
                        throw ReminderServiceError.listNotFound
                    }
                    selectedCalendars.append(calendar)
                }
                calendars = selectedCalendars
            }
        }

        let eventStore = permissionService.eventStore
        let predicate = eventStore.predicateForReminders(in: calendars)

        // Fetch reminders using continuation to bridge callback-based API to async/await
        // Convert to our model immediately to avoid Sendable issues with EKReminder
        var reminders: [Reminder] = await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { ekReminders in
                let reminders = (ekReminders ?? []).map { Reminder(from: $0) }
                continuation.resume(returning: reminders)
            }
        }

        // Apply completion status filter
        reminders = self.applyFilter(filter, to: reminders)

        // Apply date range filter
        reminders = self.applyDateFilter(dateRange, to: reminders)

        // Apply tag filter
        reminders = self.applyTagFilter(tagFilter, to: reminders)

        // Apply sorting
        reminders = self.applySort(sortBy, to: reminders)

        // Update cache
        self.reminders = reminders

        return reminders
    }

    /// Creates a new reminder in the specified reminder list.
    ///
    /// This method requires that the app has permission to access reminders.
    ///
    /// - Parameters:
    ///   - title: The title of the reminder. Must not be empty.
    ///   - notes: Optional notes to attach to the reminder.
    ///   - dueDate: Optional due date for the reminder.
    ///   - priority: The priority level. Defaults to `.none`.
    ///   - list: The reminder list to add the reminder to.
    /// - Returns: The newly created reminder.
    /// - Throws: An error if creation fails, if permissions are not granted, if the title is empty, or if the list is not found.
    @discardableResult
    public func createReminder(
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        priority: Priority = .none,
        in list: ReminderList
    ) async throws -> Reminder {
        guard permissionService.hasReminderAccess else {
            throw ReminderServiceError.permissionDenied
        }

        // Validate title
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReminderServiceError.invalidTitle
        }

        // Find the calendar for the specified list
        guard let calendar = permissionService.eventStore.calendar(withIdentifier: list.id) else {
            throw ReminderServiceError.listNotFound
        }

        // Create the EKReminder
        let ekReminder = EKReminder(eventStore: permissionService.eventStore)
        ekReminder.calendar = calendar
        ekReminder.title = title
        ekReminder.notes = notes
        ekReminder.priority = priority.eventKitValue

        // Set due date if provided
        if let dueDate = dueDate {
            let calendar = FoundationCalendar.current
            ekReminder.dueDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        }

        // Save to EventKit
        do {
            try permissionService.eventStore.save(ekReminder, commit: true)
        } catch {
            throw ReminderServiceError.saveFailed
        }

        // Convert to our model and return
        return Reminder(from: ekReminder)
    }

    /// Updates an existing reminder.
    ///
    /// This method requires that the app has permission to access reminders.
    /// Only the provided (non-nil) parameters will be updated; others remain unchanged.
    ///
    /// - Parameters:
    ///   - reminderId: The unique identifier of the reminder to update.
    ///   - title: Optional new title for the reminder.
    ///   - notes: Optional new notes for the reminder. Pass empty string to clear notes.
    ///   - dueDate: Optional new due date for the reminder. Pass nil to clear the due date.
    ///   - priority: Optional new priority level.
    ///   - list: Optional new reminder list to move the reminder to.
    /// - Returns: The updated reminder.
    /// - Throws: An error if updating fails, if permissions are not granted, if the reminder is not found, or if the new list is not found.
    @discardableResult
    public func updateReminder(
        _ reminderId: String,
        title: String? = nil,
        notes: String? = nil,
        dueDate: Date? = nil,
        priority: Priority? = nil,
        moveTo list: ReminderList? = nil
    ) async throws -> Reminder {
        guard permissionService.hasReminderAccess else {
            throw ReminderServiceError.permissionDenied
        }

        // Find the existing reminder
        guard let ekReminder = permissionService.eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            throw ReminderServiceError.reminderNotFound
        }

        // Update title if provided
        if let title = title {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ReminderServiceError.invalidTitle
            }
            ekReminder.title = title
        }

        // Update notes if provided
        if let notes = notes {
            ekReminder.notes = notes.isEmpty ? nil : notes
        }

        // Update due date if provided
        if let dueDate = dueDate {
            let calendar = FoundationCalendar.current
            ekReminder.dueDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        }

        // Update priority if provided
        if let priority = priority {
            ekReminder.priority = priority.eventKitValue
        }

        // Move to new list if provided
        if let list = list {
            guard let calendar = permissionService.eventStore.calendar(withIdentifier: list.id) else {
                throw ReminderServiceError.listNotFound
            }
            ekReminder.calendar = calendar
        }

        // Save changes to EventKit
        do {
            try permissionService.eventStore.save(ekReminder, commit: true)
        } catch {
            throw ReminderServiceError.saveFailed
        }

        // Convert to our model and return
        return Reminder(from: ekReminder)
    }

    /// Deletes a reminder by its identifier.
    ///
    /// This method requires that the app has permission to access reminders.
    ///
    /// - Parameter reminderId: The unique identifier of the reminder to delete.
    /// - Throws: An error if deletion fails, if permissions are not granted, or if the reminder is not found.
    public func deleteReminder(_ reminderId: String) async throws {
        guard permissionService.hasReminderAccess else {
            throw ReminderServiceError.permissionDenied
        }

        // Find the reminder
        guard let ekReminder = permissionService.eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            throw ReminderServiceError.reminderNotFound
        }

        // Delete from EventKit
        do {
            try permissionService.eventStore.remove(ekReminder, commit: true)
        } catch {
            throw ReminderServiceError.deleteFailed
        }
    }

    /// Deletes a reminder by its model object.
    ///
    /// This method requires that the app has permission to access reminders.
    ///
    /// - Parameter reminder: The reminder to delete.
    /// - Throws: An error if deletion fails, if permissions are not granted, or if the reminder is not found.
    public func deleteReminder(_ reminder: Reminder) async throws {
        try await deleteReminder(reminder.id)
    }

    /// Toggles the completion status of a reminder by its identifier.
    ///
    /// This method requires that the app has permission to access reminders.
    ///
    /// - Parameter reminderId: The unique identifier of the reminder to toggle.
    /// - Returns: The updated reminder with toggled completion status.
    /// - Throws: An error if updating fails, if permissions are not granted, or if the reminder is not found.
    @discardableResult
    public func toggleReminderCompletion(_ reminderId: String) async throws -> Reminder {
        guard permissionService.hasReminderAccess else {
            throw ReminderServiceError.permissionDenied
        }

        // Find the reminder
        guard let ekReminder = permissionService.eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            throw ReminderServiceError.reminderNotFound
        }

        // Toggle completion status
        ekReminder.isCompleted = !ekReminder.isCompleted

        // Save changes to EventKit
        do {
            try permissionService.eventStore.save(ekReminder, commit: true)
        } catch {
            throw ReminderServiceError.saveFailed
        }

        // Convert to our model and return
        return Reminder(from: ekReminder)
    }

    /// Toggles the completion status of a reminder by its model object.
    ///
    /// This method requires that the app has permission to access reminders.
    ///
    /// - Parameter reminder: The reminder to toggle.
    /// - Returns: The updated reminder with toggled completion status.
    /// - Throws: An error if updating fails, if permissions are not granted, or if the reminder is not found.
    @discardableResult
    public func toggleReminderCompletion(_ reminder: Reminder) async throws -> Reminder {
        try await toggleReminderCompletion(reminder.id)
    }

    // MARK: - Private Methods

    /// Applies the specified filter to an array of reminders.
    private func applyFilter(_ filter: ReminderFilter, to reminders: [Reminder]) -> [Reminder] {
        switch filter {
        case .all:
            return reminders
        case .completed:
            return reminders.filter { $0.isCompleted }
        case .incomplete:
            return reminders.filter { !$0.isCompleted }
        }
    }

    /// Applies the specified date range filter to an array of reminders.
    ///
    /// Reminders without a due date are excluded when a date range filter is active (except for `.all`).
    private func applyDateFilter(_ dateFilter: DateRangeFilter, to reminders: [Reminder]) -> [Reminder] {
        guard let range = dateFilter.dateRange() else {
            // .all case - no filtering
            return reminders
        }

        return reminders.filter { reminder in
            // Exclude reminders without a due date
            guard let dueDate = reminder.dueDate else {
                return false
            }

            // Check if due date falls within the range
            return dueDate >= range.start && dueDate < range.end
        }
    }

    /// Applies the specified tag filter to an array of reminders.
    ///
    /// Tags are extracted from the reminder's notes field and compared case-insensitively.
    private func applyTagFilter(_ tagFilter: TagFilter, to reminders: [Reminder]) -> [Reminder] {
        switch tagFilter {
        case .none:
            return reminders

        case .hasTag(let tag):
            let lowercaseTag = tag.lowercased()
            return reminders.filter { $0.tags.contains(lowercaseTag) }

        case .hasAnyTag(let tags):
            let lowercaseTags = Set(tags.map { $0.lowercased() })
            return reminders.filter { reminder in
                !Set(reminder.tags).isDisjoint(with: lowercaseTags)
            }

        case .hasAllTags(let tags):
            let lowercaseTags = Set(tags.map { $0.lowercased() })
            return reminders.filter { reminder in
                lowercaseTags.isSubset(of: Set(reminder.tags))
            }

        case .excludingTags(let tags):
            let lowercaseTags = Set(tags.map { $0.lowercased() })
            return reminders.filter { reminder in
                Set(reminder.tags).isDisjoint(with: lowercaseTags)
            }
        }
    }

    /// Applies the specified sort option to an array of reminders.
    private func applySort(_ sortOption: ReminderSortOption, to reminders: [Reminder]) -> [Reminder] {
        switch sortOption {
        case .title:
            return reminders.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        case .dueDate(let ascending):
            return reminders.sorted { lhs, rhs in
                // Reminders without a due date go to the end
                switch (lhs.dueDate, rhs.dueDate) {
                case (nil, nil):
                    return false
                case (nil, _):
                    return false
                case (_, nil):
                    return true
                case (let lhsDate?, let rhsDate?):
                    return ascending ? lhsDate < rhsDate : lhsDate > rhsDate
                }
            }

        case .priority:
            // Priority enum is Comparable: high < medium < low < none
            return reminders.sorted { $0.priority < $1.priority }

        case .creationDate(let ascending):
            return reminders.sorted { lhs, rhs in
                // Reminders without a creation date go to the end
                switch (lhs.creationDate, rhs.creationDate) {
                case (nil, nil):
                    return false
                case (nil, _):
                    return false
                case (_, nil):
                    return true
                case (let lhsDate?, let rhsDate?):
                    return ascending ? lhsDate < rhsDate : lhsDate > rhsDate
                }
            }
        }
    }

    /// Sets up an observer to automatically refresh reminder lists when EventKit changes.
    private func setupStoreChangeObserver() {
        storeChangedObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: permissionService.eventStore,
            queue: .main
        ) { [weak self] _ in
            Task {
                try? await self?.fetchReminderLists()
            }
        }
    }
}

// MARK: - Errors

/// Errors that can occur when using the reminder service.
public enum ReminderServiceError: Error, LocalizedError {

    /// Permission to access reminders has been denied.
    case permissionDenied

    /// The specified reminder list was not found.
    case listNotFound

    /// The specified reminder was not found.
    case reminderNotFound

    /// The reminder could not be saved.
    case saveFailed

    /// The reminder could not be deleted.
    case deleteFailed

    /// The reminder title is invalid (empty or missing).
    case invalidTitle

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission to access reminders has been denied. Please grant access in Settings."
        case .listNotFound:
            return "The specified reminder list could not be found."
        case .reminderNotFound:
            return "The specified reminder could not be found."
        case .saveFailed:
            return "Failed to save the reminder to EventKit."
        case .deleteFailed:
            return "Failed to delete the reminder from EventKit."
        case .invalidTitle:
            return "The reminder title cannot be empty."
        }
    }
}
