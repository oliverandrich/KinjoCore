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
import MockingKit
@testable import KinjoCore

/// Mock implementation of PermissionServiceProtocol for testing.
///
/// This is a simple stub implementation that returns predefined values.
/// For more complex mocking scenarios, add MockReference instances as needed.
class MockPermissionService: PermissionServiceProtocol {

    // MARK: - Configurable Properties

    var mockHasReminderAccess: Bool = false
    var mockHasCalendarAccess: Bool = false
    var mockReminderAuthorizationStatus: EKAuthorizationStatus = .denied
    var mockCalendarAuthorizationStatus: EKAuthorizationStatus = .denied

    // MARK: - Protocol Properties

    lazy var eventStore: EKEventStore = {
        // Create a real event store only if actually needed
        // This will trigger permission dialogs, so it should only be used in integration tests
        EKEventStore()
    }()

    var reminderAuthorizationStatus: EKAuthorizationStatus {
        mockReminderAuthorizationStatus
    }

    var calendarAuthorizationStatus: EKAuthorizationStatus {
        mockCalendarAuthorizationStatus
    }

    var hasReminderAccess: Bool {
        mockHasReminderAccess
    }

    var hasCalendarAccess: Bool {
        mockHasCalendarAccess
    }

    // MARK: - Protocol Methods

    func requestReminderAccess() async throws -> Bool {
        mockHasReminderAccess
    }

    func requestCalendarAccess() async throws -> Bool {
        mockHasCalendarAccess
    }

    func refreshAuthorizationStatus() {
        // No-op in mock
    }
}
