// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LogView",
    platforms: [
            .iOS(.v14),
            .macOS(.v12)
        ],
    products: [
        .library(name: "LogView", targets: ["LogView"])
    ],
    targets: [
        .target(
            name: "LogView",
            path: "Sources")
    ]
)
