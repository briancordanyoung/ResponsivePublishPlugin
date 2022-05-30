// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "ResponsivePublishPlugin",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "ResponsivePublishPlugin",
            targets: ["ResponsivePublishPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/johnsundell/publish.git", from: "0.7.0"),
        .package(url: "https://github.com/briancordanyoung/SwiftGD.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "ResponsivePublishPlugin",
            dependencies: [
                .product(name: "Publish", package: "publish"),
                "SwiftGD"
            ]
        ),
        .testTarget(
            name: "ResponsivePublishPluginTests",
            dependencies: ["ResponsivePublishPlugin"],
            resources: [
                .copy("Expected/index-expected.html"),
                .copy("Expected/styles-expected-no-rewrite.css"),
                .copy("Expected/styles-expected.css"),
                .copy("Resources/css/styles-no-rewrite.css"),
                .copy("Resources/css/styles.css"),
                .copy("Resources/img/icons/favicon.ico"),
                .copy("Resources/img/subfolder/sub-background.jpg"),
                .copy("Resources/index.html"),
                .copy("Resources/img/background.jpg"),
            ]
        ),
    ]
)
