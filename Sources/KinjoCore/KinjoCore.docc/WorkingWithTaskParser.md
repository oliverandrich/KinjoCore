# Working with the Task Parser

Learn how to use the TaskParser for natural language parsing of tasks in multiple languages.

## Overview

The ``TaskParser`` provides deterministic natural language parsing for tasks, supporting German, English, French, and Spanish. It can extract dates, times, deadlines, priorities, tags, and recurring patterns from plain text input.

## Basic Usage

### Setting Up the Parser

```swift
import KinjoCore

// Use default configuration (English)
let parser = TaskParser()

// Or specify a language
let germanParser = TaskParser(config: .german)
```

### Parsing Simple Tasks

```swift
let result = parser.parse("Buy milk tomorrow at 3pm")

print(result.title)           // "Buy milk"
print(result.scheduledDate)   // Tomorrow at 3pm
print(result.annotations)     // Highlights which parts were parsed
```

## Scheduled Dates vs Deadlines

The TaskParser makes a semantic distinction between when you plan to work on a task (scheduled date) and when it must be completed (deadline):

```swift
// Scheduled date (when to work on it)
let task1 = parser.parse("Call John on Monday")
print(task1.scheduledDate)  // Next Monday

// Deadline (when it must be done by)
let task2 = parser.parse("Submit report by Friday")
print(task2.deadline)       // Next Friday

// Both scheduled date and deadline
let task3 = parser.parse("Start project tomorrow, finish by next week")
print(task3.scheduledDate)  // Tomorrow
print(task3.deadline)       // Next week
```

## Extracting Dates and Times

### Absolute Dates

```swift
// English
parser.parse("Meeting on 15th March 2025")

// German
germanParser.parse("Termin am 15. März 2025")

// French
let frenchParser = TaskParser(config: .french)
frenchParser.parse("Réunion le 15 mars 2025")
```

### Relative Dates

```swift
// English
parser.parse("Review document today")
parser.parse("Call back tomorrow")
parser.parse("Team meeting next Monday")

// German
germanParser.parse("Dokument heute prüfen")
germanParser.parse("Morgen zurückrufen")
germanParser.parse("Nächsten Montag Teambesprechung")
```

### Times

```swift
// Various time formats
parser.parse("Dentist at 2pm")
parser.parse("Workout at 6:30")
parser.parse("Conference call at 14:00")

// Combined with dates
parser.parse("Doctor appointment tomorrow at 3:30pm")
```

## Priorities

Extract task priorities using exclamation marks or keywords:

```swift
// Exclamation marks
let task1 = parser.parse("!!! Critical bug fix")
print(task1.priority)  // .high

let task2 = parser.parse("!! Review PR")
print(task2.priority)  // .medium

let task3 = parser.parse("! Update docs")
print(task3.priority)  // .low

// Keywords
let task4 = parser.parse("URGENT: Fix production issue")
print(task4.priority)  // .high
```

## Tags and Projects

### Hash Tags (Labels)

```swift
let task = parser.parse("Buy groceries #shopping #weekend")
print(task.title)  // "Buy groceries #shopping #weekend"
// Tags remain in the title for EventKit notes field
```

### At Tags (Projects)

```swift
let task = parser.parse("Write documentation @KinjoCore")
print(task.title)  // "Write documentation @KinjoCore"
```

## Recurring Tasks

The TaskParser supports complex recurring patterns:

### Simple Patterns

```swift
// Daily
parser.parse("Water plants every day")
parser.parse("Daily standup")

// Weekly
parser.parse("Team meeting every Monday")
parser.parse("Weekly review every Friday")

// Monthly
parser.parse("Pay rent every month")
parser.parse("Monthly report every 1st")
```

### Complex Patterns

```swift
// Multiple days
parser.parse("Gym every Monday, Wednesday, Friday")

// Intervals
parser.parse("Backup every 2 weeks")
parser.parse("Review every 3 months")

// Positional
parser.parse("Team meeting first Monday of month")
parser.parse("Planning last Friday of month")
```

For more details on recurrence rules, see <doc:WorkingWithRecurrence>.

## Multi-Language Support

The TaskParser supports four languages out of the box:

```swift
// German
let de = TaskParser(config: .german)
de.parse("Einkaufen morgen um 15 Uhr")

// English
let en = TaskParser(config: .english)
en.parse("Shopping tomorrow at 3pm")

// French
let fr = TaskParser(config: .french)
fr.parse("Courses demain à 15h")

// Spanish
let es = TaskParser(config: .spanish)
es.parse("Compras mañana a las 3pm")
```

## Using Annotations for UI

The parser provides annotations that indicate which parts of the input were recognised:

```swift
let result = parser.parse("Call John tomorrow at 3pm !!")

for annotation in result.annotations {
    switch annotation.type {
    case .date:
        print("Date found at \(annotation.range)")
    case .time:
        print("Time found at \(annotation.range)")
    case .priority:
        print("Priority found at \(annotation.range)")
    default:
        break
    }
}
```

Use these annotations to highlight parsed elements in your UI:

```swift
struct TaskInputView: View {
    @State private var input = ""
    @State private var parsedTask: ParsedTask?

    var body: some View {
        TextField("Enter task", text: $input)
            .onChange(of: input) { _, newValue in
                parsedTask = TaskParser().parse(newValue)
            }

        // Display parsed result
        if let task = parsedTask {
            VStack(alignment: .leading) {
                Text("Title: \(task.title)")
                if let date = task.scheduledDate {
                    Text("When: \(date.formatted())")
                }
                if let priority = task.priority {
                    Text("Priority: \(priority)")
                }
            }
        }
    }
}
```

## Custom Reference Dates

For testing or special use cases, you can provide a custom reference date:

```swift
let futureDate = Date(timeIntervalSinceNow: 86400 * 30) // 30 days from now
let parser = TaskParser(referenceDate: futureDate)

let task = parser.parse("tomorrow")
// "tomorrow" is calculated relative to futureDate
```

## Tips and Best Practices

1. **Be specific with dates**: "Monday" is clearer than "next week"
2. **Use deadline keywords**: "by", "until", "bis" (German) clearly indicate deadlines
3. **Combine information**: "Doctor tomorrow at 3pm !! #health" parses everything in one go
4. **Test different phrasings**: The parser supports multiple ways to express the same thing
5. **Use priorities wisely**: Reserve !!! for truly critical tasks

## See Also

- ``TaskParser``
- ``ParsedTask``
- ``ParserConfig``
- <doc:WorkingWithRecurrence>
- <doc:WorkingWithFilters>
