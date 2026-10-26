// swift-tools-version: 6.2
import PackageDescription

// StarlightCore is the app's portable, dependency-free logic: the sky of a place and a time,
// computed on the device. It builds on Apple platforms and on Linux, so its tests run without
// Xcode (tools/swift.sh test, and CI's `core` job).
let package = Package(
    name: "StarlightCore",
    platforms: [.iOS("26.0"), .macOS("15.0")],
    products: [
        .library(name: "StarlightCore", targets: ["StarlightCore"]),
    ],
    targets: [
        .target(name: "StarlightCore", resources: [.process("Resources")]),
        .testTarget(name: "StarlightCoreTests", dependencies: ["StarlightCore"]),
    ],
    swiftLanguageModes: [.v6]
)
