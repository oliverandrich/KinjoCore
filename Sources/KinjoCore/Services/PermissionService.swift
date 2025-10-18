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

/// Service responsible for managing EventKit permissions and providing access to the event store.
///
/// This service handles authorisation requests for both reminders and calendars,
/// and provides a centralised `EKEventStore` instance for use by other services.
@Observable
public final class PermissionService {

    // MARK: - Properties

    /// The shared EventKit event store instance.
    public let eventStore: EKEventStore

    /// Current authorisation status for reminders.
    public private(set) var reminderAuthorizationStatus: EKAuthorizationStatus

    /// Current authorisation status for calendars.
    public private(set) var calendarAuthorizationStatus: EKAuthorizationStatus

    // MARK: - Initialisation

    /// Creates a new permission service with a fresh event store.
    public init() {
        self.eventStore = EKEventStore()
        self.reminderAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        self.calendarAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Public Methods

    /// Requests access to reminders if not already authorised.
    ///
    /// - Returns: `true` if access is granted, `false` otherwise.
    /// - Throws: An error if the authorisation request fails.
    @discardableResult
    public func requestReminderAccess() async throws -> Bool {
        // Update current status
        reminderAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)

        // If already authorised, return immediately
        guard reminderAuthorizationStatus != .fullAccess else {
            return true
        }

        // Request access
        let granted = try await eventStore.requestFullAccessToReminders()

        // Update status after request
        reminderAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)

        return granted
    }

    /// Requests access to calendars if not already authorised.
    ///
    /// - Returns: `true` if access is granted, `false` otherwise.
    /// - Throws: An error if the authorisation request fails.
    @discardableResult
    public func requestCalendarAccess() async throws -> Bool {
        // Update current status
        calendarAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)

        // If already authorised, return immediately
        guard calendarAuthorizationStatus != .fullAccess else {
            return true
        }

        // Request access
        let granted = try await eventStore.requestFullAccessToEvents()

        // Update status after request
        calendarAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)

        return granted
    }

    /// Checks if the app currently has full access to reminders.
    ///
    /// - Returns: `true` if full access is granted, `false` otherwise.
    public var hasReminderAccess: Bool {
        reminderAuthorizationStatus == .fullAccess
    }

    /// Checks if the app currently has full access to calendars.
    ///
    /// - Returns: `true` if full access is granted, `false` otherwise.
    public var hasCalendarAccess: Bool {
        calendarAuthorizationStatus == .fullAccess
    }

    /// Refreshes the current authorisation status for both reminders and calendars.
    public func refreshAuthorizationStatus() {
        reminderAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        calendarAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
}
