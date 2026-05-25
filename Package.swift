// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "NetworkMonitor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "NetworkMonitor", targets: ["NetworkMonitor"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "NetworkMonitor",
            dependencies: [],
            path: "Sources/NetworkMonitor"
        )
    ]
)
