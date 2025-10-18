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

/// Service responsible for managing calendars and events.
///
/// This service provides access to calendars stored in EventKit and automatically
/// updates when the underlying EventKit store changes.
@Observable
@MainActor
public final class CalendarService {

    // MARK: - Properties

    /// The permission service used to access the EventKit store.
    private let permissionService: PermissionService

    /// The currently loaded calendars.
    public private(set) var calendars: [Calendar] = []

    /// Observation token for EventKit store changes.
    @ObservationIgnored
    nonisolated(unsafe) private var storeChangedObserver: NSObjectProtocol?

    // MARK: - Initialisation

    /// Creates a new calendar service.
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

    // MARK: - Private Methods

    /// Sets up an observer to automatically refresh calendars when EventKit changes.
    private func setupStoreChangeObserver() {
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

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission to access calendars has been denied. Please grant access in Settings."
        }
    }
}
