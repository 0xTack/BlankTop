//
//  linebox.swift
//  留白 v1.1 · 线稿风格盒子图标
//
//  参考：现有开关的粗黑描边 + 参考图里的猫头。
//  透明填充，只保留黑线 + 绿色；输出大图和实际 18pt 预览。
//
//  运行：
//    swiftc -O dev/linebox.swift -framework AppKit -o /tmp/linebox && /tmp/linebox
//

import AppKit

// MARK: - 基础

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
            green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255,
            alpha: a)
}

var ink = hex(0x262626)
var inkSoft: NSColor { ink.withAlphaComponent(0.55) }
let whiteInk = hex(0xF7F2E6)
let green = hex(0xA9CE8A)
let greenDeep = hex(0x7FB35F)
let beige = hex(0xE8D8B0)
let beigeLight = hex(0xF2E4C4)
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

func roundRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r)
}

func stroke(_ p: NSBezierPath, _ color: NSColor = ink, _ width: CGFloat = 1.25) {
    color.setStroke()
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
          _ color: NSColor = ink, _ width: CGFloat = 1.0) {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: x1, y: y1))
    p.line(to: NSPoint(x: x2, y: y2))
    p.lineCapStyle = .round
    stroke(p, color, width)
}

func iconCanvas(in rect: NSRect, _ body: () -> Void) {
    let ctx = NSGraphicsContext.current!.cgContext
    let s = rect.width / 20
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.minY)
    ctx.scaleBy(x: s, y: s)
    body()
    ctx.restoreGState()
}

// MARK: - 猫头

/// 参考图里的猫头：两只耳朵、点眼睛、圆鼻子、w 嘴。
func catHead(baseY: CGFloat, awake: Bool, scale s: CGFloat = 1.0) {
    // 耳朵
    let earL = poly([
        NSPoint(x: 7.0, y: baseY + 4.3 * s),
        NSPoint(x: 7.8, y: baseY + 7.2 * s),
        NSPoint(x: 9.2, y: baseY + 4.7 * s)
    ])
    let earR = poly([
        NSPoint(x: 10.8, y: baseY + 4.7 * s),
        NSPoint(x: 12.2, y: baseY + 7.2 * s),
        NSPoint(x: 13.0, y: baseY + 4.3 * s)
    ])
    stroke(earL, ink, 1.2 * s)
    stroke(earR, ink, 1.2 * s)

    // 头
    let head = roundRect(6.6, baseY, 6.8, 4.9 * s, 2.2)
    stroke(head, ink, 1.25 * s)

    // 眼睛
    if awake {
        fill(NSBezierPath(ovalIn: NSRect(x: 8.35, y: baseY + 2.75, width: 0.85, height: 0.85)), ink)
        fill(NSBezierPath(ovalIn: NSRect(x: 10.8, y: baseY + 2.75, width: 0.85, height: 0.85)), ink)
    } else {
        line(8.2, baseY + 3.15, 9.2, baseY + 3.15, ink, 1.0)
        line(10.8, baseY + 3.15, 11.8, baseY + 3.15, ink, 1.0)
    }

    // 鼻子 + 嘴
    let nose = NSBezierPath(ovalIn: NSRect(x: 9.15, y: baseY + 1.55, width: 1.7, height: 1.35))
    stroke(nose, ink, 0.95)
    fill(NSBezierPath(ovalIn: NSRect(x: 9.72, y: baseY + 1.95, width: 0.42, height: 0.42)), ink)
    line(10.0, baseY + 1.55, 10.0, baseY + 1.25, ink, 0.8)
    line(10.0, baseY + 1.25, 9.55, baseY + 1.05, ink, 0.8)
    line(10.0, baseY + 1.25, 10.45, baseY + 1.05, ink, 0.8)
}

// MARK: - 小开关

