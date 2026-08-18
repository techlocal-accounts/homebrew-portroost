import XCTest
@testable import ServerMonitorCore

final class LaunchdSnapshotTests: XCTestCase {
  func testParsesRunningJobAndPID() {
    let output = """
    gui/501/com.openai.codex.dev.example = {
      state = running
      pid = 72076
      last exit code = (never exited)
    }
    """

    XCTAssertEqual(
      LaunchdSnapshot.parse(output: output, exitCode: 0),
      LaunchdSnapshot(state: .running, pid: 72_076)
    )
  }

  func testTreatsLoadedJobWithoutPIDAsLoaded() {
    let output = """
    gui/501/com.openai.codex.dev.example = {
      state = exited
      last exit code = 1
    }
    """

    XCTAssertEqual(
      LaunchdSnapshot.parse(output: output, exitCode: 0),
      LaunchdSnapshot(state: .loaded, pid: nil)
    )
  }

  func testTreatsMissingJobAsStopped() {
    XCTAssertEqual(
      LaunchdSnapshot.parse(output: "Could not find service", exitCode: 113),
      LaunchdSnapshot(state: .stopped, pid: nil)
    )
  }
}
