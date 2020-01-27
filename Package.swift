// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CombineExt",
    platforms: [.iOS(.v13), .watchOS(.v6), .macOS(.v10_15)],
    products: [.library(name: "CombineExt", targets: ["CombineExt"])],
    dependencies: [],
    targets: [
        .target(name: "CombineExt", dependencies: []),
        .testTarget(name: "CombineExtTests", dependencies: ["CombineExt"])
    ]
)
