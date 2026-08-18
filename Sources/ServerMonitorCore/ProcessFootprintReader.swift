import Darwin
import Foundation

public protocol ProcessFootprintReading: Sendable {
  func physicalFootprintBytes(for pid: Int32) -> UInt64?
}

public struct SystemProcessFootprintReader: ProcessFootprintReading {
  public init() {}

  public func physicalFootprintBytes(for pid: Int32) -> UInt64? {
    var info = rusage_info_v4()
    let result = withUnsafeMutablePointer(to: &info) { pointer in
      pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
        proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
      }
    }

    return result == 0 ? info.ri_phys_footprint : nil
  }
}
