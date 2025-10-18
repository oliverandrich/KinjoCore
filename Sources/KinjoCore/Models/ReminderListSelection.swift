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

/// Selection options for which reminder lists to fetch reminders from.
public enum ReminderListSelection: Sendable, Hashable {

    /// Fetch reminders from all available reminder lists.
    case all

    /// Fetch reminders from specific reminder lists.
    ///
    /// If an empty array is provided, it will be treated as `.all`.
    case specific([ReminderList])

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .all:
            hasher.combine(0)
        case .specific(let lists):
            hasher.combine(1)
            hasher.combine(lists)
        }
    }

    public static func == (lhs: ReminderListSelection, rhs: ReminderListSelection) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all):
            return true
        case (.specific(let lhsLists), .specific(let rhsLists)):
            return lhsLists == rhsLists
        default:
            return false
        }
    }
}
