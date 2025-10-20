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

/// Criteria for filtering and sorting reminders in a SmartFilter.
///
/// This struct combines all available filter options for reminders and is designed
/// to be serialisable for storage in SwiftData.
public struct FilterCriteria: Codable, Sendable, Hashable {

    // MARK: - Properties

    /// List selection mode (all, specific IDs, or excluding IDs).
    public var listSelection: ListSelectionCriteria

    /// Completion status filter.
    public var completionFilter: ReminderFilter

    /// Date range filter.
    public var dateRangeFilter: DateRangeFilter

    /// Tag-based filter.
    public var tagFilter: TagFilter

    /// Full-text search filter.
    public var textSearch: TextSearchFilter

    /// Sort option for results.
    public var sortBy: ReminderSortOption

    // MARK: - Initialisation

    /// Creates filter criteria with all parameters.
    ///
    /// - Parameters:
    ///   - listSelection: List selection criteria. Defaults to `.all`.
    ///   - completionFilter: Completion status filter. Defaults to `.all`.
    ///   - dateRangeFilter: Date range filter. Defaults to `.all`.
    ///   - tagFilter: Tag filter. Defaults to `.none`.
    ///   - textSearch: Text search filter. Defaults to `.none`.
    ///   - sortBy: Sort option. Defaults to `.title`.
    public init(
        listSelection: ListSelectionCriteria = .all,
        completionFilter: ReminderFilter = .all,
        dateRangeFilter: DateRangeFilter = .all,
        tagFilter: TagFilter = .none,
        textSearch: TextSearchFilter = .none,
        sortBy: ReminderSortOption = .title
    ) {
        self.listSelection = listSelection
        self.completionFilter = completionFilter
        self.dateRangeFilter = dateRangeFilter
        self.tagFilter = tagFilter
        self.textSearch = textSearch
        self.sortBy = sortBy
    }

    // MARK: - Conversion Methods

    /// Converts the list selection criteria to a `ReminderListSelection` enum.
    ///
    /// - Parameter availableLists: All available reminder lists to resolve IDs.
    /// - Returns: The corresponding `ReminderListSelection` value.
    public func toReminderListSelection(availableLists: [ReminderList]) -> ReminderListSelection {
        switch listSelection {
        case .all:
            return .all

        case .specific(let ids):
            let lists = availableLists.filter { ids.contains($0.id) }
            return .specific(lists)

        case .excluding(let ids):
            let lists = availableLists.filter { ids.contains($0.id) }
            return .excluding(lists)
        }
    }

    /// Creates filter criteria from a `ReminderListSelection`.
    ///
    /// - Parameter selection: The reminder list selection.
    /// - Returns: The corresponding list selection criteria.
    public static func listSelectionFrom(_ selection: ReminderListSelection) -> ListSelectionCriteria {
        switch selection {
        case .all:
            return .all
        case .specific(let lists):
            return .specific(lists.map { $0.id })
        case .excluding(let lists):
            return .excluding(lists.map { $0.id })
        }
    }
}

// MARK: - ListSelectionCriteria

/// Serialisable version of `ReminderListSelection` that stores only list IDs.
///
/// This enum allows `ReminderListSelection` to be persisted without storing
/// full `ReminderList` objects.
public enum ListSelectionCriteria: Codable, Sendable, Hashable {

    /// Select all reminder lists.
    case all

    /// Select specific reminder lists by their IDs.
    case specific([String])

    /// Exclude specific reminder lists by their IDs (select all others).
    case excluding([String])
}
