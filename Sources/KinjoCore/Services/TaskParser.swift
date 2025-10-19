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

/// A deterministic parser for extracting task information from natural language input.
///
/// The parser uses a multi-phase approach to extract structured information:
/// 1. Extract symbols (@projects, #labels, priorities)
/// 2. Extract absolute dates (using NSDataDetector)
/// 3. Extract recurring patterns (jeden Montag, every monday, etc.)
/// 4. Extract time-based deadlines (Montag bis 14 Uhr = deadline: Monday 14:00)
/// 5. Extract date-based deadlines (bis Freitag, by Friday, etc.)
/// 6. Extract times (14:00, 2 PM, etc.)
/// 7. Extract relative dates (heute, tomorrow, monday, etc.)
/// 8. Extract title from remaining text
///
/// ## Example Usage
///
/// ```swift
/// let parser = TaskParser(config: .german)
/// let task = parser.parse("Meeting morgen 14:00 p1 @Arbeit")
///
/// print(task.title)           // "Meeting"
/// print(task.scheduledDate)   // Tomorrow's date
/// print(task.time)            // 14:00
/// print(task.priority)        // 1
/// print(task.project)         // "Arbeit"
/// ```
public final class TaskParser: Sendable {

    // MARK: - Properties

    /// The parser configuration for language-specific patterns.
    private let config: ParserConfig

    /// The calendar used for date calculations.
    private let calendar: Foundation.Calendar

    /// The reference date for relative date calculations (defaults to now).
    private let referenceDate: Date

    // MARK: - Initialisation

    /// Creates a new task parser.
    ///
    /// - Parameters:
    ///   - config: The parser configuration for language-specific patterns.
    ///   - calendar: The calendar to use for date calculations. Defaults to Gregorian.
    ///   - referenceDate: The reference date for relative calculations. Defaults to now.
    public init(
        config: ParserConfig,
        calendar: Foundation.Calendar = Foundation.Calendar(identifier: .gregorian),
        referenceDate: Date = Date()
    ) {
        self.config = config
        self.calendar = calendar
        self.referenceDate = referenceDate
    }

    // MARK: - Parsing

    /// Parses natural language input into a structured task.
    ///
    /// - Parameter input: The natural language input string.
    /// - Returns: A parsed task with extracted information.
    public func parse(_ input: String) -> ParsedTask {
        var mutableInput = input
        var annotations: [Annotation] = []
        var priority: Int?
        var project: String?
        var labels: [String] = []
        var scheduledDate: Date?
        var deadline: Date?
        var time: DateComponents?
        var recurring: RecurringPattern?

        // Phase 1: Extract symbols (@projects, #labels, priorities)
        (mutableInput, priority, project, labels, annotations) = extractSymbols(from: mutableInput)

        // Phase 2: Extract absolute dates using NSDataDetector (may also extract time)
        (mutableInput, scheduledDate, time, annotations) = extractAbsoluteDates(
            from: mutableInput,
            annotations: annotations
        )

        // Phase 3: Extract recurring patterns (before relative dates, so "jeden Freitag" is recognized as recurring)
        (mutableInput, recurring, annotations) = extractRecurring(from: mutableInput, annotations: annotations)

        // Phase 4: Extract "bis Zeit" deadlines (e.g., "Montag bis 14 Uhr" = scheduled Montag, deadline Montag 14:00)
        (mutableInput, deadline, time, annotations) = extractTimeBasedDeadlines(
            from: mutableInput,
            scheduledDate: scheduledDate,
            currentTime: time,
            annotations: annotations
        )

        // Phase 5: Extract regular deadlines (before relative dates, so "bis Freitag" is recognized as deadline)
        if deadline == nil {
            (mutableInput, deadline, annotations) = extractDeadlines(from: mutableInput, annotations: annotations)
        }

        // Phase 6: Extract times (only if not already extracted in phase 2 or 4)
        if time == nil {
            (mutableInput, time, annotations) = extractTimes(from: mutableInput, annotations: annotations)
        }

        // Phase 7: Extract relative dates
        (mutableInput, scheduledDate, annotations) = extractRelativeDates(
            from: mutableInput,
            currentDate: scheduledDate,
            annotations: annotations
        )

        // Phase 8: Extract title from remaining text (use original input to preserve case)
        let title = extractTitle(from: mutableInput, originalInput: input, annotations: annotations)

        return ParsedTask(
            originalInput: input,
            title: title,
            scheduledDate: scheduledDate,
            deadline: deadline,
            time: time,
            priority: priority,
            project: project,
            labels: labels,
            recurring: recurring,
            annotations: annotations
        )
    }

