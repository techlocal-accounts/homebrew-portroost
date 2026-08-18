import Foundation

public struct LaunchdSnapshot: Equatable, Sendable {
  public let state: ServerState
  public let pid: Int32?

  public init(state: ServerState, pid: Int32?) {
    self.state = state
    self.pid = pid
  }

  public static func parse(output: String, exitCode: Int32) -> LaunchdSnapshot {
    guard exitCode == 0 else {
      return LaunchdSnapshot(state: .stopped, pid: nil)
    }

    let stateValue = capture(
      in: output,
      pattern: #"(?m)^\s*state = ([^\n]+)$"#
    )?.trimmingCharacters(in: .whitespacesAndNewlines)
    let pid = capture(in: output, pattern: #"(?m)^\s*pid = ([0-9]+)$"#)
      .flatMap(Int32.init)

    if stateValue == "running" || pid != nil {
      return LaunchdSnapshot(state: .running, pid: pid)
    }

    return LaunchdSnapshot(state: .loaded, pid: nil)
  }

  private static func capture(in text: String, pattern: String) -> String? {
    guard let expression = try? NSRegularExpression(pattern: pattern),
          let match = expression.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)
          ),
          match.numberOfRanges > 1,
          let range = Range(match.range(at: 1), in: text) else {
      return nil
    }

    return String(text[range])
  }
}
