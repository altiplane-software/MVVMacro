# MVVMacro
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/altiplane-software/MVVMacro/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/altiplane-software/MVVMacro/tree/main)

## Development & Distribution

MVVMacro uses a two-package approach to optimize compilation time for consumers.

## Quick Start

```bash
# Initial setup (only needed once)
chmod +x setup.sh
./setup.sh

# Show available commands
make help
```

## Using the Makefile

MVVMacro includes a Makefile to simplify common tasks:

```bash
# Switch to development mode
make dev

# Build and test
make build
make test

# Build XCFramework and switch to distribution mode
make dist

# Clean build artifacts
make clean
```

## Package Structure

### For Consumers

The default `Package.swift` uses precompiled XCFrameworks, eliminating the need for consumers to compile swift-syntax dependencies.

### For Contributors

Development is done using `Package.development.swift`, which includes all necessary dependencies for building and testing macros.

## Manual Commands

If you prefer not to use the Makefile:

### Development Mode

```bash
# Switch to development mode
cp Package.development.swift Package.swift

# Build and test
swift build
swift test
```

### Distribution Mode

```bash
# Build XCFramework
chmod +x build_xcframework.sh
./build_xcframework.sh

# Switch to distribution mode
cp Package.distribution.swift Package.swift
```