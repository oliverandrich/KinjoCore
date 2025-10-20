# Working with Filters and SmartFilters

Learn how to filter reminders and create custom SmartFilter views with KinjoCore.

## Overview

KinjoCore provides a powerful filtering system for reminders, including built-in filters, custom SmartFilters with SwiftData persistence, and various filter criteria types.

## Basic Filtering

### Completion Status

Filter reminders by their completion status:

```swift
@Environment(ReminderService.self) private var reminderService

// Fetch only incomplete reminders
let incomplete = try await reminderService.fetchReminders(
    from: .all,
    filter: .incomplete
)

// Fetch only completed reminders
let completed = try await reminderService.fetchReminders(
    from: .all,
    filter: .completed
)

// Fetch all reminders
let all = try await reminderService.fetchReminders(
    from: .all,
    filter: .all
)
```

### Date Range Filtering

Filter by when reminders are due:

```swift
// Today's tasks
let today = try await reminderService.fetchReminders(
    from: .all,
    dateRange: .today
)

// This week
let thisWeek = try await reminderService.fetchReminders(
    from: .all,
    dateRange: .thisWeek
)

// Custom date range
let calendar = Calendar.current
let start = calendar.startOfDay(for: Date())
let end = calendar.date(byAdding: .day, value: 7, to: start)!
let custom = try await reminderService.fetchReminders(
    from: .all,
    dateRange: .custom(start: start, end: end)
)

// All reminders (no date filter)
let allDates = try await reminderService.fetchReminders(
    from: .all,
    dateRange: .all
)
```

### Tag Filtering

Filter reminders by tags extracted from their notes:

```swift
// Has specific tag
let shopping = try await reminderService.fetchReminders(
    from: .all,
    tagFilter: .hasTag("shopping")
)

// Has any of these tags
let personal = try await reminderService.fetchReminders(
    from: .all,
    tagFilter: .hasAnyTag(["home", "family", "personal"])
)

// Has all of these tags
let urgent = try await reminderService.fetchReminders(
    from: .all,
    tagFilter: .hasAllTags(["urgent", "work"])
)

// Inverted filters (exclusion)
let notWork = try await reminderService.fetchReminders(
    from: .all,
    tagFilter: .notHasTag("work")
)

let noPersonal = try await reminderService.fetchReminders(
    from: .all,
    tagFilter: .notHasAnyTag(["home", "family"])
)
```

### Text Search

Search in reminder titles and notes:

```swift
// Search in both title and notes
let results = try await reminderService.fetchReminders(
    from: .all,
    textSearch: .both("meeting")
)

// Search only in title
let titleSearch = try await reminderService.fetchReminders(
    from: .all,
    textSearch: .titleOnly("urgent")
)

// Search only in notes
let notesSearch = try await reminderService.fetchReminders(
    from: .all,
    textSearch: .notesOnly("#project")
)
```

### Reminder List Selection

Control which reminder lists to fetch from:

```swift
// All lists
let all = try await reminderService.fetchReminders(from: .all)

// Specific lists
let workList = reminderService.reminderLists.first { $0.title == "Work" }!
let specific = try await reminderService.fetchReminders(
    from: .specific([workList])
)

// Multiple lists
let lists = reminderService.reminderLists.filter {
    ["Work", "Personal"].contains($0.title)
}
let multiple = try await reminderService.fetchReminders(
    from: .specific(lists)
)

// Exclude specific lists
let excludeCompleted = reminderService.reminderLists.first {
    $0.title == "Completed"
}!
let excluded = try await reminderService.fetchReminders(
    from: .excluding([excludeCompleted])
)
```

## Combining Filters

All filters can be combined for complex queries:

```swift
let filtered = try await reminderService.fetchReminders(
    from: .specific([workList]),
    filter: .incomplete,
    dateRange: .thisWeek,
    tagFilter: .hasTag("urgent"),
    textSearch: .both("meeting"),
    sortBy: .dueDate
)
```

## Sorting

Control the order of returned reminders:

```swift
// Sort by due date
let byDate = try await reminderService.fetchReminders(
    from: .all,
    sortBy: .dueDate
)

// Sort by priority
let byPriority = try await reminderService.fetchReminders(
    from: .all,
    sortBy: .priority
)

// Sort by title
let byTitle = try await reminderService.fetchReminders(
    from: .all,
    sortBy: .title
)

// Sort by creation date
let byCreation = try await reminderService.fetchReminders(
    from: .all,
    sortBy: .creationDate
)
```

## SmartFilter System

SmartFilters allow you to create and persist custom filter configurations with iCloud sync.

### Setting Up SmartFilterService

