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

import EventKit
import Foundation
import MockingKit
@testable import KinjoCore

#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Mock implementation of ReminderServiceProtocol for testing.
///
/// **Note**: This mock provides stub implementations for most methods.
/// For testing filter and sort operations, use the real ReminderService
/// as those methods are pure functions without EventKit dependencies.
///
/// Add MockReferences for specific methods as needed for your tests.
@MainActor
class MockReminderService: Mock, ReminderServiceProtocol {

    // MARK: - Properties (stubbed)

    var reminderLists: [ReminderList] = []
    var reminders: [Reminder] = []

    // MARK: - Filter & Sort Methods (delegated to real service)
    // These are pure functions, so we can safely use the real implementation

    private let realService: ReminderService

    init(permissionService: any PermissionServiceProtocol) {
        self.realService = ReminderService(permissionService: permissionService)
        super.init()
    }

    func applyFilter(_ filter: ReminderFilter, to reminders: [Reminder]) -> [Reminder] {
        realService.applyFilter(filter, to: reminders)
    }

    func applyDateFilter(_ dateFilter: DateRangeFilter, to reminders: [Reminder]) -> [Reminder] {
        realService.applyDateFilter(dateFilter, to: reminders)
    }

    func applyTagFilter(_ tagFilter: TagFilter, to reminders: [Reminder]) -> [Reminder] {
        realService.applyTagFilter(tagFilter, to: reminders)
    }

    func applyTextFilter(_ textFilter: TextSearchFilter, to reminders: [Reminder]) -> [Reminder] {
        realService.applyTextFilter(textFilter, to: reminders)
    }

    func applySort(_ sortOption: ReminderSortOption, to reminders: [Reminder]) -> [Reminder] {
        realService.applySort(sortOption, to: reminders)
    }

    // MARK: - Stub Implementations (Not Used in Current Tests)

    func fetchReminderLists() async throws -> [ReminderList] {
        fatalError("Not implemented - add MockReference if needed")
    }

    func createReminderList(title: String, color: CGColor?, sourceType: EKSourceType?) async throws -> ReminderList {
        fatalError("Not implemented - add MockReference if needed")
    }

    func updateReminderList(_ listId: String, title: String?, color: CGColor?) async throws -> ReminderList {
        fatalError("Not implemented - add MockReference if needed")
    }

    func updateReminderList(_ list: ReminderList, title: String?, color: CGColor?) async throws -> ReminderList {
        fatalError("Not implemented - add MockReference if needed")
    }

    func deleteReminderList(_ listId: String) async throws {
        fatalError("Not implemented - add MockReference if needed")
    }

    func deleteReminderList(_ list: ReminderList) async throws {
        fatalError("Not implemented - add MockReference if needed")
    }

    func fetchReminders(from: ReminderListSelection, filter: ReminderFilter, dateRange: DateRangeFilter, tagFilter: TagFilter, textSearch: TextSearchFilter, sortBy: ReminderSortOption) async throws -> [Reminder] {
        fatalError("Not implemented - add MockReference if needed")
    }

    func createReminder(title: String, notes: String?, startDate: Date?, dueDate: Date?, priority: Priority, recurrenceRules: [RecurrenceRule]?, alarms: [Alarm]?, location: String?, in list: ReminderList) async throws -> Reminder {
        fatalError("Not implemented - add MockReference if needed")
    }

    func updateReminder(_ reminderId: String, title: String?, notes: String?, startDate: Date?, dueDate: Date?, priority: Priority?, recurrenceRules: [RecurrenceRule]?, alarms: [Alarm]?, location: String?, moveTo list: ReminderList?) async throws -> Reminder {
        fatalError("Not implemented - add MockReference if needed")
    }

    func deleteReminder(_ reminderId: String) async throws {
        fatalError("Not implemented - add MockReference if needed")
    }

    func deleteReminder(_ reminder: Reminder) async throws {
        fatalError("Not implemented - add MockReference if needed")
    }

    func toggleReminderCompletion(_ reminderId: String) async throws -> Reminder {
        fatalError("Not implemented - add MockReference if needed")
    }

    func toggleReminderCompletion(_ reminder: Reminder) async throws -> Reminder {
        fatalError("Not implemented - add MockReference if needed")
    }
}
