#!/bin/bash
set -e

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo "Error: This script must be run on macOS"
    exit 1
fi

echo "Building MVVMacro XCFramework..."

# Save current package state
if [ -f Package.swift ]; then
    cp Package.swift Package.swift.bak
fi

# Use development package for building
cp Package.development.swift Package.swift

# Clean build artifacts
rm -rf .build
mkdir -p Artifacts

# First build the project with SwiftPM to ensure all dependencies are resolved
echo "Building with SwiftPM first..."
swift build

# Build for all platforms
echo "Building for iOS..."
xcodebuild archive \
    -scheme MVVMacro \
    -destination "generic/platform=iOS" \
    -archivePath ".build/ios.xcarchive" \
    -derivedDataPath ".build/DerivedData" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

echo "Building for iOS Simulator..."
xcodebuild archive \
    -scheme MVVMacro \
    -destination "generic/platform=iOS Simulator" \
    -archivePath ".build/ios-simulator.xcarchive" \
    -derivedDataPath ".build/DerivedData" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

echo "Building for macOS..."
xcodebuild archive \
    -scheme MVVMacro \
    -destination "generic/platform=macOS" \
    -archivePath ".build/macos.xcarchive" \
    -derivedDataPath ".build/DerivedData" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

# Create XCFramework
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework ".build/ios.xcarchive/Products/Library/Frameworks/MVVMacroBinary.framework" \
    -framework ".build/ios-simulator.xcarchive/Products/Library/Frameworks/MVVMacroBinary.framework" \
    -framework ".build/macos.xcarchive/Products/Library/Frameworks/MVVMacroBinary.framework" \
    -output "Artifacts/MVVMacroBinary.xcframework"

# Apply distribution package if requested
if [ "$1" == "--distribution" ] || [ "$1" == "-d" ]; then
    echo "Switching to distribution package..."
    cp Package.distribution.swift Package.swift
else
    # Restore original package
    if [ -f Package.swift.bak ]; then
        cp Package.swift.bak Package.swift
    fi
fi

# Clean up backup
rm -f Package.swift.bak

echo "XCFramework built successfully at Artifacts/MVVMacroBinary.xcframework"