    // MARK: - Phase 1: Symbols

    /// Extracts symbols from the input (@projects, #labels, priorities).
    private func extractSymbols(
        from input: String
    ) -> (String, Int?, String?, [String], [Annotation]) {
        var mutableInput = input
        var priority: Int?
        var project: String?
        var labels: [String] = []
        var annotations: [Annotation] = []

        // Extract priority (p1-4 or !!!-!)
        let priorityPattern = #/\b(p[1-4]|!!!|!!|!)\b/#
        if let match = mutableInput.firstMatch(of: priorityPattern) {
            let matchText = String(match.0)
            let range = input.range(of: matchText)!

            // Convert to priority number
            switch matchText {
            case "p1", "!!!":
                priority = 1
            case "p2", "!!":
                priority = 2
            case "p3", "!":
                priority = 3
            case "p4":
                priority = 4
            default:
                break
            }

            annotations.append(Annotation(
                range: range,
                text: matchText,
                type: .priority
            ))

            mutableInput = mutableInput.replacingOccurrences(of: matchText, with: "")
        }

        // Extract project (@tag) - capture first, but remove all
        let projectPattern = #/@(\w+)/#
        for match in mutableInput.matches(of: projectPattern) {
            let matchText = String(match.0)
            let projectName = String(match.1)
            let range = input.range(of: matchText)!

            // Only keep the first project
            if project == nil {
                project = projectName
            }

            annotations.append(Annotation(
                range: range,
                text: matchText,
                type: .project
            ))

            mutableInput = mutableInput.replacingOccurrences(of: matchText, with: "", options: [.literal], range: nil)
        }

        // Extract labels (#tags)
        let labelPattern = #/#(\w+)/#
        for match in mutableInput.matches(of: labelPattern) {
            let matchText = String(match.0)
            let labelName = String(match.1)
            let range = input.range(of: matchText)!

            labels.append(labelName)

            annotations.append(Annotation(
                range: range,
                text: matchText,
                type: .label
            ))

            mutableInput = mutableInput.replacingOccurrences(of: matchText, with: "", options: [.literal], range: nil)
        }

        return (mutableInput.trimmingCharacters(in: .whitespaces), priority, project, labels, annotations)
    }

    // MARK: - Phase 2: Absolute Dates

    /// Extracts absolute dates using NSDataDetector.
    private func extractAbsoluteDates(
        from input: String,
        annotations: [Annotation]
    ) -> (String, Date?, DateComponents?, [Annotation]) {
        var mutableInput = input
        var annotations = annotations
        var extractedDate: Date?
        var extractedTime: DateComponents?

        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: input, options: [], range: NSRange(input.startIndex..., in: input)) ?? []

