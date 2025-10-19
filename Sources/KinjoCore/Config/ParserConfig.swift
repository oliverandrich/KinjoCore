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

/// Configuration for the task parser supporting multiple languages.
///
/// This configuration defines language-specific patterns and keywords used
/// to extract task information from natural language input.
public struct ParserConfig: Sendable {

    // MARK: - Language Code

    /// The language code for this configuration (e.g., "de", "en", "fr", "es").
    public let languageCode: String

    /// The language-specific configuration.
    public let language: LanguageConfig

    // MARK: - Initialisation

    /// Creates a new parser configuration.
    ///
    /// - Parameters:
    ///   - languageCode: The language code.
    ///   - language: The language-specific configuration.
    public init(languageCode: String, language: LanguageConfig) {
        self.languageCode = languageCode
        self.language = language
    }

    // MARK: - Predefined Configurations

    /// German parser configuration.
    public static let german = ParserConfig(
        languageCode: "de",
        language: .german
    )

    /// English parser configuration.
    public static let english = ParserConfig(
        languageCode: "en",
        language: .english
    )

    /// French parser configuration.
    public static let french = ParserConfig(
        languageCode: "fr",
        language: .french
    )

    /// Spanish parser configuration.
    public static let spanish = ParserConfig(
        languageCode: "es",
        language: .spanish
    )
}

// MARK: - Language Configuration

/// Language-specific configuration for parsing.
public struct LanguageConfig: Sendable {

    // MARK: - Keywords

    /// Keywords that indicate a deadline (e.g., "bis", "by", "avant").
    public let deadlineKeywords: [String]

    /// Relative date keywords mapped to their calendar offsets.
    ///
    /// For example: "heute" → 0 days, "morgen" → 1 day, "montag" → next Monday
    public let relativeDates: [String: RelativeDateModifier]

    /// Recurring pattern keywords mapped to their pattern definitions.
    ///
    /// For example: "täglich" → daily pattern, "jeden montag" → weekly Monday pattern
    public let recurringKeywords: [String: RecurringKeyword]

    // MARK: - Patterns

    /// Regular expressions for matching time patterns.
    ///
    /// For example: "14:00", "14 Uhr", "2:30 PM"
    public let timePatterns: [String]

    // MARK: - Initialisation

    /// Creates a new language configuration.
    public init(
        deadlineKeywords: [String],
        relativeDates: [String: RelativeDateModifier],
        recurringKeywords: [String: RecurringKeyword],
        timePatterns: [String]
    ) {
        self.deadlineKeywords = deadlineKeywords
        self.relativeDates = relativeDates
        self.recurringKeywords = recurringKeywords
        self.timePatterns = timePatterns
    }
}

// MARK: - Relative Date Modifier

/// Defines how to modify a date based on a relative keyword.
public enum RelativeDateModifier: Sendable, Equatable {
    /// Today (0 days offset).
    case today

    /// Tomorrow (1 day offset).
    case tomorrow

    /// Day after tomorrow (2 days offset).
    case dayAfterTomorrow

    /// Next occurrence of a specific weekday.
    case nextWeekday(RecurringPattern.Weekday)

    /// Next week (7 days offset).
    case nextWeek

    /// Next month (1 month offset).
    case nextMonth

    /// Next year (1 year offset).
    case nextYear

    /// Custom offset in days.
    case daysOffset(Int)
}

// MARK: - Recurring Keyword

/// Defines a recurring pattern keyword and its properties.
public struct RecurringKeyword: Sendable, Equatable {
    /// The frequency of the recurrence.
    public let frequency: RecurringPattern.Frequency

    /// The interval between recurrences (e.g., 2 for "every 2 days").
    public let interval: Int?

    /// The weekday for weekly patterns.
    public let weekday: RecurringPattern.Weekday?

    /// The day of the month for monthly patterns.
    public let dayOfMonth: Int?

    /// The week of the month for positional patterns (1 = first, -1 = last).
    public let weekOfMonth: Int?

    /// Creates a new recurring keyword definition.
    public init(
        frequency: RecurringPattern.Frequency,
        interval: Int? = nil,
        weekday: RecurringPattern.Weekday? = nil,
        dayOfMonth: Int? = nil,
        weekOfMonth: Int? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.weekday = weekday
        self.dayOfMonth = dayOfMonth
        self.weekOfMonth = weekOfMonth
    }
}

// MARK: - German Configuration

