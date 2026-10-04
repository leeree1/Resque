// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "torch_light",
    platforms: [.iOS("15.0")],
    products: [
        .library(name: "torch-light", targets: ["torch_light"])
    ],
    targets: [
        .target(
            name: "torch_light",
            dependencies: [],
            path: "Sources"
        )
    ]
)