func miniToggle(on: Bool, cx: CGFloat, cy: CGFloat) {
    let w: CGFloat = 6.2, h: CGFloat = 3.3
    let track = roundRect(cx - w / 2, cy - h / 2, w, h, h / 2)
    if on {
        NSGraphicsContext.saveGraphicsState()
        track.addClip()
        fill(NSBezierPath(rect: NSRect(x: cx - w / 2, y: cy - h / 2, width: w / 2, height: h)), green)
        NSGraphicsContext.restoreGraphicsState()
    }
    stroke(track, ink, 1.25)
    let knob = h - 1.1
    let knobX = on ? cx + w / 2 - knob - 0.55 : cx - w / 2 + 0.55
    fill(NSBezierPath(ovalIn: NSRect(x: knobX, y: cy - knob / 2, width: knob, height: knob)), ink)
}

// MARK: - 箱子底稿

func boxBody(open: Bool, tape: Bool = true, label: Bool = true) {
    let body = roundRect(3.4, 3.0, 13.2, 8.8, 1.0)
    stroke(body, ink, 1.3)

    if tape {
        line(10.0, 3.2, 10.0, 11.8, ink, 1.0)
        line(9.3, 10.7, 10.7, 10.7, ink, 0.9)
    }

    if label {
        let l = roundRect(4.7, 4.6, 3.7, 2.3, 0.3)
        stroke(l, ink, 0.8)
        line(5.1, 6.2, 7.4, 6.2, inkSoft, 0.6)
        line(5.1, 5.65, 7.8, 5.65, inkSoft, 0.6)
        line(5.1, 5.1, 7.0, 5.1, inkSoft, 0.6)
    }

    if open {
        // 绿色内衬
        let inner = roundRect(4.3, 11.0, 11.4, 1.8, 0.7)
        fill(inner, green)
        stroke(inner, ink, 0.9)

        // 掀起的盖
        let lid = poly([
            NSPoint(x: 3.4, y: 11.8),
            NSPoint(x: 11.0, y: 11.8),
            NSPoint(x: 8.6, y: 15.6),
            NSPoint(x: 1.4, y: 14.2)
        ])
        stroke(lid, ink, 1.2)
        line(4.2, 13.2, 10.0, 12.7, inkSoft, 0.8)
    } else {
        // 盖着的盖
        let lid = roundRect(2.7, 11.6, 14.6, 2.3, 0.8)
        stroke(lid, ink, 1.25)
        line(3.4, 12.75, 16.6, 12.75, inkSoft, 0.7)
    }
}

/// 关着时只露耳朵
func earsOverLid() {
    let slit = NSBezierPath(ovalIn: NSRect(x: 8.2, y: 13.4, width: 3.6, height: 0.7))
    fill(slit, ink)
    let earL = poly([
        NSPoint(x: 7.7, y: 13.6),
        NSPoint(x: 8.4, y: 16.3),
        NSPoint(x: 9.5, y: 13.7)
    ])
    let earR = poly([
        NSPoint(x: 10.5, y: 13.7),
        NSPoint(x: 11.6, y: 16.3),
        NSPoint(x: 12.3, y: 13.6)
    ])
    stroke(earL, ink, 1.15)
    stroke(earR, ink, 1.15)
}

func linePaw(cx: CGFloat, cy: CGFloat) {
    let paw = roundRect(cx - 1.6, cy - 1.3, 3.2, 2.5, 1.2)
    stroke(paw, ink, 1.1)
    for dx in [-0.8, 0.0, 0.8] {
        line(cx + dx, cy - 1.25, cx + dx, cy - 0.35, inkSoft, 0.8)
    }
}

// MARK: - 三款

/// L1：纸箱 + 猫头
func l1(open: Bool) {
    boxBody(open: open)
    if open {
        catHead(baseY: 13.0, awake: true)
        linePaw(cx: 12.4, cy: 12.1)
    } else {
        earsOverLid()
    }
}

/// L2：纸箱 + 猫头 + 小开关
func l2(open: Bool) {
    boxBody(open: open, tape: false, label: false)
    miniToggle(on: open, cx: 10.0, cy: 6.6)
    if open {
        catHead(baseY: 13.0, awake: true)
        linePaw(cx: 12.4, cy: 12.1)
    } else {
        earsOverLid()
        // 关了也画两条睡眼，像在等
        line(7.0, 8.9, 8.0, 8.9, inkSoft, 0.8)
        line(9.2, 8.9, 10.2, 8.9, inkSoft, 0.8)
    }
}

