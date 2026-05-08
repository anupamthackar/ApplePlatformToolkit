// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ToolkitDemo",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ToolkitDemo", targets: ["ToolkitDemo"])
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "ToolkitDemo",
            dependencies: [
                .product(name: "ToolkitAll", package: "MyToolkit")
            ],
            path: "Sources/ToolkitDemo"
        )
    ]
)