        // Find the first date match (skip if it starts with a deadline keyword)
        for match in matches {
            guard let matchRange = Range(match.range, in: input),
                  let date = match.date else {
                continue
            }

            var matchText = String(input[matchRange])
            var matchWasSplit = false

            // If this match contains "bis/by/avant/para" + (time or date), split it
            // e.g., "morgen bis 17:00" should become just "morgen"
            // e.g., "morgen 09:00 bis Freitag" should become just "morgen 09:00"
            let splitKeywords = ["bis", "by", "avant", "para"]
            for keyword in splitKeywords {
                if let splitRange = matchText.lowercased().range(of: " " + keyword + " ") {
                    // Check if there's a time or date pattern after the keyword
                    let afterKeyword = String(matchText[splitRange.upperBound...])
                    let hasTimeOrDate = afterKeyword.contains(":") ||
                                        afterKeyword.lowercased().contains("uhr") ||
                                        afterKeyword.lowercased().contains("am") ||
                                        afterKeyword.lowercased().contains("pm") ||
                                        afterKeyword.lowercased().contains("h") ||
                                        // Check for weekday names
                                        ["montag", "dienstag", "mittwoch", "donnerstag", "freitag", "samstag", "sonntag",
                                         "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
                                         "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche",
                                         "lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"].contains {
                                            afterKeyword.lowercased().hasPrefix($0)
                                        }

                    if hasTimeOrDate {
                        // Split the match - keep only the part before the keyword
                        matchText = String(matchText[..<splitRange.lowerBound])
                        matchWasSplit = true
                        break
                    }
                }
            }

            if matchWasSplit {
                // Process the shortened match
                if let newRange = input.range(of: matchText, options: .caseInsensitive) {
                    extractedDate = date

                    // Extract time components if the split match text contains time indicators
                    let timeIndicators = [":", "uhr", "am", "pm", "h"]
                    let containsTime = timeIndicators.contains { matchText.lowercased().contains($0) }

                    if containsTime {
                        let components = calendar.dateComponents([.hour, .minute], from: date)
                        if let hour = components.hour, hour != 0 || components.minute != 0 {
                            extractedTime = components
                        }
                    }

                    annotations.append(Annotation(
                        range: newRange,
                        text: matchText,
                        type: .scheduledDate
                    ))

                    mutableInput = mutableInput.replacingOccurrences(of: matchText, with: "")
                    break  // Processed this match, exit the matches loop
                }
                continue  // Try next match
            }

            // Skip if this match starts with a deadline keyword (let Phase 5 handle it)
            let startsWithDeadlineKeyword = config.language.deadlineKeywords.contains { keyword in
                matchText.lowercased().hasPrefix(keyword.lowercased())
            }

            if startsWithDeadlineKeyword {
                continue
            }

            // Skip if this match is preceded by a deadline keyword
            // But only if it's a real date, not just a time (e.g., "bis 14 Uhr" should extract time, not be skipped)
            let matchStartIndex2 = input.distance(from: input.startIndex, to: matchRange.lowerBound)
            if matchStartIndex2 > 0 {
                let textBeforeMatch2 = String(input[..<matchRange.lowerBound]).lowercased().trimmingCharacters(in: .whitespaces)

                let precededByDeadline2 = config.language.deadlineKeywords.contains { deadlineKeyword in
                    textBeforeMatch2.hasSuffix(" " + deadlineKeyword.lowercased()) ||
                    textBeforeMatch2 == deadlineKeyword.lowercased()
                }

                // Check if this is just a time (not a full date)
                let isTimeOnly = matchText.contains(":") ||
                                 matchText.lowercased().contains("uhr") ||
                                 (matchText.lowercased().contains("am") && matchText.split(separator: " ").count == 2) ||
                                 (matchText.lowercased().contains("pm") && matchText.split(separator: " ").count == 2)

                let hasDateComponent = matchText.split(separator: " ").count > 2 ||
                                       matchText.lowercased().split(separator: " ").contains { word in
                                           ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
                                            "montag", "dienstag", "mittwoch", "donnerstag", "freitag", "samstag", "sonntag",
                                            "today", "tomorrow", "heute", "morgen"].contains(String(word))
                                       }

                // If preceded by deadline keyword and it's a real date (not just time), skip it
                if precededByDeadline2 && (hasDateComponent || !isTimeOnly) {
                    continue
                }
            }

            // Skip if the match starts with an unexpected word (not a date/time word)
            // This prevents "Breakfast tomorrow" from being matched as a date
            let dateTimeWords = [
                // English
                "today", "tomorrow", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
                "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december",
                // German
                "heute", "morgen", "übermorgen", "montag", "dienstag", "mittwoch", "donnerstag", "freitag", "samstag", "sonntag",
                "januar", "februar", "märz", "april", "mai", "juni", "juli", "august", "september", "oktober", "november", "dezember",
                // French
                "aujourd'hui", "demain", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche",
                "janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre",
                // Spanish
                "hoy", "mañana", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo",
                "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
            ]

