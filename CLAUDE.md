# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands
- Build: `swift build`
- Test all: `swift test`
- List tests: `swift test --list-tests`
- Run single test: `swift test --filter MVVMacroTests/testFunctionName`
- Production build: `MVVMACRO_PRODUCTION=1 swift build -c release` (requires binary artifacts)

## CI/CD
- CI uses CircleCI with macOS/Xcode environments
- Development job: `swift build && swift test`
- Production job: Creates XCFramework for distribution
- CircleCI config in `.circleci/config.yml`
- Note: CircleCI macOS jobs cannot run locally with `circleci local execute`

## Code Style Guidelines
- Indentation: 4 spaces
- File headers: Include filename and creation date in comments
- Organization: Use `// MARK: - Section Name` for code organization
- Documentation: Use `///` for documentation comments
- Architecture: Follow MVVM pattern with Swift macros
- Access control: Prefer private properties when possible
- Actor safety: Use `@MainActor` for UI-related code
- Extensions: Use extensions for protocol conformance
- Error handling: Use structured Swift error handling with do-catch

## Project Structure
- MVVMacroAPI: Public API interfaces and protocols
- MVVMacroImpl: Macro implementation details (development only)
- MVVMacroBinary: Binary distribution (production only)
- Tests: Unit tests for macro functionality