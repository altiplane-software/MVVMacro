#!/bin/bash
set -e

# Function to check if running on macOS
check_macos() {
    if [ "$(uname)" != "Darwin" ]; then
        echo "Error: This script must be run on macOS"
        exit 1
    fi
}

# Function to check if Xcode is installed
check_xcode() {
    if ! command -v xcodebuild &> /dev/null; then
        echo "Error: Xcode command line tools not found"
        echo "Please install Xcode from the App Store or run 'xcode-select --install'"
        exit 1
    fi
}

# Function to check Swift version - currently just logs the version without validation
check_swift() {
    local current_version=$(swift --version | head -n 1)
    echo "Info: Using $current_version"
}

# Function to check if files already exist - now always proceeds
check_files() {
    # Check if Package.swift exists and is not a symlink
    if [ -f "Package.swift" ]; then
        echo "Note: Package.swift exists, will overwrite if needed"
    fi
}

# Main setup function
setup_development() {
    echo "Setting up MVVMacro development environment..."
    
    # Create initial development configuration
    cp Package.development.swift Package.swift
    
    # Make build script executable
    chmod +x build_xcframework.sh
    
    # Create empty Artifacts directory if it doesn't exist
    mkdir -p Artifacts
    
    echo "Development environment setup complete!"
    echo
    echo "Next steps:"
    echo "1. Run 'make dev' to ensure you're in development mode"
    echo "2. Run 'make build' to build the project"
    echo "3. Run 'make test' to run tests"
    echo
    echo "When ready to create a distribution build:"
    echo "1. Run 'make dist' to build the XCFramework and switch to distribution mode"
}

# Run setup
check_macos
check_xcode
check_swift
check_files
setup_development