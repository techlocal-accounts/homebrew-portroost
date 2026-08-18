#!/usr/bin/env swift

import AppKit
import Foundation

let scriptURL = URL(fileURLWithPath: #filePath)
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let iconsetURL = projectRoot.appendingPathComponent("Resources/AppIcon.iconset")
let fileManager = FileManager.default

try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
  NSColor(
    calibratedRed: red / 255,
    green: green / 255,
    blue: blue / 255,
    alpha: alpha
  )
}

func drawIcon(size: Int) throws -> Data {
  guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bitmapFormat: [],
    bytesPerRow: 0,
    bitsPerPixel: 0
  ), let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    throw NSError(domain: "IconGenerator", code: 1)
  }

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = graphicsContext
  defer { NSGraphicsContext.restoreGraphicsState() }

  let scale = CGFloat(size) / 1_024
  graphicsContext.cgContext.scaleBy(x: scale, y: scale)
  graphicsContext.cgContext.setShouldAntialias(true)

  let tile = NSBezierPath(
    roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896),
    xRadius: 220,
    yRadius: 220
  )
  graphicsContext.saveGraphicsState()
  tile.addClip()
  NSGradient(
    starting: color(24, 29, 51),
    ending: color(66, 74, 128)
  )?.draw(in: tile, angle: 45)
  graphicsContext.restoreGraphicsState()

  color(255, 255, 255, 0.12).setStroke()
  tile.lineWidth = 12
  tile.stroke()

  let rowYs: [CGFloat] = [650, 442, 234]
  for (index, y) in rowYs.enumerated() {
    let row = NSBezierPath(
      roundedRect: NSRect(x: 190, y: y, width: 644, height: 156),
      xRadius: 42,
      yRadius: 42
    )
    color(9, 13, 29, 0.76).setFill()
    row.fill()

    color(index == 1 ? 82 : 93, index == 1 ? 214 : 231, index == 1 ? 147 : 180).setFill()
    NSBezierPath(ovalIn: NSRect(x: 238, y: y + 59, width: 38, height: 38)).fill()

    color(225, 231, 255, 0.72).setFill()
    NSBezierPath(
      roundedRect: NSRect(x: 318, y: y + 66, width: 184, height: 24),
      xRadius: 12,
      yRadius: 12
    ).fill()

    let barWidths: [CGFloat] = [48, 72, 98]
    for (barIndex, width) in barWidths.enumerated() {
      color(118, 164 + CGFloat(barIndex * 18), 255, 0.9).setFill()
      NSBezierPath(
        roundedRect: NSRect(
          x: 682 - width,
          y: y + 48 + CGFloat(barIndex * 25),
          width: width,
          height: 15
        ),
        xRadius: 7,
        yRadius: 7
      ).fill()
    }
  }

  guard let png = bitmap.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "IconGenerator", code: 2)
  }
  return png
}

let outputs: [(String, Int)] = [
  ("icon_16x16.png", 16),
  ("icon_16x16@2x.png", 32),
  ("icon_32x32.png", 32),
  ("icon_32x32@2x.png", 64),
  ("icon_128x128.png", 128),
  ("icon_128x128@2x.png", 256),
  ("icon_256x256.png", 256),
  ("icon_256x256@2x.png", 512),
  ("icon_512x512.png", 512),
  ("icon_512x512@2x.png", 1_024),
]

for (filename, size) in outputs {
  try drawIcon(size: size).write(to: iconsetURL.appendingPathComponent(filename))
}

let icnsURL = projectRoot.appendingPathComponent("Resources/AppIcon.icns")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
  throw NSError(domain: "IconGenerator", code: Int(process.terminationStatus))
}

print("Generated \(icnsURL.path)")
