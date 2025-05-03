// swift-tools-version: 6.0.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MVVMacro",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(
            name: "MVVMacro",   
            type: .static,
            targets: ["MVVMacroAPI"]
        ),
    ],
    dependencies: [],
    targets: [
        // Public API wrapper
        .target(
            name: "MVVMacroAPI",
            dependencies: ["MVVMacroBinary"]
        ),
        
        // Precompiled binary artifacts
        .binaryTarget(
            name: "MVVMacroBinary",
            path: "Artifacts/MVVMacroBinary.xcframework"
        ),
        
        // Test target
        .testTarget(
            name: "MVVMacroTests",
            dependencies: ["MVVMacroAPI"]
        ),
    ]
)