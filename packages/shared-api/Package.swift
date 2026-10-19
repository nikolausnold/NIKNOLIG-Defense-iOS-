// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SharedAPI",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SharedAPI", targets: ["SharedAPI"])
    ],
    dependencies: [
        .package(path: "../shared-models")
    ],
    targets: [
        .target(
            name: "SharedAPI",
            dependencies: [.product(name: "SharedModels", package: "shared-models")],
            path: "Sources/SharedAPI"
        )
    ]
)
