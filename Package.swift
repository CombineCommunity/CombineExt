// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CombineExt",
    platforms: [
        .iOS(.v13), .tvOS(.v13), .macOS(.v10_15), .watchOS(.v6)
    ],
    products: [
        .library(name: "CombineExt", targets: ["CombineExt"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "CombineExt", dependencies: [], path: "Sources"),
        .testTarget(name: "CombineExtTests", dependencies: [], path: "Tests"),
    ],
    swiftLanguageVersions: [.v5]
)