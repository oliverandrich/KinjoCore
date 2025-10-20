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

/// Protocol for managing calendars and events.
///
/// This protocol defines the interface for accessing calendars and events
/// stored in EventKit.
@MainActor
public protocol CalendarServiceProtocol {

    // MARK: - Properties

    /// The currently loaded calendars.
    var calendars: [Calendar] { get }

    /// The currently loaded events.
    var events: [Event] { get }

    // MARK: - Public Methods

    /// Fetches all calendars from EventKit.
    @discardableResult
    func fetchCalendars() async throws -> [Calendar]

    /// Fetches events from EventKit with optional date range filtering.
    @discardableResult
    func fetchEvents(
        from: CalendarSelection,
        dateRange: DateRangeFilter
    ) async throws -> [Event]
}
