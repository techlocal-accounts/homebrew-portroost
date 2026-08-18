import XCTest
@testable import ServerMonitorCore

private struct StubFootprintReader: ProcessFootprintReading {
  let values: [Int32: UInt64]

  func physicalFootprintBytes(for pid: Int32) -> UInt64? {
    values[pid]
  }
}

final class ProcessTableTests: XCTestCase {
  func testFindsRootAndAllDescendants() {
    let table = ProcessTable.parse("""
      100     1   1024 npm run dev
      101   100   2048 node vite
      102   101   4096 esbuild
      200     1   8192 unrelated
    """)

    XCTAssertEqual(table.processIDs(forProcessTree: 100), [100, 101, 102])
    XCTAssertEqual(table.residentMemoryBytes(forProcessTree: 100), 7_168 * 1_024)
  }

  func testSumsFootprintAndFallsBackToResidentMemory() {
    let table = ProcessTable.parse("""
      100     1   1024 npm run dev
      101   100   2048 node vite
      102   101   4096 esbuild
    """)
    let usage = table.memoryUsage(
      forProcessTree: 100,
      footprintReader: StubFootprintReader(values: [
        100: 10_000_000,
        101: 20_000_000,
      ])
    )

    XCTAssertEqual(usage.residentBytes, 7_168 * 1_024)
    XCTAssertEqual(usage.footprintBytes, 30_000_000 + (4_096 * 1_024))
  }

  func testIgnoresMalformedRowsAndMissingRoots() {
    let table = ProcessTable.parse("""
      malformed
      20 1 512 valid
    """)

    XCTAssertEqual(table.samples.count, 1)
    XCTAssertEqual(table.residentMemoryBytes(forProcessTree: 99), 0)
  }
}