            let firstWord = matchText.lowercased().split(separator: " ").first.map(String.init) ?? ""
            let startsWithNumber = firstWord.first?.isNumber ?? false
            if !firstWord.isEmpty && !dateTimeWords.contains(firstWord) && !startsWithNumber {
                // First word is not a recognized date/time word and not a number - skip this match
                continue
            }

            // Skip if this match is preceded by recurring indicator words (let Phase 3 handle it)
            let matchStartIndex = input.distance(from: input.startIndex, to: matchRange.lowerBound)
            if matchStartIndex > 0 {
                let textBeforeMatch = String(input[..<matchRange.lowerBound]).lowercased().trimmingCharacters(in: .whitespaces)

                // Common recurring indicator words across languages
                let recurringIndicators = [
                    "jeden", "jede", "jeder", "jedes",  // German
                    "every", "each",                     // English
                    "chaque", "tous", "toutes",          // French
                    "cada", "todos", "todas",            // Spanish
                    "alle"                               // German (for "alle 3 tage")
                ]

                let precededByRecurring = recurringIndicators.contains { indicator in
                    textBeforeMatch.hasSuffix(" " + indicator) || textBeforeMatch == indicator
                }

                if precededByRecurring {
                    continue
                }
            }

            // Found a valid date match
            extractedDate = date

            // Extract time components if the match text contains time indicators
            let timeIndicators = [":", "uhr", "am", "pm", "h"]
            let containsTime = timeIndicators.contains { matchText.lowercased().contains($0) }

            if containsTime {
                let components = calendar.dateComponents([.hour, .minute], from: date)
                if let hour = components.hour, hour != 0 || components.minute != 0 {
                    extractedTime = components
                }
            }

            annotations.append(Annotation(
                range: matchRange,
                text: matchText,
                type: .scheduledDate
            ))

