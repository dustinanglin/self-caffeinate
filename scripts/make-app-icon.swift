#!/usr/bin/env swift
// Generates AppIcon.appiconset from the full-caf cup PDF: dark cup centered on a white
// rounded square (classic macOS icon grid: 824pt tile on a 1024pt canvas, transparent margin).
//
// Usage: swift scripts/make-app-icon.swift   (run from repo root)

import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let cupURL = root.appendingPathComponent("SelfCaffeinate/Assets.xcassets/MenuBarCupFilled.imageset/cup.pdf")
let iconSet = root.appendingPathComponent("SelfCaffeinate/Assets.xcassets/AppIcon.appiconset")

guard let cup = NSImage(contentsOf: cupURL) else {
    FileHandle.standardError.write("Could not load \(cupURL.path)\n".data(using: .utf8)!)
    exit(1)
}
cup.isTemplate = false

/// Draws the cup into its own transparent bitmap and recolors it there, so the tint only
/// covers the cup.s alpha and not the white tile behind it.
func tintedCup(width: Int, height: Int) -> NSImage {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let rect = NSRect(x: 0, y: 0, width: width, height: height)
    cup.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
    NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
    rect.fill(using: .sourceAtop)
    NSGraphicsContext.restoreGraphicsState()
    let image = NSImage(size: rep.size)
    image.addRepresentation(rep)
    return image
}

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    let s = CGFloat(pixels) / 1024.0
    // Apple's macOS icon grid: 824pt tile, ~185pt corner radius, centered.
    let tile = CGRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let path = NSBezierPath(roundedRect: tile, xRadius: 185 * s, yRadius: 185 * s)

    // Soft shadow under the tile so it reads against white backgrounds too.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12 * s), blur: 24 * s,
                  color: NSColor.black.withAlphaComponent(0.25).cgColor)
    NSColor.white.setFill()
    path.fill()
    ctx.restoreGState()

    // Cup: template PDF tinted near-black, scaled to ~64% of the tile.
    let cupSide = tile.width * 0.64
    let aspect = cup.size.width / cup.size.height
    let cupW = aspect >= 1 ? cupSide : cupSide * aspect
    let cupH = aspect >= 1 ? cupSide / aspect : cupSide
    let cupRect = CGRect(x: tile.midX - cupW / 2, y: tile.midY - cupH / 2, width: cupW, height: cupH)

    tintedCup(width: Int(cupW.rounded(.up)), height: Int(cupH.rounded(.up)))
        .draw(in: cupRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

struct Slot { let size: Int; let scale: Int }
let slots = [16, 32, 128, 256, 512].flatMap { [Slot(size: $0, scale: 1), Slot(size: $0, scale: 2)] }

var images: [[String: String]] = []
for slot in slots {
    let name = "icon_\(slot.size)x\(slot.size)@\(slot.scale)x.png"
    try! render(pixels: slot.size * slot.scale).write(to: iconSet.appendingPathComponent(name))
    images.append(["filename": name, "idiom": "mac", "scale": "\(slot.scale)x", "size": "\(slot.size)x\(slot.size)"])
}
let json: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let data = try! JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
try! data.write(to: iconSet.appendingPathComponent("Contents.json"))
print("Wrote \(slots.count) icons to \(iconSet.path)")
