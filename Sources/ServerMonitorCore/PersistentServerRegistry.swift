import Darwin
import Foundation

public struct PersistentServerRegistry: @unchecked Sendable {
  private let fileManager: FileManager
  private let executor: any CommandExecuting
  private let footprintReader: any ProcessFootprintReading
  public let registryRoot: String
  public let runnerPath: String

  public init(
    registryRoot: String = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".codex/persistent-dev").path,
    runnerPath: String = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(
        ".codex/skills/persistent-local-dev/scripts/persistent-dev.sh"
      ).path,
    fileManager: FileManager = .default,
    executor: any CommandExecuting = SystemCommandExecutor(),
    footprintReader: any ProcessFootprintReading = SystemProcessFootprintReader()
  ) {
    self.registryRoot = registryRoot
    self.runnerPath = runnerPath
    self.fileManager = fileManager
    self.executor = executor
    self.footprintReader = footprintReader
  }

  public func scan() -> RegistrySnapshot {
    let processResult = executor.run(
      executable: "/bin/ps",
      arguments: ["-axo", "pid=,ppid=,rss=,command="]
    )
    let processTable = ProcessTable.parse(processResult.output)
    let monitorMemory = processTable.memoryUsage(
      forProcessTree: getpid(),
      footprintReader: footprintReader
    )

    guard let directories = try? fileManager.contentsOfDirectory(atPath: registryRoot) else {
      return RegistrySnapshot(
        servers: [],
        monitorFootprintBytes: monitorMemory.footprintBytes,
        monitorResidentMemoryBytes: monitorMemory.residentBytes
      )
    }

    let servers = directories.compactMap { directoryName in
      loadServer(directoryName: directoryName, processTable: processTable)
    }.sorted { left, right in
      if left.state != right.state {
        return stateOrder(left.state) < stateOrder(right.state)
      }
      return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
    }

    return RegistrySnapshot(
      servers: servers,
      monitorFootprintBytes: monitorMemory.footprintBytes,
      monitorResidentMemoryBytes: monitorMemory.residentBytes
    )
  }

  public func perform(_ action: ServerAction, on server: PersistentServer) -> CommandResult {
    guard fileManager.isExecutableFile(atPath: runnerPath) else {
      return CommandResult(
        exitCode: 127,
        output: "Persistent server runner was not found at \(runnerPath)"
      )
    }
    guard server.isRunnable else {
      return CommandResult(
        exitCode: 1,
        output: "Project directory no longer exists: \(server.workingDirectory)"
      )
    }

    return executor.run(
      executable: runnerPath,
      arguments: [action.rawValue, "--cwd", server.workingDirectory]
    )
  }

  private func loadServer(
    directoryName: String,
    processTable: ProcessTable
  ) -> PersistentServer? {
    let stateDirectory = URL(fileURLWithPath: registryRoot)
      .appendingPathComponent(directoryName, isDirectory: true)
    let plistURL = stateDirectory.appendingPathComponent("job.plist")

    guard let data = try? Data(contentsOf: plistURL),
          let plist = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
          ) as? [String: Any],
          let label = plist["Label"] as? String,
          let workingDirectory = plist["WorkingDirectory"] as? String else {
      return nil
    }

    let launchResult = executor.run(
      executable: "/bin/launchctl",
      arguments: ["print", "gui/\(getuid())/\(label)"]
    )
    let launchSnapshot = LaunchdSnapshot.parse(
      output: launchResult.output,
      exitCode: launchResult.exitCode
    )
    let command = readText(at: stateDirectory.appendingPathComponent("command"))
    let url = readText(at: stateDirectory.appendingPathComponent("url"))
    let memory = launchSnapshot.pid.map {
      processTable.memoryUsage(forProcessTree: $0, footprintReader: footprintReader)
    } ?? ProcessTreeMemoryUsage(footprintBytes: 0, residentBytes: 0)

    return PersistentServer(
      id: directoryName,
      label: label,
      name: URL(fileURLWithPath: workingDirectory).lastPathComponent,
      workingDirectory: workingDirectory,
      command: command,
      url: url.isEmpty ? nil : url,
      logPath: stateDirectory.appendingPathComponent("server.log").path,
      setupFiles: detectSetupFiles(in: workingDirectory),
      state: launchSnapshot.state,
      pid: launchSnapshot.pid,
      footprintBytes: memory.footprintBytes,
      residentMemoryBytes: memory.residentBytes
    )
  }

  private func readText(at url: URL) -> String {
    (try? String(contentsOf: url, encoding: .utf8))?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  private func detectSetupFiles(in workingDirectory: String) -> [String] {
    guard let files = try? fileManager.contentsOfDirectory(atPath: workingDirectory) else {
      return []
    }

    let exactNames: Set<String> = [
      ".env",
      ".env.local",
      ".env.development",
      ".env.development.local",
      ".envrc",
      ".mise.toml",
      ".nvmrc",
      ".tool-versions",
      "mise.toml",
    ]

    return files.filter { file in
      exactNames.contains(file)
        || (file.hasPrefix(".env.") && !file.hasSuffix(".example"))
    }.sorted()
  }

  private func stateOrder(_ state: ServerState) -> Int {
    switch state {
    case .running: return 0
    case .loaded: return 1
    case .stopped: return 2
    }
  }
}
