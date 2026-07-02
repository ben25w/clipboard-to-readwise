// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ClipboardToReadwise",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "ClipboardToReadwiseCore", targets: ["ClipboardToReadwiseCore"]),
        .executable(name: "ClipboardToReadwise", targets: ["ClipboardToReadwise"])
    ],
    targets: [
        .target(
            name: "ClipboardToReadwiseCore"
        ),
        .executableTarget(
            name: "ClipboardToReadwise",
            dependencies: ["ClipboardToReadwiseCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Security"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("UserNotifications")
            ]
        ),
        .testTarget(
            name: "ClipboardToReadwiseCoreTests",
            dependencies: ["ClipboardToReadwiseCore"]
        )
    ]
)
