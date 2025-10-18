#!/usr/bin/env swift

import EventKit
import Foundation

// Script to inspect all available properties of EKReminder objects

let store = EKEventStore()

// Request access
print("🔍 Inspecting Reminders Database\n")
print("Requesting access to Reminders...")

let semaphore = DispatchSemaphore(value: 0)
var hasAccess = false

#if os(macOS)
if #available(macOS 14.0, *) {
    Task {
        hasAccess = try await store.requestFullAccessToReminders()
        semaphore.signal()
    }
} else {
    store.requestAccess(to: .reminder) { granted, error in
        hasAccess = granted
        semaphore.signal()
    }
}
#else
store.requestAccess(to: .reminder) { granted, error in
    hasAccess = granted
    semaphore.signal()
}
#endif

semaphore.wait()

guard hasAccess else {
    print("❌ Access to Reminders denied. Please grant access in System Settings.\n")
    exit(1)
}

print("✅ Access granted\n")

// Fetch all reminder lists
let calendars = store.calendars(for: .reminder)
print("📋 Found \(calendars.count) reminder list(s)\n")

// Fetch all reminders
let predicate = store.predicateForReminders(in: calendars)
var allReminders: [EKReminder] = []

let fetchSemaphore = DispatchSemaphore(value: 0)
store.fetchReminders(matching: predicate) { reminders in
    allReminders = reminders ?? []
    fetchSemaphore.signal()
}
fetchSemaphore.wait()

print("📝 Found \(allReminders.count) reminder(s) total\n")

if allReminders.isEmpty {
    print("No reminders to inspect.\n")
    exit(0)
}

// Filter for reminders with interesting properties
let remindersWithURLs = allReminders.filter { $0.url != nil }
let remindersWithAlarms = allReminders.filter { $0.hasAlarms }
let remindersWithRecurrence = allReminders.filter { $0.hasRecurrenceRules }

print("🔍 Found \(remindersWithURLs.count) reminder(s) with URLs")
print("🔍 Found \(remindersWithAlarms.count) reminder(s) with alarms")
print("🔍 Found \(remindersWithRecurrence.count) reminder(s) with recurrence rules\n")

// Helper function to format optional values
func formatOptional<T>(_ value: T?) -> String {
    if let value = value {
        return "\(value)"
    }
    return "nil"
}

