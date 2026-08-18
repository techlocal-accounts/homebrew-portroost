import Foundation

public struct CommandResult: Equatable, Sendable {
  public let exitCode: Int32
  public let output: String

  public init(exitCode: Int32, output: String) {
    self.exitCode = exitCode
    self.output = output
  }
}

public protocol CommandExecuting: Sendable {
  func run(executable: String, arguments: [String]) -> CommandResult
}

public struct SystemCommandExecutor: CommandExecuting {
  public init() {}

  public func run(executable: String, arguments: [String]) -> CommandResult {
    let process = Process()
    let outputPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = outputPipe
    process.standardError = outputPipe

    do {
      try process.run()
      let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      return CommandResult(
        exitCode: process.terminationStatus,
        output: String(decoding: data, as: UTF8.self)
      )
    } catch {
      return CommandResult(exitCode: 127, output: error.localizedDescription)
    }
  }
}