extension LanguageConfig {
    /// German language configuration.
    public static let german = LanguageConfig(
        deadlineKeywords: [
            "bis",
            "bis zum",
            "spätestens",
            "deadline"
        ],
        relativeDates: [
            "heute": .today,
            "morgen": .tomorrow,
            "übermorgen": .dayAfterTomorrow,
            "montag": .nextWeekday(.monday),
            "dienstag": .nextWeekday(.tuesday),
            "mittwoch": .nextWeekday(.wednesday),
            "donnerstag": .nextWeekday(.thursday),
            "freitag": .nextWeekday(.friday),
            "samstag": .nextWeekday(.saturday),
            "sonntag": .nextWeekday(.sunday),
            "nächste woche": .nextWeek,
            "nächsten monat": .nextMonth,
            "nächstes jahr": .nextYear
        ],
        recurringKeywords: [
            // Daily
            "täglich": RecurringKeyword(frequency: .daily, interval: 1),
            "jeden tag": RecurringKeyword(frequency: .daily, interval: 1),

            // Weekly
            "wöchentlich": RecurringKeyword(frequency: .weekly, interval: 1),
            "jede woche": RecurringKeyword(frequency: .weekly, interval: 1),
            "jeden montag": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .monday),
            "jeden dienstag": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .tuesday),
            "jeden mittwoch": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .wednesday),
            "jeden donnerstag": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .thursday),
            "jeden freitag": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .friday),
            "jeden samstag": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .saturday),
            "jeden sonntag": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .sunday),

            // Monthly
            "monatlich": RecurringKeyword(frequency: .monthly, interval: 1),
            "jeden monat": RecurringKeyword(frequency: .monthly, interval: 1),
            "jeden 1.": RecurringKeyword(frequency: .monthly, interval: 1, dayOfMonth: 1),
            "jeden 15.": RecurringKeyword(frequency: .monthly, interval: 1, dayOfMonth: 15),
            "jeden ersten montag": RecurringKeyword(frequency: .monthly, interval: 1, weekday: .monday, weekOfMonth: 1),
            "jeden letzten freitag": RecurringKeyword(frequency: .monthly, interval: 1, weekday: .friday, weekOfMonth: -1),

            // Yearly
            "jährlich": RecurringKeyword(frequency: .yearly, interval: 1),
            "jedes jahr": RecurringKeyword(frequency: .yearly, interval: 1)
        ],
        timePatterns: [
            "\\b([0-1]?[0-9]|2[0-3]):([0-5][0-9])\\b",           // 14:00, 9:30
            "\\b([0-1]?[0-9]|2[0-3])\\s*[uU]hr\\b",              // 14 Uhr, 9 uhr
            "\\b([0-1]?[0-9])\\s*[aA][mM]\\b",                   // 9 AM
            "\\b([0-1]?[0-9]|2[0-3])\\s*[pP][mM]\\b"             // 2 PM
        ]
    )
}

// MARK: - English Configuration

extension LanguageConfig {
    /// English language configuration.
    public static let english = LanguageConfig(
        deadlineKeywords: [
            "by",
            "due",
            "deadline",
            "until"
        ],
        relativeDates: [
            "today": .today,
            "tomorrow": .tomorrow,
            "monday": .nextWeekday(.monday),
            "tuesday": .nextWeekday(.tuesday),
            "wednesday": .nextWeekday(.wednesday),
            "thursday": .nextWeekday(.thursday),
            "friday": .nextWeekday(.friday),
            "saturday": .nextWeekday(.saturday),
            "sunday": .nextWeekday(.sunday),
            "next week": .nextWeek,
            "next month": .nextMonth,
            "next year": .nextYear
        ],
        recurringKeywords: [
            // Daily
            "daily": RecurringKeyword(frequency: .daily, interval: 1),
            "every day": RecurringKeyword(frequency: .daily, interval: 1),

            // Weekly
            "weekly": RecurringKeyword(frequency: .weekly, interval: 1),
            "every week": RecurringKeyword(frequency: .weekly, interval: 1),
            "every monday": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .monday),
            "every tuesday": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .tuesday),
            "every wednesday": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .wednesday),
            "every thursday": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .thursday),
            "every friday": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .friday),
            "every saturday": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .saturday),
            "every sunday": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .sunday),

            // Monthly
            "monthly": RecurringKeyword(frequency: .monthly, interval: 1),
            "every month": RecurringKeyword(frequency: .monthly, interval: 1),
            "every 1st": RecurringKeyword(frequency: .monthly, interval: 1, dayOfMonth: 1),
            "every 15th": RecurringKeyword(frequency: .monthly, interval: 1, dayOfMonth: 15),
            "every first monday": RecurringKeyword(frequency: .monthly, interval: 1, weekday: .monday, weekOfMonth: 1),
            "every last friday": RecurringKeyword(frequency: .monthly, interval: 1, weekday: .friday, weekOfMonth: -1),

            // Yearly
            "yearly": RecurringKeyword(frequency: .yearly, interval: 1),
            "every year": RecurringKeyword(frequency: .yearly, interval: 1)
        ],
        timePatterns: [
            "\\b([0-1]?[0-9]|2[0-3]):([0-5][0-9])\\b",           // 14:00, 9:30
            "\\b([0-1]?[0-9])\\s*[aA][mM]\\b",                   // 9 AM
            "\\b([0-1]?[0-9]|2[0-3])\\s*[pP][mM]\\b"             // 2 PM
        ]
    )
}

// MARK: - French Configuration

