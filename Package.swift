// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-context-management",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "SwiftContextManagement",
            targets: ["SwiftContextManagement"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftContextManagement"
        ),
        .testTarget(
            name: "SwiftContextManagementTests",
            dependencies: ["SwiftContextManagement"]
        ),
    ]
)
