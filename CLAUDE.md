# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KinjoCore is a Swift Package Manager (SPM) library that provides the service layer for macOS and iOS applications. It targets **Swift 6.2 exclusively** with **minimum deployment targets of iOS 26 and macOS 26**. There is no need to maintain backward compatibility with older OS versions.

### Purpose
KinjoCore serves as the core service layer that will be integrated into both macOS and iOS applications, providing shared business logic and data management capabilities.

## Development Commands

This project uses [just](https://github.com/casey/just) as a command runner. All common development tasks are defined in the `justfile`.

### Prerequisites

Install required tools:
```bash
brew install just xcbeautify
```

### Available Just Commands

```bash
# Building
just build              # Build the package using swift build

# Testing
just test               # Run all tests (macOS and iOS)
just test-macos         # Run tests on macOS only
just test-ios           # Run tests on iOS Simulator (iPhone 17, iOS 26.0)

# Documentation
just docs               # Generate documentation for GitHub Pages
just preview-docs       # Preview documentation with live reload

# Cleaning
just clean              # Clean build artifacts
```

### Testing Strategy
- **During development**: Use `just test-macos` for quick feedback
- **Before commits/PRs**: Use `just test` to run tests on both platforms
- Tests on both platforms are important as EventKit behaviour can differ between iOS and macOS

### Direct Swift Commands (alternative to just)
If you need to use Swift Package Manager commands directly:

```bash
# Build
swift build

# Test (macOS only via SPM)
swift test

# Test with verbose output
swift test --verbose

# Run a specific test
swift test --filter <test-name>

# Clean
swift package clean
```

**Note**: For cross-platform testing and coverage reports, prefer using the `just` commands as they properly configure xcodebuild with the correct destinations and settings.

## Documentation & Code Style

### Language
All documentation and code comments in this project must be written in **British English**.

This applies to:
- README files
- Code comments and documentation comments (`///` doc comments)
- CHANGELOG or other documentation files
- Error messages and user-facing strings
- Test descriptions

Examples of British English spelling:
- Use "synchronise" not "synchronize"
- Use "colour" not "color"
- Use "behaviour" not "behavior"
- Use "initialise" not "initialize"
- Use "organise" not "organize"

**Note:** Commit messages (Conventional Commits) should also follow British English conventions.

## Git Workflow

### Commit Message Format
This project uses **Conventional Commits** for all commit messages.

Format:
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Required Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code formatting, missing semicolons, etc. (no code change)
- `refactor:` - Code refactoring (no functional changes)
- `perf:` - Performance improvements
- `test:` - Adding or updating tests
- `build:` - Build system or dependency changes
- `ci:` - CI/CD configuration changes
- `chore:` - Other changes (tooling, configs, etc.)

**Examples:**
```
feat: add EventKit task synchronization service
fix: resolve SwiftData iCloud sync conflict
docs: update CLAUDE.md with licensing information
refactor: improve service initialization pattern
test: add unit tests for FoundationModels integration
```

**Guidelines:**
- Use lowercase for type and description
- Keep the description concise (50 characters or less)
- Use imperative mood ("add" not "added" or "adds")
- Add scope in parentheses when relevant: `feat(eventkit): add reminder support`
- Include breaking changes with `BREAKING CHANGE:` in footer or `!` after type: `feat!: change service API`
- **NEVER add references to Claude, AI tools, or any advertisements** in commit messages (no "Co-Authored-By: Claude", no "Generated with Claude", etc.)
- **Do not mention** EUPL 1.2 licence headers or British English documentation adherence in commit messages (these are project standards and don't need to be stated in every commit)
- **Keep commit messages compact**: Be informative but concise. Avoid overly verbose bodies - focus on key changes and rationale, not exhaustive implementation details
- **Do not include test counts or results** in commit messages (e.g., "17 tests passing", "69 tests total") - tests are verified by CI and the counts change frequently

### Changelog Management

This project maintains a changelog following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format in `CHANGELOG.md`.

**When to update the changelog:**

For **every commit** that affects functionality or user experience, you **must** update the `CHANGELOG.md` file under the `[Unreleased]` section before committing. This ensures the changelog stays current and release preparation is simplified.

**Mapping Conventional Commit types to Changelog categories:**

- `feat:` → **Added** - New features or capabilities
- `fix:` → **Fixed** - Bug fixes
- `refactor:` → **Changed** - Refactorings that change behaviour
- `perf:` → **Changed** - Performance improvements
- `BREAKING CHANGE` → **Changed** (with clear indication it's breaking)
- `deprecate:` or deprecation notices → **Deprecated**
- Removal of deprecated features → **Removed**
- Security-related fixes → **Security**

**Do NOT add changelog entries for:**
- `docs:` - Documentation changes (unless they describe a new user-facing feature)
- `test:` - Test additions or modifications
- `style:` - Code style changes
- `chore:` - Maintenance tasks, dependency updates
- `build:` - Build system changes
- `ci:` - CI/CD configuration changes

**Format for changelog entries:**

Each entry should be a concise bullet point describing the change from a user's perspective:

```markdown
## [Unreleased]

### Added
- New feature X that allows users to do Y

### Fixed
- Issue where Z would fail under condition W

### Changed
- Service X now uses approach Y for better performance
```

**Before creating a release:**

1. Change `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD`
2. Add a new empty `[Unreleased]` section at the top
3. Update the comparison links at the bottom of the file
4. Create a git tag for the release

## Code Architecture

### Package Structure
- **Sources/KinjoCore/**: Contains the library source code
  - Main entry point: `KinjoCore.swift`
- **Tests/KinjoCoreTests/**: Contains test suites
  - Uses Swift Testing framework (not XCTest)
  - Tests can be run with `@Test` macro

### Service Layer Integration
Services provided by KinjoCore are designed to be injected into the iOS and macOS applications using **SwiftUI Environment**.

Key principles:
- All services should be defined as observable classes (using `@Observable` macro)
- Services are exposed to the app layer via SwiftUI's environment system
- Use `@Environment` property wrapper in views to access services
- Services should be registered in the app's entry point using `.environment()` modifier

Example pattern:
```swift
// In KinjoCore - Service definition
@Observable
public class MyService {
    // Service implementation
}

// In iOS/macOS App - Service registration
@main
struct MyApp: App {
    private let myService = MyService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(myService)
        }
    }
}

// In Views - Service usage
struct ContentView: View {
    @Environment(MyService.self) private var myService
    // Use service
}
```

### Testing Framework
This project uses the **Swift Testing** framework (introduced in Swift 5.9+), NOT XCTest. Key differences:
- Use `@Test` attribute instead of `XCTestCase` classes
- Use `#expect(...)` for assertions instead of `XCTAssert...`
- Tests can be async by default (`async throws`)
- Import tests with `@testable import KinjoCore`

### Testing with Mocks (MockingKit)

This project uses **protocol-based dependency injection** combined with **MockingKit** for testing.

**Key principles:**
- All services implement protocols (`PermissionServiceProtocol`, `ReminderServiceProtocol`, `CalendarServiceProtocol`)
- Services accept protocol types in their initialisers: `init(permissionService: any PermissionServiceProtocol)`
- Tests use simple stub-based mocks instead of EventKit dependencies

**Creating mocks:**
Mock implementations are located in `Tests/KinjoCoreTests/Mocks/`. Each mock provides stub implementations that return configurable values:

```swift
class MockPermissionService: PermissionServiceProtocol {
    var mockHasReminderAccess: Bool = true  // Configurable
    var mockHasCalendarAccess: Bool = true

    var hasReminderAccess: Bool {
        mockHasReminderAccess  // Returns configured value
    }

    // ... other methods
}
```

**Using mocks in tests:**
```swift
@Test("My test")
@MainActor
func myTest() async throws {
    // Create mock
    let mockPermissions = MockPermissionService()
    mockPermissions.mockHasReminderAccess = true

    // Inject into service
    let service = ReminderService(permissionService: mockPermissions)

    // Test without EventKit
    let result = service.applyFilter(.all, to: testReminders)
    #expect(result.count == 5)
}
```

**Creating test data:**
Use `Reminder.makeTest()` helper to create test reminders without EventKit:

```swift
let testReminder = Reminder.makeTest(
    title: "Test Task",
    notes: "Notes #tag",
    dueDate: Date(),
    priority: .high,
    isCompleted: false
)
```

**Why this approach?**
- ✅ Tests run without EventKit permissions
- ✅ Fast, isolated tests
- ✅ Works on CI/CD without interactive permission prompts
- ✅ Simple, maintainable mocks (no complex mocking framework magic)
- ✅ Tests our code, not Apple's EventKit implementation

### Swift Version
The project requires Swift 6.2 or higher (`swift-tools-version: 6.2` in Package.swift).

## Core Technologies & Frameworks

### EventKit
- **Primary data storage and synchronisation technology**
- Uses EventKit for task management and synchronisation
- **Full recurrence rule support** for repeating reminders (EKRecurrenceRule)
- Supports complex recurrence patterns including positional rules (e.g., "first Monday", "last Friday")
- Only use APIs available in iOS 26+ and macOS 26+ versions of EventKit
- No need to handle deprecated or legacy EventKit APIs

### FoundationModels
- Integration with Apple's **FoundationModels** framework for AI functionality
- Use the latest version available for iOS 26+ and macOS 26+
- Provides AI-powered features within the service layer

### SwiftData
- Used for storing application-specific data (not task data - that's in EventKit)
- **iCloud synchronization** enabled for all SwiftData models
- All persistent data should be defined using SwiftData models
- Ensure models are designed with iCloud sync in mind (consider sync conflicts, model versioning)

### Platform Requirements
- **Minimum iOS version:** 26.0
- **Minimum macOS version:** 26.0
- **Swift version:** 6.2 (exclusively)
- No backward compatibility required - always use the latest APIs available

## Licensing

This project is licensed under the **EUPL 1.2** (European Union Public Licence v. 1.2).

### License Headers
**All new source code files must include the EUPL 1.2 license header** at the top of the file.

Required header format for Swift files:
```swift
// Copyright (C) [Year] [Copyright Holder]
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
```

When creating new files:
- Add the license header at the very top of each `.swift` file
- Replace `[Year]` with the current year
- Replace `[Copyright Holder]` with the appropriate copyright holder information
- Ensure the header is present before any `import` statements

## Important Notes

- The project uses Swift 6.2's strict concurrency checking
- All new code should be compatible with Swift 6 concurrency model
- The library target has no external dependencies (modify Package.swift if adding dependencies)
- **Always add the EUPL 1.2 license header to new source files**
