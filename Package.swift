// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "MyToolkit",
    
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    
    products: [
        // MARK: - Core
        .library(name: "ToolkitCore", targets: ["ToolkitCore"]),
        .library(name: "ToolkitUtility", targets: ["ToolkitUtility"]),
        .library(name: "ToolkitCrypto", targets: ["ToolkitCrypto"]),
        .library(name: "ToolkitCompression", targets: ["ToolkitCompression"]),
        
        // MARK: - Service
        .library(name: "ToolkitNetworking", targets: ["ToolkitNetworking"]),
        .library(name: "ToolkitAuth", targets: ["ToolkitAuth"]),
        
        // MARK: - Feature
        .library(name: "ToolkitUI", targets: ["ToolkitUI"]),
        
        // MARK: - Plugin
        .library(name: "ToolkitPlugins", targets: ["ToolkitPlugins"]),
        
        // MARK: - Umbrella (Optional)
        .library(name: "ToolkitAll", targets: ["ToolkitAll"])
    ],
    
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0")
    ],
    
    targets: [
        // MARK: - Core Layer
        .target(
            name: "ToolkitCore"
        ),
        .target(
            name: "ToolkitUtility",
            dependencies: ["ToolkitCore"]
        ),
        .target(
            name: "ToolkitCrypto",
            dependencies: ["ToolkitCore"]
        ),
        .target(
            name: "ToolkitCompression",
            dependencies: ["ToolkitCore"]
        ),
        
        // MARK: - Service Layer
        .target(
            name: "ToolkitNetworking",
            dependencies: [
                "ToolkitCore",
                .product(name: "Alamofire", package: "Alamofire")
            ]
        ),
        .target(
            name: "ToolkitAuth",
            dependencies: [
                "ToolkitCore",
                "ToolkitNetworking",
                "ToolkitCrypto"
            ]
        ),
        
        // MARK: - Feature Layer
        .target(
            name: "ToolkitUI",
            dependencies: [
                "ToolkitAuth",
                "ToolkitNetworking"
            ]
        ),
        
        // MARK: - Plugin Layer
        .target(
            name: "ToolkitPlugins",
            dependencies: [
                "ToolkitCore"
            ]
        ),
        
        // MARK: - Umbrella Target
        .target(
            name: "ToolkitAll",
            dependencies: [
                "ToolkitCore",
                "ToolkitUtility",
                "ToolkitCrypto",
                "ToolkitCompression",
                "ToolkitNetworking",
                "ToolkitAuth",
                "ToolkitUI",
                "ToolkitPlugins"
            ]
        ),
        
        // MARK: - Tests
        
        .testTarget(
            name: "ToolkitCoreTests",
            dependencies: ["ToolkitCore"]
        ),
        .testTarget(
            name: "ToolkitUtilityTests",
            dependencies: ["ToolkitUtility"]
        ),
        .testTarget(
            name: "ToolkitCryptoTests",
            dependencies: ["ToolkitCrypto"]
        ),
        .testTarget(
            name: "ToolkitCompressionTests",
            dependencies: ["ToolkitCompression"]
        ),
        .testTarget(
            name: "ToolkitNetworkingTests",
            dependencies: ["ToolkitNetworking"]
        ),
        .testTarget(
            name: "ToolkitAuthTests",
            dependencies: ["ToolkitAuth"]
        ),
        .testTarget(
            name: "ToolkitUITests",
            dependencies: ["ToolkitUI"]
        ),
        .testTarget(
            name: "ToolkitPluginsTests",
            dependencies: ["ToolkitPlugins"]
        ),
        .testTarget(
            name: "ToolkitAllTests",
            dependencies: ["ToolkitAll"]
        )
    ],
    
    swiftLanguageModes: [.v6]
)