//
//  smoothicon.swift
//  留白 v1.1 · 光滑版应用图标
//
//  把参考图重画成干净的矢量：圆角白底 + 黑手剪影 + 眼睛。
//  不再使用手绘扫描线，边缘和圆角都是平滑的。
//
//  运行：
//    swiftc -O dev/smoothicon.swift -framework AppKit -o /tmp/smoothicon && /tmp/smoothicon
//

import AppKit

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
            green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255,
            alpha: a)
}

let ink = hex(0x1E1E1E)
let white = hex(0xFFFFFF)

func rr(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r)
}

func fill(_ p: NSBezierPath, _ color: NSColor) {
    color.setFill()
    p.fill()
}

func stroke(_ p: NSBezierPath, _ color: NSColor, _ width: CGFloat) {
    color.setStroke()
    p.lineWidth = width
    p.lineCapStyle = .round
    p.lineJoinStyle = .round
    p.stroke()
}

func renderIcon(to path: String) {
    let size: CGFloat = 1024
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))

    // 圆角白底
    let plate = rr(30, 30, 964, 964, 202)
    white.setFill()
    plate.fill()
    ink.setStroke()
    plate.lineWidth = 18
    plate.stroke()

    // 眼睛：先画，手会盖住上沿
    let eye = NSBezierPath()
    eye.move(to: NSPoint(x: 226, y: 500))
    eye.curve(to: NSPoint(x: 572, y: 500),
              controlPoint1: NSPoint(x: 330, y: 606),
              controlPoint2: NSPoint(x: 468, y: 606))
    eye.curve(to: NSPoint(x: 226, y: 500),
              controlPoint1: NSPoint(x: 468, y: 394),
              controlPoint2: NSPoint(x: 330, y: 394))
    stroke(eye, ink, 16)

    fill(NSBezierPath(ovalIn: NSRect(x: 348, y: 448, width: 104, height: 104)), ink)
    fill(NSBezierPath(ovalIn: NSRect(x: 408, y: 512, width: 30, height: 30)), white)

    // 四根手指
    for y in [530, 630, 730, 830] {
        fill(rr(292, CGFloat(y), 468, 72, 36), ink)
    }
    // 手掌 + 手腕
    fill(rr(556, 250, 306, 660, 145), ink)
    fill(rr(812, 110, 150, 410, 75), ink)

    // 拇指
    ctx.saveGState()
    ctx.translateBy(x: 760, y: 790)
    ctx.rotate(by: -38 * .pi / 180)
    fill(rr(-52, 0, 104, 232, 52), ink)
    ctx.restoreGState()

    // 手指之间的白缝
    for y in [602, 702, 802] {
        let gap = NSBezierPath()
        gap.move(to: NSPoint(x: 306, y: CGFloat(y)))
        gap.line(to: NSPoint(x: 612, y: CGFloat(y)))
        stroke(gap, white, 18)
    }

    NSGraphicsContext.restoreGraphicsState()

    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: path))
        print("wrote \(path)")
    }
}

renderIcon(to: "/tmp/blanktop-smooth-1024.png")

// 小尺寸预览：直接重采样，看看 256 / 128 / 64 / 32 是否还清楚
if let image = NSImage(contentsOfFile: "/tmp/blanktop-smooth-1024.png") {
    for s in [256, 128, 64, 32] {
        let out = NSImage(size: NSSize(width: s, height: s))
        out.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: s, height: s))
        out.unlockFocus()
        if let tiff = out.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: "/tmp/blanktop-smooth-\(s).png"))
            print("wrote /tmp/blanktop-smooth-\(s).png")
        }
    }
}
