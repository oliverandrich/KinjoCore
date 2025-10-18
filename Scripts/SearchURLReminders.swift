#!/usr/bin/env swift

import EventKit
import Foundation

let store = EKEventStore()

print("🔍 Searching for Reminders with URLs\n")
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
    print("❌ Access denied\n")
    exit(1)
}

print("✅ Access granted\n")

// Fetch all reminders
let calendars = store.calendars(for: .reminder)
let predicate = store.predicateForReminders(in: calendars)
var allReminders: [EKReminder] = []

let fetchSemaphore = DispatchSemaphore(value: 0)
store.fetchReminders(matching: predicate) { reminders in
    allReminders = reminders ?? []
    fetchSemaphore.signal()
}
fetchSemaphore.wait()

print("Total reminders: \(allReminders.count)\n")

// Search for URLs
print("Searching for reminders with URLs...\n")

// 1. Check url field
let withURLField = allReminders.filter { $0.url != nil }
print("✅ Found \(withURLField.count) reminder(s) with url field set")
for reminder in withURLField.prefix(5) {
    print("  - \(reminder.title ?? "Untitled")")
    print("    URL: \(reminder.url!.absoluteString)")
    print("    List: \(reminder.calendar?.title ?? "Unknown")")
    print()
}

// 2. Check title for URLs
let withURLInTitle = allReminders.filter {
    guard let title = $0.title else { return false }
    return title.contains("http://") || title.contains("https://")
}
print("✅ Found \(withURLInTitle.count) reminder(s) with URLs in title")
for reminder in withURLInTitle.prefix(5) {
    print("  - \(reminder.title ?? "Untitled")")
    print("    List: \(reminder.calendar?.title ?? "Unknown")")
    print()
}

// 3. Check notes for URLs
let withURLInNotes = allReminders.filter {
    guard let notes = $0.notes else { return false }
    return notes.contains("http://") || notes.contains("https://")
}
print("✅ Found \(withURLInNotes.count) reminder(s) with URLs in notes")
for reminder in withURLInNotes.prefix(5) {
    print("  - \(reminder.title ?? "Untitled")")
    print("    Notes preview: \(String(reminder.notes?.prefix(100) ?? ""))")
    print("    List: \(reminder.calendar?.title ?? "Unknown")")
    print()
}

// 4. Filter by "Privat" list specifically
let privatList = calendars.first { $0.title == "Privat" }
if let privatList = privatList {
    let privatReminders = allReminders.filter { $0.calendar?.calendarIdentifier == privatList.calendarIdentifier }
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("📋 List 'Privat' has \(privatReminders.count) reminder(s)")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

    let privatWithURL = privatReminders.filter { $0.url != nil }
    print("  With url field: \(privatWithURL.count)")

    let privatWithURLInTitle = privatReminders.filter {
        guard let title = $0.title else { return false }
        return title.contains("http://") || title.contains("https://")
    }
    print("  With URL in title: \(privatWithURLInTitle.count)")

    let privatWithURLInNotes = privatReminders.filter {
        guard let notes = $0.notes else { return false }
        return notes.contains("http://") || notes.contains("https://")
    }
    print("  With URL in notes: \(privatWithURLInNotes.count)\n")

    // Show first few
    print("First few reminders from 'Privat':")
    for (i, reminder) in privatReminders.prefix(10).enumerated() {
        print("\n[\(i+1)] \(reminder.title ?? "Untitled")")
        print("    Completed: \(reminder.isCompleted)")
        if let url = reminder.url {
            print("    URL field: \(url.absoluteString)")
        }
        if let notes = reminder.notes, !notes.isEmpty {
            print("    Notes: \(String(notes.prefix(80)))")
        }
    }
} else {
    print("⚠️  No list named 'Privat' found")
    print("Available lists:")
    for calendar in calendars {
        print("  - \(calendar.title)")
    }
}
