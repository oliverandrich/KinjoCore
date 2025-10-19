# Run all tests (macOS and iOS)
test: test-macos test-ios

# Run tests on macOS
test-macos:
    xcodebuild test \
        -scheme KinjoCore-Package \
        -destination 'platform=macOS' \
        -enableCodeCoverage NO

# Run tests on iOS Simulator
test-ios:
    #!/usr/bin/env bash
    # Shutdown all simulators to ensure clean state
    xcrun simctl shutdown all 2>/dev/null || true
    sleep 1
    # Boot simulator
    xcrun simctl boot "iPhone 17" 2>/dev/null || true
    sleep 3
    xcodebuild test \
        -scheme KinjoCore-Package \
        -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' \
        -enableCodeCoverage NO \
        -parallel-testing-enabled NO \
        2>&1 | tee /tmp/xcodebuild-ios.log
    # Shutdown after tests
    xcrun simctl shutdown "iPhone 17" 2>/dev/null || true

# Build the package
build:
    swift build

# Clean build artifacts
clean:
    swift package clean

# Generate documentation for GitHub Pages
docs:
    swift package \
        --allow-writing-to-directory ./docs \
        generate-documentation \
        --target KinjoCore \
        --output-path ./docs \
        --transform-for-static-hosting \
        --hosting-base-path KinjoCore

# Preview documentation with live reload (starts DocC preview server)
preview-docs:
    swift package --disable-sandbox preview-documentation --target KinjoCore