extension LanguageConfig {
    /// French language configuration.
    public static let french = LanguageConfig(
        deadlineKeywords: [
            "avant",
            "pour",
            "d'ici",
            "jusqu'à"
        ],
        relativeDates: [
            "aujourd'hui": .today,
            "demain": .tomorrow,
            "lundi": .nextWeekday(.monday),
            "mardi": .nextWeekday(.tuesday),
            "mercredi": .nextWeekday(.wednesday),
            "jeudi": .nextWeekday(.thursday),
            "vendredi": .nextWeekday(.friday),
            "samedi": .nextWeekday(.saturday),
            "dimanche": .nextWeekday(.sunday),
            "la semaine prochaine": .nextWeek,
            "le mois prochain": .nextMonth,
            "l'année prochaine": .nextYear
        ],
        recurringKeywords: [
            // Daily
            "quotidien": RecurringKeyword(frequency: .daily, interval: 1),
            "chaque jour": RecurringKeyword(frequency: .daily, interval: 1),

            // Weekly
            "hebdomadaire": RecurringKeyword(frequency: .weekly, interval: 1),
            "chaque semaine": RecurringKeyword(frequency: .weekly, interval: 1),
            "chaque lundi": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .monday),
            "chaque mardi": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .tuesday),
            "chaque mercredi": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .wednesday),
            "chaque jeudi": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .thursday),
            "chaque vendredi": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .friday),
            "chaque samedi": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .saturday),
            "chaque dimanche": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .sunday),

            // Monthly
            "mensuel": RecurringKeyword(frequency: .monthly, interval: 1),
            "chaque mois": RecurringKeyword(frequency: .monthly, interval: 1),
            "chaque 1er": RecurringKeyword(frequency: .monthly, interval: 1, dayOfMonth: 1),
            "chaque 15": RecurringKeyword(frequency: .monthly, interval: 1, dayOfMonth: 15),
            "chaque premier lundi": RecurringKeyword(frequency: .monthly, interval: 1, weekday: .monday, weekOfMonth: 1),
            "chaque dernier vendredi": RecurringKeyword(frequency: .monthly, interval: 1, weekday: .friday, weekOfMonth: -1),

            // Yearly
            "annuel": RecurringKeyword(frequency: .yearly, interval: 1),
            "chaque année": RecurringKeyword(frequency: .yearly, interval: 1)
        ],
        timePatterns: [
            "\\b([0-1]?[0-9]|2[0-3])[hH]([0-5][0-9])\\b",        // 14h00
            "\\b([0-1]?[0-9]|2[0-3]):([0-5][0-9])\\b"            // 14:00
        ]
    )
}

// MARK: - Spanish Configuration

extension LanguageConfig {
    /// Spanish language configuration.
    public static let spanish = LanguageConfig(
        deadlineKeywords: [
            "para",
            "antes de",
            "hasta",
            "límite"
        ],
        relativeDates: [
            "hoy": .today,
            "mañana": .tomorrow,
            "lunes": .nextWeekday(.monday),
            "martes": .nextWeekday(.tuesday),
            "miércoles": .nextWeekday(.wednesday),
            "jueves": .nextWeekday(.thursday),
            "viernes": .nextWeekday(.friday),
            "sábado": .nextWeekday(.saturday),
            "domingo": .nextWeekday(.sunday),
            "la próxima semana": .nextWeek,
            "el próximo mes": .nextMonth,
            "el próximo año": .nextYear
        ],
        recurringKeywords: [
            // Daily
            "diario": RecurringKeyword(frequency: .daily, interval: 1),
            "cada día": RecurringKeyword(frequency: .daily, interval: 1),

            // Weekly
            "semanal": RecurringKeyword(frequency: .weekly, interval: 1),
            "cada semana": RecurringKeyword(frequency: .weekly, interval: 1),
            "cada lunes": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .monday),
            "cada martes": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .tuesday),
            "cada miércoles": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .wednesday),
            "cada jueves": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .thursday),
            "cada viernes": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .friday),
            "cada sábado": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .saturday),
            "cada domingo": RecurringKeyword(frequency: .weekly, interval: 1, weekday: .sunday),

            // Monthly
            "mensual": RecurringKeyword(frequency: .monthly, interval: 1),
            "cada mes": RecurringKeyword(frequency: .monthly, interval: 1),
            "cada 1": RecurringKeyword(frequency: .monthly, interval: 1, dayOfMonth: 1),
            "cada 15": RecurringKeyword(frequency: .monthly, interval: 1, dayOfMonth: 15),
            "cada primer lunes": RecurringKeyword(frequency: .monthly, interval: 1, weekday: .monday, weekOfMonth: 1),
            "cada último viernes": RecurringKeyword(frequency: .monthly, interval: 1, weekday: .friday, weekOfMonth: -1),

            // Yearly
            "anual": RecurringKeyword(frequency: .yearly, interval: 1),
            "cada año": RecurringKeyword(frequency: .yearly, interval: 1)
        ],
        timePatterns: [
            "\\b([0-1]?[0-9]|2[0-3]):([0-5][0-9])\\b",           // 14:00
            "\\b([0-1]?[0-9]|2[0-3])[hH]([0-5][0-9])\\b"         // 14h00
        ]
    )
}
