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

# Function to check if necessary files exist
check_files() {
    # Check if Package.swift exists
    if [ ! -f "Package.swift" ]; then
        echo "Warning: Package.swift not found, this is required for the project"
    else
        echo "Found Package.swift"
    fi
}

# Main setup function
setup_development() {
    echo "Setting up MVVMacro development environment..."
    
    # Verify Package.swift exists
    if [ ! -f "Package.swift" ]; then
        echo "Error: Package.swift not found"
        exit 1
    fi
    
    echo "Development environment setup complete!"
    echo
    echo "Next steps:"
    echo "1. Run 'make test' to build and test the project"
    echo "2. Run 'make help' to see all available commands"
}

# Run setup
check_macos
check_xcode
check_swift
check_files
setup_development