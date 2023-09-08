// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription


func products() -> [Product] {
    var products: [Product] = [
        .library(name: "PKCore", targets: ["PKCore"]),
        .library(name: "PKWebServer", targets: ["PKWebServer"]),
        .library(name: "PKJSON", targets: ["PKJSON"]),
        .library(name: "PKUI", targets: ["PKUI"])
    ]
    return products
}


func targets() -> [Target] {
    var targets: [Target] = [
        .target(name: "PKCore", path: "Sources/Core"),
        .target(
            name: "PKWebServer",
            dependencies: [
                .target(name: "PKCore", condition: nil),
                .productItem(name: "NIO", package: "swift-nio", condition: nil),
                .productItem(name: "NIOHTTP1", package: "swift-nio", condition: nil),
                .productItem(name: "NIOWebSocket", package: "swift-nio", condition: nil),
            ],
            path: "Sources/WebServer",
            resources: [.process("Resources")]
        ),
        .target(
            name: "PKJSON",
            dependencies: [
                .productItem(name: "RxSwift", package: "RxSwift"),
                .productItem(name: "RxRelay", package: "RxSwift")
            ],
            path: "Sources/JSON"),
        .testTarget(name: "JSONTests",
                    dependencies: [
                        "PKJSON",
                    ]),
        .testTarget(name: "WebServerTests",
                    dependencies: ["PKCore", "PKWebServer"]),
        .target(name: "PKUI", path: "Sources/UI")
    ]
    
    return targets
}


let package = Package(
    name: "PKit",
    platforms: [
        .iOS(.v11)
    ],
    products: products(),
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .exact("6.6.0"))
    ],
    targets: targets(),
    swiftLanguageVersions: [
        .v5
    ]
)
