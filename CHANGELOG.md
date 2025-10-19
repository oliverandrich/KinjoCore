# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions workflow for automated testing on macOS with Xcode 26
- Added justfile for convenient local testing with `just test`
- Swift-DocC-Plugin integration for generating API documentation
- DocC catalog with comprehensive documentation structure:
  - Landing page with Topics organisation
  - Getting Started guide for new users
  - Advanced guide for working with recurrence rules
- GitHub Actions workflow for automatic documentation deployment to GitHub Pages
- `just docs` and `just preview-docs` commands for local documentation generation

### Changed
- Migrated repository from Codeberg to GitHub for CI/CD support with macOS runners
- GitHub Actions now uses macOS 26 runner with macOS 26 SDK
- iOS test target in justfile now boots simulator automatically before running tests
- Disabled parallel testing for both macOS and iOS targets for improved reliability with EventKit
- iOS test target now shuts down all simulators before each run to ensure clean state
- Re-enabled iOS tests in GitHub Actions workflow with serial test execution and proper simulator management

### Documentation
- Added Swift version, platform, and SPM compatibility badges to README
- Added GitHub Actions test status badge to README
- Enhanced code comments with examples for CalendarSelection and ReminderListSelection
- Added comprehensive Topics organisation to DocC landing page

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

[unreleased]: https://github.com/oliverandrich/KinjoCore/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/oliverandrich/KinjoCore/releases/tag/v0.9.0
