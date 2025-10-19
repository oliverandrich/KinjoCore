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

/// The proximity trigger for location-based alarms.
///
/// Determines when a location-based alarm should fire relative to arriving at or leaving a location.
public enum AlarmProximity: Int, Sendable, Hashable, CaseIterable {

    /// No location-based trigger.
    ///
    /// Used for time-based alarms (absolute or relative).
    case none = 0

    /// Trigger the alarm when entering the geofenced area.
    ///
    /// The alarm fires when the device detects that the user has entered
    /// the radius around the structured location.
    case enter = 1

    /// Trigger the alarm when leaving the geofenced area.
    ///
    /// The alarm fires when the device detects that the user has left
    /// the radius around the structured location.
    case leave = 2

    // MARK: - Initialisation

    /// Creates an alarm proximity from an EventKit alarm proximity.
    ///
    /// - Parameter ekProximity: The EventKit alarm proximity.
    public init(from ekProximity: EKAlarmProximity) {
        switch ekProximity {
        case .none:
            self = .none
        case .enter:
            self = .enter
        case .leave:
            self = .leave
        @unknown default:
            self = .none
        }
    }

    // MARK: - Conversion

    /// Converts this alarm proximity to an EventKit alarm proximity.
    ///
    /// - Returns: The corresponding `EKAlarmProximity` value.
    public func toEKAlarmProximity() -> EKAlarmProximity {
        switch self {
        case .none:
            return .none
        case .enter:
            return .enter
        case .leave:
            return .leave
        }
    }
}
