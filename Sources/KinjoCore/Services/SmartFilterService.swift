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

import Foundation
import Observation
import SwiftData

/// Service responsible for managing smart filters.
///
/// This service provides access to smart filters stored in SwiftData and automatically
/// synchronises them via iCloud when configured with an app group.
@Observable
@MainActor
public final class SmartFilterService {

    // MARK: - Properties

    /// The SwiftData model container.
    private let container: ModelContainer

    /// The currently loaded smart filters.
    public private(set) var filters: [SmartFilter] = []

    // MARK: - Initialisation

    /// Creates a new smart filter service.
    ///
    /// The provided ModelContainer should include `SmartFilter` in its schema.
    /// This allows the app to use a single ModelContainer for both KinjoCore models
    /// and its own SwiftData models.
    ///
    /// - Parameter container: The SwiftData ModelContainer to use for persistence.
    ///   The container's schema must include `SmartFilter.self`.
    public init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - Public Methods

    /// Fetches all smart filters from SwiftData.
    ///
    /// Filters are automatically sorted by their `sortOrder` property.
    ///
    /// - Returns: An array of smart filters sorted by sort order.
    /// - Throws: An error if fetching fails.
    @discardableResult
    public func fetchFilters() async throws -> [SmartFilter] {
        let context = container.mainContext
        let descriptor = FetchDescriptor<SmartFilter>(sortBy: [SortDescriptor(\.sortOrder)])

        let fetchedFilters = try context.fetch(descriptor)
        self.filters = fetchedFilters

        return fetchedFilters
    }

    /// Creates a new smart filter and saves it to SwiftData.
    ///
    /// - Parameters:
    ///   - name: The display name of the filter.
    ///   - iconName: The SF Symbol name for the icon.
    ///   - tintColor: Optional hex colour string for the icon tint.
    ///   - criteria: The filter criteria defining which reminders to show.
    /// - Returns: The newly created smart filter.
    /// - Throws: An error if creation fails or if the name is empty.
    @discardableResult
    public func createFilter(
        name: String,
        iconName: String,
        tintColor: String? = nil,
        criteria: FilterCriteria
    ) async throws -> SmartFilter {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SmartFilterServiceError.invalidName
        }

        // Calculate sort order (append to end)
        let maxSortOrder = filters.map { $0.sortOrder }.max() ?? -1
        let newSortOrder = maxSortOrder + 1

        let filter = SmartFilter(
            name: name,
            iconName: iconName,
            tintColor: tintColor,
            sortOrder: newSortOrder,
            isBuiltIn: false,
            criteria: criteria
        )

        let context = container.mainContext
        context.insert(filter)

        do {
            try context.save()
        } catch {
            throw SmartFilterServiceError.saveFailed
        }

        // Refresh the list
        try await fetchFilters()

