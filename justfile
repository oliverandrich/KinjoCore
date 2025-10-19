# Run all tests (macOS and iOS)
test: test-macos test-ios

# Run tests on macOS
test-macos:
    xcodebuild test \
        -scheme KinjoCore \
        -destination 'platform=macOS'

# Run tests on iOS Simulator
test-ios:
    #!/usr/bin/env bash
    # Boot simulator first
    xcrun simctl boot "iPhone 17" 2>/dev/null || true
    sleep 2
    xcodebuild test \
        -scheme KinjoCore \
        -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0'

# Build the package
build:
    swift build

# Clean build artifacts
clean:
    swift package clean
