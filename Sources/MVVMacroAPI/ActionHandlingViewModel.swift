//
//  ActionHandlingViewModel.swift
//  MVVMacro
//
//  Created by Jasper S. Valdivia on 02/05/2025.
//
import Combine

@MainActor
public protocol ActionHandlingViewModel: ObservableObject {
    associatedtype SendableAction: ActionProtocol
    var actionHandlers: [SendableAction.Key: (Any?) -> Void] { get }

    func send(_ action: SendableAction)
}

@MainActor
public extension ActionHandlingViewModel {
    func send(_ action: SendableAction) {
        actionHandlers[action.key]?(action.associatedValue)
    }

    func bindHandler<T>(_ method: @escaping @MainActor (T) -> Void) -> (Any?) -> Void {
        return { @MainActor [weak self] value in
            guard self != nil else {
                // Debugging log: You can safely remove this in production
                assertionFailure("ViewModel was deallocated before handler was executed")
                return
            }
            guard let typedValue = value as? T else {
                assertionFailure("Unexpected type for value: \(String(describing: value))")
                return
            }
            method(typedValue)
        }
    }
}
