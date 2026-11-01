//
//  handeye.swift
//  留白 v1.1 · 手遮眼图标
//
//  参考图：一只手横在眼睛上方。菜单栏里简化为：黑手剪影 + 眼睛。
//  合上 = 手放下盖住眼；展开 = 手抬起，眼睛睁开。
//
//  运行：
//    swiftc -O dev/handeye.swift -framework AppKit -o /tmp/handeye && /tmp/handeye
//

import AppKit

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
            green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255,
            alpha: a)
}

let ink = hex(0x242424)
let white = hex(0xF7F2E6)
let beige = hex(0xE8D8B0)
let beigeLight = hex(0xF2E4C4)
let darkBar = hex(0x1E1E20)
let textMain = hex(0x1B1B1B)
let textSub = hex(0x6E6A63)

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

func canvas(in rect: NSRect, scaleTo: CGFloat = 20, _ body: () -> Void) {
    let ctx = NSGraphicsContext.current!.cgContext
    let s = rect.width / scaleTo
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.minY)
    ctx.scaleBy(x: s, y: s)
    body()
    ctx.restoreGState()
}

// MARK: - 手 + 眼

/// lift：手离眼睛的距离。0 = 手放下盖住眼；2.2 = 手抬起来。
func drawHand(lift: CGFloat, color: NSColor, filled: Bool) {
    // 三根手指
    let fingers: [(CGFloat, CGFloat, CGFloat)] = [
        (6.2, 2.6, 10.6),
        (8.0, 3.0, 10.2),
        (9.8, 3.4, 9.8)
    ]
    for (y, x, w) in fingers {
        let p = rr(x, y + lift, w, 1.7, 0.85)
        if filled { fill(p, color) } else { stroke(p, color, 1.0) }
    }

    // 手掌
    let palm = rr(11.2, 5.2 + lift, 6.0, 8.2, 2.6)
    if filled { fill(palm, color) } else { stroke(palm, color, 1.0) }

    // 手腕
    let wrist = rr(14.2, 2.8 + lift, 3.2, 4.2, 1.2)
    if filled { fill(wrist, color) } else { stroke(wrist, color, 1.0) }

    // 拇指
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.saveGState()
    ctx.translateBy(x: 14.6, y: 11.4 + lift)
    ctx.rotate(by: -32 * .pi / 180)
    let thumb = rr(-1.1, 0, 2.2, 4.2, 1.1)
    if filled { fill(thumb, color) } else { stroke(thumb, color, 1.0) }
    ctx.restoreGState()
}

func drawEye(open: Bool, color: NSColor) {
    if open {
        // 眼框
        let eye = NSBezierPath()
        eye.move(to: NSPoint(x: 2.8, y: 6.4))
        eye.curve(to: NSPoint(x: 12.4, y: 6.4),
                  controlPoint1: NSPoint(x: 5.6, y: 9.8),
                  controlPoint2: NSPoint(x: 9.6, y: 9.8))
        eye.curve(to: NSPoint(x: 2.8, y: 6.4),
                  controlPoint1: NSPoint(x: 9.6, y: 3.4),
                  controlPoint2: NSPoint(x: 5.6, y: 3.4))
        stroke(eye, color, 1.05)

        // 瞳孔
        fill(NSBezierPath(ovalIn: NSRect(x: 6.7, y: 5.1, width: 2.0, height: 2.0)), color)
    } else {
        // 闭眼线
        let closed = NSBezierPath()
        closed.move(to: NSPoint(x: 3.4, y: 5.7))
        closed.curve(to: NSPoint(x: 11.8, y: 5.7),
                     controlPoint1: NSPoint(x: 6.2, y: 4.2),
                     controlPoint2: NSPoint(x: 9.0, y: 4.2))
        stroke(closed, color, 1.0)
    }
}

func drawHandEye(state: Bool, dark: Bool, framed: Bool, filled: Bool) {
    let color = dark ? white : ink
    // state: true = 展开（手抬起、眼睁开）
    let lift: CGFloat = state ? 2.3 : 0.0

    if framed {
        let frame = rr(1.4, 1.4, 17.2, 17.2, 4.2)
        stroke(frame, color, 1.0)
    }

    let ctx = NSGraphicsContext.current!.cgContext
    ctx.saveGState()
    if framed {
        ctx.translateBy(x: 10, y: 10)
        ctx.scaleBy(x: 0.86, y: 0.86)
        ctx.translateBy(x: -10, y: -10)
    }

    if state {
        // 手抬起时眼睛完整
        drawEye(open: true, color: color)
    }
    drawHand(lift: lift, color: color, filled: filled)
    if !state {
        // 手放下时，眼睛只露一条闭眼线
        drawEye(open: false, color: color)
    }

    ctx.restoreGState()
}

// MARK: - 输出

struct Spec {
    let id: String
    let name: String
    let subtitle: String
    let framed: Bool
    let filled: Bool
}

let specs: [Spec] = [
    Spec(id: "H1", name: "剪影", subtitle: "黑手 + 眼睛，没有边框；18pt 最清楚", framed: false, filled: true),
    Spec(id: "H2", name: "剪影 + 边框", subtitle: "和参考图一样加圆角方框，会更重", framed: true, filled: true),
    Spec(id: "H3", name: "线稿", subtitle: "手指用线条画，更接近参考图，但 18pt 会细", framed: false, filled: false)
]

let scale: CGFloat = 2

func render(_ spec: Spec) {
    let w: CGFloat = 380, h: CGFloat = 280
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
        .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 18, y: h - 30))

    NSAttributedString(string: spec.subtitle, attributes: [
        .font: NSFont.systemFont(ofSize: 9, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 18, y: h - 46))

    let size: CGFloat = 104
    for (i, state) in [false, true].enumerated() {
        let x = 48 + CGFloat(i) * (size + 26)
        let y: CGFloat = 76
        let bg = rr(x, y, size, size, 15)
        beigeLight.setFill()
        bg.fill()
        canvas(in: NSRect(x: x + 10, y: y + 10, width: size - 20, height: size - 20)) {
            drawHandEye(state: state, dark: false, framed: spec.framed, filled: spec.filled)
        }
        let label = NSAttributedString(string: state ? "开" : "关", attributes: [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: textSub
        ])
        let ls = label.size()
        label.draw(at: NSPoint(x: x + (size - ls.width) / 2, y: y - 14))
    }

    // 实际大小
    let strip = NSRect(x: 18, y: 16, width: w - 36, height: 32)
    let half = strip.width / 2
    beige.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.minX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 8, yRadius: 8).fill()
    darkBar.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.midX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 8, yRadius: 8).fill()
    for (i, state) in [false, true].enumerated() {
        canvas(in: NSRect(x: strip.minX + 26 + CGFloat(i) * 44, y: strip.midY - 9, width: 18, height: 18)) {
            drawHandEye(state: state, dark: false, framed: spec.framed, filled: spec.filled)
        }
        canvas(in: NSRect(x: strip.midX + 26 + CGFloat(i) * 44, y: strip.midY - 9, width: 18, height: 18)) {
            drawHandEye(state: state, dark: true, framed: spec.framed, filled: spec.filled)
        }
    }

    NSAttributedString(string: "实际大小 18pt · 左浅 / 右深", attributes: [
        .font: NSFont.systemFont(ofSize: 8, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 18, y: 2))

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "/tmp/handeye-\(spec.id).png"))
        print("wrote /tmp/handeye-\(spec.id).png")
    }
}

for spec in specs { render(spec) }
