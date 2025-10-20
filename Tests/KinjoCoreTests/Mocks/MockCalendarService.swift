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
import MockingKit
@testable import KinjoCore

/// Mock implementation of CalendarServiceProtocol for testing.
///
/// This is a simple stub implementation that returns predefined values.
@MainActor
class MockCalendarService: CalendarServiceProtocol {

    // MARK: - Configurable Properties

    var mockCalendars: [KinjoCore.Calendar] = []
    var mockEvents: [Event] = []

    // MARK: - Protocol Properties

    var calendars: [KinjoCore.Calendar] {
        mockCalendars
    }

    var events: [Event] {
        mockEvents
    }

    // MARK: - Protocol Methods

    func fetchCalendars() async throws -> [KinjoCore.Calendar] {
        mockCalendars
    }

    func fetchEvents(from: CalendarSelection, dateRange: DateRangeFilter) async throws -> [Event] {
        mockEvents
    }
}
