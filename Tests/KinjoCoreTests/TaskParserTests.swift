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

import Foundation
import Testing
@testable import KinjoCore

// MARK: - Test Suite

@Suite("TaskParser Tests", .serialized)
struct TaskParserTests {

    // MARK: - Helper Properties

    let calendar = Foundation.Calendar(identifier: .gregorian)
    let referenceDate: Date

    init() {
        // Use a fixed reference date for consistent testing: 2025-10-19 (Sunday)
        var components = DateComponents()
        components.year = 2025
        components.month = 10
        components.day = 19
        components.hour = 12
        components.minute = 0
        self.referenceDate = Foundation.Calendar(identifier: .gregorian).date(from: components)!
    }

    // MARK: - German Tests (Basic)

    @Test("German: Simple title only")
    func germanSimpleTitle() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Einkaufen gehen")
        #expect(task.title == "Einkaufen gehen")
        #expect(task.scheduledDate == nil)
        #expect(task.deadline == nil)
        #expect(task.time == nil)
        #expect(task.priority == nil)
        #expect(task.project == nil)
        #expect(task.labels.isEmpty)
        #expect(task.recurring == nil)
    }

    @Test("German: Title with priority p1")
    func germanTitleWithP1() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Meeting vorbereiten p1")
        #expect(task.title == "Meeting vorbereiten")
        #expect(task.priority == 1)
    }

    @Test("German: Title with priority p2")
    func germanTitleWithP2() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Bericht schreiben p2")
        #expect(task.title == "Bericht schreiben")
        #expect(task.priority == 2)
    }

    @Test("German: Title with priority p3")
    func germanTitleWithP3() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Email beantworten p3")
        #expect(task.title == "Email beantworten")
        #expect(task.priority == 3)
    }

    @Test("German: Title with priority p4")
    func germanTitleWithP4() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Aufräumen p4")
        #expect(task.title == "Aufräumen")
        #expect(task.priority == 4)
    }

    @Test("German: Title with priority !!!")
    func germanTitleWithTripleExclamation() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Notfall behandeln !!!")
        #expect(task.title == "Notfall behandeln")
        #expect(task.priority == 1)
    }

    @Test("German: Title with priority !!")
    func germanTitleWithDoubleExclamation() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Dringend anrufen !!")
        #expect(task.title == "Dringend anrufen")
        #expect(task.priority == 2)
    }

    @Test("German: Title with priority !")
    func germanTitleWithSingleExclamation() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Antworten !")
        #expect(task.title == "Antworten")
        #expect(task.priority == 3)
    }

    @Test("German: Title with project")
    func germanTitleWithProject() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Code reviewen @Arbeit")
        #expect(task.title == "Code reviewen")
        #expect(task.project == "Arbeit")
    }

    @Test("German: Title with label")
    func germanTitleWithLabel() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Dokumentation aktualisieren #wichtig")
        #expect(task.title == "Dokumentation aktualisieren")
        #expect(task.labels == ["wichtig"])
    }

    @Test("German: Title with multiple labels")
    func germanTitleWithMultipleLabels() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Präsentation erstellen #wichtig #dringend #arbeit")
        #expect(task.title == "Präsentation erstellen")
        #expect(task.labels.contains("wichtig"))
        #expect(task.labels.contains("dringend"))
        #expect(task.labels.contains("arbeit"))
        #expect(task.labels.count == 3)
    }

    @Test("German: Title with project and priority")
    func germanTitleWithProjectAndPriority() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Sprint planen @Team p1")
        #expect(task.title == "Sprint planen")
        #expect(task.project == "Team")
        #expect(task.priority == 1)
    }

    @Test("German: Date heute (today)")
    func germanDateToday() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Einkaufen heute")
        #expect(task.title == "Einkaufen")
        #expect(task.scheduledDate != nil)

        let expectedDate = calendar.startOfDay(for: referenceDate)
        #expect(calendar.isDate(task.scheduledDate!, inSameDayAs: expectedDate))
    }

    @Test("German: Date morgen (tomorrow)")
    func germanDateTomorrow() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Meeting morgen")
        #expect(task.title == "Meeting")
        #expect(task.scheduledDate != nil)

        let expectedDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: referenceDate))!
        #expect(calendar.isDate(task.scheduledDate!, inSameDayAs: expectedDate))
    }

    @Test("German: Date übermorgen (day after tomorrow)")
    func germanDateDayAfterTomorrow() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Termin übermorgen")
        #expect(task.title == "Termin")
        #expect(task.scheduledDate != nil)

        let expectedDate = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: referenceDate))!
        #expect(calendar.isDate(task.scheduledDate!, inSameDayAs: expectedDate))
    }

    @Test("German: Time 14:00")
    func germanTime1400() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Meeting morgen 14:00")
        #expect(task.title == "Meeting")
        #expect(task.time?.hour == 14)
        #expect(task.time?.minute == 0)
    }

    @Test("German: Time 09:30")
    func germanTime0930() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Frühstück morgen 09:30")
        #expect(task.title == "Frühstück")
        #expect(task.time?.hour == 9)
        #expect(task.time?.minute == 30)
    }

    @Test("German: Complete task with all features")
    func germanCompleteTask() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Meeting morgen 14:00 p1 @Arbeit #wichtig")
        #expect(task.title == "Meeting")
        #expect(task.scheduledDate != nil)
        #expect(task.time?.hour == 14)
        #expect(task.time?.minute == 0)
        #expect(task.priority == 1)
        #expect(task.project == "Arbeit")
        #expect(task.labels == ["wichtig"])
    }

    @Test("German: Deadline with bis")
    func germanDeadlineWithBis() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Bericht schreiben bis morgen")
        #expect(task.title == "Bericht schreiben")
        #expect(task.deadline != nil)
        #expect(task.scheduledDate == nil)

        let expectedDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: referenceDate))!
        #expect(calendar.isDate(task.deadline!, inSameDayAs: expectedDate))
    }

    @Test("German: Deadline with bis zum")
    func germanDeadlineWithBisZum() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Projekt abschliessen bis zum Freitag")
        #expect(task.title == "Projekt abschliessen")
        #expect(task.deadline != nil)
    }

    @Test("German: Deadline with spätestens")
    func germanDeadlineWithSpaetestens() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Antwort senden spätestens morgen")
        #expect(task.title == "Antwort senden")
        #expect(task.deadline != nil)
    }

    @Test("German: Recurring täglich (daily)")
    func germanRecurringDaily() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Training täglich")
        #expect(task.title == "Training")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .daily)
        #expect(task.recurring?.interval == 1)
    }

    @Test("German: Recurring jeden Tag (every day)")
    func germanRecurringEveryDay() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Meditation jeden Tag")
        #expect(task.title == "Meditation")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .daily)
    }

    @Test("German: Recurring jeden Montag (every Monday)")
    func germanRecurringEveryMonday() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Teammeeting jeden Montag")
        #expect(task.title == "Teammeeting")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .weekly)
        #expect(task.recurring?.daysOfWeek?.contains(.monday) == true)
    }

    @Test("German: Recurring jeden Freitag (every Friday)")
    func germanRecurringEveryFriday() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Softfolio eintragen jeden Freitag")
        #expect(task.title == "Softfolio eintragen")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .weekly)
        #expect(task.recurring?.daysOfWeek?.contains(.friday) == true)
    }

    // MARK: - German Tests (Advanced)

    @Test("German: Recurring with time")
    func germanRecurringWithTime() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Softfolio eintragen jeden Freitag 17:00 @Arbeit p1")
        #expect(task.title == "Softfolio eintragen")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .weekly)
        #expect(task.recurring?.daysOfWeek?.contains(.friday) == true)
        #expect(task.time?.hour == 17)
        #expect(task.time?.minute == 0)
        #expect(task.project == "Arbeit")
        #expect(task.priority == 1)
    }

    @Test("German: Recurring wöchentlich (weekly)")
    func germanRecurringWeekly() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Statusbericht wöchentlich")
        #expect(task.title == "Statusbericht")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .weekly)
    }

    @Test("German: Recurring monatlich (monthly)")
    func germanRecurringMonthly() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Miete zahlen monatlich")
        #expect(task.title == "Miete zahlen")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .monthly)
    }

    @Test("German: Recurring jeden Monat (every month)")
    func germanRecurringEveryMonth() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Rechnung erstellen jeden Monat")
        #expect(task.title == "Rechnung erstellen")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .monthly)
    }

    @Test("German: Recurring jährlich (yearly)")
    func germanRecurringYearly() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Geburtstag feiern jährlich")
        #expect(task.title == "Geburtstag feiern")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .yearly)
    }

    @Test("German: Recurring interval alle 3 Tage")
    func germanRecurringEvery3Days() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Pflanzen giessen alle 3 Tage")
        #expect(task.title == "Pflanzen giessen")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .daily)
        #expect(task.recurring?.interval == 3)
    }

    @Test("German: Recurring interval alle 2 Wochen")
    func germanRecurringEvery2Weeks() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Backups prüfen alle 2 Wochen")
        #expect(task.title == "Backups prüfen")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .weekly)
        #expect(task.recurring?.interval == 2)
    }

    @Test("German: Weekday Montag")
    func germanWeekdayMonday() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Meeting Montag")
        #expect(task.title == "Meeting")
        #expect(task.scheduledDate != nil)
        // Monday after reference date (Sunday 19.10.2025) = 20.10.2025
    }

    @Test("German: Weekday Dienstag")
    func germanWeekdayTuesday() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Zahnarzt Dienstag")
        #expect(task.title == "Zahnarzt")
        #expect(task.scheduledDate != nil)
    }

    @Test("German: Weekday Mittwoch")
    func germanWeekdayWednesday() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Training Mittwoch")
        #expect(task.title == "Training")
        #expect(task.scheduledDate != nil)
    }

    @Test("German: Weekday Donnerstag")
    func germanWeekdayThursday() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Präsentation Donnerstag")
        #expect(task.title == "Präsentation")
        #expect(task.scheduledDate != nil)
    }

    @Test("German: Weekday Freitag")
    func germanWeekdayFriday() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Softfolio Freitag")
        #expect(task.title == "Softfolio")
        #expect(task.scheduledDate != nil)
    }

    @Test("German: Weekday Samstag")
    func germanWeekdaySaturday() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Einkaufen Samstag")
        #expect(task.title == "Einkaufen")
        #expect(task.scheduledDate != nil)
    }

    @Test("German: Weekday Sonntag")
    func germanWeekdaySunday() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Familie treffen Sonntag")
        #expect(task.title == "Familie treffen")
        #expect(task.scheduledDate != nil)
    }

    @Test("German: Both scheduled and deadline")
    func germanBothScheduledAndDeadline() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Bericht morgen beginnen bis Freitag")
        #expect(task.title.contains("Bericht"))
        #expect(task.scheduledDate != nil)
        #expect(task.deadline != nil)
    }

    @Test("German: Complex task with multiple features")
    func germanComplexTask() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Projektbericht schreiben morgen 09:00 bis Freitag p1 @Arbeit #wichtig #dringend")
        #expect(task.title.contains("Projektbericht"))
        #expect(task.scheduledDate != nil)
        #expect(task.deadline != nil)
        #expect(task.time?.hour == 9)
        #expect(task.priority == 1)
        #expect(task.project == "Arbeit")
        #expect(task.labels.count == 2)
    }

    @Test("German: Multiple projects (only first is captured)")
    func germanMultipleProjects() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Koordination @Team @Arbeit")
        #expect(task.title == "Koordination")
        #expect(task.project == "Team")  // First one wins
    }

    @Test("German: Time format 14 Uhr")
    func germanTimeFormatUhr() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("Meeting morgen 14 Uhr")
        #expect(task.title == "Meeting")
        #expect(task.time?.hour == 14)
        #expect(task.time?.minute == 0)
    }

    @Test("German: Edge case - priority at start")
    func germanPriorityAtStart() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("p1 Notfall behandeln")
        #expect(task.title == "Notfall behandeln")
        #expect(task.priority == 1)
    }

    @Test("German: Edge case - empty after extraction")
    func germanEmptyAfterExtraction() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("p1 @Arbeit #wichtig")

        #expect(task.priority == 1)
        #expect(task.project == "Arbeit")
        #expect(task.labels == ["wichtig"])
        // Title should be empty or minimal
    }

    @Test("German: Special characters in title")
    func germanSpecialCharactersInTitle() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("E-Mail an Max schreiben")
        #expect(task.title.contains("E-Mail"))
        #expect(task.title.contains("Max"))
    }

    @Test("German: Numbers in title")
    func germanNumbersInTitle() {
        let parser = TaskParser(config: .german, referenceDate: referenceDate)
        let task = parser.parse("10 Seiten lesen")
        #expect(task.title.contains("10"))
        #expect(task.title.contains("Seiten"))
    }

    // MARK: - English Tests

    @Test("English: Simple title only")
    func englishSimpleTitle() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Buy groceries")
        #expect(task.title == "Buy groceries")
        #expect(task.priority == nil)
        #expect(task.project == nil)
    }

    @Test("English: Title with priority")
    func englishTitleWithPriority() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Prepare presentation p1")
        #expect(task.title == "Prepare presentation")
        #expect(task.priority == 1)
    }

    @Test("English: Title with project")
    func englishTitleWithProject() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Review code @Work")
        #expect(task.title == "Review code")
        #expect(task.project == "Work")
    }

    @Test("English: Date today")
    func englishDateToday() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Shopping today")
        #expect(task.title == "Shopping")
        #expect(task.scheduledDate != nil)
    }

    @Test("English: Date tomorrow")
    func englishDateTomorrow() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Meeting tomorrow")
        #expect(task.title == "Meeting")
        #expect(task.scheduledDate != nil)
    }

    @Test("English: Time 2 PM")
    func englishTime2PM() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Call client tomorrow 2 PM")
        #expect(task.title.contains("Call"))
        #expect(task.time?.hour == 14)
    }

    @Test("English: Time 9 AM")
    func englishTime9AM() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Breakfast tomorrow 9 AM")
        #expect(task.title == "Breakfast")
        #expect(task.time?.hour == 9)
    }

    @Test("English: Deadline with by")
    func englishDeadlineWithBy() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        // Use absolute date for deadline test
        let task = parser.parse("Submit report by October 25")
        #expect(task.title.contains("Submit"))
        #expect(task.deadline != nil)
    }

    @Test("English: Deadline with due")
    func englishDeadlineWithDue() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Assignment due tomorrow")
        #expect(task.title == "Assignment")
        #expect(task.deadline != nil)
    }

    @Test("English: Recurring daily")
    func englishRecurringDaily() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Exercise daily")
        #expect(task.title == "Exercise")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .daily)
    }

    @Test("English: Recurring every day")
    func englishRecurringEveryDay() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Meditate every day")
        #expect(task.title == "Meditate")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .daily)
    }

    @Test("English: Recurring every Monday")
    func englishRecurringEveryMonday() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Team meeting every Monday")
        #expect(task.title.contains("Team"))
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .weekly)
        #expect(task.recurring?.daysOfWeek?.contains(.monday) == true)
    }

    @Test("English: Recurring weekly")
    func englishRecurringWeekly() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Status report weekly")
        #expect(task.title.contains("Status"))
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .weekly)
    }

    @Test("English: Recurring monthly")
    func englishRecurringMonthly() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Pay rent monthly")
        #expect(task.title.contains("Pay"))
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .monthly)
    }

    @Test("English: Recurring every 3 days")
    func englishRecurringEvery3Days() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Water plants every 3 days")
        #expect(task.title.contains("Water"))
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .daily)
        #expect(task.recurring?.interval == 3)
    }

    @Test("English: Complete task")
    func englishCompleteTask() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Meeting tomorrow 2 PM p1 @Work #important")
        #expect(task.title == "Meeting")
        #expect(task.scheduledDate != nil)
        #expect(task.time?.hour == 14)
        #expect(task.priority == 1)
        #expect(task.project == "Work")
        #expect(task.labels == ["important"])
    }

    @Test("English: Weekday Monday")
    func englishWeekdayMonday() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Call dentist Monday")
        #expect(task.title.contains("Call"))
        #expect(task.scheduledDate != nil)
    }

    @Test("English: Weekday Friday")
    func englishWeekdayFriday() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Submit timesheet Friday")
        #expect(task.title.contains("Submit"))
        #expect(task.scheduledDate != nil)
    }

    @Test("English: Both scheduled and deadline")
    func englishBothScheduledAndDeadline() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Start report Monday due Friday")
        #expect(task.title.contains("Start"))
        #expect(task.scheduledDate != nil)
        #expect(task.deadline != nil)
    }

    @Test("English: Multiple labels")
    func englishMultipleLabels() {
        let parser = TaskParser(config: .english, referenceDate: referenceDate)
        let task = parser.parse("Design mockup #design #urgent #review")
        #expect(task.title.contains("Design"))
        #expect(task.labels.count == 3)
        #expect(task.labels.contains("design"))
        #expect(task.labels.contains("urgent"))
        #expect(task.labels.contains("review"))
    }

    // MARK: - French Tests

    @Test("French: Simple title")
    func frenchSimpleTitle() {
        let parser = TaskParser(config: .french, referenceDate: referenceDate)
        let task = parser.parse("Acheter du pain")
        #expect(task.title.contains("Acheter"))
        #expect(task.priority == nil)
    }

    @Test("French: Title with priority")
    func frenchTitleWithPriority() {
        let parser = TaskParser(config: .french, referenceDate: referenceDate)
        let task = parser.parse("Préparer présentation p1")
        #expect(task.title.contains("Préparer"))
        #expect(task.priority == 1)
    }

    @Test("French: Title with project")
    func frenchTitleWithProject() {
        let parser = TaskParser(config: .french, referenceDate: referenceDate)
        let task = parser.parse("Réviser code @Travail")
        #expect(task.title.contains("Réviser"))
        #expect(task.project == "Travail")
    }

    @Test("French: Date aujourd'hui (today)")
    func frenchDateToday() {
        let parser = TaskParser(config: .french, referenceDate: referenceDate)
        let task = parser.parse("Courses aujourd'hui")
        #expect(task.title == "Courses")
        #expect(task.scheduledDate != nil)
    }

    @Test("French: Date demain (tomorrow)")
    func frenchDateTomorrow() {
        let parser = TaskParser(config: .french, referenceDate: referenceDate)
        let task = parser.parse("Réunion demain")
        #expect(task.title == "Réunion")
        #expect(task.scheduledDate != nil)
    }

    @Test("French: Time 14h00")
    func frenchTime14h() {
        let parser = TaskParser(config: .french, referenceDate: referenceDate)
        let task = parser.parse("Rendez-vous demain 14h00")
        #expect(task.title.contains("Rendez-vous"))
        #expect(task.time?.hour == 14)
    }

    @Test("French: Deadline with avant")
    func frenchDeadlineWithAvant() {
        let parser = TaskParser(config: .french, referenceDate: referenceDate)
        let task = parser.parse("Envoyer rapport avant vendredi")
        #expect(task.title.contains("Envoyer"))
        #expect(task.deadline != nil)
    }

    @Test("French: Recurring quotidien (daily)")
    func frenchRecurringDaily() {
        let parser = TaskParser(config: .french, referenceDate: referenceDate)
        let task = parser.parse("Exercice quotidien")
        #expect(task.title == "Exercice")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .daily)
    }

    @Test("French: Recurring chaque jour")
    func frenchRecurringEveryDay() {
        let parser = TaskParser(config: .french, referenceDate: referenceDate)
        let task = parser.parse("Méditation chaque jour")
        #expect(task.title == "Méditation")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .daily)
    }

    @Test("French: Recurring chaque lundi")
    func frenchRecurringEveryMonday() {
        let parser = TaskParser(config: .french, referenceDate: referenceDate)
        let task = parser.parse("Réunion équipe chaque lundi")
        #expect(task.title.contains("Réunion"))
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .weekly)
        #expect(task.recurring?.daysOfWeek?.contains(.monday) == true)
    }

    @Test("French: Complete task")
    func frenchCompleteTask() {
        let parser = TaskParser(config: .french, referenceDate: referenceDate)
        let task = parser.parse("Réunion demain 14h00 p1 @Travail #important")
        #expect(task.title == "Réunion")
        #expect(task.scheduledDate != nil)
        #expect(task.time?.hour == 14)
        #expect(task.priority == 1)
        #expect(task.project == "Travail")
        #expect(task.labels == ["important"])
    }

    // MARK: - Spanish Tests

    @Test("Spanish: Simple title")
    func spanishSimpleTitle() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        let task = parser.parse("Comprar comida")
        #expect(task.title.contains("Comprar"))
        #expect(task.priority == nil)
    }

    @Test("Spanish: Title with priority")
    func spanishTitleWithPriority() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        let task = parser.parse("Preparar presentación p1")
        #expect(task.title.contains("Preparar"))
        #expect(task.priority == 1)
    }

    @Test("Spanish: Title with project")
    func spanishTitleWithProject() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        let task = parser.parse("Revisar código @Trabajo")
        #expect(task.title.contains("Revisar"))
        #expect(task.project == "Trabajo")
    }

    @Test("Spanish: Date hoy (today)")
    func spanishDateToday() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        let task = parser.parse("Compras hoy")
        #expect(task.title == "Compras")
        #expect(task.scheduledDate != nil)
    }

    @Test("Spanish: Date mañana (tomorrow)")
    func spanishDateTomorrow() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        let task = parser.parse("Reunión mañana")
        #expect(task.title == "Reunión")
        #expect(task.scheduledDate != nil)
    }

    @Test("Spanish: Time 14:00")
    func spanishTime1400() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        let task = parser.parse("Cita mañana 14:00")
        #expect(task.title == "Cita")
        #expect(task.time?.hour == 14)
    }

    @Test("Spanish: Deadline with para")
    func spanishDeadlineWithPara() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        // Use absolute date for deadline test
        let task = parser.parse("Enviar informe para 25 de octubre")
        #expect(task.title.contains("Enviar"))
        #expect(task.deadline != nil)
    }

    @Test("Spanish: Recurring diario (daily)")
    func spanishRecurringDaily() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        let task = parser.parse("Ejercicio diario")
        #expect(task.title == "Ejercicio")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .daily)
    }

    @Test("Spanish: Recurring cada día")
    func spanishRecurringEveryDay() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        let task = parser.parse("Meditación cada día")
        #expect(task.title == "Meditación")
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .daily)
    }

    @Test("Spanish: Recurring cada lunes")
    func spanishRecurringEveryMonday() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        let task = parser.parse("Reunión equipo cada lunes")
        #expect(task.title.contains("Reunión"))
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .weekly)
        #expect(task.recurring?.daysOfWeek?.contains(.monday) == true)
    }

    @Test("Spanish: Complete task")
    func spanishCompleteTask() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        let task = parser.parse("Reunión mañana 14:00 p1 @Trabajo #importante")
        #expect(task.title == "Reunión")
        #expect(task.scheduledDate != nil)
        #expect(task.time?.hour == 14)
        #expect(task.priority == 1)
        #expect(task.project == "Trabajo")
        #expect(task.labels == ["importante"])
    }

    @Test("Spanish: Recurring every 2 weeks")
    func spanishRecurringEvery2Weeks() {
        let parser = TaskParser(config: .spanish, referenceDate: referenceDate)
        let task = parser.parse("Revisar backups cada 2 semanas")
        #expect(task.title.contains("Revisar"))
        #expect(task.recurring != nil)
        #expect(task.recurring?.frequency == .weekly)
        #expect(task.recurring?.interval == 2)
    }
}
