//
//  simple.swift
//  留白 v1.1 · 最简版
//
//  只留下四个最简单的选择：剪影猫 / 细线猫 / 猫头+被子线 / 拨杆盒子。
//  没有猫脸、没有颜色块、没有粗描边。
//
//  运行：
//    swiftc -O dev/simple.swift -framework AppKit -o /tmp/simple && /tmp/simple
//

import AppKit

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
            green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255,
            alpha: a)
}

let ink = hex(0x262626)
let white = hex(0xF7F2E6)
let green = hex(0xA9CE8A)
let greenDeep = hex(0x6FA34C)
let beige = hex(0xE8D8B0)
let beigeLight = hex(0xF2E4C4)
let textMain = hex(0x1B1B1B)
let textSub = hex(0x6E6A63)
let darkBar = hex(0x1E1E20)

func poly(_ pts: [NSPoint]) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: pts[0])
    for pt in pts.dropFirst() { p.line(to: pt) }
    p.close()
    return p
}

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

func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
          _ color: NSColor, _ width: CGFloat) {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: x1, y: y1))
    p.line(to: NSPoint(x: x2, y: y2))
    p.lineCapStyle = .round
    stroke(p, color, width)
}

func canvas(in rect: NSRect, _ body: () -> Void) {
    let ctx = NSGraphicsContext.current!.cgContext
    let s = rect.width / 20
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.minY)
    ctx.scaleBy(x: s, y: s)
    body()
    ctx.restoreGState()
}

// MARK: - 四个最简图标

/// 1：黑猫 + 绿被子（纯剪影，没有脸）
func simpleSilhouette(dark: Bool, open: Bool) {
    let cat = dark ? white : ink
    // 被子
    fill(rr(4.0, 3.0, 13.0, 6.2, 3.0), green)
    // 卷边
    let roll = NSBezierPath(ovalIn: NSRect(x: 14.4, y: 5.0, width: 2.8, height: 2.8))
    fill(roll, green)
    stroke(roll, dark ? white.withAlphaComponent(0.7) : greenDeep, 0.55)

    // 猫头 + 耳朵（剪影）
    fill(NSBezierPath(ovalIn: NSRect(x: 4.0, y: 6.8, width: 6.2, height: 6.2)), cat)
    fill(poly([
        NSPoint(x: 4.5, y: 12.0),
        NSPoint(x: 5.3, y: 15.4),
        NSPoint(x: 6.8, y: 12.6)
    ]), cat)
    fill(poly([
        NSPoint(x: 7.4, y: 12.6),
        NSPoint(x: 8.9, y: 15.4),
        NSPoint(x: 9.7, y: 12.0)
    ]), cat)

    if open {
        // 掀开：猫头抬高一点，被子退到腰
        fill(rr(4.0, 3.0, 13.0, 1.6, 0.8), green)
        fill(NSBezierPath(ovalIn: NSRect(x: 5.0, y: 4.4, width: 2.2, height: 2.2)), cat)
    }
}

/// 2：细线版（0.8pt，没有粗描边）
func simpleThin(dark: Bool, open: Bool) {
    let c = dark ? white : ink
    let blanket = rr(4.0, 3.0, 13.0, 6.2, 3.0)
    stroke(blanket, c, 0.8)
    let roll = NSBezierPath(ovalIn: NSRect(x: 14.4, y: 5.0, width: 2.8, height: 2.8))
    stroke(roll, c, 0.8)

    let head = NSBezierPath(ovalIn: NSRect(x: 4.0, y: 6.8, width: 6.2, height: 6.2))
    stroke(head, c, 0.8)
    stroke(poly([
        NSPoint(x: 4.5, y: 12.0),
        NSPoint(x: 5.3, y: 15.4),
        NSPoint(x: 6.8, y: 12.6)
    ]), c, 0.8)
    stroke(poly([
        NSPoint(x: 7.4, y: 12.6),
        NSPoint(x: 8.9, y: 15.4),
        NSPoint(x: 9.7, y: 12.0)
    ]), c, 0.8)

    // 闭眼两小段
    line(5.2, 9.6, 6.4, 9.6, c, 0.7)
    line(7.6, 9.6, 8.8, 9.6, c, 0.7)

    if open {
        stroke(rr(4.0, 3.0, 13.0, 1.6, 0.8), c, 0.8)
        line(5.0, 7.6, 9.0, 7.6, c, 0.8)
    }
}

