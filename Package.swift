// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-webster",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Webster",
            targets: ["Webster"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.10.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "Webster",
            dependencies: [
                .product(name:"Logging", package:"swift-log"),
            ]),
        .executableTarget(
                    name: "webster-cli",
                    dependencies: [
                        "Webster",
                        .product(name: "ArgumentParser", package: "swift-argument-parser"),
                        .product(name: "Logging", package: "swift-log"),
                    ]
                ),
    ]
)
