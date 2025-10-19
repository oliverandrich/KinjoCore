# Working with Recurrence Rules

Learn how to create repeating reminders with complex patterns.

## Overview

KinjoCore provides full support for EventKit's recurrence rules through the ``RecurrenceRule`` type. You can create simple daily/weekly patterns or complex rules like "first Monday of every month" or "last Friday, 12 times".

## Simple Recurrence Patterns

### Daily Reminders

```swift
let dailyRule = RecurrenceRule(frequency: .daily)

let reminder = try await reminderService.createReminder(
    title: "Daily standup",
    dueDate: tomorrow,
    recurrenceRules: [dailyRule],
    in: workList
)
```

### Weekly Reminders

```swift
// Every week
let weeklyRule = RecurrenceRule(frequency: .weekly)

// Every 2 weeks
let biweeklyRule = RecurrenceRule(frequency: .weekly, interval: 2)
```

### Monthly and Yearly

```swift
let monthlyRule = RecurrenceRule(frequency: .monthly)
let yearlyRule = RecurrenceRule(frequency: .yearly)
```

## Specific Days of the Week

Create reminders that repeat on specific weekdays:

```swift
// Every Monday and Friday
let weekdaysRule = RecurrenceRule(
    frequency: .weekly,
    daysOfTheWeek: [.every(.monday), .every(.friday)]
)

// Every Monday and Friday, every 2 weeks, 12 times
let complexRule = RecurrenceRule(
    frequency: .weekly,
    interval: 2,
    daysOfTheWeek: [.every(.monday), .every(.friday)],
    end: .afterOccurrences(12)
)
```

## Positional Rules

KinjoCore supports positional recurrence patterns for advanced use cases:

### First/Last Day Patterns

```swift
// First Monday of every month
let firstMonday = RecurrenceRule(
    frequency: .monthly,
    daysOfTheWeek: [.first(.monday)]
)

// Last Friday of every month
let lastFriday = RecurrenceRule(
    frequency: .monthly,
    daysOfTheWeek: [.last(.friday)]
)

// Second and fourth Tuesday of each month
let tuesdaysRule = RecurrenceRule(
    frequency: .monthly,
    daysOfTheWeek: [.nth(2, .tuesday), .nth(4, .tuesday)]
)
```

### Last Day of Month

```swift
// Last day of every month
let lastDayRule = RecurrenceRule(
    frequency: .monthly,
    daysOfTheMonth: [-1]
)
```

## Ending Recurrence

Control when recurrence stops using ``RecurrenceEnd``:

### Never End

```swift
let infiniteRule = RecurrenceRule(
    frequency: .weekly,
    end: .never  // Default
)
```

### End After Count

```swift
let limitedRule = RecurrenceRule(
    frequency: .daily,
    end: .afterOccurrences(30)  // 30 times
)
```

### End on Date

```swift
let endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
let timedRule = RecurrenceRule(
    frequency: .weekly,
    end: .afterDate(endDate)
)
```

## Updating Reminders with Recurrence

Add or modify recurrence rules on existing reminders:

```swift
let newRule = RecurrenceRule(
    frequency: .weekly,
    daysOfTheWeek: [.every(.monday)]
)

try await reminderService.updateReminder(
    reminder,
    recurrenceRules: [newRule]
)
```

## Advanced Patterns

### Specific Months

```swift
// Every January and July (yearly)
let semiannual = RecurrenceRule(
    frequency: .yearly,
    monthsOfTheYear: [1, 7]
)
```

### Specific Days of Month

```swift
// 1st and 15th of every month
let bimonthly = RecurrenceRule(
    frequency: .monthly,
    daysOfTheMonth: [1, 15]
)
```

### Multiple Rules

Combine multiple recurrence rules for complex patterns:

```swift
// Weekdays (Mon-Fri) AND first Saturday of month
let weekdayRule = RecurrenceRule(
    frequency: .weekly,
    daysOfTheWeek: [
        .every(.monday),
        .every(.tuesday),
        .every(.wednesday),
        .every(.thursday),
        .every(.friday)
    ]
)

let saturdayRule = RecurrenceRule(
    frequency: .monthly,
    daysOfTheWeek: [.first(.saturday)]
)

try await reminderService.createReminder(
    title: "Complex schedule",
    dueDate: startDate,
    recurrenceRules: [weekdayRule, saturdayRule],
    in: list
)
```

## See Also

- ``RecurrenceRule``
- ``RecurrenceFrequency``
- ``RecurrenceEnd``
- ``RecurrenceDayOfWeek``
- ``ReminderService/createReminder(title:notes:startDate:dueDate:priority:recurrenceRules:alarms:location:in:)``
- ``ReminderService/updateReminder(_:title:notes:startDate:dueDate:priority:recurrenceRules:alarms:location:moveTo:)``
