// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FirstStateLens",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FirstStateCore", targets: ["FirstStateCore"])
    ],
    targets: [
        .target(name: "FirstStateCore"),
        .testTarget(name: "FirstStateCoreTests", dependencies: ["FirstStateCore"])
    ]
)
