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

/// Protocol for managing EventKit permissions and providing access to the event store.
///
/// This protocol defines the interface for handling authorisation requests for both
/// reminders and calendars, and provides a centralised `EKEventStore` instance.
public protocol PermissionServiceProtocol {

    /// The shared EventKit event store instance.
    var eventStore: EKEventStore { get }

    /// Current authorisation status for reminders.
    var reminderAuthorizationStatus: EKAuthorizationStatus { get }

    /// Current authorisation status for calendars.
    var calendarAuthorizationStatus: EKAuthorizationStatus { get }

    /// Checks if the app currently has full access to reminders.
    var hasReminderAccess: Bool { get }

    /// Checks if the app currently has full access to calendars.
    var hasCalendarAccess: Bool { get }

    /// Requests access to reminders if not already authorised.
    ///
    /// - Returns: `true` if access is granted, `false` otherwise.
    /// - Throws: An error if the authorisation request fails.
    @discardableResult
    func requestReminderAccess() async throws -> Bool

    /// Requests access to calendars if not already authorised.
    ///
    /// - Returns: `true` if access is granted, `false` otherwise.
    /// - Throws: An error if the authorisation request fails.
    @discardableResult
    func requestCalendarAccess() async throws -> Bool

    /// Refreshes the current authorisation status for both reminders and calendars.
    func refreshAuthorizationStatus()
}
