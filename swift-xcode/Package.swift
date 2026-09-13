// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AegisReplaySwiftPoc",
    products: [
        .library(name: "PocLibrary", targets: ["PocLibrary"]),
    ],
    targets: [
        .target(name: "PocLibrary"),
        .testTarget(name: "PocLibraryTests", dependencies: ["PocLibrary"]),
    ]
)
