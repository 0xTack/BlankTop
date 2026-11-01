//
//  boxstyles.swift
//  留白 v1.1 · 盒子的不同图标风格
//
//  不是再画细节，而是先定“风格方向”：
//  实心剪影 / 双色 / 单线 / 绿胶带 / 几何色块 / 徽章 / 贴纸 / 状态点。
//
//  运行：
//    swiftc -O dev/boxstyles.swift -framework AppKit -o /tmp/boxstyles && /tmp/boxstyles
//

import AppKit

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
            green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255,
            alpha: a)
}

var ink = hex(0x242424)
let whiteInk = hex(0xF7F2E6)
let green = hex(0xA9CE8A)
let greenDeep = hex(0x6FA34C)
let beige = hex(0xE8D8B0)
let beigeLight = hex(0xF2E4C4)
let brown = hex(0xB98554)
let brownDark = hex(0x8E5F37)
let darkBar = hex(0x1E1E20)
let textMain = hex(0x1B1B1B)
let textSub = hex(0x6E6A63)

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

func stroke(_ p: NSBezierPath, _ color: NSColor? = nil, _ width: CGFloat = 1.3) {
    (color ?? ink).setStroke()
    p.lineWidth = width
    p.lineCapStyle = .round
    p.lineJoinStyle = .round
    p.stroke()
}

func fill(_ p: NSBezierPath, _ color: NSColor) {
    color.setFill()
    p.fill()
}

