// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Edipad",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Edipad", targets: ["Edipad"]),
    ],
    targets: [
        .target(
            name: "Edipad",
            dependencies: [],
            path: "Sources/Edipad",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "EdipadTests",
            dependencies: ["Edipad"],
            path: "Tests/EdipadTests"
        ),
    ]
)
