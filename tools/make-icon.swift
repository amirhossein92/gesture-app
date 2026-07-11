import AppKit

// Renders the GestureTabs app icon to a 1024x1024 PNG.
// Theme: a trackpad with a held anchor finger (center dot) and left/right
// chevrons for the tap-to-switch gesture.
// Usage: swift tools/make-icon.swift <output.png>

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let px = 1024

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("no bitmap rep") }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// --- Background squircle with blue gradient -------------------------------
let inset: CGFloat = 100
let bgRect = CGRect(x: inset, y: inset, width: CGFloat(px) - 2 * inset, height: CGFloat(px) - 2 * inset)
let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.saveGState()
ctx.addPath(bgPath)
ctx.clip()
let colors = [
    CGColor(red: 0.29, green: 0.56, blue: 0.91, alpha: 1),  // top  #4A8FE8
    CGColor(red: 0.16, green: 0.40, blue: 0.82, alpha: 1),  // bot  #2A66D1
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(gradient,
    start: CGPoint(x: 0, y: CGFloat(px)),
    end: CGPoint(x: 0, y: 0),
    options: [])
ctx.restoreGState()

let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

// --- Trackpad outline -----------------------------------------------------
let padRect = CGRect(x: 232, y: 352, width: 560, height: 320)
let padPath = CGPath(roundedRect: padRect, cornerWidth: 64, cornerHeight: 64, transform: nil)
ctx.addPath(padPath)
ctx.setStrokeColor(white)
ctx.setLineWidth(22)
ctx.strokePath()

// --- Anchor finger (center dot) -------------------------------------------
ctx.setFillColor(white)
ctx.fillEllipse(in: CGRect(x: 512 - 60, y: 512 - 60, width: 120, height: 120))

// --- Left / right chevrons ------------------------------------------------
ctx.setStrokeColor(white)
ctx.setLineWidth(42)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)

// Right chevron ">"
ctx.beginPath()
ctx.move(to: CGPoint(x: 656, y: 588))
ctx.addLine(to: CGPoint(x: 716, y: 512))
ctx.addLine(to: CGPoint(x: 656, y: 436))
ctx.strokePath()

// Left chevron "<"
ctx.beginPath()
ctx.move(to: CGPoint(x: 368, y: 588))
ctx.addLine(to: CGPoint(x: 308, y: 512))
ctx.addLine(to: CGPoint(x: 368, y: 436))
ctx.strokePath()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("png encode failed") }
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
