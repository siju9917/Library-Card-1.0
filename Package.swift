// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibraryCard",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LibraryCard",
            targets: ["LibraryCard"]
        )
    ],
    targets: [
        .target(
            name: "LibraryCard",
            path: "LibraryCard"
        ),
        .testTarget(
            name: "LibraryCardTests",
            dependencies: ["LibraryCard"],
            path: "LibraryCardTests"
        )
    ]
)
