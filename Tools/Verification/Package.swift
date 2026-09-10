// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "ChessKitVerification",
    dependencies: [.package(name: "ChessKit", path: "../..")],
    targets: [
        .executableTarget(
            name: "ChessKitVerify",
            dependencies: [.product(name: "ChessKit", package: "ChessKit")]
        )
    ]
)