func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
          _ color: NSColor? = nil, _ width: CGFloat = 1.0) {
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

// MARK: - 共用零件

func catEars(baseY: CGFloat, width: CGFloat = 1.0, fillColor: NSColor? = nil) {
    let left = poly([
        NSPoint(x: 7.2, y: baseY),
        NSPoint(x: 7.9, y: baseY + 2.6 * width),
        NSPoint(x: 9.2, y: baseY + 0.5)
    ])
    let right = poly([
        NSPoint(x: 10.8, y: baseY + 0.5),
        NSPoint(x: 12.1, y: baseY + 2.6 * width),
        NSPoint(x: 12.8, y: baseY)
    ])
    if let fillColor {
        fill(left, fillColor); fill(right, fillColor)
    } else {
        stroke(left, nil, 1.2); stroke(right, nil, 1.2)
    }
}

func catDots(baseY: CGFloat) {
    fill(NSBezierPath(ovalIn: NSRect(x: 8.3, y: baseY + 1.0, width: 0.9, height: 0.9)), ink)
    fill(NSBezierPath(ovalIn: NSRect(x: 10.8, y: baseY + 1.0, width: 0.9, height: 0.9)), ink)
    let nose = NSBezierPath(ovalIn: NSRect(x: 9.35, y: baseY + 0.35, width: 1.3, height: 1.0))
    stroke(nose, nil, 0.8)
}

// MARK: - 风格

/// F1 实心剪影：黑盒子 + 黑猫剪影，绿色只做“开”
func styleFilled(open: Bool) {
    if open {
        fill(rr(3.8, 3.2, 12.4, 8.4, 1.2), ink)
        fill(rr(4.8, 10.4, 10.4, 2.0, 0.7), green)
        // 猫剪影
        fill(rr(6.8, 12.4, 6.4, 4.6, 2.1), ink)
        catEars(baseY: 15.8, fillColor: ink)
        fill(NSBezierPath(ovalIn: NSRect(x: 8.3, y: 14.4, width: 0.9, height: 0.9)), green)
        fill(NSBezierPath(ovalIn: NSRect(x: 10.8, y: 14.4, width: 0.9, height: 0.9)), green)
        fill(NSBezierPath(ovalIn: NSRect(x: 9.6, y: 13.6, width: 0.8, height: 0.6)), green)
        // 箱子高光缝
        line(4.4, 11.4, 15.6, 11.4, greenDeep, 0.7)
    } else {
        fill(rr(3.8, 3.2, 12.4, 9.6, 1.2), ink)
        fill(rr(9.1, 3.2, 1.8, 9.6, 0.4), beige)
        fill(NSBezierPath(ovalIn: NSRect(x: 13.4, y: 5.0, width: 1.4, height: 1.4)), green)
        line(4.4, 10.8, 15.6, 10.8, hex(0x4A4A4A), 0.7)
        catEars(baseY: 12.8, fillColor: ink)
    }
}

/// F2 双色：黑盒子 + 绿盖
func styleTwoTone(open: Bool) {
    if open {
        fill(rr(3.8, 3.2, 12.4, 8.4, 1.2), ink)
        fill(rr(4.8, 10.4, 10.4, 2.0, 0.7), green)
        fill(rr(6.8, 12.4, 6.4, 4.6, 2.1), ink)
        catEars(baseY: 15.8, fillColor: ink)
        fill(NSBezierPath(ovalIn: NSRect(x: 8.3, y: 14.4, width: 0.9, height: 0.9)), green)
        fill(NSBezierPath(ovalIn: NSRect(x: 10.8, y: 14.4, width: 0.9, height: 0.9)), green)
    } else {
        fill(rr(3.8, 3.2, 12.4, 8.0, 1.2), ink)
        fill(rr(3.8, 11.2, 12.4, 2.2, 1.1), green)
        catEars(baseY: 12.8, fillColor: ink)
    }
}

/// F3 单线极简：只有线，没有填色
func styleSingleLine(open: Bool) {
    let body = rr(3.8, 3.2, 12.4, 8.8, 1.1)
    stroke(body, nil, 1.4)
    line(10, 3.4, 10, 11.8, ink.withAlphaComponent(0.35), 0.8)

    if open {
        // 掀起的盖：一条斜线
        line(3.6, 13.4, 14.2, 11.2, nil, 1.4)
        let inner = rr(4.8, 10.8, 10.4, 1.4, 0.5)
        stroke(inner, greenDeep, 1.3)
        catEars(baseY: 13.0, width: 0.9)
        catDots(baseY: 12.4)
    } else {
        // 盖线 + 露出的耳朵
        line(3.6, 11.6, 16.4, 11.6, nil, 1.3)
        catEars(baseY: 12.4, width: 0.9)
        line(8.4, 10.2, 9.3, 10.2, ink, 0.9)
        line(10.7, 10.2, 11.6, 10.2, ink, 0.9)
    }
}

/// F4 绿胶带：线稿盒子 + 一条绿色胶带
func styleGreenTape(open: Bool) {
    let body = rr(3.8, 3.2, 12.4, 8.8, 1.1)
    stroke(body, nil, 1.3)
    // 胶带
    fill(rr(8.9, 3.2, 2.2, 8.8, 0.3), green)
    stroke(rr(8.9, 3.2, 2.2, 8.8, 0.3), nil, 0.9)
    line(10.0, 3.4, 10.0, 11.8, greenDeep.withAlphaComponent(0.5), 0.6)

    if open {
        line(3.6, 13.4, 14.2, 11.2, nil, 1.3)
        let inner = rr(4.8, 10.8, 10.4, 1.4, 0.5)
        fill(inner, green)
        stroke(inner, nil, 0.8)
        catEars(baseY: 13.0, width: 0.9)
        catDots(baseY: 12.4)
    } else {
        line(3.6, 11.6, 16.4, 11.6, nil, 1.2)
        catEars(baseY: 12.4, width: 0.9)
        line(7.2, 10.0, 8.1, 10.0, ink, 0.9)
        line(11.9, 10.0, 12.8, 10.0, ink, 0.9)
    }
}

/// F5 几何色块：没有线，只有三块颜色
func styleGeometric(open: Bool) {
    let front = NSBezierPath(rect: NSRect(x: 3.8, y: 3.2, width: 10.2, height: 8.8))
    let side = poly([
        NSPoint(x: 14.0, y: 4.2), NSPoint(x: 16.8, y: 5.6),
        NSPoint(x: 16.8, y: 12.4), NSPoint(x: 14.0, y: 11.0)
    ])
    let top = poly([
        NSPoint(x: 3.8, y: 12.0), NSPoint(x: 14.0, y: 12.0),
        NSPoint(x: 16.8, y: 13.4), NSPoint(x: 6.6, y: 13.4)
    ])

    fill(side, brownDark)
    if open {
        fill(top, hex(0x4E7A36))
        fill(NSBezierPath(rect: NSRect(x: 4.8, y: 10.8, width: 9.2, height: 1.5)), greenDeep)
        fill(front, brown)
        // 猫头色块
        fill(rr(6.8, 12.8, 6.4, 4.4, 2.1), beigeLight)
        catEars(baseY: 16.0, fillColor: beigeLight)
        fill(NSBezierPath(ovalIn: NSRect(x: 8.3, y: 14.6, width: 0.9, height: 0.9)), ink)
        fill(NSBezierPath(ovalIn: NSRect(x: 10.8, y: 14.6, width: 0.9, height: 0.9)), ink)
        fill(NSBezierPath(ovalIn: NSRect(x: 9.55, y: 13.8, width: 0.9, height: 0.7)), brown)
    } else {
        fill(top, green)
        fill(front, brown)
        line(3.8, 11.2, 14.0, 11.2, hex(0x8A5F36), 0.8)
        catEars(baseY: 13.0, fillColor: beigeLight)
        fill(rr(9.3, 4.2, 1.4, 7.2, 0.2), beigeLight) // 胶带
    }
}

/// F7 徽章：黑底 + 负空间
func styleBadge(open: Bool) {
    let badge = rr(2.4, 2.4, 15.2, 15.2, 4.2)
    fill(badge, ink)

    // 负空间盒子
    let w = hex(0xF7F2E6)
    if open {
        let box = rr(5.0, 4.4, 10.0, 6.4, 0.8)
        stroke(box, w, 1.4)
        fill(rr(6.0, 9.8, 8.0, 1.2, 0.4), green)
        catEars(baseY: 12.4, width: 0.8)
        // 白色猫头
        fill(rr(7.0, 11.6, 6.0, 4.0, 1.9), w)
        fill(NSBezierPath(ovalIn: NSRect(x: 8.4, y: 13.4, width: 0.8, height: 0.8)), ink)
        fill(NSBezierPath(ovalIn: NSRect(x: 10.8, y: 13.4, width: 0.8, height: 0.8)), ink)
    } else {
        let box = rr(5.0, 4.8, 10.0, 7.0, 0.8)
        stroke(box, w, 1.4)
        line(10, 5.0, 10, 11.6, w, 1.0)
        catEars(baseY: 12.0, width: 0.8)
    }
}

/// F8 贴纸：厚白边 + 柔和阴影
func styleSticker(open: Bool) {
    // 阴影
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowBlurRadius = 1.2
    shadow.shadowOffset = NSSize(width: 0, height: -0.6)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()

    let bodyPath = rr(3.8, 3.2, 12.4, 8.8, 1.2)
    let border = bodyPath.copy() as! NSBezierPath
    border.lineWidth = 3.0
    stroke(border, hex(0xFFFDF7), 3.0)
    fill(bodyPath, beige)
    stroke(bodyPath, hex(0x3A2A1A, 0.8), 1.0)

    NSGraphicsContext.restoreGraphicsState()

    if open {
        fill(rr(4.8, 10.8, 10.4, 1.5, 0.5), green)
        stroke(rr(4.8, 10.8, 10.4, 1.5, 0.5), hex(0x3A2A1A, 0.7), 0.7)
        // 猫头
        fill(rr(6.9, 12.6, 6.2, 4.4, 2.0), beigeLight)
        stroke(rr(6.9, 12.6, 6.2, 4.4, 2.0), hex(0x3A2A1A, 0.85), 0.8)
        catEars(baseY: 16.2, fillColor: beigeLight)
        fill(NSBezierPath(ovalIn: NSRect(x: 8.4, y: 14.5, width: 0.8, height: 0.8)), ink)
        fill(NSBezierPath(ovalIn: NSRect(x: 10.8, y: 14.5, width: 0.8, height: 0.8)), ink)
    } else {
        fill(rr(3.8, 11.2, 12.4, 2.0, 0.8), green)
        stroke(rr(3.8, 11.2, 12.4, 2.0, 0.8), hex(0x3A2A1A, 0.7), 0.7)
        catEars(baseY: 13.0, fillColor: beigeLight)
    }
}

/// F9 状态点：最像系统工具图标
func styleStatusDot(open: Bool) {
    let body = rr(3.8, 3.2, 12.4, 8.8, 1.1)
    stroke(body, nil, 1.35)
    line(10, 3.4, 10, 11.8, ink.withAlphaComponent(0.3), 0.8)

    if open {
        line(3.6, 13.4, 14.2, 11.2, nil, 1.35)
        fill(rr(4.8, 10.8, 10.4, 1.4, 0.5), green)
        stroke(rr(4.8, 10.8, 10.4, 1.4, 0.5), nil, 0.8)
    } else {
        line(3.6, 11.6, 16.4, 11.6, nil, 1.25)
    }

    // 两颗小耳朵，保留“猫盒子”的暗示
    catEars(baseY: open ? 13.0 : 12.4, width: 0.85)

    // 状态点
    let dot = NSBezierPath(ovalIn: NSRect(x: 13.2, y: 4.4, width: 1.8, height: 1.8))
    if open {
        fill(dot, green)
        stroke(dot, greenDeep, 0.6)
    } else {
        fill(dot, ink.withAlphaComponent(0.18))
        stroke(dot, ink.withAlphaComponent(0.45), 0.6)
    }
}

// MARK: - 输出

struct Style {
    let id: String
    let name: String
    let subtitle: String
    let draw: (Bool) -> Void
}

let styles: [Style] = [
    Style(id: "S1", name: "实心剪影", subtitle: "整块黑盒子 + 黑猫，绿色只提示“开”",
          draw: { styleFilled(open: $0) }),
    Style(id: "S2", name: "双色", subtitle: "黑盒子 + 绿盖，最简洁的色块对比",
          draw: { styleTwoTone(open: $0) }),
    Style(id: "S3", name: "单线极简", subtitle: "只有线条，没有填色，最像系统菜单栏图标",
          draw: { styleSingleLine(open: $0) }),
    Style(id: "S4", name: "绿胶带", subtitle: "线稿盒子 + 一条绿胶带，一眼认出是纸箱",
          draw: { styleGreenTape(open: $0) }),
    Style(id: "S5", name: "几何色块", subtitle: "三块颜色拼成盒子，没有描边，偏现代",
          draw: { styleGeometric(open: $0) }),
    Style(id: "S6", name: "徽章", subtitle: "黑色圆角底 + 负空间盒子，最像 App 图标",
          draw: { styleBadge(open: $0) }),
    Style(id: "S7", name: "贴纸", subtitle: "厚白边 + 柔和阴影，像贴在菜单栏上的贴纸",
          draw: { styleSticker(open: $0) }),
    Style(id: "S8", name: "状态点", subtitle: "线稿盒子 + 一颗绿点，最像工具类图标",
          draw: { styleStatusDot(open: $0) })
]

let scale: CGFloat = 2

func renderTile(_ style: Style) {
    let w: CGFloat = 300, h: CGFloat = 280
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

    NSAttributedString(string: "\(style.id) · \(style.name)", attributes: [
        .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 16, y: h - 28))

    NSAttributedString(string: style.subtitle, attributes: [
        .font: NSFont.systemFont(ofSize: 8.5, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 16, y: h - 42))

    let size: CGFloat = 96
    for (i, open) in [false, true].enumerated() {
        let x = 42 + CGFloat(i) * (size + 24)
        let y: CGFloat = 82
        let bg = rr(x, y, size, size, 14)
        beigeLight.setFill()
        bg.fill()
        stroke(bg, ink.withAlphaComponent(0.08), 0.6)
        canvas(in: NSRect(x: x + 10, y: y + 10, width: size - 20, height: size - 20)) {
            style.draw(open)
        }
        let label = NSAttributedString(string: open ? "开" : "关", attributes: [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: textSub
        ])
        let ls = label.size()
        label.draw(at: NSPoint(x: x + (size - ls.width) / 2, y: y - 14))
    }

    // 实际大小
    let strip = NSRect(x: 16, y: 18, width: w - 32, height: 30)
    let half = strip.width / 2
    beige.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.minX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 8, yRadius: 8).fill()
    darkBar.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.midX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 8, yRadius: 8).fill()

    ink = hex(0x242424)
    canvas(in: NSRect(x: strip.minX + 26, y: strip.midY - 9, width: 18, height: 18)) { style.draw(false) }
    canvas(in: NSRect(x: strip.minX + 68, y: strip.midY - 9, width: 18, height: 18)) { style.draw(true) }

    ink = whiteInk
    canvas(in: NSRect(x: strip.midX + 26, y: strip.midY - 9, width: 18, height: 18)) { style.draw(false) }
    canvas(in: NSRect(x: strip.midX + 68, y: strip.midY - 9, width: 18, height: 18)) { style.draw(true) }
    ink = hex(0x242424)

    NSAttributedString(string: "实际大小 18pt · 浅 / 深", attributes: [
        .font: NSFont.systemFont(ofSize: 8, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 16, y: 4))

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        let path = "/tmp/style-\(style.id).png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("wrote \(path)")
    }
}

for style in styles { renderTile(style) }
