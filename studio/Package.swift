// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "studio",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.2"),
    ],
    targets: [
        .target(
            name: "NibblewayStudioCore",
            dependencies: [
                "Yams",
                .product(name: "MCP", package: "swift-sdk")
            ],
            path: "Sources",
            exclude: ["NibblewayStudioApp.swift"],
            linkerSettings: [
                .linkedFramework("SwiftData"),
                .linkedFramework("SwiftUI")
            ]
        ),
    ]
)
