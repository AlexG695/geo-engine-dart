// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "geo_engine_sdk",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "geo-engine-sdk", targets: ["geo_engine_sdk"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "geo_engine_sdk",
            dependencies: [],
            path: "Classes" 
        )
    ]
)