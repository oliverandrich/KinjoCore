#!/usr/bin/env swift

import EventKit
import Foundation

let store = EKEventStore()

print("🔍 Searching for 'Reifen auf Alpin Symbol prüfen'\n")

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

// Find the reminder
guard let reminder = allReminders.first(where: { $0.title == "Reifen auf Alpin Symbol prüfen" }) else {
    print("❌ Reminder not found\n")
    print("Available reminders in 'Privat':")
    let privatReminders = allReminders.filter { $0.calendar?.title == "Privat" }
    for r in privatReminders {
        print("  - \(r.title ?? "Untitled")")
    }
    exit(1)
}

print("✅ Found reminder!\n")
print("═══════════════════════════════════════════════════════════════")
print("COMPLETE FIELD DUMP FOR: \(reminder.title ?? "Untitled")")
print("═══════════════════════════════════════════════════════════════\n")

// Helper function
func format<T>(_ value: T?) -> String {
    guard let value = value else { return "nil" }
    return "\(value)"
}

func formatDate(_ date: Date?) -> String {
    guard let date = date else { return "nil" }
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .full
    return formatter.string(from: date)
}

print("━━━ IDENTITY ━━━")
print("calendarItemIdentifier: \(reminder.calendarItemIdentifier)")
print("calendarItemExternalIdentifier: \(format(reminder.calendarItemExternalIdentifier))")
print()

print("━━━ BASIC INFO ━━━")
print("title: \(format(reminder.title))")
print("notes: \(format(reminder.notes))")
print()

print("━━━ DATES & TIME ━━━")
print("creationDate: \(formatDate(reminder.creationDate))")
print("lastModifiedDate: \(formatDate(reminder.lastModifiedDate))")
print("completionDate: \(formatDate(reminder.completionDate))")
print()
print("dueDateComponents: \(format(reminder.dueDateComponents))")
if let components = reminder.dueDateComponents {
    print("  -> date: \(formatDate(components.date))")
    print("  -> year: \(format(components.year))")
    print("  -> month: \(format(components.month))")
    print("  -> day: \(format(components.day))")
    print("  -> hour: \(format(components.hour))")
    print("  -> minute: \(format(components.minute))")
    print("  -> calendar: \(format(components.calendar?.identifier))")
    print("  -> timeZone: \(format(components.timeZone?.identifier))")
}
print()
print("startDateComponents: \(format(reminder.startDateComponents))")
if let components = reminder.startDateComponents {
    print("  -> date: \(formatDate(components.date))")
}
print()
print("timeZone: \(format(reminder.timeZone?.identifier))")
print()

print("━━━ STATUS ━━━")
print("isCompleted: \(reminder.isCompleted)")
print("priority: \(reminder.priority)")
print()

print("━━━ CALENDAR/LIST ━━━")
print("calendar.calendarIdentifier: \(format(reminder.calendar?.calendarIdentifier))")
print("calendar.title: \(format(reminder.calendar?.title))")
print("calendar.type: \(format(reminder.calendar?.type.rawValue))")
print("calendar.allowsContentModifications: \(format(reminder.calendar?.allowsContentModifications))")
print("calendar.isImmutable: \(format(reminder.calendar?.isImmutable))")
print("calendar.isSubscribed: \(format(reminder.calendar?.isSubscribed))")
if let source = reminder.calendar?.source {
    print("calendar.source.title: \(source.title)")
    print("calendar.source.sourceType: \(source.sourceType.rawValue)")
}
print()

print("━━━ ALARMS ━━━")
print("hasAlarms: \(reminder.hasAlarms)")
if let alarms = reminder.alarms, !alarms.isEmpty {
    print("alarms.count: \(alarms.count)")
    for (i, alarm) in alarms.enumerated() {
        print("\n[Alarm #\(i)]")
        if let absoluteDate = alarm.absoluteDate {
            print("  absoluteDate: \(formatDate(absoluteDate))")
        } else {
            print("  relativeOffset: \(alarm.relativeOffset) seconds")
        }
        print("  proximity: \(alarm.proximity.rawValue)")
        print("  type: \(alarm.type.rawValue)")
    }
} else {
    print("alarms: nil")
}
print()

print("━━━ RECURRENCE ━━━")
print("hasRecurrenceRules: \(reminder.hasRecurrenceRules)")
if let rules = reminder.recurrenceRules, !rules.isEmpty {
    print("recurrenceRules.count: \(rules.count)")
    for (i, rule) in rules.enumerated() {
        print("\n[Rule #\(i)]")
        print("  frequency: \(rule.frequency.rawValue)")
        print("  interval: \(rule.interval)")
        print("  firstDayOfTheWeek: \(rule.firstDayOfTheWeek)")
        if let daysOfWeek = rule.daysOfTheWeek {
            print("  daysOfTheWeek: \(daysOfWeek.map { $0.dayOfTheWeek.rawValue })")
        }
        if let daysOfMonth = rule.daysOfTheMonth {
            print("  daysOfTheMonth: \(daysOfMonth)")
        }
        if let daysOfYear = rule.daysOfTheYear {
            print("  daysOfYear: \(daysOfYear)")
        }
        if let weeksOfYear = rule.weeksOfTheYear {
            print("  weeksOfYear: \(weeksOfYear)")
        }
        if let monthsOfYear = rule.monthsOfTheYear {
            print("  monthsOfYear: \(monthsOfYear)")
        }
        if let setPositions = rule.setPositions {
            print("  setPositions: \(setPositions)")
        }
        if let end = rule.recurrenceEnd {
            if let endDate = end.endDate {
                print("  recurrenceEnd.endDate: \(formatDate(endDate))")
            }
            if end.occurrenceCount > 0 {
                print("  recurrenceEnd.occurrenceCount: \(end.occurrenceCount)")
            }
        }
    }
} else {
    print("recurrenceRules: nil")
}
print()

print("━━━ LOCATION ━━━")
print("location: \(format(reminder.location))")
print()

print("━━━ URL ━━━")
print("url: \(format(reminder.url?.absoluteString))")
print()

print("━━━ ATTENDEES ━━━")
print("hasAttendees: \(reminder.hasAttendees)")
if let attendees = reminder.attendees, !attendees.isEmpty {
    print("attendees.count: \(attendees.count)")
    for (i, attendee) in attendees.enumerated() {
        print("\n[Attendee #\(i)]")
        print("  name: \(format(attendee.name))")
        print("  url: \(attendee.url.absoluteString)")
        print("  participantType: \(attendee.participantType.rawValue)")
        print("  participantStatus: \(attendee.participantStatus.rawValue)")
    }
} else {
    print("attendees: nil")
}
print()

print("═══════════════════════════════════════════════════════════════")
print("END OF FIELD DUMP")
print("═══════════════════════════════════════════════════════════════")