/// L3：猫形盒子
func l3(open: Bool) {
    // 耳朵长在盒子上
    let earL = poly([
        NSPoint(x: 4.4, y: 11.8),
        NSPoint(x: 5.1, y: 15.2),
        NSPoint(x: 6.6, y: 12.4)
    ])
    let earR = poly([
        NSPoint(x: 13.4, y: 12.4),
        NSPoint(x: 14.9, y: 15.2),
        NSPoint(x: 15.6, y: 11.8)
    ])
    stroke(earL, ink, 1.25)
    stroke(earR, ink, 1.25)

    let body = roundRect(3.4, 2.9, 13.2, 9.3, 1.3)
    stroke(body, ink, 1.3)

    // 猫脸
    if open {
        fill(NSBezierPath(ovalIn: NSRect(x: 7.1, y: 8.0, width: 0.9, height: 0.9)), ink)
        fill(NSBezierPath(ovalIn: NSRect(x: 12.0, y: 8.0, width: 0.9, height: 0.9)), ink)
    } else {
        line(6.9, 8.4, 8.0, 8.4, ink, 1.0)
        line(12.0, 8.4, 13.1, 8.4, ink, 1.0)
    }
    let nose = NSBezierPath(ovalIn: NSRect(x: 9.15, y: 6.5, width: 1.7, height: 1.35))
    stroke(nose, ink, 0.95)
    fill(NSBezierPath(ovalIn: NSRect(x: 9.72, y: 6.9, width: 0.42, height: 0.42)), ink)
    line(10.0, 6.5, 10.0, 6.1, ink, 0.8)
    line(10.0, 6.1, 9.5, 5.9, ink, 0.8)
    line(10.0, 6.1, 10.5, 5.9, ink, 0.8)

    if open {
        let inner = roundRect(4.2, 10.8, 11.6, 1.5, 0.6)
        fill(inner, green)
        stroke(inner, ink, 0.9)
        let lid = poly([
            NSPoint(x: 3.4, y: 11.7),
            NSPoint(x: 11.2, y: 11.7),
            NSPoint(x: 8.8, y: 15.0),
            NSPoint(x: 1.6, y: 13.8)
        ])
        stroke(lid, ink, 1.2)
        linePaw(cx: 12.6, cy: 11.9)
    } else {
        let lid = roundRect(2.8, 11.5, 14.4, 2.2, 0.8)
        stroke(lid, ink, 1.2)
        line(3.5, 12.6, 16.5, 12.6, inkSoft, 0.7)
    }
}

// MARK: - 输出

let scale: CGFloat = 2

struct LineCandidate {
    let id: String
    let name: String
    let subtitle: String
    let draw: (Bool, NSRect) -> Void
}

let candidates: [LineCandidate] = [
    LineCandidate(id: "L1", name: "纸箱 + 猫头", subtitle: "关着只露耳朵，打开猫头冒出来",
                  draw: { open, rect in iconCanvas(in: rect) { l1(open: open) } }),
    LineCandidate(id: "L2", name: "纸箱 + 小开关", subtitle: "正面一个小开关，关/开一眼看出",
                  draw: { open, rect in iconCanvas(in: rect) { l2(open: open) } }),
    LineCandidate(id: "L3", name: "猫形盒子", subtitle: "耳朵长在盒子上，关着是睡眼，打开就醒",
                  draw: { open, rect in iconCanvas(in: rect) { l3(open: open) } })
]

