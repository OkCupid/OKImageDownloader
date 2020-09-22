// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "OKImageDownloader",
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "OKImageDownloader",
            targets: ["OKImageDownloader"]),
    ],
    targets: [
        .target(
            name: "OKImageDownloader",
            dependencies: [],
            path: "Sources",
            exclude: ["Example"]),
        .testTarget(
            name: "OKImageDownloaderTests",
            dependencies: ["OKImageDownloader"],
            path: "Tests"),
    ]
)