```swift
import SwiftUI
import SwiftData
import KinjoCore

@main
struct MyApp: App {
    let modelContainer: ModelContainer
    let smartFilterService: SmartFilterService

    init() {
        do {
            // Set up SwiftData with iCloud sync
            let schema = Schema([SmartFilter.self])
            let config = ModelConfiguration(
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )

            // Initialise SmartFilterService
            smartFilterService = SmartFilterService(
                groupIdentifier: "group.com.yourapp.kinjocore"
            )
        } catch {
            fatalError("Failed to initialise ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(smartFilterService)
                .modelContainer(modelContainer)
        }
    }
}
```

### Built-In Filters

SmartFilterService provides six built-in filters that cannot be deleted:

```swift
@Environment(SmartFilterService.self) private var filterService

// Fetch filters (creates built-ins on first run)
try await filterService.fetchFilters()

// Built-in filters:
// - All: All incomplete reminders
// - Today: Due today
// - Tomorrow: Due tomorrow
// - This Week: Due this week
// - Flagged: High priority reminders
// - Completed: Completed reminders
```

### Creating Custom SmartFilters

```swift
@Environment(SmartFilterService.self) private var filterService
@Environment(ReminderService.self) private var reminderService

// Create a work filter
let workList = reminderService.reminderLists.first { $0.title == "Work" }!
let workFilter = try await filterService.createFilter(
    name: "Work Tasks",
    iconName: "briefcase.fill",
    tintColor: .blue,
    criteria: FilterCriteria(
        listSelection: .specific([workList.id]),
        completionFilter: .incomplete,
        dateRangeFilter: .all,
        tagFilter: nil,
        textSearch: nil,
        sortBy: .priority
    )
)

// Create an urgent filter
let urgentFilter = try await filterService.createFilter(
    name: "Urgent",
    iconName: "exclamationmark.triangle.fill",
    tintColor: .red,
    criteria: FilterCriteria(
        listSelection: .all,
        completionFilter: .incomplete,
        dateRangeFilter: .all,
        tagFilter: .hasTag("urgent"),
        textSearch: nil,
        sortBy: .dueDate
    )
)
```

### Using SmartFilters

```swift
struct FilteredRemindersView: View {
    @Environment(SmartFilterService.self) private var filterService
    @Environment(ReminderService.self) private var reminderService
    let filter: SmartFilter

    @State private var reminders: [Reminder] = []

    var body: some View {
        List(reminders) { reminder in
            ReminderRow(reminder: reminder)
        }
        .navigationTitle(filter.name)
        .task {
            await loadReminders()
        }
    }

    func loadReminders() async {
        do {
            // Fetch reminder lists first
            try await reminderService.fetchReminderLists()

            // Apply the filter
            reminders = try await filterService.applyFilter(
                filter,
                with: reminderService
            )
        } catch {
            print("Error loading reminders: \(error)")
        }
    }
}
```

### Updating SmartFilters

```swift
// Update filter properties
let updated = try await filterService.updateFilter(
    filter,
    name: "Work - High Priority",
    iconName: "star.fill",
    tintColor: .orange,
    criteria: FilterCriteria(
        listSelection: .specific([workList.id]),
        completionFilter: .incomplete,
        dateRangeFilter: .thisWeek,
        tagFilter: .hasTag("urgent"),
        textSearch: nil,
        sortBy: .priority
    )
)
```

### Deleting SmartFilters

```swift
// Delete custom filter (built-in filters cannot be deleted)
try await filterService.deleteFilter(customFilter)
```

### Reordering SmartFilters

```swift
// Change display order
let reordered = [filter3, filter1, filter2]
try await filterService.reorderFilters(reordered)
```

## FilterCriteria

The ``FilterCriteria`` struct provides a serialisable representation of filter settings:

```swift
let criteria = FilterCriteria(
    listSelection: .all,
    completionFilter: .incomplete,
    dateRangeFilter: .thisWeek,
    tagFilter: .hasAnyTag(["work", "urgent"]),
    textSearch: .both("meeting"),
    sortBy: .dueDate
)

// Convert to ReminderListSelection
let selection = criteria.toReminderListSelection(
    availableLists: reminderService.reminderLists
)

// Create from ReminderListSelection
let fromSelection = FilterCriteria.listSelectionFrom(.all)
```

## Tips and Best Practices

1. **Use SmartFilters for common views**: Create filters for your daily workflows
2. **Combine multiple criteria**: Mix date ranges, tags, and text search for precise results
3. **Built-in filters are templates**: Study them to understand effective filter combinations
4. **iCloud sync**: SmartFilters automatically sync across devices via SwiftData
5. **Test filter performance**: Complex filters on large reminder sets may take time
6. **Use exclusion filters**: Sometimes it's easier to exclude than include

## See Also

- ``SmartFilterService``
- ``SmartFilter``
- ``FilterCriteria``
- ``ReminderFilter``
- ``DateRangeFilter``
- ``TagFilter``
- ``TextSearchFilter``
- ``ReminderListSelection``
- ``ReminderSortOption``
