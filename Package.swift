// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CardSnap",
    platforms: [.iOS(.v17), .macCatalyst(.v17)],
    targets: [
        .executableTarget(
            name: "CardSnap",
            path: "CardSnap",
            resources: [.process("Assets.xcassets")]
        )
    ]
)
