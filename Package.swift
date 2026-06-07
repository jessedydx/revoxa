// swift-tools-version: 5.9

import PackageDescription

let embeddedInfoPlist = "Sources/Revoxa/Resources/EmbeddedInfo.plist"

let package = Package(
    name: "Revoxa",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "Revoxa",
            targets: ["Revoxa"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Revoxa",
            exclude: ["Resources/EmbeddedInfo.plist"],
            resources: [
                .process("Resources/Assets.xcassets"),
                .process("Resources/Localizable.xcstrings")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", embeddedInfoPlist,
                ], .when(platforms: [.macOS])),
            ]
        ),
        .testTarget(
            name: "RevoxaTests",
            dependencies: ["Revoxa"]
        )
    ]
)
