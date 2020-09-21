// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "OKImageDownloader",
    products: [
        .library(
            name: "OKImageDownloader",
            targets: ["OKImageDownloader"]),
    ],
    targets: [
        .target(
            name: "OKImageDownloader",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "OKImageDownloaderTests",
            dependencies: ["OKImageDownloader"],
            path: "Tests"),
    ]
)
