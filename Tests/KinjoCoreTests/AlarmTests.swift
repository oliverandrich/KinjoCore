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
import CoreLocation
import Foundation
@testable import KinjoCore

@Suite("Alarm Tests")
struct AlarmTests {

    // MARK: - AlarmProximity Tests

    @Test("AlarmProximity converts to and from EventKit proximity")
    func proximityConversion() {
        let proximities: [(AlarmProximity, EKAlarmProximity)] = [
            (.none, .none),
            (.enter, .enter),
            (.leave, .leave)
        ]

        for (kinjoProx, ekProx) in proximities {
            // Test conversion to EKAlarmProximity
            #expect(kinjoProx.toEKAlarmProximity() == ekProx)

            // Test conversion from EKAlarmProximity
            let converted = AlarmProximity(from: ekProx)
            #expect(converted == kinjoProx)
        }
    }

    // MARK: - StructuredLocation Tests

    @Test("StructuredLocation can be created with title only")
    func locationWithTitleOnly() {
        let location = StructuredLocation.named("Office")

        #expect(location.title == "Office")
        #expect(location.geoLocation == nil)
        #expect(location.radius == 0)
    }

    @Test("StructuredLocation can be created with coordinates")
    func locationWithCoordinates() {
        let location = StructuredLocation.location(
            title: "Berlin",
            latitude: 52.520008,
            longitude: 13.404954,
            radius: 100
        )

        #expect(location.title == "Berlin")
        #expect(location.geoLocation != nil)
        #expect(location.geoLocation?.coordinate.latitude == 52.520008)
        #expect(location.geoLocation?.coordinate.longitude == 13.404954)
        #expect(location.radius == 100)
    }

    @Test("StructuredLocation converts to and from EventKit")
    func locationEventKitConversion() {
        let original = StructuredLocation.location(
            title: "Home",
            latitude: 51.5074,
            longitude: -0.1278,
            radius: 50
        )

        let ekLocation = original.toEKStructuredLocation()
        let converted = StructuredLocation(from: ekLocation)

        #expect(converted.title == original.title)
        #expect(converted.geoLocation?.coordinate.latitude == original.geoLocation?.coordinate.latitude)
        #expect(converted.geoLocation?.coordinate.longitude == original.geoLocation?.coordinate.longitude)
        #expect(converted.radius == original.radius)
    }

    // MARK: - Absolute Alarm Tests

    @Test("Alarm.absolute creates alarm with specific date")
    func absoluteAlarmCreation() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let alarm = Alarm.absolute(date: date)

        #expect(alarm.isTimeBased == true)
        #expect(alarm.isLocationBased == false)

