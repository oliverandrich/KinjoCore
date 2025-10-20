# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Protocol-based service architecture for improved testability
  - `PermissionServiceProtocol`, `ReminderServiceProtocol`, and `CalendarServiceProtocol`
  - All services now use dependency injection with protocols instead of concrete types
  - Enables proper unit testing without EventKit dependencies
- MockingKit integration for clean, maintainable test mocks
  - Simple stub-based mock implementations for all service protocols
  - Test helper (`Reminder.makeTest`) for creating test data without EventKit
  - Improved test isolation and reliability
- SmartFilter system for creating custom reminder views
  - `SmartFilter` SwiftData model with iCloud synchronisation
  - `SmartFilterService` for CRUD operations and filter management
  - `FilterCriteria` struct for serialisable filter configuration
  - Built-in filters: "All", "Today", "Tomorrow", "This Week", "Flagged", "Completed"
  - Support for custom icons (SF Symbols), tint colours, and sort order
  - Built-in filters cannot be deleted
- Full-text search filtering (`TextSearchFilter`)
  - Search in title only, notes only, or both
  - Case-insensitive search
  - Integrates with existing filter pipeline
- Extended `TagFilter` with inverted filter options
  - `.notHasTag(String)` - excludes reminders with specific tag
  - `.notHasAnyTag([String])` - excludes reminders with any of the tags (renamed from `excludingTags`)
  - `.notHasAllTags([String])` - includes reminders missing at least one tag
- Extended `ReminderListSelection` with exclusion option
  - `.excluding([ReminderList])` - fetch from all lists except specified ones

### Changed
- Service architecture refactored to use protocol-based dependency injection
  - Services accept protocol types instead of concrete implementations
  - Filter and sort methods in `ReminderService` are now `public` for direct testing
- **Breaking:** `TagFilter.excludingTags` renamed to `.notHasAnyTag` for consistency
- All filter enums now conform to `Codable` for serialisation
  - `ReminderFilter`, `DateRangeFilter`, `TagFilter`, `ReminderSortOption`, `TextSearchFilter`
- `ReminderService.fetchReminders()` now accepts `textSearch` parameter
- Tests adapted to handle missing EventKit permissions in CI environments
  - Tests that require EventKit access now gracefully skip when permissions are unavailable
  - Ensures CI workflows succeed without interactive permission prompts
- Significantly improved test coverage with comprehensive unit tests
  - Added tests for all model computed properties (Reminder, Event, RecurringPattern)
  - Added tests for FilterCriteria conversion methods
  - Added tests for Calendar and ReminderList models
  - Test count increased from 320 to 400+ tests

## [0.10.0] - 2025-10-19

### Added
- Deterministic task parser (`TaskParser`) with multi-language support (German, English, French, Spanish)
  - Natural language parsing for dates, times, deadlines, and recurring patterns
  - Support for priorities, projects (@tags), and labels (#tags)
  - Semantic distinction between scheduled date (when to work) and deadline (when it must be done)
  - Complex recurrence patterns including positional rules (e.g., "first Monday", "last Friday")
  - `ParsedTask` model with annotations for UI highlighting of parsed elements
  - Command-line tool `parse-task` for testing the parser
- Swift-DocC documentation with comprehensive guides:
  - Getting Started guide
  - Advanced guide for working with recurrence rules
  - API reference with full DocC coverage
  - Automatic deployment to GitHub Pages
- `justfile` commands for development:
  - `just test` - Run all tests (macOS and iOS)
  - `just docs` - Generate static documentation
  - `just preview-docs` - Local documentation preview with live reload

### Changed
- Test infrastructure now uses `xcodebuild test` instead of `swift test` for better EventKit compatibility
- Tests run with proper simulator management and serial execution for reliability

### Fixed
- Documentation link warnings in DocC
- Parameter documentation mismatches

## [0.9.0] - 2025-10-19

### Added

- EventKit integration with Permission Service for managing calendar and reminder access
- CalendarService for fetching and managing calendars and events
- ReminderService for managing reminders and reminder lists
- Event model with meeting link detection for video conferencing URLs
- Reminder model with comprehensive properties:
  - Completion and last modified dates
  - Boolean computed properties for convenience
  - URL detection in both dedicated URL field and notes
  - Tag extraction from notes with support for hash-tag syntax
- ReminderList model with CRUD operations
- Priority enum for type-safe priority handling with EventKit conversion
- Recurrence rule support for repeating reminders with complex patterns
- Alarm support with time-based and location-based triggers
- Location support for reminders (both simple text and structured locations)
- Tag filtering system with multiple filter modes (any, all, excluding)
- Reminder fetching with filtering options:
  - Completion status (all, completed, incomplete)
  - Date range filtering
  - Tag-based filtering
  - Multiple sorting options (title, due date, priority, creation date)
- Event fetching with calendar selection and date range filtering
- Complete CRUD operations for reminders and reminder lists
- iCloud and local source support for reminder lists

### Fixed

- Source selection logic for ReminderList creation to properly handle default sources

### Documentation

- Project README with comprehensive overview
- CLAUDE.md with development guidelines and project documentation
- EUPL 1.2 licence file
- CONTRIBUTORS.md file
- Commit message guidelines following Conventional Commits
- EUPL 1.2 licence headers on all source files

[unreleased]: https://github.com/oliverandrich/KinjoCore/compare/v0.10.0...HEAD
[0.10.0]: https://github.com/oliverandrich/KinjoCore/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/oliverandrich/KinjoCore/releases/tag/v0.9.0
