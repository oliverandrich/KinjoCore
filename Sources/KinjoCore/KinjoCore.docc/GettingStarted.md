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

KinjoCore uses three main services that should be injected into your SwiftUI environment:

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
