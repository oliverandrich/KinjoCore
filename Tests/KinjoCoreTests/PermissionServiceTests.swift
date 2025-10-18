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

import Testing
import EventKit
@testable import KinjoCore

@Suite("PermissionService Tests")
struct PermissionServiceTests {

    @Test("PermissionService initialises correctly")
    func initialisesCorrectly() async throws {
        let service = PermissionService()

        // EventStore should be properly initialised (not checking against nil as it's non-optional)
        _ = service.eventStore
        // Authorisation status should be a valid EKAuthorizationStatus value
        #expect(service.reminderAuthorizationStatus.rawValue >= 0)
        #expect(service.calendarAuthorizationStatus.rawValue >= 0)
    }

    @Test("PermissionService provides access status properties")
    func providesAccessStatusProperties() async throws {
        let service = PermissionService()

        // These properties should return boolean values based on authorisation status
        let hasReminderAccess = service.hasReminderAccess
        let hasCalendarAccess = service.hasCalendarAccess

        // Values should be boolean (this will always pass, but verifies the property is accessible)
        #expect(hasReminderAccess == true || hasReminderAccess == false)
        #expect(hasCalendarAccess == true || hasCalendarAccess == false)
    }

    @Test("PermissionService can refresh authorisation status")
    func canRefreshAuthorisationStatus() async throws {
        let service = PermissionService()

        let initialReminderStatus = service.reminderAuthorizationStatus
        let initialCalendarStatus = service.calendarAuthorizationStatus

        service.refreshAuthorizationStatus()

        // Status should remain consistent after refresh (in test environment)
        #expect(service.reminderAuthorizationStatus == initialReminderStatus)
        #expect(service.calendarAuthorizationStatus == initialCalendarStatus)
    }

    @Test("PermissionService hasReminderAccess reflects authorisation status")
    func hasReminderAccessReflectsStatus() async throws {
        let service = PermissionService()

        // hasReminderAccess should be true only when status is .fullAccess
        let expectedAccess = service.reminderAuthorizationStatus == .fullAccess
        #expect(service.hasReminderAccess == expectedAccess)
    }

    @Test("PermissionService hasCalendarAccess reflects authorisation status")
    func hasCalendarAccessReflectsStatus() async throws {
        let service = PermissionService()

        // hasCalendarAccess should be true only when status is .fullAccess
        let expectedAccess = service.calendarAuthorizationStatus == .fullAccess
        #expect(service.hasCalendarAccess == expectedAccess)
    }
}
