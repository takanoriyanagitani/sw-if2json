// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "PrintInterfaces",
  platforms: [
    .macOS(.v15)
  ],
  dependencies: [
    .package(url: "https://github.com/realm/SwiftLint", from: "0.59.1"),
    .package(path: "../../.."),
  ],
  targets: [
    .executableTarget(
      name: "PrintInterfaces",
      dependencies: [
        .product(name: "NetInterfaceToJson", package: "sw-if2json")
      ],
    )
  ]
)
