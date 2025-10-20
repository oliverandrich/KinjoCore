// Copyright (C) 2025 KinjoCore Contributors
//
// Licensed under the EUPL, Version 1.2 or – as soon they will be approved by
// the European Commission - subsequent versions of the EUPL (the "Licence");
// You may not use this work except in compliance with the Licence.
// You may obtain a copy of the Licence at:
//
// https://joinup.ec.europa.eu/software/page/eupl
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the Licence is distributed on an "AS IS" basis,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the Licence for the specific language governing permissions and
// limitations under the Licence.

import Testing
import Foundation
@testable import KinjoCore

@Suite("Reminder Computed Properties Tests")
struct ReminderPropertiesTests {

    // MARK: - Tags Tests

    @Test("Reminder extracts single tag from notes")
    func reminderExtractsSingleTag() {
        let reminder = Reminder.makeTest(
            title: "Test",
            notes: "This is #important"
        )

        #expect(reminder.tags == ["important"])
        #expect(reminder.hasTags == true)
    }

    @Test("Reminder extracts multiple tags from notes")
    func reminderExtractsMultipleTags() {
        let reminder = Reminder.makeTest(
            title: "Test",
            notes: "Meeting #work #urgent #project"
        )

        #expect(reminder.tags.count == 3)
        #expect(reminder.tags.contains("work"))
        #expect(reminder.tags.contains("urgent"))
        #expect(reminder.tags.contains("project"))
        #expect(reminder.hasTags == true)
    }

    @Test("Reminder normalises tag case")
    func reminderNormalisesTagCase() {
        let reminder = Reminder.makeTest(
            title: "Test",
            notes: "#Work #URGENT #Project"
        )

        #expect(reminder.tags == ["project", "urgent", "work"])
    }

    @Test("Reminder handles no tags")
    func reminderHandlesNoTags() {
        let reminder = Reminder.makeTest(
            title: "Test",
            notes: "No tags here"
        )

        #expect(reminder.tags.isEmpty)
        #expect(reminder.hasTags == false)
    }

    @Test("Reminder handles nil notes for tags")
    func reminderHandlesNilNotesForTags() {
        let reminder = Reminder.makeTest(
            title: "Test",
            notes: nil
        )

        #expect(reminder.tags.isEmpty)
        #expect(reminder.hasTags == false)
    }

    // MARK: - hasNote Tests

    @Test("Reminder hasNote returns true for non-empty notes")
    func reminderHasNoteReturnsTrueForNonEmptyNotes() {
        let reminder = Reminder.makeTest(
            title: "Test",
            notes: "Some notes"
        )

        #expect(reminder.hasNote == true)
    }

    @Test("Reminder hasNote returns false for nil notes")
    func reminderHasNoteReturnsFalseForNilNotes() {
        let reminder = Reminder.makeTest(
            title: "Test",
            notes: nil
        )

        #expect(reminder.hasNote == false)
    }

    @Test("Reminder hasNote returns false for whitespace-only notes")
    func reminderHasNoteReturnsFalseForWhitespaceNotes() {
        let reminder = Reminder.makeTest(
            title: "Test",
            notes: "   \n\t  "
        )

        #expect(reminder.hasNote == false)
    }

    // MARK: - hasURL Tests

    @Test("Reminder hasURL detects URL in url field")
    func reminderHasURLDetectsURLInURLField() {
        let reminder = Reminder.makeTest(
            title: "Test",
            url: URL(string: "https://example.com")
        )

        #expect(reminder.hasURL == true)
    }

    @Test("Reminder hasURL detects URL in title")
    func reminderHasURLDetectsURLInTitle() {
        let reminder = Reminder.makeTest(
            title: "Check https://example.com",
            notes: nil
        )

        #expect(reminder.hasURL == true)
    }

    @Test("Reminder hasURL detects URL in notes")
    func reminderHasURLDetectsURLInNotes() {
        let reminder = Reminder.makeTest(
            title: "Test",
            notes: "Visit https://docs.example.com for details"
        )

        #expect(reminder.hasURL == true)
    }

