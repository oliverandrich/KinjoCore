# Getting Started with KinjoCore

Learn how to integrate KinjoCore into your iOS or macOS application.

## Overview

This guide walks you through setting up KinjoCore, requesting permissions, and performing basic operations with reminders and calendars.

## Installation

Add KinjoCore to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/oliverandrich/KinjoCore.git", from: "0.9.0")
]
```

## Setting Up Services

KinjoCore provides several services that should be injected into your SwiftUI environment. Some services require additional setup with SwiftData.

### Basic Setup (Without SmartFilters)

For basic reminder and calendar functionality:

```swift
import SwiftUI
import KinjoCore

@main
struct MyApp: App {
    private let permissionService = PermissionService()
    private let reminderService: ReminderService
    private let calendarService: CalendarService

    init() {
        self.reminderService = ReminderService(permissionService: permissionService)
        self.calendarService = CalendarService(permissionService: permissionService)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(permissionService)
                .environment(reminderService)
                .environment(calendarService)
        }
    }
}
```

### Complete Setup (With SmartFilters)

For full functionality including SmartFilters with iCloud sync:

```swift
import SwiftUI
import SwiftData
import KinjoCore

@main
struct MyApp: App {
    // SwiftData Container
    let container: ModelContainer

    // KinjoCore Services
    let permissionService: PermissionService
    let reminderService: ReminderService
    let calendarService: CalendarService
    let smartFilterService: SmartFilterService

    init() {
        // 1. Create ModelContainer with KinjoCore models
        let schema = Schema([
            SmartFilter.self  // Required for SmartFilterService
        ])

        let config = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier("group.com.yourapp.shared"),
            cloudKitDatabase: .automatic  // Enables iCloud sync
        )

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // 2. Initialise KinjoCore services
        permissionService = PermissionService()
        reminderService = ReminderService(permissionService: permissionService)
        calendarService = CalendarService(permissionService: permissionService)
        smartFilterService = SmartFilterService(container: container)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)  // For SwiftUI @Query
                .environment(permissionService)
                .environment(reminderService)
                .environment(calendarService)
                .environment(smartFilterService)
        }
        .task {
            // Ensure built-in filters exist on first launch
            try? await smartFilterService.ensureBuiltInFilters()
        }
    }
}
```

### Adding Your Own SwiftData Models

If your app uses its own SwiftData models alongside KinjoCore:

```swift
let schema = Schema([
    // KinjoCore models
    SmartFilter.self,

    // Your app's models
    MyAppModel.self,
    AnotherModel.self
])
```

> Important: Use a single `ModelContainer` for all SwiftData models (both KinjoCore and your app) to prevent conflicts. Configure the same `groupContainer` identifier for data sharing between targets (app, widgets, extensions).

## Requesting Permissions

Before accessing reminders or calendars, you must request permission from the user:

```swift
struct ContentView: View {
    @Environment(PermissionService.self) private var permissionService

    var body: some View {
        Button("Request Reminder Access") {
            Task {
                let granted = try await permissionService.requestReminderAccess()
                if granted {
                    print("Access granted!")
                }
            }
        }
    }
}
```

## Working with Reminders

### Fetching Reminder Lists

```swift
struct ReminderListsView: View {
    @Environment(ReminderService.self) private var reminderService

    var body: some View {
        List(reminderService.reminderLists) { list in
            Text(list.title)
        }
        .task {
            try? await reminderService.fetchReminderLists()
        }
    }
}
```

### Creating a Reminder List

```swift
let newList = try await reminderService.createReminderList(
    title: "Shopping",
    color: CGColor(red: 0, green: 0.5, blue: 1, alpha: 1),
    sourceType: .calDAV  // Use iCloud for sync
)
```

### Fetching Reminders

```swift
let incompleteReminders = try await reminderService.fetchReminders(
    from: .all,
    filter: .incomplete,
    dateRange: .thisWeek,
    tagFilter: .none,
    sortBy: .dueDate
)
```

### Creating a Reminder

```swift
let newReminder = try await reminderService.createReminder(
    title: "Buy groceries",
    notes: "Milk, bread, eggs #shopping",
    dueDate: tomorrow,
    priority: .high,
    in: shoppingList
)
```

## Working with Calendars

### Fetching Calendars

```swift
let calendars = try await calendarService.fetchCalendars()
```

### Fetching Events

```swift
let thisWeekEvents = try await calendarService.fetchEvents(
    from: .all,
    range: .thisWeek
)
```

## Next Steps

- Learn about <doc:WorkingWithRecurrence> for repeating reminders
- Explore ``TagFilter`` for advanced reminder filtering
- Set up ``Alarm``s with location-based triggers
