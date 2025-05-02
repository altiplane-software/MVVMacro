// swift-tools-version: 6.0.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport
import Foundation

let isProduction: Bool = {
  guard let envValue = getenv("MVVMACRO_PRODUCTION") else { return false }
  return String(cString: envValue) == "1"
}()

let package = Package(
    name: "MVVMacro",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(
            name: "MVVMacro",
            targets: ["MVVMacroAPI"]
        ),
    ],
    dependencies: [
        .package(url: "git@github.com:swiftlang/swift-syntax", revision: "601.0.1")
    ],
    targets: [
        // Public API wrapper
        .target(
            name: "MVVMacroAPI",
            dependencies: [
                .target(
                    name: isProduction ? "MVVMacroBinary" : "MVVMacroImpl"
                )
            ]
        ),
        
        isProduction ?
        // Precompiled macro implementation
            .binaryTarget(
                name: "MVVMacroBinary",
                path: "Artifacts/MVVMacroBinary.xcframework"
            )
        :
            // Implementation target (development only - remove before distribution)
                .macro(
                    name: "MVVMacroImpl",
                    dependencies: [
                        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
                    ],
                    exclude: ["README.md"]  // Reduce unnecessary build artifacts
                )
        ,
        
        // Test target
        .testTarget(
            name: "MVVMacroTests",
            dependencies: ["MVVMacroAPI"]
        ),
    ]
)
