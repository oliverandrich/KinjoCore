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

/// Sort options for reminder lists.
public enum ReminderSortOption: Sendable, Hashable {

    /// Sort alphabetically by title (A-Z).
    case title

    /// Sort by due date.
    /// - Parameter ascending: If `true`, sorts oldest first; if `false`, sorts newest first.
    /// Reminders without a due date will appear at the end.
    case dueDate(ascending: Bool)

    /// Sort by priority (high to low: 1-4 = high, 5 = medium, 6-9 = low, 0 = none).
    /// Reminders with higher priority (lower numbers) appear first.
    case priority

    /// Sort by creation date.
    /// - Parameter ascending: If `true`, sorts oldest first; if `false`, sorts newest first.
    case creationDate(ascending: Bool)
}
