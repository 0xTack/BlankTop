// 开关特写：开/关两种状态，大尺寸矢量绘制。
import AppKit

func drawSwitch(width: CGFloat, height: CGFloat, on: Bool, scale: CGFloat) -> NSImage {
    let w = width * scale, h = height * scale
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(w), pixelsHigh: Int(h),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let inset: CGFloat = 1.0 * scale
    let radius = (h - inset * 2) / 2
    let track = NSBezierPath(roundedRect: NSRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2),
                             xRadius: radius, yRadius: radius)

    NSGraphicsContext.saveGraphicsState()
    track.addClip()
    let tint = on ? NSColor(srgbRed: 121 / 255, green: 188 / 255, blue: 81 / 255, alpha: 0.62)
                  : NSColor.black.withAlphaComponent(0.15)
    tint.setFill()
    NSRect(x: on ? inset : w / 2, y: inset, width: w / 2 - inset, height: h - inset * 2).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSColor.black.withAlphaComponent(0.78).setStroke()
    track.lineWidth = 1.2 * scale
    track.stroke()

    let knob = 5.2 / 12 * h
    let margin = 2.4 / 12 * h
    let knobX = on ? w - margin - knob : margin
    NSColor.black.withAlphaComponent(0.85).setFill()
    NSBezierPath(ovalIn: NSRect(x: knobX, y: (h - knob) / 2, width: knob, height: knob)).fill()

    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: NSSize(width: width * scale, height: height * scale))
    image.addRepresentation(rep)
    return image
}

let width: CGFloat = 1200
let height: CGFloat = 460

let output = NSImage(size: NSSize(width: width, height: height))
output.lockFocus()

let bg = NSGradient(colors: [NSColor(srgbRed: 0.12, green: 0.16, blue: 0.32, alpha: 1),
                             NSColor(srgbRed: 0.07, green: 0.09, blue: 0.18, alpha: 1)])!
bg.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -70)

// 两段菜单栏
for (index, on) in [true, false].enumerated() {
    let stripW: CGFloat = 500, stripH: CGFloat = 120
    let x: CGFloat = index == 0 ? 60 : 640
    let strip = NSRect(x: x, y: 90, width: stripW, height: stripH)
    let path = NSBezierPath(roundedRect: strip, xRadius: 22, yRadius: 22)
    let g = NSGradient(colors: [NSColor(srgbRed: 0.984, green: 0.972, blue: 0.937, alpha: 1),
                                NSColor(srgbRed: 0.937, green: 0.910, blue: 0.847, alpha: 1)])!
    g.draw(in: path, angle: -90)
    NSColor(calibratedWhite: 0, alpha: 0.06).setStroke()
    path.lineWidth = 1.5
    path.stroke()

    let sw = drawSwitch(width: 160, height: 96, on: on, scale: 2)
    sw.draw(in: NSRect(x: strip.midX - 80, y: strip.midY - 48, width: 160, height: 96))

    let text = NSAttributedString(string: on ? "展开 · 圆点在右，底板绿" : "折叠 · 圆点在左，底板灰", attributes: [
        .font: NSFont.systemFont(ofSize: 15, weight: .medium),
        .foregroundColor: NSColor(calibratedWhite: 0.78, alpha: 1)
    ])
    let size = text.size()
    text.draw(at: NSPoint(x: strip.midX - size.width / 2, y: 52))
}

output.unlockFocus()

if let tiff = output.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "/tmp/switch-shot.png"))
    print("wrote /tmp/switch-shot.png")
}
