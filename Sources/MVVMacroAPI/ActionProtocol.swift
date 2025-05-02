//
//  ActionProtocol.swift
//  MVVMacro
//
//  Created by Jasper S. Valdivia on 02/05/2025.
//
import Combine

public protocol ActionProtocol {
    associatedtype Key: Hashable
    var key: Key { get }
    var associatedValue: Any? { get }
}
