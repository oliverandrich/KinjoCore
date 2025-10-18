#!/usr/bin/env swift

import EventKit
import Foundation

let store = EKEventStore()

print("🔍 Searching for '#tag4' in Reminders\n")

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

print("Searching through \(allReminders.count) reminders...\n")

// Search for #tag4 in notes
let withTag4 = allReminders.filter {
    guard let notes = $0.notes else { return false }
    return notes.contains("#tag4")
}

if withTag4.isEmpty {
    print("❌ No reminders found with '#tag4' in notes\n")

    // Also search in title
    let withTag4InTitle = allReminders.filter {
        guard let title = $0.title else { return false }
        return title.contains("#tag4")
    }

    if !withTag4InTitle.isEmpty {
        print("✅ Found \(withTag4InTitle.count) reminder(s) with '#tag4' in TITLE:")
        for reminder in withTag4InTitle {
            print("\n─────────────────────────────────────")
            print("Title: \(reminder.title ?? "Untitled")")
            print("List: \(reminder.calendar?.title ?? "Unknown")")
            print("Completed: \(reminder.isCompleted)")
            if let notes = reminder.notes {
                print("Notes: \(notes)")
            }
        }
    } else {
        print("❌ Also no reminders with '#tag4' in title\n")
    }
} else {
    print("✅ Found \(withTag4.count) reminder(s) with '#tag4' in notes:\n")

    for reminder in withTag4 {
        print("─────────────────────────────────────")
        print("Title: \(reminder.title ?? "Untitled")")
        print("List: \(reminder.calendar?.title ?? "Unknown")")
        print("Completed: \(reminder.isCompleted)")
        print("Notes: \(reminder.notes ?? "")")
        print()
    }
}
