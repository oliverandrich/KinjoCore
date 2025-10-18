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

## What's Included

### EventKit Integration
- CRUD operations for reminders and reminder lists
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

- No support for recurring reminders (not needed for my use cases)
- No support for event creation (read-only calendar integration)
- Tag format is fixed to `#tagname` - no customisation
- Priority mapping is opinionated (1-4 = high, 5 = medium, 6-9 = low)
- Command-line testing is unreliable due to EventKit

## Project Structure

```
Sources/KinjoCore/
  ├── Models/      # Reminder, Event, ReminderList, Priority
  └── Services/    # ReminderService, CalendarService, PermissionService

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
