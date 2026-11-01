//
//  previewicon.swift
//  应用图标预览：浅色 / 深色背景，256 / 128 / 64 / 32。
//
//  运行：
//    swiftc -O dev/previewicon.swift -framework AppKit -o /tmp/previewicon && /tmp/previewicon
//

import AppKit

let iconPath = "/tmp/blanktop-ref-1024.png"
guard let icon = NSImage(contentsOfFile: iconPath) else {
    print("missing \(iconPath)")
    exit(1)
}

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
            green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255,
            alpha: a)
}

let w: CGFloat = 1200, h: CGFloat = 820
let scale: CGFloat = 2
let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                           pixelsWide: Int(w * scale), pixelsHigh: Int(h * scale),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: w, height: h)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
ctx.scaleBy(x: scale, y: scale)

hex(0xEFE9DD).setFill()
NSRect(x: 0, y: 0, width: w, height: h).fill()

let title = NSAttributedString(string: "留白 v1.1 · 应用图标", attributes: [
    .font: NSFont.systemFont(ofSize: 26, weight: .semibold),
    .foregroundColor: hex(0x1B1B1B)
])
title.draw(at: NSPoint(x: 40, y: h - 54))

let sub = NSAttributedString(string: "原图形态不变；只做了去毛刺、2× 重采样和透明圆角。", attributes: [
    .font: NSFont.systemFont(ofSize: 13, weight: .regular),
    .foregroundColor: hex(0x6E6A63)
])
sub.draw(at: NSPoint(x: 40, y: h - 76))

func panel(_ rect: NSRect, _ color: NSColor) {
    let p = NSBezierPath(roundedRect: rect, xRadius: 22, yRadius: 22)
    color.setFill()
    p.fill()
    hex(0x000000, 0.06).setStroke()
    p.lineWidth = 1
    p.stroke()
}

let light = NSRect(x: 40, y: 90, width: 540, height: 610)
let dark = NSRect(x: 620, y: 90, width: 540, height: 610)
panel(light, hex(0xF4F4F4))
panel(dark, hex(0x1E1E20))

func drawIcon(_ size: CGFloat, center: NSPoint) {
    icon.draw(in: NSRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size),
              from: .zero, operation: .sourceOver, fraction: 1)
}

func label(_ text: String, center: NSPoint, color: NSColor) {
    let s = NSAttributedString(string: text, attributes: [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
        .foregroundColor: color
    ])
    let size = s.size()
    s.draw(at: NSPoint(x: center.x - size.width / 2, y: center.y))
}

drawIcon(256, center: NSPoint(x: light.midX, y: light.maxY - 190))
drawIcon(256, center: NSPoint(x: dark.midX, y: dark.maxY - 190))

let sizes: [CGFloat] = [128, 64, 32]
for (i, s) in sizes.enumerated() {
    let xLight = light.minX + 100 + CGFloat(i) * 170
    let xDark = dark.minX + 100 + CGFloat(i) * 170
    let y = light.minY + 170
    drawIcon(s, center: NSPoint(x: xLight, y: y))
    drawIcon(s, center: NSPoint(x: xDark, y: y))
    label("\(Int(s)) px", center: NSPoint(x: xLight, y: light.minY + 96), color: hex(0x6E6A63))
    label("\(Int(s)) px", center: NSPoint(x: xDark, y: dark.minY + 96), color: hex(0xB8B4AC))
}

label("浅色背景", center: NSPoint(x: light.midX, y: light.minY + 34), color: hex(0x6E6A63))
label("深色背景", center: NSPoint(x: dark.midX, y: dark.minY + 34), color: hex(0xB8B4AC))

let footer = NSAttributedString(string: "手遮眼 · 应用图标（Finder / 应用程序文件夹）", attributes: [
    .font: NSFont.systemFont(ofSize: 12, weight: .regular),
    .foregroundColor: hex(0x8A857C)
])
footer.draw(at: NSPoint(x: 40, y: 40))

NSGraphicsContext.restoreGraphicsState()
let out = "/tmp/blanktop-icon-preview.png"
if let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: out))
    print("wrote \(out)")
}
