// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "OpenWaterGUI",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "OpenWaterGUI", targets: ["OpenWaterGUI"])
    ],
    targets: [
        .executableTarget(
            name: "OpenWaterGUI",
            dependencies: ["OpenWaterBridge"],
            path: "Sources/OpenWaterGUI"
        ),
        .target(
            name: "OpenWaterBridge",
            dependencies: ["OpenWaterCore"],
            path: "Sources/OpenWaterBridge"
        ),
        .systemLibrary(
            name: "OpenWaterCore",
            path: "Sources/OpenWaterCore",
            pkgConfig: "openwater",
            providers: [
                .brew(["openwater"])
            ]
        )
    ]
)
