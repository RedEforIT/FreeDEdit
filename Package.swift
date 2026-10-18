// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FreeDEdit",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "FreeDEdit", targets: ["FreeDEdit"])],
    targets: [.executableTarget(name: "FreeDEdit")]
)
