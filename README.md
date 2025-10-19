# KinjoCore

A Swift service layer for working with EventKit in macOS and iOS applications. This library provides a structured way to interact with reminders and calendar events, designed for specific project requirements.

[![License](https://img.shields.io/badge/license-EUPL%201.2-blue.svg)](https://joinup.ec.europa.eu/software/page/eupl)

## Purpose

KinjoCore serves as the shared service layer for two personal macOS/iOS projects. It wraps EventKit's API with some additional functionality like tag extraction, priority handling, and meeting link detection.

**This is not a general-purpose EventKit abstraction.** It contains specific assumptions and design decisions that work for my use cases but may not fit yours.

## Requirements

- Swift 6.2+
- iOS 26.0+ / macOS 26.0+
- No backward compatibility with older OS versions

## Installation

Add via Swift Package Manager:

```swift
.package(url: "https://github.com/yourusername/KinjoCore.git", from: "1.0.0")
```

## Basic Usage

Services are designed to work with SwiftUI's Environment system:

```swift
@main
struct MyApp: App {
    private let permissionService = PermissionService()
    private var reminderService: ReminderService {
        ReminderService(permissionService: permissionService)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(reminderService)
        }
    }
}
```

In views:

```swift
struct ContentView: View {
    @Environment(ReminderService.self) private var reminderService

    var body: some View {
        List(reminderService.reminders) { reminder in
            Text(reminder.title)
        }
        .task {
            try? await reminderService.fetchReminders()
        }
    }
}
```

### Recurring Reminders

The library provides full support for recurring reminders with flexible recurrence rules:

```swift
// Every day
let daily = RecurrenceRule.daily()

// Every week on Monday, Wednesday, and Friday
let weekdays = RecurrenceRule.weekly(
    daysOfWeek: [.every(.monday), .every(.wednesday), .every(.friday)]
)

// First Monday of every month
let firstMonday = RecurrenceRule.monthly(daysOfWeek: [.first(.monday)])

// Last Friday of every month, for 12 occurrences
let lastFriday = RecurrenceRule.monthly(
    daysOfWeek: [.last(.friday)],
    end: .afterOccurrences(12)
)

// Every 2 weeks, ending on a specific date
let biweekly = RecurrenceRule.weekly(
    interval: 2,
    end: .afterDate(endDate)
)

// Create a recurring reminder
let reminder = try await reminderService.createReminder(
    title: "Team Meeting",
    recurrenceRules: [firstMonday],
    in: myList
)
```

Recurrence rules support:
- **Frequencies**: Daily, weekly, monthly, yearly
- **Intervals**: Every X days/weeks/months/years
- **Specific days**: Particular weekdays or days of the month
- **Positional rules**: First/last/nth occurrence (e.g., "first Monday", "last Friday")
- **End conditions**: Never, after a specific date, or after X occurrences
- **Multiple rules**: Combine rules for complex patterns

### Start Date vs. Due Date

The library supports both `startDate` and `dueDate` for flexible task planning:

```swift
// Simple reminder with just a due date (like Apple Reminders app)
let simple = try await reminderService.createReminder(
    title: "Finish report",
    dueDate: friday,
    in: myList
)
// reminder.plannedDate == friday (falls back to dueDate)

// Reminder with planned start and deadline
let complex = try await reminderService.createReminder(
    title: "Write thesis",
    startDate: monday,    // When you plan to start
    dueDate: friday,      // When it must be done
    in: myList
)
// reminder.plannedDate == monday (prefers startDate)
// reminder.hasDeadline == true
```

**Semantics:**
- `dueDate` alone: Compatible with Apple Reminders app behaviour (single "date" field)
- `startDate` + `dueDate`: Planned start time + deadline
- `plannedDate`: Computed property that returns `startDate ?? dueDate`
- `hasDeadline`: `true` when both dates are set

### Alarms and Notifications

Full support for reminder notifications with three alarm types:

```swift
// Time-based alarms - notify at specific times
let absoluteAlarm = Alarm.absolute(date: specificDate)
let relativeBefore = Alarm.relative(minutes: -15)  // 15 minutes before
let oneHourBefore = Alarm.relative(hours: -1)
let oneDayBefore = Alarm.relative(days: -1)

// Location-based alarms - notify when entering/leaving a location
let office = StructuredLocation.location(
    title: "Office",
    latitude: 52.520008,
    longitude: 13.404954,
    radius: 100  // metres
)
let leaveOfficeAlarm = Alarm.location(location: office, proximity: .leave)
let arriveHomeAlarm = Alarm.location(location: home, proximity: .enter)

// Multiple alarms on one reminder
let reminder = try await reminderService.createReminder(
    title: "Important Meeting",
    dueDate: meetingTime,
    alarms: [
        .relative(days: -1),      // Day before
        .relative(hours: -1),     // Hour before
        .relative(minutes: -15)   // 15 minutes before
    ],
    in: myList
)
```

**Alarm types:**
- **Absolute**: Fire at a specific date/time
- **Relative**: Fire X minutes/hours/days before the reminder's due date or start date
- **Location-based**: Fire when entering or leaving a geofenced location

### Location Support

Reminders can have location information:

```swift
// Simple text location
let reminder1 = try await reminderService.createReminder(
    title: "Buy groceries",
    location: "Supermarket",  // String only, no coordinates
    in: myList
)

// Location-based reminder with geofenced alarm
let supermarket = StructuredLocation.location(
    title: "Tesco",
    latitude: 51.5074,
    longitude: -0.1278,
    radius: 50
)

let reminder2 = try await reminderService.createReminder(
    title: "Buy milk",
    alarms: [.location(location: supermarket, proximity: .enter)],
    location: "Tesco",  // Text for display
    in: myList
)
// Notification fires when you arrive at the supermarket!
```

**Important:**
- `EKReminder` only supports `location: String?` (simple text)
- For geofencing/coordinates, use location-based **alarms** (via `StructuredLocation`)
- You can combine both: text location for display + location alarm for triggers

## What's Included

### EventKit Integration
- CRUD operations for reminders and reminder lists
- **Full recurrence rule support** for repeating reminders (daily, weekly, monthly, yearly)
- **Start date and due date support** for flexible task planning
- **Alarm/notification support** (time-based and location-based triggers)
- **Location support** for reminders
- Calendar event fetching
- Tag extraction from notes (e.g., `#work`, `#important`)
- Priority enum mapping to EventKit values
- Meeting link detection (Teams, Zoom, Google Meet)

### Services
- `PermissionService` - EventKit authorisation handling
- `ReminderService` - Reminder and reminder list management
- `CalendarService` - Calendar event fetching

All services use `@Observable` and are async/await throughout.

## Testing

The project uses Swift Testing (not XCTest).

**Important**: EventKit has known issues with command-line test execution. Tests may crash with Signal 5 when running `swift test` from the terminal. This is an EventKit limitation, not a bug in this library.

**Recommended**: Run tests in Xcode (Cmd+U) where they work reliably.

For CI/CD, you'll need to either use Xcode-based test runners or exclude EventKit-dependent tests.

## Code Style

- All documentation is written in British English
- Commit messages follow Conventional Commits
- All source files must include the EUPL 1.2 licence header
- Swift 6 strict concurrency is enforced

## Known Limitations

- No support for event creation (read-only calendar integration)
- Tag format is fixed to `#tagname` - no customisation
- Priority mapping is opinionated (1-4 = high, 5 = medium, 6-9 = low)
- Command-line testing is unreliable due to EventKit

## Project Structure

```
Sources/KinjoCore/
  ├── Models/
  │   ├── Reminder, ReminderList, Event, Calendar
  │   ├── RecurrenceRule, RecurrenceFrequency, RecurrenceEnd, RecurrenceDayOfWeek
  │   ├── Alarm, AlarmProximity, StructuredLocation
  │   ├── Priority, DateRangeFilter, TagFilter, etc.
  └── Services/
      ├── ReminderService, CalendarService, PermissionService

Tests/KinjoCoreTests/
  └── ...          # Swift Testing test suites
```

## License

Licensed under the EUPL 1.2 (European Union Public Licence v. 1.2).

See https://joinup.ec.europa.eu/software/page/eupl for details.

## Technical Notes

### EventKit & SwiftData
This library uses EventKit for reminders/calendars and SwiftData for app-specific data. SwiftData models are configured with iCloud sync enabled.

### Swift 6 Concurrency
All services are designed for Swift 6's strict concurrency model. Most operations require `@MainActor` context due to EventKit's requirements.

### Meeting Link Detection
Meeting links are detected via pattern matching on URLs in both the `url` field and `notes`/`title` text fields. Supported platforms:
- Microsoft Teams (teams.microsoft.com, teams.live.com)
- Google Meet (meet.google.com)
- Zoom (zoom.us, zoomgov.com)
