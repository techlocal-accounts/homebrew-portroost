import Foundation
import XCTest
@testable import ServerMonitorCore

private struct RecordingExecutor: CommandExecuting {
  let handler: @Sendable (String, [String]) -> CommandResult

  func run(executable: String, arguments: [String]) -> CommandResult {
    handler(executable, arguments)
  }
}

private struct RegistryFootprintReader: ProcessFootprintReading {
  let values: [Int32: UInt64]

  func physicalFootprintBytes(for pid: Int32) -> UInt64? {
    values[pid]
  }
}

final class RegistryTests: XCTestCase {
  func testLoadsSavedServerWithoutReadingEnvironmentContents() throws {
    let temporaryRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let serverDirectory = temporaryRoot.appendingPathComponent("sample-123", isDirectory: true)
    let projectDirectory = temporaryRoot.appendingPathComponent("sample", isDirectory: true)
    try FileManager.default.createDirectory(
      at: serverDirectory,
      withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
      at: projectDirectory,
      withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: temporaryRoot) }

    let plist: [String: Any] = [
      "Label": "com.openai.codex.dev.sample",
      "WorkingDirectory": projectDirectory.path,
    ]
    let plistData = try PropertyListSerialization.data(
      fromPropertyList: plist,
      format: .xml,
      options: 0
    )
    try plistData.write(to: serverDirectory.appendingPathComponent("job.plist"))
    try Data("npm run dev".utf8).write(
      to: serverDirectory.appendingPathComponent("command")
    )
    try Data("http://127.0.0.1:3000/".utf8).write(
      to: serverDirectory.appendingPathComponent("url")
    )
    try Data("SECRET=not-read".utf8).write(
      to: projectDirectory.appendingPathComponent(".env.local")
    )

    let executor = RecordingExecutor { executable, _ in
      if executable == "/bin/ps" {
        return CommandResult(
          exitCode: 0,
          output: "4321 1 2048 npm\n4322 4321 4096 node\n"
        )
      }
      if executable == "/bin/launchctl" {
        return CommandResult(exitCode: 0, output: "state = running\npid = 4321\n")
      }
      return CommandResult(exitCode: 1, output: "unexpected")
    }
    let registry = PersistentServerRegistry(
      registryRoot: temporaryRoot.path,
      runnerPath: "/missing/runner",
      executor: executor,
      footprintReader: RegistryFootprintReader(values: [
        4_321: 20_000_000,
        4_322: 40_000_000,
      ])
    )

    let snapshot = registry.scan()

    XCTAssertEqual(snapshot.servers.count, 1)
    XCTAssertEqual(snapshot.servers[0].command, "npm run dev")
    XCTAssertEqual(snapshot.servers[0].url, "http://127.0.0.1:3000/")
    XCTAssertEqual(snapshot.servers[0].setupFiles, [".env.local"])
    XCTAssertEqual(snapshot.servers[0].footprintBytes, 60_000_000)
    XCTAssertEqual(snapshot.servers[0].residentMemoryBytes, 6_144 * 1_024)
  }

  func testControlUsesSavedProjectDirectory() throws {
    let temporaryRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let projectDirectory = temporaryRoot.appendingPathComponent("project", isDirectory: true)
    let runner = temporaryRoot.appendingPathComponent("persistent-dev.sh")
    try FileManager.default.createDirectory(
      at: projectDirectory,
      withIntermediateDirectories: true
    )
    try Data("#!/bin/zsh\n".utf8).write(to: runner)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o700],
      ofItemAtPath: runner.path
    )
    defer { try? FileManager.default.removeItem(at: temporaryRoot) }

    let executor = RecordingExecutor { executable, arguments in
      XCTAssertEqual(executable, runner.path)
      XCTAssertEqual(arguments, ["restart", "--cwd", projectDirectory.path])
      return CommandResult(exitCode: 0, output: "Started")
    }
    let registry = PersistentServerRegistry(
      registryRoot: temporaryRoot.path,
      runnerPath: runner.path,
      executor: executor
    )
    let server = PersistentServer(
      id: "example",
      label: "com.openai.codex.dev.example",
      name: "project",
      workingDirectory: projectDirectory.path,
      command: "npm run dev",
      url: nil,
      logPath: temporaryRoot.appendingPathComponent("server.log").path,
      setupFiles: [],
      state: .stopped,
      pid: nil,
      footprintBytes: 0,
      residentMemoryBytes: 0
    )

    let result = registry.perform(.restart, on: server)

    XCTAssertEqual(result, CommandResult(exitCode: 0, output: "Started"))
  }
}
