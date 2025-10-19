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

/// An alarm for a reminder that triggers at a specific time or location.
///
/// This type wraps `EKAlarm` to provide a clean, Swift-native interface for
/// configuring notifications for reminders.
///
/// ## Examples
///
/// ```swift
/// // Absolute alarm at specific date/time
/// let absolute = Alarm.absolute(date: tomorrow)
///
/// // Relative alarms before the reminder's due date
/// let fifteenMin = Alarm.relative(minutes: -15)
/// let oneHour = Alarm.relative(hours: -1)
/// let oneDay = Alarm.relative(days: -1)
///
/// // Location-based alarm
/// let office = StructuredLocation.location(
///     title: "Office",
///     latitude: 52.520008,
///     longitude: 13.404954,
///     radius: 100
/// )
/// let locationAlarm = Alarm.location(office, proximity: .leave)
/// ```
public enum Alarm: Sendable, Hashable {

    /// An alarm that triggers at an absolute date and time.
    ///
    /// - Parameter date: The specific date and time when the alarm should trigger.
    case absolute(date: Date)

    /// An alarm that triggers relative to the reminder's due date or start date.
    ///
    /// - Parameter offset: The time offset in seconds. Negative values trigger before the date,
    ///   positive values trigger after. For example, `-900` = 15 minutes before.
    case relative(offset: TimeInterval)

    /// An alarm that triggers based on geographical location.
    ///
    /// - Parameters:
    ///   - location: The structured location with coordinates and geofence radius.
    ///   - proximity: Whether to trigger when entering or leaving the location.
    case location(location: StructuredLocation, proximity: AlarmProximity)

    // MARK: - Initialisation

    /// Creates an alarm from an EventKit alarm.
    ///
    /// - Parameter ekAlarm: The EventKit alarm.
    /// - Returns: The corresponding `Alarm` enum case, or `nil` if the alarm type cannot be determined.
    public init?(from ekAlarm: EKAlarm) {
        if let absoluteDate = ekAlarm.absoluteDate {
            // Absolute alarm
            self = .absolute(date: absoluteDate)
        } else if let structuredLocation = ekAlarm.structuredLocation {
            // Location-based alarm
            let location = StructuredLocation(from: structuredLocation)
            let proximity = AlarmProximity(from: ekAlarm.proximity)
            self = .location(location: location, proximity: proximity)
        } else {
            // Relative alarm
            // Note: relativeOffset is always 0 for absolute/location alarms, non-zero for relative
            let offset = ekAlarm.relativeOffset
            if offset != 0 {
                self = .relative(offset: offset)
            } else {
                // Invalid alarm state - no date, no location, no offset
                return nil
            }
        }
    }

    // MARK: - Conversion

    /// Converts this alarm to an EventKit alarm.
    ///
    /// - Returns: The corresponding `EKAlarm` object.
    public func toEKAlarm() -> EKAlarm {
        switch self {
        case .absolute(let date):
            return EKAlarm(absoluteDate: date)

        case .relative(let offset):
            return EKAlarm(relativeOffset: offset)

        case .location(let location, let proximity):
            let ekAlarm = EKAlarm()
            ekAlarm.structuredLocation = location.toEKStructuredLocation()
            ekAlarm.proximity = proximity.toEKAlarmProximity()
            return ekAlarm
        }
    }

    // MARK: - Convenience Factory Methods

    /// Creates a relative alarm that triggers a specified number of minutes before the reminder.
    ///
    /// - Parameter minutes: The number of minutes before the reminder (use negative values).
    ///   For example, `-15` means "15 minutes before".
    /// - Returns: A relative alarm.
    public static func relative(minutes: Int) -> Alarm {
        .relative(offset: TimeInterval(minutes * 60))
    }

    /// Creates a relative alarm that triggers a specified number of hours before the reminder.
    ///
    /// - Parameter hours: The number of hours before the reminder (use negative values).
    ///   For example, `-1` means "1 hour before".
    /// - Returns: A relative alarm.
    public static func relative(hours: Int) -> Alarm {
        .relative(offset: TimeInterval(hours * 3600))
    }

    /// Creates a relative alarm that triggers a specified number of days before the reminder.
    ///
    /// - Parameter days: The number of days before the reminder (use negative values).
    ///   For example, `-1` means "1 day before".
    /// - Returns: A relative alarm.
    public static func relative(days: Int) -> Alarm {
        .relative(offset: TimeInterval(days * 86400))
    }

    // MARK: - Properties

    /// Whether this is a location-based alarm.
    public var isLocationBased: Bool {
        if case .location = self {
            return true
        }
        return false
    }

    /// Whether this is a time-based alarm (absolute or relative).
    public var isTimeBased: Bool {
        switch self {
        case .absolute, .relative:
            return true
        case .location:
            return false
        }
    }
}
