//
//  ActionProtocolMacro.swift
//  MVVMacro
//
//  Created by Jasper S. Valdivia on 02/05/2025.
//
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser


public struct ActionProtocolMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        let actionExtension = try ExtensionDeclSyntax("extension \(type.trimmed): ActionProtocol {}")

        return [actionExtension]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDeclaration = declaration.as(EnumDeclSyntax.self) else { return [] }

        // Extract case information
        let cases = enumDeclaration.memberBlock.members.compactMap { member -> EnumCaseElementSyntax? in
            guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { return nil }
            return enumCaseDecl.elements.first
        }

        // Propagate class access level for generated members
        let isPublic = enumDeclaration.modifiers.contains(
            where: {
                $0.name.text == "public" || $0.name.text == "open"
            }
        )
        let visibilityPrefix: String = isPublic ? "public " : ""


        let keyEnum = try EnumDeclSyntax("""
        \(raw: visibilityPrefix)enum Key: Hashable {
        }
        """)

        /// Populate the enum with the cases
        let keyCases = cases.map { c in
            "case \(c.name)"
        }

        let keyEnumWithCases = keyEnum.with(\.memberBlock.members, MemberBlockItemListSyntax {
            for kc in keyCases {
                DeclSyntax(stringLiteral: kc)
            }
        })

        /// Generate the `var key: Key` computed property
        /// It will switch over `self` and return `Key.<case>`
        let keyProperty = try makeKeyProperty(
            cases: cases,
            enumName: enumDeclaration.name.text,
            visibilityPrefix: visibilityPrefix
        )

        /// Generate the `var associatedValue: Any?` computed property
        let associatedValueProperty = try makeAssociatedValueProperty(
            cases: cases,
            visibilityPrefix: visibilityPrefix
        )

        return [
            DeclSyntax(keyEnumWithCases),
            keyProperty,
            associatedValueProperty
        ]
    }

    private static func makeKeyProperty(
        cases: [EnumCaseElementSyntax],
        enumName: String,
        visibilityPrefix: String
    ) throws -> DeclSyntax {
        var switchClauses: [SwitchCaseSyntax] = []

        for c in cases {
            let caseName = c.name.text

            // Pattern depens on whether we have associated values
            let hasAssociatedValues = c.parameterClause?.parameters.count ?? 0 > 0

            let pattern: String
            if hasAssociatedValues {
                let placeholders = c.parameterClause?.parameters.map { _ in "_" } ?? []
                pattern = "case .\(caseName)(\(placeholders.joined(separator: ", "))):"
            } else {
                pattern = "case .\(caseName):"
            }

            switchClauses
                .append(
                    SwitchCaseSyntax(
                        "\(raw: pattern)\nreturn .\(raw: caseName)"
                    )
                )
        }

        let keyProp = """
        \(visibilityPrefix)var key: Key {
            switch self {
                \(switchClauses.map(\.description).joined(separator: "\n"))
            }
        }
        """
        return DeclSyntax(stringLiteral: keyProp)
    }

    private static func makeAssociatedValueProperty(cases: [EnumCaseElementSyntax], visibilityPrefix: String) throws -> DeclSyntax {
        var switchClauses: [SwitchCaseSyntax] = []
        for c in cases {
            let caseName = c.name.text
            let params = c.parameterClause?.parameters
            let count = params?.count ?? 0

            if count == 0 {
                // No associated values: return nil
                switchClauses.append(SwitchCaseSyntax("case .\(raw: caseName): return nil"))
            } else if count == 1, let singleParam = params?.first {
                // Single associated value: capture it and return it
                let paramName = singleParam.firstName?.text ?? "_value"
                switchClauses.append(SwitchCaseSyntax("case let .\(raw: caseName)(\(raw: paramName)): return \(raw: paramName)"))
            } else {
                // Multiple associated values: tuple them
                let paramNames: [String] = params?.enumerated().map { idx, param in
                    param.firstName?.text ?? "_value\(idx)"
                } ?? []
                switchClauses.append(SwitchCaseSyntax(
                    "case let .\(raw: caseName)(\(raw: paramNames.joined(separator: ", "))): return (\(raw: paramNames.joined(separator: ", ")))"
                ))
            }
        }

        let associatedValueProp = """
        \(visibilityPrefix)var associatedValue: Any? {
            switch self {
            \(switchClauses.map(\.description).joined(separator: "\n"))
            }
        }
        """
        return DeclSyntax(stringLiteral: associatedValueProp)
    }
}