func renderTile(_ candidate: LineCandidate) {
    let w: CGFloat = 380, h: CGFloat = 250
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

    NSAttributedString(string: "\(candidate.id) · \(candidate.name)", attributes: [
        .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 18, y: h - 30))

    NSAttributedString(string: candidate.subtitle, attributes: [
        .font: NSFont.systemFont(ofSize: 9, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 18, y: h - 46))

    let size: CGFloat = 116
    for (index, open) in [false, true].enumerated() {
        let x = 56 + CGFloat(index) * (size + 20)
        let y: CGFloat = 64
        let bg = roundRect(x, y, size, size, 16)
        beigeLight.setFill()
        bg.fill()
        stroke(bg, ink.withAlphaComponent(0.10), 0.6)
        candidate.draw(open, NSRect(x: x + 12, y: y + 12, width: size - 24, height: size - 24))

        let label = NSAttributedString(string: open ? "开" : "关", attributes: [
            .font: NSFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: textSub
        ])
        let ls = label.size()
        label.draw(at: NSPoint(x: x + (size - ls.width) / 2, y: y - 16))
    }

    let strip = NSRect(x: 18, y: 14, width: w - 36, height: 34)
    let half = strip.width / 2
    beige.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.minX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 9, yRadius: 9).fill()
    darkBar.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.midX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 9, yRadius: 9).fill()
    line(strip.midX, strip.minY + 2, strip.midX, strip.maxY - 2, NSColor(calibratedWhite: 0.5, alpha: 0.18), 0.8)

    for open in [false, true] {
        let i = open ? 1 : 0
        candidate.draw(open, NSRect(x: strip.minX + 24 + CGFloat(i) * 42,
                                    y: strip.midY - 9, width: 18, height: 18))
    }
    let savedInk = ink
    ink = whiteInk
    for open in [false, true] {
        let i = open ? 1 : 0
        candidate.draw(open, NSRect(x: strip.midX + 24 + CGFloat(i) * 42,
                                    y: strip.midY - 9, width: 18, height: 18))
    }
    ink = savedInk

    NSAttributedString(string: "实际大小 18pt · 左浅色 / 右深色", attributes: [
        .font: NSFont.systemFont(ofSize: 8, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 18, y: 2))

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        let path = "/tmp/linebox-\(candidate.id).png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("wrote \(path)")
    }
}

func renderAll() {
    let w: CGFloat = 1200, h: CGFloat = 520
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

    NSAttributedString(string: "留白 v1.1 · 线稿盒子候选", attributes: [
        .font: NSFont.systemFont(ofSize: 24, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 28, y: h - 42))

    let cardW: CGFloat = 360, cardH: CGFloat = 340
    for (index, candidate) in candidates.enumerated() {
        let x = 28 + CGFloat(index) * (cardW + 20)
        let y: CGFloat = 96
        let card = roundRect(x, y, cardW, cardH, 18)
        beigeLight.setFill()
        card.fill()
        stroke(card, ink.withAlphaComponent(0.10), 0.6)

        NSAttributedString(string: "\(candidate.id) · \(candidate.name)", attributes: [
            .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: x + 18, y: y + cardH - 30))

        NSAttributedString(string: candidate.subtitle, attributes: [
            .font: NSFont.systemFont(ofSize: 9.5, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: x + 18, y: y + cardH - 47))

        let size: CGFloat = 104
        for (i, open) in [false, true].enumerated() {
            let px = x + 24 + CGFloat(i) * (size + 12)
            let py = y + 110
            let bg = roundRect(px, py, size, size, 14)
            beige.setFill()
            bg.fill()
            candidate.draw(open, NSRect(x: px + 10, y: py + 10, width: size - 20, height: size - 20))
        }

        let strip = NSRect(x: x + 24, y: y + 22, width: cardW - 48, height: 34)
        let half = strip.width / 2
        beige.setFill()
        NSBezierPath(roundedRect: NSRect(x: strip.minX, y: strip.minY, width: half, height: strip.height),
                     xRadius: 9, yRadius: 9).fill()
        darkBar.setFill()
        NSBezierPath(roundedRect: NSRect(x: strip.midX, y: strip.minY, width: half, height: strip.height),
                     xRadius: 9, yRadius: 9).fill()
        candidate.draw(false, NSRect(x: strip.minX + 22, y: strip.midY - 9, width: 18, height: 18))
        candidate.draw(true, NSRect(x: strip.minX + 64, y: strip.midY - 9, width: 18, height: 18))
        let savedInk = ink
        ink = whiteInk
        candidate.draw(false, NSRect(x: strip.midX + 22, y: strip.midY - 9, width: 18, height: 18))
        candidate.draw(true, NSRect(x: strip.midX + 64, y: strip.midY - 9, width: 18, height: 18))
        ink = savedInk
    }

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "/tmp/linebox-all.png"))
        print("wrote /tmp/linebox-all.png")
    }
}

for candidate in candidates { renderTile(candidate) }
renderAll()
