# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
