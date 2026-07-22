// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LocalGroq",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LocalGroq", targets: ["LocalGroq"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/argmaxinc/argmax-oss-swift.git",
            exact: "1.0.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "LocalGroq",
            dependencies: [
                .product(name: "WhisperKit", package: "argmax-oss-swift")
            ],
            path: "Sources/LocalGroq"
        ),
        .testTarget(
            name: "LocalGroqTests",
            dependencies: ["LocalGroq"],
            path: "Tests/LocalGroqTests"
        )
    ]
)
