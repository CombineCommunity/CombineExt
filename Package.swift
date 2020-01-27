// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CombineExt",
    products: [.library(name: "CombineExt", targets: ["CombineExt"])],
    dependencies: [],
    targets: [
        .target(name: "CombineExt", dependencies: []),
        .testTarget(name: "CombineExtTests", dependencies: ["CombineExt"])
    ]
)
