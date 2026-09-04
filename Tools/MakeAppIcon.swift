//
//  MakeAppIcon.swift
//  KeepAwake
//
//  Regenerates every PNG in Assets.xcassets/AppIcon.appiconset.
//
//  Usage:
//      swift Tools/MakeAppIcon.swift <output.png> <pixel-size>
//
//  To rebuild the whole set (run from the repo root):
//      SET=KeepAwake/Resources/Assets.xcassets/AppIcon.appiconset
//      swift Tools/MakeAppIcon.swift $SET/icon_16x16.png       16
//      swift Tools/MakeAppIcon.swift $SET/icon_16x16@2x.png    32
//      swift Tools/MakeAppIcon.swift $SET/icon_32x32.png       32
//      swift Tools/MakeAppIcon.swift $SET/icon_32x32@2x.png    64
//      swift Tools/MakeAppIcon.swift $SET/icon_128x128.png    128
//      swift Tools/MakeAppIcon.swift $SET/icon_128x128@2x.png 256
//      swift Tools/MakeAppIcon.swift $SET/icon_256x256.png    256
//      swift Tools/MakeAppIcon.swift $SET/icon_256x256@2x.png 512
//      swift Tools/MakeAppIcon.swift $SET/icon_512x512.png    512
//      swift Tools/MakeAppIcon.swift $SET/icon_512x512@2x.png 1024
//
//  Lives outside the KeepAwake/ and KeepAwakeTests/ synchronized folders so it
//  is not compiled into either target.
//

import AppKit
import Foundation

// Renders the KeepAwake app icon: a golden sun held up against a night sky.
// The sun is the same SF Symbol the menu bar uses in its "awake" state, so the
// app icon and the status item read as the same object.

// Rendered natively at each target size rather than downsampled from one master:
// SF Symbols substitute size-optimised glyph variants at small point sizes, so a
// 16pt render is legible where a 16px downscale of a 1024px render is mush.
let canvas = Double(CommandLine.arguments[2])!
let scale = canvas / 1024.0

// macOS Big Sur+ icon grid: the rounded square occupies 824x824 centred in a
// 1024x1024 canvas, leaving the surrounding margin for the system's shadow.
let plateInset = 100.0 * scale
let plateSize = canvas - plateInset * 2
let cornerRadius = 185.4 * scale

func makeContext() -> NSBitmapImageRep {
    NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(canvas), pixelsHigh: Int(canvas),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
}

func srgb(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

// MARK: - The sun, masked out of a gold gradient

let sunRep = makeContext()
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: sunRep)

let symbolConfig = NSImage.SymbolConfiguration(pointSize: 560 * scale, weight: .medium)
guard let symbol = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(symbolConfig) else {
    fatalError("sun.max.fill unavailable")
}
let symbolSize = symbol.size
let symbolRect = NSRect(
    x: (canvas - symbolSize.width) / 2,
    y: (canvas - symbolSize.height) / 2,
    width: symbolSize.width,
    height: symbolSize.height
)

// The glyph goes down first as an alpha stencil, then the gold gradient is
// composited onto it with .sourceIn.
//
// The reverse order (gradient, then glyph with .destinationIn) leaves a 1px
// bright line around the symbol's bounding box: the gradient's own rect edge is
// antialiased and .destinationIn only composites within the mask's draw rect, so
// that edge survives instead of being masked away. Stencil-first means the only
// alpha edges in the result are the glyph's own.
symbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1)

let fullCanvas = NSRect(x: 0, y: 0, width: canvas, height: canvas)
let goldRep = makeContext()
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: goldRep)
NSGradient(colors: [srgb(0xFFE08A), srgb(0xFFB020)],
           atLocations: [0, 1], colorSpace: .sRGB)?
    .draw(in: symbolRect, angle: -90)
NSGraphicsContext.restoreGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: sunRep)

let goldImage = NSImage(size: NSSize(width: canvas, height: canvas))
goldImage.addRepresentation(goldRep)
goldImage.draw(in: fullCanvas, from: .zero, operation: .sourceIn, fraction: 1)

NSGraphicsContext.restoreGraphicsState()
let sunImage = NSImage(size: NSSize(width: canvas, height: canvas))
sunImage.addRepresentation(sunRep)

// MARK: - Compose the plate and the sun

let iconRep = makeContext()
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: iconRep)
NSGraphicsContext.current?.imageInterpolation = .high

let plate = NSBezierPath(
    roundedRect: NSRect(x: plateInset, y: plateInset, width: plateSize, height: plateSize),
    xRadius: cornerRadius, yRadius: cornerRadius
)
NSGraphicsContext.saveGraphicsState()
plate.addClip()
NSGradient(colors: [srgb(0x35406F), srgb(0x0B1026)],
           atLocations: [0, 1], colorSpace: .sRGB)?
    .draw(in: plate.bounds, angle: -90)

// Soft halo so the sun reads as a light source rather than a sticker.
//
// Drawn across the full plate rather than a tighter rect: a radial NSGradient
// hard-stops at its rect boundary, and a smaller rect leaves a visible seam
// where that boundary crosses the plate. Spanning the plate puts the boundary
// under the clip, and the falloff is controlled by the stop locations instead.
NSGradient(colors: [srgb(0xFFC65A, alpha: 0.34), srgb(0xFFC65A, alpha: 0)],
           atLocations: [0, 0.62], colorSpace: .sRGB)?
    .draw(in: plate.bounds, relativeCenterPosition: .zero)
NSGraphicsContext.restoreGraphicsState()

sunImage.draw(in: NSRect(x: 0, y: 0, width: canvas, height: canvas),
              from: .zero, operation: .sourceOver, fraction: 1)

NSGraphicsContext.restoreGraphicsState()

let outPath = CommandLine.arguments[1]
guard let png = iconRep.representation(using: .png, properties: [:]) else {
    fatalError("PNG encoding failed")
}
try png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
