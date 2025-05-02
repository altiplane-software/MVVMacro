//
//  ActionHandlingViewModelMacro.swift
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

public struct ActionHandlingViewModelMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            // This macro should only be attached to a class
            context.diagnose(
                Diagnostic(
                    node: Syntax(declaration),
                    message: ActionHandlingMacroDiagnosticError(
                        message: "`@ActionHandlingViewModel` can only be applied to classes."
                    )
                )
            )
            return []
        }

        // Check if `@MainActor` is already present
        guard classDecl.attributes.contains(where: { attr in
            guard let attrSyntax = attr.as(AttributeSyntax.self),
                  let identifier = attrSyntax.attributeName.as(IdentifierTypeSyntax.self)
            else {
                return false
            }
            return identifier.name.text == "MainActor"
        }) else {
            // Create the `@MainActor` attribute
            let mainActorAttribute = AttributeSyntax("@MainActor")

            // Prepend the `@MainActor` attribute to the declaration

            var newAttributes = classDecl.attributes
            newAttributes.insert(AttributeListSyntax.Element(mainActorAttribute), at: classDecl.attributes.startIndex)

            let newDecl = classDecl.with(\.attributes, newAttributes)
            let fixIt = FixIt(
                message: ActionHandlingAddMainActorFixIt(),
                changes: [
                    .replace(oldNode: Syntax(classDecl), newNode: Syntax(newDecl))
                ]
            )
            context.diagnose(
                Diagnostic(
                    node: Syntax(classDecl),
                    message: ActionHandlingMacroDiagnosticError(
                        message: """
                        `@ActionHandlingViewModel` requires this class to run on `@MainActor`.
                        Please add an `@MainActor` to the class declaration.
                        """
                    ),
                    fixIts: [fixIt]
                )
            )
            return []
        }

        // Propagate class access level for generated members
        let isPublic = classDecl.modifiers.contains(
            where: {
                $0.name.text == "public" || $0.name.text == "open"
            }
        )
        let visibilityPrefix: String = isPublic ? "public " : ""

        // Collect fixes and diagnostics
        var updatedMembers = Array(classDecl.memberBlock.members)
        var allChanges: [FixIt.Change] = []
        var messages: [String] = []

        // 1) Check for an `@Action`-annotated enum
        let hasActionEnum = classDecl.memberBlock.members.contains { member in
            guard let enumDecl = member.decl.as(EnumDeclSyntax.self) else {
                return false
            }

            // Check each attribute for `@Action`
            for attr in enumDecl.attributes {
                if let attrSyntax = attr.as(AttributeSyntax.self),
                   let simpleType = attrSyntax.attributeName.as(IdentifierTypeSyntax.self),
                   simpleType.name.text == "Action" {
                    return true
                }
            }
            return false
        }

        if !hasActionEnum {
            // Build the new enum declaration
            let actionEnumDecl = try EnumDeclSyntax("""
            
            
            @Action
            \(raw: visibilityPrefix)enum Action {
                case something
            }
            """)

            // Append this enum to the existing members
            let currentMembers = Array(classDecl.memberBlock.members)
            let newMember = MemberBlockItemListBuilder.buildExpression(actionEnumDecl)
            var updatedMembers = currentMembers
            updatedMembers.append(contentsOf: newMember)

            let newMembers = MemberBlockItemListSyntax(updatedMembers)
            let fixIt = FixIt(
                message: ActionHandlingAddActionEnumFixIt(),
                changes: [
                    .replace(
                        oldNode: Syntax(classDecl.memberBlock.members),
                        newNode: Syntax(newMembers)
                    )
                ]
            )

            context.diagnose(
                Diagnostic(
                    node: Syntax(declaration),
                    message: ActionHandlingMacroDiagnosticError(
                        message: """
                        `@ActionHandlingViewModel` requires this class to have an `@Action` annotated enum.
                        Please add an `@Action` enum declaration inside `\(classDecl.name.text)`.
                        
                        Example:
                        @Action
                        enum Action {
                            case something
                        }
                        """
                    ),
                    fixIts: [fixIt]
                )
            )
            return []
        }

        // 2) Locate the actual @Action enum node
        guard let actionEnumDecl = classDecl.memberBlock.members
            .compactMap({ $0.decl.as(EnumDeclSyntax.self) })
            .first(where: { enumDecl in
                enumDecl.attributes.contains(where: { attr in
                    guard let attrSyntax = attr.as(AttributeSyntax.self),
                          let simpleType = attrSyntax.attributeName.as(IdentifierTypeSyntax.self)
                    else { return false }
                    return simpleType.name.text == "Action"
                })
            })
        else {
            // Should never happen at this point, since hasActionEnum == true
            return []
        }

        // 3) Extract all enum cases and their associated types, check if the action implements multiple associated values if so notify to fix this
        var actionCases: [(caseName: String, associatedType: String?, hasAssociatedValue: Bool)] = []
        var shouldFixMultipleAssociatedValues = false

        for member in actionEnumDecl.memberBlock.members {
            guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self),
                  let firstCase = enumCaseDecl.elements.first
            else {
                continue
            }

            // Extract case name
            let caseName = firstCase.name.text

            var associatedType: String?
            // Extract associated type (if any)
            if let parameterClause = firstCase.parameterClause, parameterClause.parameters.count > 1 {
                // Get the original parameter clause text.
                let originalClauseText = parameterClause.trimmedDescription
                // Wrap it in an extra pair of parentheses.
                let newClauseText = "(" + originalClauseText + ")"

                // Parse the new parameter clause into a syntax node.
                // (Assuming that `Parser.parse(source:)` can give you the new ParameterClauseSyntax.)
                let parsedSource = Parser.parse(source: newClauseText)
                // Locate the new parameter clause in the parsed syntax.
                // (You may need to adjust this lookup based on your parsing API.)
                guard let newParameterClause = parsedSource.statements.first(where: { statement in
                    statement.description.contains(newClauseText)
                }) else {
                    continue
                }

                // Create the fix-it change.
                let fixIt = FixIt(
                    message: ActionHandlingRefactorEnumCaseSignatureFixIt(),
                    changes: [
                        .replace(
                            oldNode: Syntax(parameterClause),
                            newNode: Syntax(newParameterClause)
                        )
                    ]
                )

                // Emit the diagnostic with the fix-it suggestion.
                context.diagnose(
                    Diagnostic(
                        node: Syntax(declaration),
                        message: ActionHandlingMacroDiagnosticError(
                            message: """
                            Enum case '\(caseName)' has multiple associated values.
                            Please refactor them into a single tuple.
                            For example, change:
                                case \(caseName)\(originalClauseText)
                            to:
                                case \(caseName)\(newClauseText)
                            """
                        ),
                        fixIts: [fixIt]
                    )
                )
                // Mark that a fix is needed and stop further processing.
                shouldFixMultipleAssociatedValues = true
                break
            } else {
                associatedType = firstCase.parameterClause?.parameters.first?.type.description
            }
            // Determine if this case has an associated value
            let hasAssociatedValue = (associatedType != nil)

            actionCases.append((caseName: caseName, associatedType: associatedType, hasAssociatedValue: hasAssociatedValue))
        }

        // Exit prematurely to ensure that we wont have action with multiple associated values
        guard !shouldFixMultipleAssociatedValues else {
            return []
        }

        // 4) Find existing "handleX" functions in the class
        let existingFunctions = classDecl.memberBlock.members.compactMap { member -> (name: String, parameterTypes: [String])? in
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                return nil
            }

            // Check if the function is private (optional)
            let isPrivate = funcDecl.modifiers.contains(where: { $0.name.text == "private" })
            guard isPrivate else { return nil }

            // Get the function name
            let functionName = funcDecl.name.text

            // Extract parameter types
            let parameterTypes = funcDecl.signature.parameterClause.parameters.compactMap { param in
                param.type.trimmedDescription
            }

            return (name: functionName, parameterTypes: parameterTypes)
        }

        // 5) Determine which ones are missing
        let missingOrMismatchedFunctions = actionCases.filter { actionCase in
            // Expected function name
            let expectedName = actionCase.caseName

            // Expected parameter types
            let expectedParameters: [String]
            if actionCase.hasAssociatedValue, let associatedType = actionCase.associatedType {
                expectedParameters = [associatedType]
            } else {
                expectedParameters = []
            }

            // Check if a matching function exists
            return !existingFunctions.contains(where: { existing in
                existing.name == expectedName && existing.parameterTypes == expectedParameters
            })
        }

        if !missingOrMismatchedFunctions.isEmpty {
            for actionCase in missingOrMismatchedFunctions {
                let functionName = actionCase.caseName

                // Generate the function based on whether it has associated values
                let functionString: String
                if actionCase.hasAssociatedValue, let associatedType = actionCase.associatedType {
                    functionString = """
                    
                    
                    private func \(functionName)(value: \(associatedType)) {
                        // TODO: Implement \(functionName) for \(actionCase.caseName)
                    }
                    """
                } else {
                    functionString = """
                    
                    
                    private func \(functionName)() {
                        // TODO: Implement \(functionName) for \(actionCase.caseName)
                    }
                    """
                }

                let decl = DeclSyntax(stringLiteral: functionString)
                updatedMembers.append(MemberBlockItemSyntax(decl: decl))
            }

            let newMembers = MemberBlockItemListSyntax(updatedMembers)

            // Append the fix to replace only the required members
            allChanges.append(
                FixIt.Change.replace(
                    oldNode: Syntax(classDecl.memberBlock.members),
                    newNode: Syntax(newMembers)
                )
            )
            messages.append("""
                The following private handlers are missing or have incorrect signatures:
                \(missingOrMismatchedFunctions.map { "\($0.caseName)" }.joined(separator: "\n")).
                """
            )
        }

        // Emit combined fix-it if necessary
        if !allChanges.isEmpty {
            let combinedFixIt = FixIt(
                message: CombinedFixItMessage(),
                changes: [allChanges.last].compactMap { $0 }
            )

            context.diagnose(
                Diagnostic(
                    node: Syntax(declaration),
                    message: ActionHandlingMacroDiagnosticError(
                        message: messages.joined(separator: "\n")
                    ),
                    fixIts: [combinedFixIt]
                )
            )
            return []
        }

        // Generate the handle method with a switch statement
        let switchCases = actionCases.map { actionCase in
            if actionCase.hasAssociatedValue {
                "case .\(actionCase.caseName)(let value):\n        \(actionCase.caseName)(value: value)"
            } else {
                "case .\(actionCase.caseName):\n        \(actionCase.caseName)()"
            }
        }.joined(separator: "\n    ")

        // Generate the handle method and send implementation
        let handleImplementation = """
        \(visibilityPrefix)typealias SendableAction = Action

        @MainActor
        private func handle(action: Action) {
            switch action {
            \(switchCases)
            }
        }

        @MainActor
        \(visibilityPrefix)func send(_ action: SendableAction) {
            handle(action: action)
        }
        """
        let handleDecl = DeclSyntax(stringLiteral: handleImplementation)
        return [handleDecl]
    }

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        // 1) Generate the extension
        let actionExtension = try ExtensionDeclSyntax("""
            extension \(type.trimmed): ActionHandlingViewModel {}
            """)
        return [actionExtension]
    }

    private static func findVariable(named name: String, in classDecl: ClassDeclSyntax) -> VariableDeclSyntax? {
        classDecl.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .first { varDecl in
                varDecl.bindings.contains { binding in
                    binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name
                }
            }
    }

    private static func extractDictionaryKeys(from initializer: ExprSyntax) -> [String] {
        guard let dictionaryExpr = initializer.as(DictionaryExprSyntax.self),
              case .elements(let elements) = dictionaryExpr.content else {
            return []
        }

        var uniqueKeys: Set<String> = []

        elements.forEach { element in
            if let keyExpr = element.key.as(MemberAccessExprSyntax.self) {
                let caseName = keyExpr.declName.baseName.text
                uniqueKeys.insert(caseName)
            }
        }

        return Array(uniqueKeys)
    }
}

