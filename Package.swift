// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "tcc",
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/auth.git", from:"2.0.1"),
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0-rc"),
    ],
    targets: [
        .target(name: "App", dependencies: ["Leaf", "Vapor", "Authentication", "FluentPostgreSQL"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