        return filter
    }

    /// Updates an existing smart filter.
    ///
    /// Only the provided (non-nil) parameters will be updated; others remain unchanged.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the filter to update.
    ///   - name: Optional new name for the filter.
    ///   - iconName: Optional new icon name.
    ///   - tintColor: Optional new tint colour. Pass empty string to clear.
    ///   - criteria: Optional new filter criteria.
    /// - Returns: The updated smart filter.
    /// - Throws: An error if updating fails, if the filter is not found, if the name is empty,
    ///   or if attempting to modify a built-in filter.
    @discardableResult
    public func updateFilter(
        _ id: UUID,
        name: String? = nil,
        iconName: String? = nil,
        tintColor: String? = nil,
        criteria: FilterCriteria? = nil
    ) async throws -> SmartFilter {
        let context = container.mainContext
        let descriptor = FetchDescriptor<SmartFilter>(predicate: #Predicate { $0.id == id })

        guard let filter = try context.fetch(descriptor).first else {
            throw SmartFilterServiceError.filterNotFound
        }

        // Cannot modify built-in filters
        guard !filter.isBuiltIn else {
            throw SmartFilterServiceError.builtInFilterImmutable
        }

        // Update properties if provided
        if let name = name {
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw SmartFilterServiceError.invalidName
            }
            filter.name = name
        }

        if let iconName = iconName {
            filter.iconName = iconName
        }

        if let tintColor = tintColor {
            filter.tintColor = tintColor.isEmpty ? nil : tintColor
        }

        if let criteria = criteria {
            filter.criteriaData = (try? JSONEncoder().encode(criteria)) ?? Data()
        }

        filter.modifiedAt = Date()

        do {
            try context.save()
        } catch {
            throw SmartFilterServiceError.saveFailed
        }

        // Refresh the list
        try await fetchFilters()

        return filter
    }

    /// Deletes a smart filter by its identifier.
    ///
    /// Built-in filters cannot be deleted.
    ///
    /// - Parameter id: The unique identifier of the filter to delete.
    /// - Throws: An error if deletion fails, if the filter is not found,
    ///   or if attempting to delete a built-in filter.
    public func deleteFilter(_ id: UUID) async throws {
        let context = container.mainContext
        let descriptor = FetchDescriptor<SmartFilter>(predicate: #Predicate { $0.id == id })

        guard let filter = try context.fetch(descriptor).first else {
            throw SmartFilterServiceError.filterNotFound
        }

        // Cannot delete built-in filters
        guard !filter.isBuiltIn else {
            throw SmartFilterServiceError.builtInFilterImmutable
        }

        context.delete(filter)

        do {
            try context.save()
        } catch {
            throw SmartFilterServiceError.deleteFailed
        }

        // Refresh the list
        try await fetchFilters()
    }

    /// Reorders the smart filters.
    ///
    /// Updates the `sortOrder` property of each filter based on its position
    /// in the provided array.
    ///
    /// - Parameter orderedFilters: The filters in their desired display order.
    /// - Throws: An error if saving fails.
    public func reorderFilters(_ orderedFilters: [SmartFilter]) async throws {
        let context = container.mainContext

        for (index, filter) in orderedFilters.enumerated() {
            filter.sortOrder = index
        }

        do {
            try context.save()
        } catch {
            throw SmartFilterServiceError.saveFailed
        }

        // Refresh the list
        try await fetchFilters()
    }

    /// Ensures that built-in filters exist in the database.
    ///
    /// This method should be called on app launch to ensure the built-in
    /// filters are available. It only creates filters that don't already exist.
    ///
    /// - Throws: An error if saving fails.
    public func ensureBuiltInFilters() async throws {
        let context = container.mainContext

        // Fetch existing built-in filter names
        let descriptor = FetchDescriptor<SmartFilter>(predicate: #Predicate { $0.isBuiltIn })
        let existingFilters = try context.fetch(descriptor)
        let existingNames = Set(existingFilters.map { $0.name })

        // Create missing built-in filters
        let builtInFilters = SmartFilter.builtInFilters()
        for filter in builtInFilters {
            if !existingNames.contains(filter.name) {
                context.insert(filter)
            }
        }

        do {
            try context.save()
        } catch {
            throw SmartFilterServiceError.saveFailed
        }

        // Refresh the list
        try await fetchFilters()
    }

    // MARK: - Convenience Methods

    /// Applies a smart filter to a reminder service and returns the filtered reminders.
    ///
    /// This convenience method converts the filter criteria to the appropriate
    /// parameters and calls `reminderService.fetchReminders()`.
    ///
    /// - Parameters:
    ///   - filter: The smart filter to apply.
    ///   - reminderService: The reminder service to fetch from.
    /// - Returns: An array of filtered and sorted reminders.
    /// - Throws: An error if fetching fails or if permissions are not granted.
    public func applyFilter(
        _ filter: SmartFilter,
        with reminderService: ReminderService
    ) async throws -> [Reminder] {
        // Get all available lists for conversion
        let allLists = reminderService.reminderLists

        // Convert criteria to fetch parameters
        let listSelection = filter.criteria.toReminderListSelection(availableLists: allLists)

        // Fetch with all criteria
        return try await reminderService.fetchReminders(
            from: listSelection,
            filter: filter.criteria.completionFilter,
            dateRange: filter.criteria.dateRangeFilter,
            tagFilter: filter.criteria.tagFilter,
            textSearch: filter.criteria.textSearch,
            sortBy: filter.criteria.sortBy
        )
    }
}

// MARK: - Errors

/// Errors that can occur when using the smart filter service.
public enum SmartFilterServiceError: Error, LocalizedError {

    /// The specified smart filter was not found.
    case filterNotFound

    /// The smart filter could not be saved.
    case saveFailed

    /// The smart filter could not be deleted.
    case deleteFailed

    /// The filter name is invalid (empty or missing).
    case invalidName

    /// Built-in filters cannot be modified or deleted.
    case builtInFilterImmutable

    public var errorDescription: String? {
        switch self {
        case .filterNotFound:
            return "The specified smart filter could not be found."
        case .saveFailed:
            return "Failed to save the smart filter to SwiftData."
        case .deleteFailed:
            return "Failed to delete the smart filter from SwiftData."
        case .invalidName:
            return "The filter name cannot be empty."
        case .builtInFilterImmutable:
            return "Built-in filters cannot be modified or deleted."
        }
    }
}
