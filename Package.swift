// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "CombineExt",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "CombineExt", targets: ["CombineExt"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "1.1.0"),
    ],
    targets: [
        .target(name: "CombineExt", dependencies: [], path: "Sources"),
        .testTarget(
            name: "CombineExtTests",
            dependencies: [
                "CombineExt",
                .product(name: "CombineSchedulers", package: "combine-schedulers"),
            ],
            path: "Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
