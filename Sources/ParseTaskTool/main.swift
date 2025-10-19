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
import KinjoCore

// MARK: - CLI Tool

func printUsage() {
    print("""
    Usage: parse-task [options] <text>

    Options:
      -l, --lang <language>    Language: de, en, fr, es (default: de)
      -h, --help              Show this help message

    Examples:
      parse-task "Meeting morgen 14:00 p1 @Arbeit"
      parse-task --lang en "Meeting tomorrow 2 PM p1 @Work"
      parse-task --lang fr "Réunion demain 14h00 p1 @Travail"
      parse-task --lang es "Reunión mañana 14:00 p1 @Trabajo"
    """)
}

func formatDate(_ date: Date, includeTime: Bool = false) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = includeTime ? .short : .none
    return formatter.string(from: date)
}

func formatTime(_ components: DateComponents) -> String {
    guard let hour = components.hour else { return "?" }
    let minute = components.minute ?? 0
    return String(format: "%02d:%02d", hour, minute)
}

func formatRecurring(_ pattern: RecurringPattern) -> String {
    var result = "\(pattern.frequency)"

    if pattern.interval > 1 {
        result += " (every \(pattern.interval))"
    }

    if let daysOfWeek = pattern.daysOfWeek, !daysOfWeek.isEmpty {
        let days = daysOfWeek.map { "\($0)" }.joined(separator: ", ")
        result += " on \(days)"
    }

    if let dayOfMonth = pattern.dayOfMonth {
        result += " on day \(dayOfMonth)"
    }

    if let weekOfMonth = pattern.weekOfMonth {
        let position = weekOfMonth == -1 ? "last" : "\(weekOfMonth)."
        result += " (\(position) week)"
    }

    return result
}

func formatAnnotations(_ annotations: [Annotation]) -> String {
    if annotations.isEmpty {
        return "  (none)"
    }

    return annotations.map { annotation in
        "  - \(annotation.type): \"\(annotation.text)\""
    }.joined(separator: "\n")
}

// MARK: - Main

var args = CommandLine.arguments
args.removeFirst() // Remove program name

var language = "de"
var inputText: String?

var i = 0
while i < args.count {
    let arg = args[i]

    switch arg {
    case "-h", "--help":
        printUsage()
        exit(0)

    case "-l", "--lang":
        i += 1
        if i < args.count {
            language = args[i]
        } else {
            print("Error: --lang requires a language code")
            printUsage()
            exit(1)
        }

    default:
        if inputText == nil {
            inputText = arg
        } else {
            // Concatenate remaining args as the input text
            inputText! += " " + arg
        }
    }

    i += 1
}

// Check if we have input text
guard let text = inputText, !text.isEmpty else {
    print("Error: No input text provided")
    printUsage()
    exit(1)
}

// Select parser configuration based on language
let config: ParserConfig
switch language.lowercased() {
case "de", "german", "deutsch":
    config = .german
case "en", "english":
    config = .english
case "fr", "french", "français":
    config = .french
case "es", "spanish", "español":
    config = .spanish
default:
    print("Warning: Unknown language '\(language)', defaulting to German")
    config = .german
}

// Parse the input
let parser = TaskParser(config: config)
let task = parser.parse(text)

// Print results
print("╔════════════════════════════════════════════════════════════════╗")
print("║                      PARSED TASK RESULT                        ║")
print("╚════════════════════════════════════════════════════════════════╝")
print()
print("Original Input:")
print("  \"\(task.originalInput)\"")
print()
// Check if deadline has time component
let deadlineHasTime: Bool
if let deadline = task.deadline {
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents([.hour, .minute], from: deadline)
    deadlineHasTime = (components.hour != nil && components.hour != 0) || (components.minute != nil && components.minute != 0)
} else {
    deadlineHasTime = false
}

print("Extracted Information:")
print("  Title:          \(task.title.isEmpty ? "(none)" : "\"\(task.title)\"")")
print("  Scheduled Date: \(task.scheduledDate.map { formatDate($0, includeTime: false) } ?? "(none)")")
print("  Deadline:       \(task.deadline.map { formatDate($0, includeTime: deadlineHasTime) } ?? "(none)")")
print("  Time:           \(task.time.map(formatTime) ?? "(none)")")
print("  Priority:       \(task.priority.map { "p\($0)" } ?? "(none)")")
print("  Project:        \(task.project.map { "@\($0)" } ?? "(none)")")
print("  Labels:         \(task.labels.isEmpty ? "(none)" : task.labels.map { "#\($0)" }.joined(separator: ", "))")
print("  Recurring:      \(task.recurring.map(formatRecurring) ?? "(none)")")
print()
print("Annotations:")
print(formatAnnotations(task.annotations))
print()