    @Test("Reminder hasURL returns false when no URLs present")
    func reminderHasURLReturnsFalseWhenNoURLs() {
        let reminder = Reminder.makeTest(
            title: "Regular reminder",
            notes: "No URLs here"
        )

        #expect(reminder.hasURL == false)
    }

    // MARK: - hasRecurrenceRules Tests

    @Test("Reminder hasRecurrenceRules returns true when rules exist")
    func reminderHasRecurrenceRulesReturnsTrueWhenRulesExist() {
        let recurrenceRule = RecurrenceRule(frequency: .daily)

        let reminder = Reminder.makeTest(
            title: "Test",
            recurrenceRules: [recurrenceRule]
        )

        #expect(reminder.hasRecurrenceRules == true)
    }

    @Test("Reminder hasRecurrenceRules returns false when no rules")
    func reminderHasRecurrenceRulesReturnsFalseWhenNoRules() {
        let reminder = Reminder.makeTest(
            title: "Test"
        )

        #expect(reminder.hasRecurrenceRules == false)
    }

    // MARK: - hasAlarms Tests

    @Test("Reminder hasAlarms returns true when alarms exist")
    func reminderHasAlarmsReturnsTrueWhenAlarmsExist() {
        let alarm = Alarm.relative(offset: -3600) // 1 hour before

        let reminder = Reminder.makeTest(
            title: "Test",
            alarms: [alarm]
        )

        #expect(reminder.hasAlarms == true)
    }

    @Test("Reminder hasAlarms returns false when no alarms")
    func reminderHasAlarmsReturnsFalseWhenNoAlarms() {
        let reminder = Reminder.makeTest(
            title: "Test"
        )

        #expect(reminder.hasAlarms == false)
    }

    // MARK: - hasLocation Tests

    @Test("Reminder hasLocation returns true when location is set")
    func reminderHasLocationReturnsTrueWhenLocationSet() {
        let reminder = Reminder.makeTest(
            title: "Test",
            location: "Office"
        )

        #expect(reminder.hasLocation == true)
        #expect(reminder.location == "Office")
    }

    @Test("Reminder hasLocation returns false when no location")
    func reminderHasLocationReturnsFalseWhenNoLocation() {
        let reminder = Reminder.makeTest(
            title: "Test"
        )

        #expect(reminder.hasLocation == false)
    }

    // MARK: - plannedDate Tests

    @Test("Reminder plannedDate returns startDate when both dates set")
    func reminderPlannedDateReturnsStartDateWhenBothSet() {
        let startDate = Date()
        let dueDate = Date(timeIntervalSinceNow: 3600)

        let reminder = Reminder.makeTest(
            title: "Test",
            startDate: startDate,
            dueDate: dueDate
        )

        #expect(reminder.plannedDate != nil)
        #expect(reminder.plannedDate == reminder.startDate)
    }

    @Test("Reminder plannedDate returns dueDate when only dueDate set")
    func reminderPlannedDateReturnsDueDateWhenOnlyDueDate() {
        let dueDate = Date()

        let reminder = Reminder.makeTest(
            title: "Test",
            dueDate: dueDate
        )

        #expect(reminder.plannedDate != nil)
        #expect(reminder.plannedDate == reminder.dueDate)
    }

    @Test("Reminder plannedDate returns nil when no dates set")
    func reminderPlannedDateReturnsNilWhenNoDates() {
        let reminder = Reminder.makeTest(
            title: "Test"
        )

        #expect(reminder.plannedDate == nil)
    }

    // MARK: - hasDeadline Tests

    @Test("Reminder hasDeadline returns true when both dates set")
    func reminderHasDeadlineReturnsTrueWhenBothDatesSet() {
        let startDate = Date()
        let dueDate = Date(timeIntervalSinceNow: 3600)

        let reminder = Reminder.makeTest(
            title: "Test",
            startDate: startDate,
            dueDate: dueDate
        )

        #expect(reminder.hasDeadline == true)
    }

    @Test("Reminder hasDeadline returns false when no dueDate")
    func reminderHasDeadlineReturnsFalseWhenNoDueDate() {
        let reminder = Reminder.makeTest(
            title: "Test"
        )

        #expect(reminder.hasDeadline == false)
    }
}