// MARK: - Diagnostic Error
struct ActionHandlingMacroDiagnosticError: DiagnosticMessage {
    let message: String
    var severity: DiagnosticSeverity { .error }
    var diagnosticID: MessageID {
        MessageID(domain: "ActionHandlingViewModelMacro", id: "MissingRequirements")
    }
}

// MARK: - Fix-it Messages

struct CombinedFixItMessage: FixItMessage {
    var message: String { "Apply all suggested fixes" }
    var fixItID: MessageID {
        MessageID(domain: "ActionHandlingViewModelMacro", id: "CombinedFixIt")
    }
}

struct ActionHandlingAddMainActorFixIt: FixItMessage {
    var message: String { "Add missing @MainActor to declaration" }
    var fixItID: MessageID {
        MessageID(domain: "ActionHandlingViewModelMacro", id: "AddMainActor")
    }
}

struct ActionHandlingAddActionEnumFixIt: FixItMessage {
    var message: String { "Add missing @Action enum" }
    var fixItID: MessageID {
        MessageID(domain: "ActionHandlingViewModelMacro", id: "AddActionEnum")
    }
}

struct ActionHandlingRefactorEnumCaseSignatureFixIt: FixItMessage {
    var message: String { "Refactor existing enum case with multiple parameters to a tuple" }
    var fixItID: MessageID {
        MessageID(domain: "ActionHandlingViewModelMacro", id: "RefactorEnumCase")
    }
}
