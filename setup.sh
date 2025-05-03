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

# Function to check Swift version
check_swift() {
    local required_version="6.0.3"
    local current_version=$(swift --version | head -n 1 | sed 's/.*Swift version \([0-9.]*\).*/\1/')
    
    if [ "$(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n1)" != "$required_version" ]; then
        echo "Warning: Swift version $required_version is required, but $current_version is installed"
        echo "You may encounter build issues if continuing"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check if files already exist
check_files() {
    local files_exist=0
    
    # Check if Package.swift exists and is not a symlink to either development or distribution
    if [ -f "Package.swift" ] && [ ! -L "Package.swift" ]; then
        files_exist=1
    fi
    
    # If any required file exists, ask user before proceeding
    if [ $files_exist -eq 1 ]; then
        echo "Warning: Some setup files already exist"
        read -p "Overwrite existing files? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Setup cancelled"
            exit 0
        fi
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