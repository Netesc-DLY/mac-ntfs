// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "NTFSDesk",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "NTFSDesk", targets: ["NTFSDesk"])
    ],
    targets: [
        .executableTarget(
            name: "NTFSDesk",
            dependencies: []
        ),
        .testTarget(
            name: "NTFSDeskTests",
            dependencies: ["NTFSDesk"]
        ),
    ]
)
