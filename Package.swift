// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HomeMaintMobile",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HomeMaintMobile",
            targets: ["HomeMaintMobile"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "HomeMaintMobile",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ]
        ),
        .testTarget(
            name: "HomeMaintMobileTests",
            dependencies: ["HomeMaintMobile"]
        )
    ]
)
