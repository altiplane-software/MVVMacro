//
//  ActionHandlingViewModel.swift
//  MVVMacro
//
//  Created by Jasper S. Valdivia on 02/05/2025.
//
@MainActor
public protocol ActionHandlingViewModel {
    associatedtype SendableAction: ActionProtocol
    func send(_ action: SendableAction)
}