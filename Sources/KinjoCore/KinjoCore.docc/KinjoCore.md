# ``KinjoCore``

A Swift framework for managing reminders, tasks, and calendars using EventKit.

## Overview

KinjoCore provides a clean, Swift-native API for integrating with EventKit on iOS and macOS. It wraps EventKit's Objective-C APIs with modern Swift types, async/await support, and seamless SwiftUI integration.

### Key Features

- **Reminder Management**: Create, read, update, and delete reminders with full CRUD operations
- **Calendar Integration**: Access and manage calendars and events
- **Rich Recurrence Support**: Complex repeating patterns with positional rules (e.g., "first Monday", "last Friday")
- **Tag-Based Filtering**: Extract and filter reminders by hashtags in notes
- **Location-Based Alarms**: Geofence-based notifications for reminders
- **iCloud Sync**: Automatic synchronisation across devices via EventKit
- **SwiftUI Ready**: Observable services designed for SwiftUI environment injection

## Topics

### Getting Started

- <doc:GettingStarted>
- <doc:WorkingWithRecurrence>

### Core Services

- ``PermissionService``
- ``ReminderService``
- ``CalendarService``

### Reminder Models

- ``Reminder``
- ``ReminderList``
- ``ReminderFilter``
- ``ReminderListSelection``
- ``ReminderSortOption``
- ``TagFilter``

### Calendar Models

- ``Calendar``
- ``Event``
- ``CalendarSelection``
- ``DateRangeFilter``

### Recurrence & Alarms

- ``RecurrenceRule``
- ``RecurrenceFrequency``
- ``RecurrenceEnd``
- ``RecurrenceDayOfWeek``
- ``Alarm``
- ``AlarmProximity``
- ``StructuredLocation``

### Supporting Types

- ``Priority``
