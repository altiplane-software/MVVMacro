# MVVMacro
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/altiplane-software/MVVMacro/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/altiplane-software/MVVMacro/tree/main)
[![Known Vulnerabilities](https://snyk.io/test/github/altiplane-software/MVVMacro/badge.svg)](https://snyk.io/test/github/altiplane-software/MVVMacro)

## Overview

MVVMacro is a Swift macro library that provides utilities for implementing the Model-View-ViewModel (MVVM) architectural pattern in Swift applications. It leverages Swift's macro system to simplify boilerplate code and provide type-safe view model actions.

## Quick Start

### Setting Up the Project

```bash
# Clone the repository
git clone https://github.com/altiplane-software/MVVMacro.git
cd MVVMacro

# Initial setup (only needed once)
chmod +x setup.sh
./setup.sh

# Show available commands
make help
```

### Integration into Your Project

Add MVVMacro to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/altiplane-software/MVVMacro.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["MVVMacro"]
    )
]
```

Then import and use the macros in your code:

```swift
import MVVMacro

@Action
enum YourAction {
    case someAction(String)
    case anotherAction
}
```

## Using the Makefile

MVVMacro includes a Makefile to simplify common tasks:

```bash
# Build and test the project (swift test handles the building)
make test

# Clean build artifacts
make clean
```

## Package Structure

The package structure is simple:

- `MVVMacroAPI`: Public API interfaces and protocols
  - Contains the `@Action` and `@ActionHandlingViewModel` macros
  - Defines core protocols like `ActionProtocol` and `ActionHandlingViewModel`
- `MVVMacroImpl`: Macro implementation details
  - Contains the Swift compiler plugin implementation of the macros
  - Handles code generation for the action handling system
- `Tests`: Unit tests for macro functionality
  - Validates the behavior of the macros and generated code

## Available Macros

### @Action

The `@Action` macro simplifies creating type-safe actions for your view models:

```swift
@Action
enum CounterAction {
    case increment
    case decrement
    case reset
}
```

This generates the necessary boilerplate to use these actions with your view model.

### @ActionHandlingViewModel

The `@ActionHandlingViewModel` macro equips your view model with action handling capabilities:

```swift
@ActionHandlingViewModel
class CounterViewModel {
    @Published var count = 0
    
    func handle(action: CounterAction) {
        switch action {
        case .increment:
            count += 1
        case .decrement:
            count -= 1
        case .reset:
            count = 0
        }
    }
}
```

This generates methods for sending actions to the view model in a type-safe way.

## Manual Commands

If you prefer not to use the Makefile:

```bash
# Build and test
swift test

# Run specific tests
swift test --filter MVVMacroTests/testFunctionName
```

## Requirements

- macOS 13 or later
- iOS 15.0 or later
- Swift 6.0.3 or later
- Xcode 16.0 or later

## Example Usage

Below is a complete example of how to use MVVMacro in a SwiftUI application:

```swift
import SwiftUI
import MVVMacro
import Combine

// Define actions using the @Action macro
@Action
enum TodoAction {
    case add(title: String)
    case toggle(id: UUID)
    case remove(id: UUID)
}

// Define a model
struct TodoItem: Identifiable {
    let id = UUID()
    let title: String
    var isCompleted: Bool = false
}

// Create a view model with the @ActionHandlingViewModel macro
@ActionHandlingViewModel
class TodoViewModel {
    @Published private(set) var items: [TodoItem] = []
    
    func handle(action: TodoAction) {
        switch action {
        case .add(let title):
            items.append(TodoItem(title: title))
        case .toggle(let id):
            if let index = items.firstIndex(where: { $0.id == id }) {
                items[index].isCompleted.toggle()
            }
        case .remove(let id):
            items.removeAll(where: { $0.id == id })
        }
    }
}

// Use the view model and actions in a SwiftUI view
struct TodoView: View {
    @StateObject var viewModel = TodoViewModel()
    @State private var newItemTitle = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("New todo", text: $newItemTitle)
                Button("Add") {
                    if !newItemTitle.isEmpty {
                        viewModel.send(.add(title: newItemTitle))
                        newItemTitle = ""
                    }
                }
            }
            .padding()
            
            List {
                ForEach(viewModel.items) { item in
                    HStack {
                        Text(item.title)
                            .strikethrough(item.isCompleted)
                        Spacer()
                        Button(item.isCompleted ? "Undo" : "Done") {
                            viewModel.send(.toggle(id: item.id))
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            viewModel.send(.remove(id: item.id))
                        }
                    }
                }
            }
        }
    }
}
```

## License

MVVMacro is available under the GNU General Public License v3.0 (GPL-3.0). See the LICENSE file for more info.