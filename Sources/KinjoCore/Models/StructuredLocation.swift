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
import CoreLocation
import Foundation

/// A structured location with geographical coordinates and geofencing capabilities.
///
/// This type wraps `EKStructuredLocation` to provide a clean, Swift-native interface
/// for working with location-based reminders and alarms.
public struct StructuredLocation: Sendable, Hashable {

    // MARK: - Properties

    /// The title or name of the location (e.g., "Home", "Office", "Supermarket").
    public let title: String

    /// The geographical location with latitude and longitude coordinates.
    ///
    /// Used for geofencing and location-based triggers.
    public let geoLocation: CLLocation?

    /// The radius in metres for the geofence around this location.
    ///
    /// When a location-based alarm is triggered, the system uses this radius to determine
    /// when the user enters or leaves the area. Typical values: 50-500 metres.
    ///
    /// - Note: iOS may adjust the actual radius based on system constraints and battery considerations.
    public let radius: Double

    // MARK: - Initialisation

    /// Creates a structured location.
    ///
    /// - Parameters:
    ///   - title: The name of the location.
    ///   - geoLocation: Optional geographical coordinates.
    ///   - radius: The geofence radius in metres. Defaults to 100 metres.
    public init(title: String, geoLocation: CLLocation? = nil, radius: Double = 100.0) {
        self.title = title
        self.geoLocation = geoLocation
        self.radius = radius
    }

    /// Creates a structured location from an EventKit structured location.
    ///
    /// - Parameter ekLocation: The EventKit structured location.
    public init(from ekLocation: EKStructuredLocation) {
        self.title = ekLocation.title ?? ""
        self.geoLocation = ekLocation.geoLocation
        self.radius = ekLocation.radius
    }

    // MARK: - Conversion

    /// Converts this structured location to an EventKit structured location.
    ///
    /// - Returns: The corresponding `EKStructuredLocation` object.
    public func toEKStructuredLocation() -> EKStructuredLocation {
        let ekLocation = EKStructuredLocation(title: title)
        ekLocation.geoLocation = geoLocation
        ekLocation.radius = radius
        return ekLocation
    }

    // MARK: - Convenience Initialisers

    /// Creates a structured location with coordinates specified as latitude and longitude.
    ///
    /// - Parameters:
    ///   - title: The name of the location.
    ///   - latitude: The latitude in degrees.
    ///   - longitude: The longitude in degrees.
    ///   - radius: The geofence radius in metres. Defaults to 100 metres.
    /// - Returns: A structured location with the specified coordinates.
    public static func location(
        title: String,
        latitude: Double,
        longitude: Double,
        radius: Double = 100.0
    ) -> StructuredLocation {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        return StructuredLocation(title: title, geoLocation: location, radius: radius)
    }

    /// Creates a structured location with just a title (no coordinates).
    ///
    /// Useful for text-based locations without geofencing.
    ///
    /// - Parameter title: The name of the location.
    /// - Returns: A structured location without geographical coordinates.
    public static func named(_ title: String) -> StructuredLocation {
        StructuredLocation(title: title, geoLocation: nil, radius: 0)
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(geoLocation?.coordinate.latitude)
        hasher.combine(geoLocation?.coordinate.longitude)
        hasher.combine(radius)
    }

    public static func == (lhs: StructuredLocation, rhs: StructuredLocation) -> Bool {
        lhs.title == rhs.title &&
        lhs.geoLocation?.coordinate.latitude == rhs.geoLocation?.coordinate.latitude &&
        lhs.geoLocation?.coordinate.longitude == rhs.geoLocation?.coordinate.longitude &&
        lhs.radius == rhs.radius
    }
}
