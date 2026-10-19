// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SharedSecurity",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SharedSecurity", targets: ["SharedSecurity"])
    ],
    targets: [
        .target(name: "SharedSecurity", path: "Sources/SharedSecurity")
    ]
)
