.PHONY: all clean setup help test

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

# Test the project (automatically builds first)
test: check-macos
	@echo "Building and testing MVVMacro..."
	@swift test
	@echo "Tests complete!"

# Clean build artifacts
clean: check-macos
	@echo "Cleaning build artifacts..."
	@rm -rf .build
	@echo "Cleaning complete!"

# Help message
help:
	@echo "MVVMacro Makefile Commands:"
	@echo "  make setup              - Set up the development environment"
	@echo "  make test               - Build and test the project"
	@echo "  make clean              - Clean build artifacts"