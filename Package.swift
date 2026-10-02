// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "Portroost",
  platforms: [
    .macOS(.v14),
  ],
  products: [
    .library(name: "ServerMonitorCore", targets: ["ServerMonitorCore"]),
    .executable(name: "Portroost", targets: ["Portroost"]),
  ],
  targets: [
    .target(name: "ServerMonitorCore"),
    .executableTarget(
      name: "Portroost",
      dependencies: ["ServerMonitorCore"]
    ),
    .testTarget(
      name: "ServerMonitorCoreTests",
      dependencies: ["ServerMonitorCore"]
    ),
  ],
  swiftLanguageModes: [.v5]
)
