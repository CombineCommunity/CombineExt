// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CombineExt",
    platforms: [
        .iOS(.v10), .tvOS(.v10), .macOS(.v10_12), .watchOS(.v3)
    ],
    products: [
        .library(name: "CombineExt", targets: ["CombineExt"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "0.1.2"),
    ],
    targets: [
        .target(name: "CombineExt", dependencies: [], path: "Sources"),
        .testTarget(name: "CombineExtTests", dependencies: ["CombineExt", "CombineSchedulers"], path: "Tests"),
    ],
    swiftLanguageVersions: [.v5]
)