        // Check EventKit conversion
        let ekAlarm = alarm.toEKAlarm()
        #expect(ekAlarm.absoluteDate == date)
    }

    @Test("Alarm.absolute roundtrip conversion works")
    func absoluteAlarmRoundtrip() {
        let date = Date()
        let alarm = Alarm.absolute(date: date)

        let ekAlarm = alarm.toEKAlarm()
        let converted = Alarm(from: ekAlarm)

        if case .absolute(let convertedDate) = converted {
            // EventKit may lose sub-second precision, so check within 1 second tolerance
            let diff = abs(convertedDate.timeIntervalSince(date))
            #expect(diff < 1.0)
        } else {
            Issue.record("Expected .absolute alarm")
        }
    }

    // MARK: - Relative Alarm Tests

    @Test("Alarm.relative creates alarm with offset in seconds")
    func relativeAlarmCreation() {
        let alarm = Alarm.relative(offset: -900) // 15 minutes before

        #expect(alarm.isTimeBased == true)
        #expect(alarm.isLocationBased == false)

        // Check EventKit conversion
        let ekAlarm = alarm.toEKAlarm()
        #expect(ekAlarm.relativeOffset == -900)
    }

    @Test("Alarm.relative with minutes convenience method")
    func relativeAlarmMinutes() {
        let alarm = Alarm.relative(minutes: -15)

        let ekAlarm = alarm.toEKAlarm()
        #expect(ekAlarm.relativeOffset == -900) // -15 * 60
    }

    @Test("Alarm.relative with hours convenience method")
    func relativeAlarmHours() {
        let alarm = Alarm.relative(hours: -1)

        let ekAlarm = alarm.toEKAlarm()
        #expect(ekAlarm.relativeOffset == -3600) // -1 * 3600
    }

    @Test("Alarm.relative with days convenience method")
    func relativeAlarmDays() {
        let alarm = Alarm.relative(days: -1)

        let ekAlarm = alarm.toEKAlarm()
        #expect(ekAlarm.relativeOffset == -86400) // -1 * 86400
    }

    @Test("Alarm.relative roundtrip conversion works")
    func relativeAlarmRoundtrip() {
        let alarm = Alarm.relative(minutes: -30)

        let ekAlarm = alarm.toEKAlarm()
        let converted = Alarm(from: ekAlarm)

        if case .relative(let offset) = converted {
            #expect(offset == -1800) // -30 * 60
        } else {
            Issue.record("Expected .relative alarm")
        }
    }

    // MARK: - Location-Based Alarm Tests

    @Test("Alarm.location creates location-based alarm")
    func locationAlarmCreation() {
        let location = StructuredLocation.location(
            title: "Office",
            latitude: 52.52,
            longitude: 13.405,
            radius: 100
        )
        let alarm = Alarm.location(location: location, proximity: .enter)

        #expect(alarm.isTimeBased == false)
        #expect(alarm.isLocationBased == true)

        // Check EventKit conversion
        let ekAlarm = alarm.toEKAlarm()
        #expect(ekAlarm.structuredLocation != nil)
        #expect(ekAlarm.structuredLocation?.title == "Office")
        #expect(ekAlarm.proximity == .enter)
    }

    @Test("Alarm.location with enter proximity")
    func locationAlarmEnter() {
        let location = StructuredLocation.named("Home")
        let alarm = Alarm.location(location: location, proximity: .enter)

        let ekAlarm = alarm.toEKAlarm()
        #expect(ekAlarm.proximity == .enter)
    }

    @Test("Alarm.location with leave proximity")
    func locationAlarmLeave() {
        let location = StructuredLocation.named("Office")
        let alarm = Alarm.location(location: location, proximity: .leave)

        let ekAlarm = alarm.toEKAlarm()
        #expect(ekAlarm.proximity == .leave)
    }

    @Test("Alarm.location roundtrip conversion works")
    func locationAlarmRoundtrip() {
        let location = StructuredLocation.location(
            title: "Gym",
            latitude: 50.0,
            longitude: 10.0,
            radius: 200
        )
        let alarm = Alarm.location(location: location, proximity: .leave)

        let ekAlarm = alarm.toEKAlarm()
        let converted = Alarm(from: ekAlarm)

        if case .location(let convertedLocation, let proximity) = converted {
            #expect(convertedLocation.title == "Gym")
            #expect(proximity == .leave)
            #expect(convertedLocation.radius == 200)
        } else {
            Issue.record("Expected .location alarm")
        }
    }

    // MARK: - Complex Scenarios

    @Test("Multiple alarm types can be distinguished")
    func multipleAlarmTypes() {
        let absolute = Alarm.absolute(date: Date())
        let relative = Alarm.relative(minutes: -15)
        let location = Alarm.location(
            location: StructuredLocation.named("Office"),
            proximity: .enter
        )

        // Absolute alarm
        #expect(absolute.isTimeBased == true)
        #expect(absolute.isLocationBased == false)

        // Relative alarm
        #expect(relative.isTimeBased == true)
        #expect(relative.isLocationBased == false)

        // Location alarm
        #expect(location.isTimeBased == false)
        #expect(location.isLocationBased == true)
    }

    @Test("Alarm equality works correctly")
    func alarmEquality() {
        let date = Date(timeIntervalSince1970: 1704067200)

        let alarm1 = Alarm.absolute(date: date)
        let alarm2 = Alarm.absolute(date: date)
        let alarm3 = Alarm.absolute(date: Date(timeIntervalSince1970: 1704153600))

        #expect(alarm1 == alarm2)
        #expect(alarm1 != alarm3)
    }

    @Test("StructuredLocation equality works correctly")
    func locationEquality() {
        let loc1 = StructuredLocation.location(title: "A", latitude: 52.0, longitude: 13.0, radius: 100)
        let loc2 = StructuredLocation.location(title: "A", latitude: 52.0, longitude: 13.0, radius: 100)
        let loc3 = StructuredLocation.location(title: "B", latitude: 52.0, longitude: 13.0, radius: 100)

        #expect(loc1 == loc2)
        #expect(loc1 != loc3)
    }
}
