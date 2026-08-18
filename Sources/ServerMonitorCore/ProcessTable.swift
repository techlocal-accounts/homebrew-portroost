import Foundation

public struct ProcessSample: Equatable, Sendable {
  public let pid: Int32
  public let parentPID: Int32
  public let residentKilobytes: UInt64
  public let command: String

  public init(
    pid: Int32,
    parentPID: Int32,
    residentKilobytes: UInt64,
    command: String
  ) {
    self.pid = pid
    self.parentPID = parentPID
    self.residentKilobytes = residentKilobytes
    self.command = command
  }
}

public struct ProcessTable: Equatable, Sendable {
  public let samples: [ProcessSample]

  public init(samples: [ProcessSample]) {
    self.samples = samples
  }

  public static func parse(_ output: String) -> ProcessTable {
    let samples = output.split(separator: "\n").compactMap { line -> ProcessSample? in
      let parts = line.split(
        maxSplits: 3,
        omittingEmptySubsequences: true,
        whereSeparator: { $0 == " " || $0 == "\t" }
      )
      guard parts.count >= 3,
            let pid = Int32(parts[0]),
            let parentPID = Int32(parts[1]),
            let residentKilobytes = UInt64(parts[2]) else {
        return nil
      }

      return ProcessSample(
        pid: pid,
        parentPID: parentPID,
        residentKilobytes: residentKilobytes,
        command: parts.count == 4 ? String(parts[3]) : ""
      )
    }

    return ProcessTable(samples: samples)
  }

  public func processIDs(forProcessTree rootPID: Int32) -> [Int32] {
    let childrenByParent = Dictionary(grouping: samples, by: \.parentPID)
    var pending = [rootPID]
    var visited = Set<Int32>()

    while let pid = pending.popLast() {
      guard visited.insert(pid).inserted else {
        continue
      }
      pending.append(contentsOf: childrenByParent[pid, default: []].map(\.pid))
    }

    return visited.sorted()
  }

  public func residentMemoryBytes(forProcessTree rootPID: Int32) -> UInt64 {
    let samplesByPID = Dictionary(uniqueKeysWithValues: samples.map { ($0.pid, $0) })
    let totalKilobytes = processIDs(forProcessTree: rootPID).reduce(UInt64(0)) {
      $0 + (samplesByPID[$1]?.residentKilobytes ?? 0)
    }

    return totalKilobytes * 1_024
  }

  public func memoryUsage(
    forProcessTree rootPID: Int32,
    footprintReader: any ProcessFootprintReading
  ) -> ProcessTreeMemoryUsage {
    let samplesByPID = Dictionary(uniqueKeysWithValues: samples.map { ($0.pid, $0) })
    let processIDs = processIDs(forProcessTree: rootPID)
    let residentBytes = residentMemoryBytes(forProcessTree: rootPID)
    let footprintBytes = processIDs.reduce(UInt64(0)) { total, pid in
      let residentFallback = (samplesByPID[pid]?.residentKilobytes ?? 0) * 1_024
      return total + (footprintReader.physicalFootprintBytes(for: pid) ?? residentFallback)
    }

    return ProcessTreeMemoryUsage(
      footprintBytes: footprintBytes,
      residentBytes: residentBytes
    )
  }
}

public struct ProcessTreeMemoryUsage: Equatable, Sendable {
  public let footprintBytes: UInt64
  public let residentBytes: UInt64

  public init(footprintBytes: UInt64, residentBytes: UInt64) {
    self.footprintBytes = footprintBytes
    self.residentBytes = residentBytes
  }
}