func formatDate(_ date: Date?) -> String {
    guard let date = date else { return "nil" }
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

func formatDateComponents(_ components: DateComponents?) -> String {
    guard let components = components else { return "nil" }
    let date = components.date
    return formatDate(date) + " (components: \(components))"
}

// Prioritize interesting reminders for inspection
var remindersToInspect: [EKReminder] = []
remindersToInspect.append(contentsOf: remindersWithURLs.prefix(3))
remindersToInspect.append(contentsOf: remindersWithAlarms.prefix(2))
remindersToInspect.append(contentsOf: remindersWithRecurrence.prefix(2))

// If we don't have enough interesting ones, add some regular ones
if remindersToInspect.count < 5 {
    let remaining = 5 - remindersToInspect.count
    let alreadyIncludedIDs = Set(remindersToInspect.map { $0.calendarItemIdentifier })
    let others = allReminders.filter { !alreadyIncludedIDs.contains($0.calendarItemIdentifier) }
    remindersToInspect.append(contentsOf: others.prefix(remaining))
}

// Inspect each reminder
for (index, reminder) in remindersToInspect.prefix(5).enumerated() {
    print("─────────────────────────────────────────────────────────")
    print("📌 Reminder #\(index + 1)")
    print("─────────────────────────────────────────────────────────")

    // Currently used properties (in our Reminder model)
    print("\n✓ CURRENTLY USED IN MODEL:")
    print("  calendarItemIdentifier: \(reminder.calendarItemIdentifier)")
    print("  title: \(formatOptional(reminder.title))")
    print("  notes: \(formatOptional(reminder.notes))")
    print("  dueDateComponents: \(formatDateComponents(reminder.dueDateComponents))")
    print("  priority: \(reminder.priority)")
    print("  isCompleted: \(reminder.isCompleted)")
    print("  creationDate: \(formatDate(reminder.creationDate))")
    print("  calendar.identifier: \(formatOptional(reminder.calendar?.calendarIdentifier))")
    print("  calendar.title: \(formatOptional(reminder.calendar?.title))")

    // Additional properties not currently used
    print("\n⚠️  AVAILABLE BUT NOT USED:")

    // Dates and timestamps
    print("\n  📅 Dates:")
    print("    completionDate: \(formatDate(reminder.completionDate))")
    print("    lastModifiedDate: \(formatDate(reminder.lastModifiedDate))")
    print("    startDateComponents: \(formatDateComponents(reminder.startDateComponents))")

    // Alarms
    print("\n  ⏰ Alarms:")
    print("    hasAlarms: \(reminder.hasAlarms)")
    if let alarms = reminder.alarms, !alarms.isEmpty {
        print("    alarms.count: \(alarms.count)")
        for (i, alarm) in alarms.enumerated() {
            if let absoluteDate = alarm.absoluteDate {
                print("      [\(i)] Absolute: \(formatDate(absoluteDate))")
            } else {
                print("      [\(i)] Relative: \(alarm.relativeOffset) seconds")
            }
            print("      [\(i)] Proximity: \(alarm.proximity.rawValue)")
        }
    } else {
        print("    alarms: nil")
    }

    // Recurrence
    print("\n  🔁 Recurrence:")
    print("    hasRecurrenceRules: \(reminder.hasRecurrenceRules)")
    if let rules = reminder.recurrenceRules, !rules.isEmpty {
        print("    recurrenceRules.count: \(rules.count)")
        for (i, rule) in rules.enumerated() {
            print("      [\(i)] Frequency: \(rule.frequency.rawValue)")
            print("      [\(i)] Interval: \(rule.interval)")
            if let end = rule.recurrenceEnd {
                if let endDate = end.endDate {
                    print("      [\(i)] End date: \(formatDate(endDate))")
                }
                if end.occurrenceCount > 0 {
                    print("      [\(i)] Occurrences: \(end.occurrenceCount)")
                }
            }
        }
    } else {
        print("    recurrenceRules: nil")
    }

    // URL
    print("\n  🔗 Links:")
    print("    url: \(formatOptional(reminder.url))")

    // Attendees (rarely used for reminders, more for events)
    print("\n  👥 Attendees:")
    print("    hasAttendees: \(reminder.hasAttendees)")
    if let attendees = reminder.attendees, !attendees.isEmpty {
        print("    attendees.count: \(attendees.count)")
    } else {
        print("    attendees: nil")
    }

    // Time zone
    print("\n  🌍 Time Zone:")
    print("    timeZone: \(formatOptional(reminder.timeZone?.identifier))")

    // Location (Note: basic location only, structuredLocation is for EKEvent)
    print("\n  📍 Location:")
    print("    location: \(formatOptional(reminder.location))")

    print()
}

if allReminders.count > remindersToInspect.count {
    print("... and \(allReminders.count - remindersToInspect.count) more reminder(s)")
    print()
}

// Summary
print("═════════════════════════════════════════════════════════")
print("📊 SUMMARY OF AVAILABLE FIELDS")
print("═════════════════════════════════════════════════════════")
print()
print("Currently used in Reminder model (8 fields):")
print("  ✓ calendarItemIdentifier (id)")
print("  ✓ title")
print("  ✓ notes")
print("  ✓ dueDateComponents (as dueDate)")
print("  ✓ priority")
print("  ✓ isCompleted")
print("  ✓ creationDate")
print("  ✓ calendar.calendarIdentifier (as calendarID)")
print()
print("Available but NOT used:")
print("  ⚠️  completionDate - When reminder was completed")
print("  ⚠️  lastModifiedDate - Last edit timestamp")
print("  ⚠️  startDateComponents - Start date for timed reminders")
print("  ⚠️  alarms - Alert/notification settings")
print("  ⚠️  recurrenceRules - Repeating reminder configuration")
print("  ⚠️  url - Associated web link")
print("  ⚠️  timeZone - Timezone for dates")
print("  ⚠️  location - Location-based reminders")
print("  ⚠️  attendees - Shared reminder participants (rare)")
print()
print("Most useful additions for the model would likely be:")
print("  1. alarms - Very commonly used")
print("  2. recurrenceRules - For repeating reminders")
print("  3. url - Often used for reference links")
print("  4. completionDate - Useful for completed reminders")
print("  5. lastModifiedDate - Good for sync/conflict resolution")
print()
