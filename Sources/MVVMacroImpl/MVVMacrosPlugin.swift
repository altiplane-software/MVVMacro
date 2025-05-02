//
//  MVVMacrosPlugin.swift
//  MVVMacro
//
//  Created by Jasper S. Valdivia on 02/05/2025.
//
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
public struct MVVMacrosPlugin: CompilerPlugin {
    public init() {}
    public let providingMacros: [Macro.Type] = [
        ActionProtocolMacro.self,
        ActionHandlingViewModelMacro.self,
    ]
}
