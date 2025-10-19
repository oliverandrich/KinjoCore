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

/// Priority level for a reminder.
///
/// EventKit uses integer values 0-9 for priority, where:
/// - 0 = no priority
/// - 1-4 = high priority
/// - 5 = medium priority
/// - 6-9 = low priority
///
/// This enum simplifies the API to four logical priority levels while
/// maintaining compatibility with EventKit's integer representation.
public enum Priority: Sendable, Hashable, Comparable {

    /// No priority assigned.
    case none

    /// High priority (urgent/important).
    case high

    /// Medium priority.
    case medium

    /// Low priority.
    case low

    // MARK: - EventKit Conversion

    /// Creates a priority from an EventKit integer value.
    ///
    /// - Parameter eventKitValue: The EventKit priority value (0-9).
    public init(eventKitValue: Int) {
        switch eventKitValue {
        case 0:
            self = .none
        case 1...4:
            self = .high
        case 5:
            self = .medium
        case 6...9:
            self = .low
        default:
            // Values outside 0-9 are treated as none
            self = .none
        }
    }

    /// Converts this priority to an EventKit integer value.
    ///
    /// Uses Apple's recommended standard values:
    /// - none: 0
    /// - high: 1
    /// - medium: 5
    /// - low: 9
    public var eventKitValue: Int {
        switch self {
        case .none:
            return 0
        case .high:
            return 1
        case .medium:
            return 5
        case .low:
            return 9
        }
    }

    // MARK: - Comparable

    public static func < (lhs: Priority, rhs: Priority) -> Bool {
        // Higher priority has lower eventKitValue (except none)
        // Ordering: high < medium < low < none
        switch (lhs, rhs) {
        case (.none, .none):
            return false
        case (.none, _):
            return false  // none is lowest priority
        case (_, .none):
            return true
        default:
            // For non-none priorities, lower eventKitValue = higher priority
            return lhs.eventKitValue < rhs.eventKitValue
        }
    }
}
