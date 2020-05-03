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
    dependencies: [],
    targets: [
        .target(name: "CombineExt", dependencies: [], path: "Sources"),
        .testTarget(name: "CombineExtTests", dependencies: ["CombineExt"], path: "Tests"),
    ],
    swiftLanguageVersions: [.v5]
)
