// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NIKNOLIGIOSFoundation",
    platforms: [.iOS(.v17), .macOS(.v14)],
    dependencies: [
        .package(path: "packages/shared-api"),
        .package(path: "packages/shared-models"),
        .package(path: "packages/shared-security")
    ],
    targets: [
        .testTarget(
            name: "FoundationContractTests",
            dependencies: [
                .product(name: "SharedAPI", package: "shared-api"),
                .product(name: "SharedModels", package: "shared-models"),
                .product(name: "SharedSecurity", package: "shared-security")
            ],
            path: "tests",
            exclude: ["README.md"]
        )
    ]
)
