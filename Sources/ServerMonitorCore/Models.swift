import Foundation

public enum ServerState: String, Codable, Sendable {
  case running
  case loaded
  case stopped
}

public struct PersistentServer: Identifiable, Equatable, Sendable {
  public let id: String
  public let label: String
  public let name: String
  public let workingDirectory: String
  public let command: String
  public let url: String?
  public let logPath: String
  public let setupFiles: [String]
  public let state: ServerState
  public let pid: Int32?
  public let footprintBytes: UInt64
  public let residentMemoryBytes: UInt64

  public init(
    id: String,
    label: String,
    name: String,
    workingDirectory: String,
    command: String,
    url: String?,
    logPath: String,
    setupFiles: [String],
    state: ServerState,
    pid: Int32?,
    footprintBytes: UInt64,
    residentMemoryBytes: UInt64
  ) {
    self.id = id
    self.label = label
    self.name = name
    self.workingDirectory = workingDirectory
    self.command = command
    self.url = url
    self.logPath = logPath
    self.setupFiles = setupFiles
    self.state = state
    self.pid = pid
    self.footprintBytes = footprintBytes
    self.residentMemoryBytes = residentMemoryBytes
  }

  public var isRunnable: Bool {
    FileManager.default.fileExists(atPath: workingDirectory)
  }
}

public struct RegistrySnapshot: Equatable, Sendable {
  public let servers: [PersistentServer]
  public let monitorFootprintBytes: UInt64
  public let monitorResidentMemoryBytes: UInt64

  public init(
    servers: [PersistentServer],
    monitorFootprintBytes: UInt64,
    monitorResidentMemoryBytes: UInt64
  ) {
    self.servers = servers
    self.monitorFootprintBytes = monitorFootprintBytes
    self.monitorResidentMemoryBytes = monitorResidentMemoryBytes
  }

  public var runningServers: [PersistentServer] {
    servers.filter { $0.state == .running }
  }

  public var runningFootprintBytes: UInt64 {
    runningServers.reduce(0) { $0 + $1.footprintBytes }
  }

  public var runningResidentMemoryBytes: UInt64 {
    runningServers.reduce(0) { $0 + $1.residentMemoryBytes }
  }
}

public enum ServerAction: String, Sendable {
  case restart
  case stop
}

public enum ByteCount {
  public static func format(_ bytes: UInt64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = bytes >= 1_000_000_000 ? [.useGB] : [.useMB]
    formatter.countStyle = .memory
    formatter.includesUnit = true
    formatter.isAdaptive = true
    return formatter.string(fromByteCount: Int64(bytes))
  }
}
