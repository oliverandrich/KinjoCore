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
import SwiftData

/// A smart filter that defines criteria for filtering and displaying reminders.
///
/// Smart filters allow users to create custom views of their reminders based on
/// various criteria such as list membership, completion status, date ranges, tags,
/// and full-text search. They are persisted using SwiftData and can be synchronised
/// via iCloud.
///
/// ## Built-in Filters
///
/// The system provides several built-in filters that cannot be deleted:
/// - **All**: Shows all reminders without any filtering
/// - **Today**: Shows reminders due today
/// - **Tomorrow**: Shows reminders due tomorrow
/// - **This Week**: Shows reminders due this week
/// - **Flagged**: Shows reminders with high priority
/// - **Completed**: Shows completed reminders
///
/// ## Examples
///
/// ```swift
/// // Create a custom smart filter
/// let workFilter = SmartFilter(
///     name: "Work Tasks",
///     iconName: "briefcase.fill",
///     tintColor: "#0066CC",
///     criteria: FilterCriteria(
///         tagFilter: .hasTag("work"),
///         completionFilter: .incomplete
///     )
/// )
/// ```
@Model
public final class SmartFilter {

    // MARK: - Properties

    /// Unique identifier for the filter.
    @Attribute(.unique) public var id: UUID

    /// Display name of the filter.
    public var name: String

    /// SF Symbol name for the filter icon (e.g., "star.fill", "calendar").
    public var iconName: String

    /// Optional tint colour for the icon as a hex string (e.g., "#FF5733").
    public var tintColor: String?

    /// Sort order for displaying filters in the UI.
    ///
    /// Lower values appear first. This allows users to customise the order
    /// of their filters via drag-and-drop.
    public var sortOrder: Int

    /// Whether this is a built-in system filter.
    ///
    /// Built-in filters cannot be deleted by users.
    public var isBuiltIn: Bool

    /// The filter criteria defining which reminders to show.
    ///
    /// Stored as JSON data using Codable conformance.
    public var criteriaData: Data

    /// The decoded filter criteria.
    @Transient
    public var criteria: FilterCriteria {
        get {
            (try? JSONDecoder().decode(FilterCriteria.self, from: criteriaData)) ?? FilterCriteria()
        }
    }

    /// Date when the filter was created.
    public var createdAt: Date

    /// Date when the filter was last modified.
    public var modifiedAt: Date

    // MARK: - Initialisation

    /// Creates a new smart filter.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - name: Display name of the filter.
    ///   - iconName: SF Symbol name for the icon.
    ///   - tintColor: Optional hex colour string for the icon tint.
    ///   - sortOrder: Sort order for display. Defaults to 0.
    ///   - isBuiltIn: Whether this is a system filter. Defaults to `false`.
    ///   - criteria: Filter criteria. Defaults to showing all reminders.
    ///   - createdAt: Creation date. Defaults to now.
    ///   - modifiedAt: Last modification date. Defaults to now.
    public init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        tintColor: String? = nil,
        sortOrder: Int = 0,
        isBuiltIn: Bool = false,
        criteria: FilterCriteria = FilterCriteria(),
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.tintColor = tintColor
        self.sortOrder = sortOrder
        self.isBuiltIn = isBuiltIn
        self.criteriaData = (try? JSONEncoder().encode(criteria)) ?? Data()
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Factory Methods

    /// Creates the built-in system filters.
    ///
    /// These filters are created automatically when the app first launches
    /// and cannot be deleted by users.
    ///
    /// - Returns: An array of built-in smart filters.
    public static func builtInFilters() -> [SmartFilter] {
        return [
            // All reminders
            SmartFilter(
                name: "All",
                iconName: "tray.fill",
                sortOrder: 0,
                isBuiltIn: true,
                criteria: FilterCriteria()
            ),

            // Today's reminders
            SmartFilter(
                name: "Today",
                iconName: "calendar",
                tintColor: "#007AFF", // System blue
                sortOrder: 1,
                isBuiltIn: true,
                criteria: FilterCriteria(
                    completionFilter: .incomplete,
                    dateRangeFilter: .today
                )
            ),

            // Tomorrow's reminders
            SmartFilter(
                name: "Tomorrow",
                iconName: "calendar.badge.plus",
                tintColor: "#34C759", // System green
                sortOrder: 2,
                isBuiltIn: true,
                criteria: FilterCriteria(
                    completionFilter: .incomplete,
                    dateRangeFilter: .tomorrow
                )
            ),

            // This week's reminders
            SmartFilter(
                name: "This Week",
                iconName: "calendar.badge.clock",
                tintColor: "#FF9500", // System orange
                sortOrder: 3,
                isBuiltIn: true,
                criteria: FilterCriteria(
                    completionFilter: .incomplete,
                    dateRangeFilter: .thisWeek
                )
            ),

            // Flagged reminders (high priority)
            SmartFilter(
                name: "Flagged",
                iconName: "flag.fill",
                tintColor: "#FF3B30", // System red
                sortOrder: 4,
                isBuiltIn: true,
                criteria: FilterCriteria(
                    completionFilter: .incomplete,
                    sortBy: .priority
                )
            ),

            // Completed reminders
            SmartFilter(
                name: "Completed",
                iconName: "checkmark.circle.fill",
                tintColor: "#8E8E93", // System grey
                sortOrder: 5,
                isBuiltIn: true,
                criteria: FilterCriteria(
                    completionFilter: .completed,
                    sortBy: .creationDate(ascending: false)
                )
            )
        ]
    }
}
