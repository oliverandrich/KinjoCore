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
// distributed under the Licence is distributed on an "AS IS" basis,q
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the Licence for the specific language governing permissions and
// limitations under the Licence.

import EventKit
import Foundation
import Observation

/// Service responsible for managing calendars and events.
///
/// This service provides access to calendars stored in EventKit and automatically
/// updates when the underlying EventKit store changes.
@Observable
@MainActor
public final class CalendarService: CalendarServiceProtocol {

    // MARK: - Properties

    /// The permission service used to access the EventKit store.
    private let permissionService: any PermissionServiceProtocol

    /// The currently loaded calendars.
    public private(set) var calendars: [Calendar] = []

    /// The currently loaded events.
    public private(set) var events: [Event] = []

    /// Observation token for EventKit store changes.
    @ObservationIgnored
    nonisolated(unsafe) private var storeChangedObserver: NSObjectProtocol?

    // MARK: - Initialisation

    /// Creates a new calendar service.
    ///
    /// - Parameter permissionService: The permission service to use for EventKit access.
    public init(permissionService: any PermissionServiceProtocol) {
        self.permissionService = permissionService
        self.setupStoreChangeObserver()
    }

    deinit {
        if let observer = storeChangedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Methods

    /// Fetches all calendars from EventKit.
    ///
    /// This method requires that the app has permission to access calendars.
    /// Call `permissionService.requestCalendarAccess()` first if needed.
    ///
    /// - Returns: An array of calendars.
    /// - Throws: An error if fetching fails or if permissions are not granted.
    @discardableResult
    public func fetchCalendars() async throws -> [Calendar] {
        guard permissionService.hasCalendarAccess else {
            throw CalendarServiceError.permissionDenied
        }

        let ekCalendars = permissionService.eventStore.calendars(for: .event)
        let calendars = ekCalendars.map { Calendar(from: $0) }

        self.calendars = calendars

        return calendars
    }

    /// Fetches events from EventKit with optional date range filtering.
    ///
    /// This method requires that the app has permission to access calendars.
    /// Call `permissionService.requestCalendarAccess()` first if needed.
    ///
    /// - Parameters:
    ///   - from: Which calendars to fetch events from. Defaults to `.all`.
    ///   - dateRange: The date range filter to apply. Defaults to `.all`.
    /// - Returns: An array of events sorted chronologically by start date.
    /// - Throws: An error if fetching fails, if permissions are not granted, or if a specified calendar is not found.
    @discardableResult
    public func fetchEvents(
        from: CalendarSelection = .all,
        dateRange: DateRangeFilter = .all
    ) async throws -> [Event] {
        guard permissionService.hasCalendarAccess else {
            throw CalendarServiceError.permissionDenied
        }

        // Determine which calendars to query
        let ekCalendars: [EKCalendar]

        switch from {
        case .all:
            // Fetch from all event calendars
            ekCalendars = permissionService.eventStore.calendars(for: .event)

        case .specific(let calendars):
            // Empty array is treated as .all
            if calendars.isEmpty {
                ekCalendars = permissionService.eventStore.calendars(for: .event)
            } else {
                // Fetch events from specific calendars
                var selectedCalendars: [EKCalendar] = []
                for calendar in calendars {
                    guard let ekCalendar = permissionService.eventStore.calendar(withIdentifier: calendar.id) else {
                        throw CalendarServiceError.calendarNotFound
                    }
                    selectedCalendars.append(ekCalendar)
                }
                ekCalendars = selectedCalendars
            }
        }

        // Determine date range for the query
        let events: [Event]

        if let range = dateRange.dateRange() {
            // Fetch events within the specified date range
            let predicate = permissionService.eventStore.predicateForEvents(
                withStart: range.start,
                end: range.end,
                calendars: ekCalendars
            )
            let ekEvents = permissionService.eventStore.events(matching: predicate)
            events = ekEvents.map { Event(from: $0) }
        } else {
            // No date range filter - this would return all events which could be huge
            // For safety, we'll throw an error requiring a date range
            throw CalendarServiceError.dateRangeRequired
        }

        // Sort chronologically by start date
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }

        // Update cache
        self.events = sortedEvents

        return sortedEvents
    }

    // MARK: - Private Methods

    /// Sets up an observer to automatically refresh calendars when EventKit changes.
    private func setupStoreChangeObserver() {
        // Only observe store changes if we have permission
        // This prevents accessing eventStore in mock tests
        guard permissionService.hasCalendarAccess else {
            return
        }

        storeChangedObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: permissionService.eventStore,
            queue: .main
        ) { [weak self] _ in
            Task {
                try? await self?.fetchCalendars()
            }
        }
    }
}

// MARK: - Errors

/// Errors that can occur when using the calendar service.
public enum CalendarServiceError: Error, LocalizedError {

    /// Permission to access calendars has been denied.
    case permissionDenied

    /// The specified calendar was not found.
    case calendarNotFound

    /// A date range is required when fetching events.
    case dateRangeRequired

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission to access calendars has been denied. Please grant access in Settings."
        case .calendarNotFound:
            return "The specified calendar could not be found."
        case .dateRangeRequired:
            return "A date range must be specified when fetching events. Use .today, .thisWeek, .thisMonth, or .custom() instead of .all."
        }
    }
}
