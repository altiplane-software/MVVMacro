// swift-tools-version: 6.0.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "MVVMacro",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(
            name: "MVVMacro",
            type: .static,
            targets: ["MVVMacroAPI"]
        )
    ],
    dependencies: [
        .package(url: "git@github.com:swiftlang/swift-syntax", revision: "601.0.1")
    ],
    targets: [
        // Public API wrapper
        .target(
            name: "MVVMacroAPI",
            dependencies: [
                "MVVMacroImpl"
            ]
        ),
        
        // Implementation target (development only)
        .macro(
            name: "MVVMacroImpl",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            exclude: ["README.md"]
        ),
        
        // Test target
        .testTarget(
            name: "MVVMacroTests",
            dependencies: ["MVVMacroAPI"]
        ),
    ]
)