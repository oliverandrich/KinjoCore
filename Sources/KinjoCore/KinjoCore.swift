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

/// KinjoCore provides the core service layer for task and reminder management.
///
/// This framework integrates with EventKit to provide a clean, Swift-native API
/// for managing reminders, tasks, and calendars across iOS and macOS applications.
///
/// ## Key Services
///
/// - ``PermissionService``: Manages EventKit permissions and provides access to the event store
/// - ``ReminderService``: Handles reminder lists and reminder operations
/// - ``CalendarService``: Handles calendars and event operations
/// - ``TaskParser``: Parses natural language input into structured task data
///
/// ## Getting Started
///
/// Services are designed to be injected into your SwiftUI application using the environment:
///
/// ```swift
/// @main
/// struct MyApp: App {
///     private let permissionService = PermissionService()
///     private let reminderService: ReminderService
///     private let calendarService: CalendarService
///     private let taskParser = TaskParser(config: .german)
///
///     init() {
///         self.reminderService = ReminderService(permissionService: permissionService)
///         self.calendarService = CalendarService(permissionService: permissionService)
///     }
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .environment(permissionService)
///                 .environment(reminderService)
///                 .environment(calendarService)
///                 .environment(taskParser)
///         }
///     }
/// }
/// ```
///
/// ## Natural Language Parsing
///
/// Use the ``TaskParser`` to parse natural language input:
///
/// ```swift
/// let parser = TaskParser(config: .german)
/// let task = parser.parse("Jeden Freitag um 17 Uhr Softfolio eintragen @Arbeit p1")
///
/// // Access parsed values
/// print(task.title)          // "Softfolio eintragen"
/// print(task.priority)       // 1
/// print(task.project)        // "Arbeit"
/// print(task.recurring)      // Every Friday
///
/// // Use annotations for UI highlighting
/// for annotation in task.annotations {
///     highlightText(annotation.text, as: annotation.type)
/// }
/// ```