            mutableInput = mutableInput.replacingOccurrences(of: matchText, with: "")
            break // Only process the first valid match
        }

        return (mutableInput.trimmingCharacters(in: .whitespaces), extractedDate, extractedTime, annotations)
    }

    // MARK: - Phase 3: Relative Dates

    /// Extracts relative dates using configured keywords.
    private func extractRelativeDates(
        from input: String,
        currentDate: Date?,
        annotations: [Annotation]
    ) -> (String, Date?, [Annotation]) {
        var mutableInput = input  // Keep original case
        let lowerInput = input.lowercased()  // Use for matching only
        var annotations = annotations
        var extractedDate = currentDate

        // Try to find relative date keywords (longest match first)
        let sortedKeywords = config.language.relativeDates.keys.sorted { $0.count > $1.count }

        for keyword in sortedKeywords {
            if let _ = lowerInput.range(of: keyword) {
                // Find the same range in the original input (case-insensitive)
                guard let originalRange = input.range(of: keyword, options: .caseInsensitive) else {
                    continue
                }

                // Skip if this keyword is preceded by a deadline keyword
                let matchStartIndex = input.distance(from: input.startIndex, to: originalRange.lowerBound)
                if matchStartIndex > 0 {
                    let textBeforeMatch = String(input[..<originalRange.lowerBound]).lowercased().trimmingCharacters(in: .whitespaces)

                    // Check if any deadline keyword appears just before this match
                    let precededByDeadline = config.language.deadlineKeywords.contains { deadlineKeyword in
                        textBeforeMatch.hasSuffix(" " + deadlineKeyword.lowercased()) ||
                        textBeforeMatch.hasSuffix(deadlineKeyword.lowercased())
                    }

                    if precededByDeadline {
                        continue // Skip this match, let deadline phase handle it
                    }
                }

                let matchText = String(input[originalRange])

                // Calculate the date based on the modifier
                if let modifier = config.language.relativeDates[keyword] {
                    extractedDate = applyRelativeDateModifier(modifier, to: referenceDate)
                }

                annotations.append(Annotation(
                    range: originalRange,
                    text: matchText,
                    type: .scheduledDate
                ))

                mutableInput = mutableInput.replacingOccurrences(of: keyword, with: "", options: .caseInsensitive)
                break // Only match one relative date
            }
        }

        return (mutableInput.trimmingCharacters(in: .whitespaces), extractedDate, annotations)
    }

    /// Applies a relative date modifier to a reference date.
    private func applyRelativeDateModifier(_ modifier: RelativeDateModifier, to date: Date) -> Date {
        switch modifier {
        case .today:
            return calendar.startOfDay(for: date)

        case .tomorrow:
            let startOfToday = calendar.startOfDay(for: date)
            return calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? date

        case .dayAfterTomorrow:
            let startOfToday = calendar.startOfDay(for: date)
            return calendar.date(byAdding: .day, value: 2, to: startOfToday) ?? date

        case .nextWeekday(let weekday):
            return nextDate(matching: weekday, after: date)

        case .nextWeek:
            let startOfToday = calendar.startOfDay(for: date)
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startOfToday) ?? date

        case .nextMonth:
            let startOfToday = calendar.startOfDay(for: date)
            return calendar.date(byAdding: .month, value: 1, to: startOfToday) ?? date

        case .nextYear:
            let startOfToday = calendar.startOfDay(for: date)
            return calendar.date(byAdding: .year, value: 1, to: startOfToday) ?? date

        case .daysOffset(let days):
            let startOfToday = calendar.startOfDay(for: date)
            return calendar.date(byAdding: .day, value: days, to: startOfToday) ?? date
        }
    }

    /// Finds the next occurrence of a specific weekday.
    private func nextDate(matching weekday: RecurringPattern.Weekday, after date: Date) -> Date {
        let targetWeekday = weekday.rawValue
        let currentWeekday = calendar.component(.weekday, from: date)

        var daysToAdd = targetWeekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7 // Move to next week
        }

        let startOfToday = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: daysToAdd, to: startOfToday) ?? date
    }

    // MARK: - Phase 4: Time-Based Deadlines

    /// Extracts "bis Zeit" patterns that combine with scheduled date to form a deadline.
    /// For example: "Montag bis 14 Uhr" = scheduled: Monday, deadline: Monday 14:00
    private func extractTimeBasedDeadlines(
        from input: String,
        scheduledDate: Date?,
        currentTime: DateComponents?,
        annotations: [Annotation]
    ) -> (String, Date?, DateComponents?, [Annotation]) {
        var mutableInput = input
        var annotations = annotations
        var extractedDeadline: Date?
        var extractedTime = currentTime

        // Only process if we have a scheduled date
        guard let scheduledDate = scheduledDate else {
            return (mutableInput, nil, extractedTime, annotations)
        }

        // Patterns for "bis + time"
        let bisTimePatterns = [
            #"bis\s+(\d{1,2}):(\d{2})"#,           // bis 14:00
            #"bis\s+(\d{1,2})\s*[uU]hr"#,          // bis 14 Uhr
            #"by\s+(\d{1,2}):(\d{2})"#,            // by 14:00 (English)
            #"by\s+(\d{1,2})\s*[aApP][mM]"#,       // by 2 PM (English)
            #"avant\s+(\d{1,2})[hH](\d{2})"#,      // avant 14h00 (French)
            #"para\s+(\d{1,2}):(\d{2})"#           // para 14:00 (Spanish)
        ]

        for pattern in bisTimePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }

            let matches = regex.matches(in: input, options: [], range: NSRange(input.startIndex..., in: input))

            if let match = matches.first,
               let matchRange = Range(match.range, in: input)
            {
                let matchText = String(input[matchRange])
                let hourNSRange = match.range(at: 1)

                if hourNSRange.location != NSNotFound,
                   let hourRange = Range(hourNSRange, in: input),
                   var hour = Int(input[hourRange])
                {
                    // Handle PM conversion
                    if matchText.lowercased().contains("pm") && hour != 12 {
                        hour += 12
                    } else if matchText.lowercased().contains("am") && hour == 12 {
                        hour = 0
                    }

                    var minute = 0

                    // Check for minute component
                    if match.numberOfRanges > 2 {
                        let minuteNSRange = match.range(at: 2)
                        if minuteNSRange.location != NSNotFound,
                           let minuteRange = Range(minuteNSRange, in: input),
                           let parsedMinute = Int(input[minuteRange])
                        {
                            minute = parsedMinute
                        }
                    }

                    // Create deadline by combining scheduled date with the time
                    var components = calendar.dateComponents([.year, .month, .day], from: scheduledDate)
                    components.hour = hour
                    components.minute = minute

                    if let deadlineDate = calendar.date(from: components) {
                        extractedDeadline = deadlineDate
                    }

                    annotations.append(Annotation(
                        range: matchRange,
                        text: matchText,
                        type: .deadline
                    ))

                    mutableInput = mutableInput.replacingOccurrences(of: matchText, with: "", options: .caseInsensitive)

                    // Don't set extractedTime - this is a deadline time, not a scheduled time
                    return (mutableInput.trimmingCharacters(in: .whitespaces), extractedDeadline, nil, annotations)
                }
            }
        }

        return (mutableInput, nil, extractedTime, annotations)
    }

    // MARK: - Phase 5: Times

    /// Extracts time components using regex patterns.
    private func extractTimes(
        from input: String,
        annotations: [Annotation]
    ) -> (String, DateComponents?, [Annotation]) {
        var mutableInput = input
        var annotations = annotations
        var extractedTime: DateComponents?

        for pattern in config.language.timePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }

            let matches = regex.matches(in: input, options: [], range: NSRange(input.startIndex..., in: input))

            if let match = matches.first,
               let matchRange = Range(match.range, in: input)
            {
                let matchText = String(input[matchRange])

                // Parse hour and minute
                let hourNSRange = match.range(at: 1)

                if hourNSRange.location != NSNotFound,
                   let hourRange = Range(hourNSRange, in: input),
                   var hour = Int(input[hourRange])
                {
                    var components = DateComponents()

                    // Handle PM conversion (add 12 to hour if it's PM and not already 12)
                    if matchText.lowercased().contains("pm") && hour != 12 {
                        hour += 12
                    } else if matchText.lowercased().contains("am") && hour == 12 {
                        hour = 0  // 12 AM is midnight
                    }

                    components.hour = hour

                    // Check if we have a minute component (capture group 2)
                    if match.numberOfRanges > 2 {
                        let minuteNSRange = match.range(at: 2)
                        if minuteNSRange.location != NSNotFound,
                           let minuteRange = Range(minuteNSRange, in: input),
                           let minute = Int(input[minuteRange])
                        {
                            components.minute = minute
                        } else {
                            components.minute = 0
                        }
                    } else {
                        // No minute capture group, default to 0
                        components.minute = 0
                    }

                    extractedTime = components
                }

                annotations.append(Annotation(
                    range: matchRange,
                    text: matchText,
                    type: .time
                ))

                mutableInput = mutableInput.replacingOccurrences(of: matchText, with: "")
                break // Only match one time
            }
        }

        return (mutableInput.trimmingCharacters(in: .whitespaces), extractedTime, annotations)
    }

    // MARK: - Phase 6: Deadlines

    /// Extracts deadlines using configured keywords.
    private func extractDeadlines(
        from input: String,
        annotations: [Annotation]
    ) -> (String, Date?, [Annotation]) {
        var mutableInput = input  // Keep original case
        let lowerInput = input.lowercased()  // Use for matching only
        var annotations = annotations
        var extractedDeadline: Date?

        // Try to find deadline keywords (longest match first)
        let sortedKeywords = config.language.deadlineKeywords.sorted { $0.count > $1.count }

        for keyword in sortedKeywords {
            if let keywordRange = lowerInput.range(of: keyword) {
                // Look for a date after the keyword (in original input)
                guard let originalKeywordRange = input.range(of: keyword, options: .caseInsensitive) else {
                    continue
                }
                let remainingText = String(input[originalKeywordRange.upperBound...])

                // Try to extract absolute date first
                let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
                let matches = detector?.matches(
                    in: remainingText,
                    options: [],
                    range: NSRange(remainingText.startIndex..., in: remainingText)
                ) ?? []

                if let match = matches.first,
                   let matchRange = Range(match.range, in: remainingText),
                   let date = match.date
                {
                    let matchedText = String(remainingText[matchRange])

                    // Skip if this is just a time (e.g., "bis 14 Uhr" should be time, not deadline)
                    let isTimeOnly = matchedText.contains(":") ||
                                     matchedText.lowercased().contains("uhr") ||
                                     matchedText.lowercased().contains("am") ||
                                     matchedText.lowercased().contains("pm") ||
                                     matchedText.lowercased().contains("h")

                    let hasDateComponent = matchedText.split(separator: " ").count > 1 ||
                                           matchedText.contains("/") ||
                                           matchedText.contains("-") ||
                                           matchedText.split(separator: " ").contains { word in
                                               let lower = word.lowercased()
                                               return ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
                                                       "montag", "dienstag", "mittwoch", "donnerstag", "freitag", "samstag", "sonntag",
                                                       "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche",
                                                       "lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo",
                                                       "januar", "februar", "märz", "april", "mai", "juni", "juli", "august", "september", "oktober", "november", "dezember",
                                                       "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"].contains(String(lower))
                                           }

                    if isTimeOnly && !hasDateComponent {
                        // This is just a time, skip it (let time extraction handle it)
                        continue
                    }

                    let fullMatchText = keyword + " " + matchedText
                    extractedDeadline = date

                    if let fullRange = input.range(of: fullMatchText, options: .caseInsensitive) {
                        annotations.append(Annotation(
                            range: fullRange,
                            text: String(input[fullRange]),
                            type: .deadline
                        ))

                        mutableInput = mutableInput.replacingOccurrences(of: fullMatchText, with: "", options: .caseInsensitive)
                    }
                    break
                }

                // Try relative dates (sorted by length for longest match first)
                let sortedRelKeywords = config.language.relativeDates.keys.sorted { $0.count > $1.count }
                for relKeyword in sortedRelKeywords {
                    let trimmedRemainingText = remainingText.trimmingCharacters(in: .whitespaces).lowercased()
                    if trimmedRemainingText.hasPrefix(relKeyword) {
                        guard let modifier = config.language.relativeDates[relKeyword] else { continue }

                        let fullMatchText = keyword + " " + relKeyword
                        extractedDeadline = applyRelativeDateModifier(modifier, to: referenceDate)

                        if let fullRange = input.range(of: fullMatchText, options: .caseInsensitive) {
                            annotations.append(Annotation(
                                range: fullRange,
                                text: String(input[fullRange]),
                                type: .deadline
                            ))

                            mutableInput = mutableInput.replacingOccurrences(of: fullMatchText, with: "", options: .caseInsensitive)
                        }
                        break
                    }
                }

                break // Only match one deadline
            }
        }

        return (mutableInput.trimmingCharacters(in: .whitespaces), extractedDeadline, annotations)
    }

    // MARK: - Phase 7: Recurring

    /// Extracts recurring patterns using configured keywords.
    private func extractRecurring(
        from input: String,
        annotations: [Annotation]
    ) -> (String, RecurringPattern?, [Annotation]) {
        var mutableInput = input  // Keep original case
        let lowerInput = input.lowercased()  // Use for matching only
        var annotations = annotations
        var extractedRecurring: RecurringPattern?

        // Try to find recurring keywords (longest match first)
        let sortedKeywords = config.language.recurringKeywords.keys.sorted { $0.count > $1.count }

        for keyword in sortedKeywords {
            if let _ = lowerInput.range(of: keyword) {
                guard let range = input.range(of: keyword, options: .caseInsensitive) else {
                    continue
                }
                let matchText = String(input[range])

                // Get the recurring pattern from config
                if let recurringKeyword = config.language.recurringKeywords[keyword] {
                    extractedRecurring = RecurringPattern(
                        frequency: recurringKeyword.frequency,
                        interval: recurringKeyword.interval ?? 1,
                        daysOfWeek: recurringKeyword.weekday.map { [$0] },
                        dayOfMonth: recurringKeyword.dayOfMonth,
                        weekOfMonth: recurringKeyword.weekOfMonth
                    )
                }

                annotations.append(Annotation(
                    range: range,
                    text: matchText,
                    type: .recurring
                ))

                mutableInput = mutableInput.replacingOccurrences(of: keyword, with: "", options: .caseInsensitive)
                break // Only match one recurring pattern
            }
        }

        // Check for interval patterns (e.g., "alle 3 tage", "every 3 days", "tous les 3 jours", "cada 3 días")
        // Note: Longer forms must come first in alternation to match correctly
        let intervalPatterns = [
            #"alle (\d+) (tage|tag|wochen|woche|monate|monat|jahre|jahr)"#,     // German
            #"every (\d+) (days|day|weeks|week|months|month|years|year)"#,      // English
            #"tous les (\d+) (jours|jour|semaines|semaine|années|année|mois)"#, // French
            #"cada (\d+) (días|día|semanas|semana|meses|mes|años|año)"#         // Spanish
        ]

        for pattern in intervalPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }

            let matches = regex.matches(in: lowerInput, options: [], range: NSRange(lowerInput.startIndex..., in: lowerInput))

            if let match = matches.first,
               let matchRange = Range(match.range, in: lowerInput)
            {
                let intervalNSRange = match.range(at: 1)
                let unitNSRange = match.range(at: 2)

                if intervalNSRange.location != NSNotFound,
                   unitNSRange.location != NSNotFound,
                   let intervalRange = Range(intervalNSRange, in: lowerInput),
                   let unitRange = Range(unitNSRange, in: lowerInput),
                   let interval = Int(lowerInput[intervalRange])
                {
                    // Find the same match in the original input
                    guard let originalMatchRange = input.range(of: String(lowerInput[matchRange]), options: .caseInsensitive) else {
                        continue
                    }
                    let matchText = String(input[originalMatchRange])
                    let unit = String(lowerInput[unitRange]).lowercased()

                    // Determine frequency based on unit
                    let frequency: RecurringPattern.Frequency
                    if ["tag", "tage", "day", "days", "jour", "jours", "día", "días"].contains(unit) {
                        frequency = .daily
                    } else if ["woche", "wochen", "week", "weeks", "semaine", "semaines", "semana", "semanas"].contains(unit) {
                        frequency = .weekly
                    } else if ["monat", "monate", "month", "months", "mois", "mes", "meses"].contains(unit) {
                        frequency = .monthly
                    } else {
                        frequency = .yearly
                    }

                    extractedRecurring = RecurringPattern(
                        frequency: frequency,
                        interval: interval
                    )

                    annotations.append(Annotation(
                        range: originalMatchRange,
                        text: matchText,
                        type: .recurring
                    ))

                    mutableInput = mutableInput.replacingOccurrences(of: matchText, with: "", options: .caseInsensitive)
                    break
                }
            }
        }

        return (mutableInput.trimmingCharacters(in: .whitespaces), extractedRecurring, annotations)
    }

    // MARK: - Phase 8: Title

    /// Extracts the title from the remaining text, preserving original casing.
    private func extractTitle(from processedInput: String, originalInput: String, annotations: [Annotation]) -> String {
        // Use the processed input which already has all annotated text removed
        var result = processedInput

        // Remove temporal connector words that are often left behind
        // These words connect dates/times but aren't part of the task title
        let connectors = [
            "um",        // German: "Montag um 14 Uhr"
            "at",        // English: "Monday at 2 PM"
            "à",         // French: "lundi à 14h"
            "a las",     // Spanish: "lunes a las 14:00"
            "a",         // Spanish (short form): "lunes a 14:00"
        ]

        for connector in connectors {
            // Remove connector if it appears at the start (with optional whitespace)
            let pattern = "^\\s*" + NSRegularExpression.escapedPattern(for: connector) + "\\s+"
            result = result.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
        }

        // Clean up multiple spaces and trim
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespaces)
    }
}