/// 3：猫头 + 一条被子线（最极简）
func simpleMinimal(dark: Bool, open: Bool) {
    let c = dark ? white : ink
    let blanketY: CGFloat = open ? 5.4 : 7.2

    // 被子线
    let blanket = NSBezierPath()
    blanket.move(to: NSPoint(x: 2.8, y: blanketY))
    blanket.curve(to: NSPoint(x: 17.2, y: blanketY),
                  controlPoint1: NSPoint(x: 6.0, y: blanketY + 2.2),
                  controlPoint2: NSPoint(x: 14.0, y: blanketY + 2.2))
    stroke(blanket, c, 1.0)

    // 卷边
    let roll = NSBezierPath(ovalIn: NSRect(x: 15.0, y: blanketY - 1.3, width: 2.2, height: 2.2))
    stroke(roll, c, 0.9)

    // 猫头
    let head = NSBezierPath(ovalIn: NSRect(x: 5.2, y: 8.4, width: 5.4, height: 5.0))
    stroke(head, c, 1.0)
    stroke(poly([
        NSPoint(x: 5.6, y: 12.6),
        NSPoint(x: 6.3, y: 15.4),
        NSPoint(x: 7.6, y: 13.0)
    ]), c, 0.9)
    stroke(poly([
        NSPoint(x: 8.2, y: 13.0),
        NSPoint(x: 9.5, y: 15.4),
        NSPoint(x: 10.2, y: 12.6)
    ]), c, 0.9)
    line(6.3, 10.9, 7.2, 10.9, c, 0.8)
    line(8.6, 10.9, 9.5, 10.9, c, 0.8)
}

/// 4：盒子 + 拨杆（最简）
func simpleLever(dark: Bool, open: Bool) {
    let c = dark ? white : ink
    stroke(rr(4.0, 3.5, 12.0, 12.0, 2.0), c, 1.1)
    // 底座
    line(8.0, 7.0, 12.0, 7.0, c, 1.0)
    // 拨杆
    let tip = open ? NSPoint(x: 12.4, y: 12.4) : NSPoint(x: 7.6, y: 12.4)
    line(10.0, 7.4, tip.x, tip.y, c, 1.1)
    let ball = NSBezierPath(ovalIn: NSRect(x: tip.x - 1.1, y: tip.y - 1.1,
                                           width: 2.2, height: 2.2))
    if open {
        fill(ball, green)
        stroke(ball, dark ? white.withAlphaComponent(0.7) : greenDeep, 0.55)
    } else {
        fill(ball, c)
    }
}

// MARK: - 输出

struct SimpleSpec {
    let id: String
    let name: String
    let subtitle: String
    let draw: (Bool, Bool) -> Void
}

let specs: [SimpleSpec] = [
    SimpleSpec(id: "1", name: "剪影猫 + 绿被子", subtitle: "只有两个形状：猫头剪影 + 被子块", draw: { simpleSilhouette(dark: $0, open: $1) }),
    SimpleSpec(id: "2", name: "细线猫 + 被子", subtitle: "0.8pt 细线，没有粗描边", draw: { simpleThin(dark: $0, open: $1) }),
    SimpleSpec(id: "3", name: "猫头 + 被子线", subtitle: "最极简：一个猫头 + 一条被子线", draw: { simpleMinimal(dark: $0, open: $1) }),
    SimpleSpec(id: "4", name: "盒子 + 拨杆", subtitle: "没有猫，只有盒子和小拨杆", draw: { simpleLever(dark: $0, open: $1) })
]

let scale: CGFloat = 2

func render(_ spec: SimpleSpec) {
    let w: CGFloat = 300, h: CGFloat = 260
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(w * scale), pixelsHigh: Int(h * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.cgContext.scaleBy(x: scale, y: scale)

    beige.setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()

    NSAttributedString(string: "\(spec.id) · \(spec.name)", attributes: [
        .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 16, y: h - 28))

    NSAttributedString(string: spec.subtitle, attributes: [
        .font: NSFont.systemFont(ofSize: 8.5, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 16, y: h - 42))

    let size: CGFloat = 92
    for (i, open) in [false, true].enumerated() {
        let x = 46 + CGFloat(i) * (size + 28)
        let y: CGFloat = 74
        let bg = rr(x, y, size, size, 14)
        beigeLight.setFill()
        bg.fill()
        canvas(in: NSRect(x: x + 8, y: y + 8, width: size - 16, height: size - 16)) {
            spec.draw(false, open)
        }
        let label = NSAttributedString(string: open ? "开" : "关", attributes: [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: textSub
        ])
        let ls = label.size()
        label.draw(at: NSPoint(x: x + (size - ls.width) / 2, y: y - 14))
    }

    // 实际大小
    let strip = NSRect(x: 16, y: 16, width: w - 32, height: 30)
    let half = strip.width / 2
    beige.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.minX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 8, yRadius: 8).fill()
    darkBar.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.midX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 8, yRadius: 8).fill()
    for (i, open) in [false, true].enumerated() {
        canvas(in: NSRect(x: strip.minX + 24 + CGFloat(i) * 42, y: strip.midY - 9, width: 18, height: 18)) {
            spec.draw(false, open)
        }
        canvas(in: NSRect(x: strip.midX + 24 + CGFloat(i) * 42, y: strip.midY - 9, width: 18, height: 18)) {
            spec.draw(true, open)
        }
    }

    NSAttributedString(string: "实际大小 18pt · 左浅 / 右深", attributes: [
        .font: NSFont.systemFont(ofSize: 8, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 16, y: 2))

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "/tmp/simple-\(spec.id).png"))
        print("wrote /tmp/simple-\(spec.id).png")
    }
}

for spec in specs { render(spec) }
