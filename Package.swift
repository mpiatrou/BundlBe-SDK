// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "BundlBe",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "BundlBe",
            targets: ["BundlBe"]),
    ],
    targets: [
        .target(
            name: "BundlBe",
            path: "BundlBe"
        ),
    ]
)
