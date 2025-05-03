.PHONY: all dev dist test clean build-xcframework setup help

# Default target
all: help

# Check if running on macOS
check-macos:
	@if [ "$$(uname)" != "Darwin" ]; then \
		echo "Error: This Makefile must be run on macOS"; \
		exit 1; \
	fi

# Setup development environment
setup: check-macos
	@echo "Setting up development environment..."
	@./setup.sh
	@echo "Setup complete!"

# Switch to development mode
dev: check-macos
	@echo "Switching to development mode..."
	@cp Package.development.swift Package.swift
	@echo "Done! You can now run 'make build' or 'make test'"

# Switch to distribution mode
dist: check-macos
	@echo "Building XCFramework and switching to distribution mode..."
	@chmod +x build_xcframework.sh
	@./build_xcframework.sh --distribution
	@echo "Done! Distribution package is now active"

# Build the project
build: check-macos
	@echo "Building MVVMacro..."
	@swift build
	@echo "Build complete!"

# Run tests
test: check-macos
	@echo "Running tests..."
	@swift test
	@echo "Tests complete!"

# Build XCFramework for distribution
build-xcframework: check-macos
	@echo "Building XCFramework..."
	@chmod +x build_xcframework.sh
	@./build_xcframework.sh
	@echo "XCFramework build complete!"

# Clean build artifacts
clean: check-macos
	@echo "Cleaning build artifacts..."
	@rm -rf .build
	@echo "Cleaning complete!"

# Help message
help:
	@echo "MVVMacro Makefile Commands:"
	@echo "  make setup              - Set up the development environment"
	@echo "  make dev                - Switch to development mode"
	@echo "  make dist               - Build XCFramework and switch to distribution mode"
	@echo "  make build              - Build the current package"
	@echo "  make test               - Run tests"
	@echo "  make build-xcframework  - Build the XCFramework for distribution"
	@echo "  make clean              - Clean build artifacts"