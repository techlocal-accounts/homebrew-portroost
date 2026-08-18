// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "CodexServerMonitor",
  platforms: [
    .macOS(.v14),
  ],
  products: [
    .library(name: "ServerMonitorCore", targets: ["ServerMonitorCore"]),
    .executable(name: "CodexServerMonitor", targets: ["CodexServerMonitor"]),
  ],
  targets: [
    .target(name: "ServerMonitorCore"),
    .executableTarget(
      name: "CodexServerMonitor",
      dependencies: ["ServerMonitorCore"]
    ),
    .testTarget(
      name: "ServerMonitorCoreTests",
      dependencies: ["ServerMonitorCore"]
    ),
  ],
  swiftLanguageModes: [.v5]
)
