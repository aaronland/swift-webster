// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-webster",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Webster",
            targets: ["Webster"]),
    ],
    dependencies: [

        .package(url: "https://github.com/apple/swift-log.git", from: "1.10.1"),
    ],
    targets: [
        .target(
            name: "Webster",
            dependencies: [
                .product(name:"Logging", package:"swift-log"),
            ]),
    ]
)
