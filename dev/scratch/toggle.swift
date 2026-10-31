// 预览开关图标：1x 实际大小 + 8x 放大，展开/折叠两态。
import AppKit

let baseWidth: CGFloat = 20
let baseHeight: CGFloat = 12

func drawSwitch(on: Bool, scale: CGFloat) -> NSImage {
    let width = baseWidth * scale
    let height = baseHeight * scale
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(width), pixelsHigh: Int(height),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let s = scale
    let inset: CGFloat = 0.75 * s
    let radius = (height - inset * 2) / 2
    let track = NSBezierPath(roundedRect: NSRect(x: inset, y: inset,
                                                 width: width - inset * 2,
                                                 height: height - inset * 2),
                             xRadius: radius, yRadius: radius)

    // 轨道内部：只在「露出」的那一半上淡淡着色，其余留白
    NSGraphicsContext.saveGraphicsState()
    track.addClip()
    let tint = on
        ? NSColor(calibratedRed: 0.20, green: 0.48, blue: 0.28, alpha: 0.30)
        : NSColor(calibratedRed: 0.60, green: 0.24, blue: 0.24, alpha: 0.26)
    tint.setFill()
    let reveal = NSRect(x: on ? inset : width / 2,
                        y: inset,
                        width: width / 2 - inset,
                        height: height - inset * 2)
    reveal.fill()
    NSGraphicsContext.restoreGraphicsState()

    // 轨道描边，用和旁边图标接近的深灰
    NSColor.black.withAlphaComponent(0.78).setStroke()
    track.lineWidth = 1.2 * s
    track.stroke()

    // 小圆点（开关钮）
    let knob = 5.2 * s
    let margin = 2.4 * s
    let knobX = on ? width - margin - knob : margin
    NSColor.black.withAlphaComponent(0.85).setFill()
    NSBezierPath(ovalIn: NSRect(x: knobX, y: (height - knob) / 2, width: knob, height: knob)).fill()

    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: NSSize(width: width, height: height))
    image.addRepresentation(rep)
    return image
}

// 拼图
let cellW: CGFloat = 210
let cellH: CGFloat = 130
let output = NSImage(size: NSSize(width: cellW * 2 + 30, height: cellH + 80))
output.lockFocus()
NSColor(calibratedWhite: 0.16, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: output.size.width, height: output.size.height).fill()

let labels = ["折叠（关）", "展开（开）"]
for (index, on) in [false, true].enumerated() {
    let x = 20 + CGFloat(index) * (cellW + 10)
    let big = drawSwitch(on: on, scale: 8)
    big.draw(in: NSRect(x: x, y: 70, width: big.size.width, height: big.size.height))
    let small = drawSwitch(on: on, scale: 2)
    small.draw(in: NSRect(x: x + 10, y: 66 - small.size.height, width: small.size.width, height: small.size.height))
    NSAttributedString(string: labels[index], attributes: [
        .font: NSFont.systemFont(ofSize: 13),
        .foregroundColor: NSColor.white
    ]).draw(at: NSPoint(x: x, y: 36))

    // 对比：旁边放一个系统 SF 图标看颜色是否接近
    if let ref = NSImage(systemSymbolName: "square.stack.3d.up", accessibilityDescription: nil) {
        ref.draw(in: NSRect(x: x + 60, y: 66 - ref.size.height, width: ref.size.width, height: ref.size.height))
    }
}
output.unlockFocus()

if let tiff = output.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "/tmp/toggle_preview.png"))
    print("wrote /tmp/toggle_preview.png")
}
