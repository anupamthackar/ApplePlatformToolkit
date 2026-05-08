// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PracticeProject",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(name: "ApplePlatformToolkit", path: "../")
    ],
    targets: [
        .executableTarget(
            name: "PracticeProject",
            dependencies: [
                .product(name: "ToolkitCore", package: "ApplePlatformToolkit"),
                .product(name: "ToolkitUtility", package: "ApplePlatformToolkit"),
                .product(name: "ToolkitCrypto", package: "ApplePlatformToolkit"),
                .product(name: "ToolkitCompression", package: "ApplePlatformToolkit"),
                .product(name: "ToolkitFormatter", package: "ApplePlatformToolkit"),
                .product(name: "ToolkitNetworking", package: "ApplePlatformToolkit"),
                .product(name: "ToolkitAuth", package: "ApplePlatformToolkit"),
                .product(name: "ToolkitUI", package: "ApplePlatformToolkit"),
                .product(name: "ToolkitPlugins", package: "ApplePlatformToolkit"),
                .product(name: "ToolkitAll", package: "ApplePlatformToolkit")
            ]
        ),
        .testTarget(
            name: "PracticeProjectTests",
            dependencies: ["PracticeProject"]
        )
    ]
)
