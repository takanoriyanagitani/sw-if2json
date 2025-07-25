// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "NetInterfaceToJson",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(
      name: "NetInterfaceToJson",
      targets: ["NetInterfaceToJson"])
  ],
  dependencies: [
    .package(url: "https://github.com/realm/SwiftLint", from: "0.59.1"),
    .package(
      url: "https://github.com/apple/swift-async-algorithms", from: "1.0.4",
    ),
  ],
  targets: [
    .target(
      name: "NetInterfaceToJson",
      dependencies: [
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
      ],
    ),
    .testTarget(
      name: "NetInterfaceToJsonTests",
      dependencies: ["NetInterfaceToJson"]
    ),
  ]
)
