//
//  noline.swift
//  留白 v1.1 · 不要粗线稿的版本
//
//  同一组“小猫被子 / 拨杆盒子”，换成三种处理：
//  C1 剪影（无描边） / C2 无描边填色 / C3 细线
//
//  运行：
//    swiftc -O dev/noline.swift -framework AppKit -o /tmp/noline && /tmp/noline
//

import AppKit

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
            green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255,
            alpha: a)
}

let ink = hex(0x262626)
let cream = hex(0xF6E9D2)
let creamDeep = hex(0xEAD5B0)
let pillow = hex(0xEFDFC0)
let bed = hex(0xC9B28A)
let green = hex(0xA9CE8A)
let greenDeep = hex(0x6FA34C)
let orange = hex(0xE8A15C)
let pink = hex(0xE8A39E)
let beige = hex(0xE8D8B0)
let textMain = hex(0x1B1B1B)
let textSub = hex(0x6E6A63)
let darkBar = hex(0x1E1E20)
let brown = hex(0xB98554)
let brownDark = hex(0x8E5F37)
let metal = hex(0xC9BFAE)

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
    let s = rect.width / 22
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.minY)
    ctx.scaleBy(x: s, y: s)
    body()
    ctx.restoreGState()
}

func withShadow(_ body: () -> Void) {
    let sh = NSShadow()
    sh.shadowColor = NSColor.black.withAlphaComponent(0.18)
    sh.shadowBlurRadius = 1.2
    sh.shadowOffset = NSSize(width: 0, height: -0.5)
    NSGraphicsContext.saveGraphicsState()
    sh.set()
    body()
    NSGraphicsContext.restoreGraphicsState()
}

enum Treat {
    case silhouette
    case flat
    case thin
}

func paint(_ p: NSBezierPath, _ color: NSColor, _ t: Treat, lineWidth: CGFloat = 1.2) {
    if t == .silhouette {
        fill(p, color)
    } else if t == .flat {
        fill(p, color)
    } else {
        fill(p, color)
        stroke(p, ink, 0.6)
    }
}

// MARK: - 小猫被子（N2 竖着坐，无粗线）

func catHeadNoLine(_ t: Treat, cx: CGFloat, baseY: CGFloat, awake: Bool) {
    let headFill: NSColor = t == .silhouette ? ink : cream
    let eyeColor: NSColor = t == .silhouette ? cream : ink
    let lineColor: NSColor = t == .silhouette ? cream : ink

    // 耳朵
    let earL = poly([
        NSPoint(x: cx - 3.4, y: baseY + 4.2),
        NSPoint(x: cx - 2.4, y: baseY + 7.6),
        NSPoint(x: cx - 0.7, y: baseY + 4.8)
    ])
    let earR = poly([
        NSPoint(x: cx + 0.7, y: baseY + 4.8),
        NSPoint(x: cx + 2.4, y: baseY + 7.6),
        NSPoint(x: cx + 3.4, y: baseY + 4.2)
    ])
    paint(earL, headFill, t, lineWidth: 1.1)
    paint(earR, headFill, t, lineWidth: 1.1)
    // 内耳粉色（剪影下也保留）
    fill(poly([
        NSPoint(x: cx - 2.7, y: baseY + 4.8),
        NSPoint(x: cx - 2.2, y: baseY + 6.4),
        NSPoint(x: cx - 1.2, y: baseY + 5.0)
    ]), pink)
    fill(poly([
        NSPoint(x: cx + 1.2, y: baseY + 5.0),
        NSPoint(x: cx + 2.2, y: baseY + 6.4),
        NSPoint(x: cx + 2.7, y: baseY + 4.8)
    ]), pink)

    // 头
    let head = rr(cx - 3.6, baseY, 7.2, 5.2, 2.4)
    paint(head, headFill, t, lineWidth: 1.2)

    // 眼睛
    if awake {
        fill(NSBezierPath(ovalIn: NSRect(x: cx - 1.9, y: baseY + 2.7, width: 0.9, height: 0.95)), eyeColor)
        fill(NSBezierPath(ovalIn: NSRect(x: cx + 1.0, y: baseY + 2.7, width: 0.9, height: 0.95)), eyeColor)
    } else {
        line(cx - 2.2, baseY + 3.1, cx - 0.9, baseY + 3.1, eyeColor, 1.0)
        line(cx + 0.9, baseY + 3.1, cx + 2.2, baseY + 3.1, eyeColor, 1.0)
    }

    // 鼻子 + 嘴
    let nose = NSBezierPath(ovalIn: NSRect(x: cx - 0.7, y: baseY + 1.5, width: 1.4, height: 1.1))
    fill(nose, pink)
    if t == .thin { stroke(nose, ink, 0.5) }
    fill(NSBezierPath(ovalIn: NSRect(x: cx - 0.2, y: baseY + 1.85, width: 0.4, height: 0.38)), lineColor)
    line(cx, baseY + 1.5, cx, baseY + 1.2, lineColor, 0.7)
    line(cx, baseY + 1.2, cx - 0.4, baseY + 1.0, lineColor, 0.7)
    line(cx, baseY + 1.2, cx + 0.4, baseY + 1.0, lineColor, 0.7)

    // 胡须
    for y in [baseY + 1.9, baseY + 1.4] {
        line(cx - 3.6, y, cx - 4.6, y + 0.15, lineColor.withAlphaComponent(0.45), 0.45)
        line(cx + 3.6, y, cx + 4.6, y + 0.15, lineColor.withAlphaComponent(0.45), 0.45)
    }
}

func catBlanketNoLine(_ t: Treat, state: CatState, headBase: CGFloat, rollY: CGFloat) {
    let bodyTop = rollY
    let blanket = rr(4.8, 3.2, 12.4, bodyTop - 3.2 + 1.9, 2.8)
    paint(blanket, green, t, lineWidth: 1.2)
    line(5.6, bodyTop - 0.4, 16.4, bodyTop - 0.4, greenDeep.withAlphaComponent(0.65), 0.4)

    let roll = rr(4.4, bodyTop, 13.2, 2.0, 1.0)
    paint(roll, green, t, lineWidth: 1.1)
    let c = NSPoint(x: 15.9, y: bodyTop + 1.0)
    stroke(NSBezierPath(ovalIn: NSRect(x: c.x - 0.4, y: c.y - 0.4, width: 0.8, height: 0.8)),
           greenDeep, 0.5)

    if state != .sleep {
        let chest = rr(6.0, rollY, 10.0, headBase - rollY + 0.6, 2.0)
        paint(chest, creamDeep, t, lineWidth: 1.0)
        for x in [7.8, 9.6, 11.4, 13.2] {
            line(x, headBase - 0.5, x + 0.6, rollY + 0.4, orange, 1.0)
        }
    }

    // 爪子
    if state == .sleep {
        let p1 = rr(6.4, 10.8, 2.2, 1.4, 0.7)
        let p2 = rr(13.4, 10.8, 2.2, 1.4, 0.7)
        paint(p1, cream, t, lineWidth: 0.7)
        paint(p2, cream, t, lineWidth: 0.7)
    } else {
        let paw = rr(14.6, bodyTop + 0.9, 2.2, 1.8, 0.9)
        paint(paw, cream, t, lineWidth: 0.7)
        for dx in [0.0, 0.7] {
            fill(NSBezierPath(ovalIn: NSRect(x: 14.9 + dx, y: bodyTop + 1.95,
                                             width: 0.36, height: 0.32)), pink)
        }
    }
}

func drawCatNoLine(_ t: Treat, _ state: CatState) {
    let headBase: CGFloat = state == .sleep ? 11.0 : 11.6
    let rollY: CGFloat = state == .sleep ? 10.7 : (state == .pull ? 8.6 : 6.4)

    // 床 + 枕头
    withShadow {
        let base = rr(3.2, 2.8, 15.4, 3.2, 1.2)
        paint(base, bed, t, lineWidth: 1.1)
    }
    let pillowRect = rr(4.6, 4.0, 4.0, 3.0, 1.2)
    paint(pillowRect, pillow, t, lineWidth: 0.9)

    catBlanketNoLine(t, state: state, headBase: headBase, rollY: rollY)
    catHeadNoLine(t, cx: 11.0, baseY: headBase, awake: state != .sleep)
}

// MARK: - 拨杆盒子（无粗线）

func drawLeverNoLine(_ t: Treat, _ state: CatState) {
    let body = rr(3.0, 2.8, 14.0, 10.4, 1.6)
    if t == .silhouette {
        fill(body, ink)
    } else {
        withShadow { paint(body, brown, t, lineWidth: 1.2) }
    }

    // 盖子：剪影里用一条米色缝；无描边用深棕
    if t == .silhouette {
        line(3.6, 11.8, 16.4, 11.8, cream.withAlphaComponent(0.75), 0.8)
    } else if t == .flat {
        fill(rr(4.0, 11.4, 12.0, 1.2, 0.5), brownDark)
    } else {
        line(3.6, 11.8, 16.4, 11.8, ink, 0.6)
    }

    // 底座
    let base = rr(7.0, 4.3, 6.0, 2.2, 1.0)
    if t == .silhouette {
        fill(base, cream)
    } else {
        paint(base, metal, t, lineWidth: 0.6)
    }
    fill(NSBezierPath(ovalIn: NSRect(x: 7.7, y: 4.9, width: 0.8, height: 0.8)),
         state == .off ? grayDot : green)

    // 拨杆
    let pivot = NSPoint(x: 10.0, y: 5.7)
    let degrees: CGFloat = state == .off ? -42 : (state == .on ? 42 : 0)
    let radians = degrees * .pi / 180
    let length: CGFloat = 4.6
    let tip = NSPoint(x: pivot.x + sin(radians) * length,
                      y: pivot.y + cos(radians) * length)
    let stickColor = t == .silhouette ? cream : ink
    line(pivot.x, pivot.y, tip.x, tip.y, stickColor, 1.7)
    fill(NSBezierPath(ovalIn: NSRect(x: pivot.x - 0.55, y: pivot.y - 0.55, width: 1.1, height: 1.1)),
         stickColor)

    let ball = NSBezierPath(ovalIn: NSRect(x: tip.x - 1.35, y: tip.y - 1.35, width: 2.7, height: 2.7))
    fill(ball, state == .off ? (t == .silhouette ? cream : metal) : green)
    if t == .thin { stroke(ball, ink, 0.6) }

    // 小手
    if state == .pressing {
        drawPawNoLine(t, at: NSPoint(x: tip.x + 1.1, y: tip.y + 0.2))
    }
}

let grayDot = hex(0x8A857C)

func drawPawNoLine(_ t: Treat, at target: NSPoint) {
    let start = NSPoint(x: 15.8, y: 13.6)
    let arm = NSBezierPath()
    arm.move(to: start)
    arm.curve(to: NSPoint(x: target.x + 1.4, y: target.y + 1.3),
              controlPoint1: NSPoint(x: 15.6, y: 12.2),
              controlPoint2: NSPoint(x: target.x + 2.6, y: target.y + 3.0))
    stroke(arm, t == .silhouette ? cream : ink, t == .thin ? 0.8 : 1.6)
    if t != .silhouette {
        stroke(arm, cream, 1.0)
    }

    let paw = rr(target.x - 1.3, target.y - 1.1, 3.0, 2.4, 1.1)
    if t == .silhouette {
        fill(paw, cream)
    } else {
        paint(paw, cream, t, lineWidth: 0.7)
    }
    for dx in [-0.75, 0.0, 0.75] {
        fill(NSBezierPath(ovalIn: NSRect(x: target.x + dx - 0.28, y: target.y + 0.9,
                                         width: 0.56, height: 0.5)), pink)
    }
}

// MARK: - 输出

struct NoLineSpec {
    let id: String
    let name: String
    let subtitle: String
    let kind: String
    let treat: Treat
}

let specs: [NoLineSpec] = [
    NoLineSpec(id: "C1", name: "小猫被子 · 剪影", subtitle: "黑猫剪影 + 绿被子，没有描边", kind: "cat", treat: .silhouette),
    NoLineSpec(id: "C2", name: "小猫被子 · 无描边", subtitle: "奶油猫 + 绿被子，靠颜色分开", kind: "cat", treat: .flat),
    NoLineSpec(id: "C3", name: "小猫被子 · 细线", subtitle: "线还在，但只有 0.6pt", kind: "cat", treat: .thin),
    NoLineSpec(id: "V1", name: "拨杆盒子 · 剪影", subtitle: "黑盒子 + 奶油拨杆，没有描边", kind: "lever", treat: .silhouette),
    NoLineSpec(id: "V2", name: "拨杆盒子 · 无描边", subtitle: "棕色盒子 + 金属拨杆，靠颜色分开", kind: "lever", treat: .flat),
    NoLineSpec(id: "V3", name: "拨杆盒子 · 细线", subtitle: "线还在，但只有 0.6pt", kind: "lever", treat: .thin)
]

let scale: CGFloat = 2

func render(_ spec: NoLineSpec) {
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

    NSAttributedString(string: "\(spec.id) · \(spec.name)", attributes: [
        .font: NSFont.systemFont(ofSize: 13.5, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 16, y: h - 28))

    NSAttributedString(string: spec.subtitle, attributes: [
        .font: NSFont.systemFont(ofSize: 8.5, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 16, y: h - 42))

    let size: CGFloat = 96
    let states: [(String, CatState)] = [("关", .sleep), ("开", .awake), ("小手", .pressing)]
    for (i, item) in states.enumerated() {
        let x = 42 + CGFloat(i) * (size + 24)
        let y: CGFloat = 80
        let bg = rr(x, y, size, size, 14)
        fill(bg, pillow.withAlphaComponent(0.85))
        if spec.kind == "cat" {
            canvas(in: NSRect(x: x + 8, y: y + 8, width: size - 16, height: size - 16)) {
                drawCatNoLine(spec.treat, item.1)
            }
        } else {
            canvas(in: NSRect(x: x + 8, y: y + 8, width: size - 16, height: size - 16)) {
                drawLeverNoLine(spec.treat, item.1)
            }
        }
        let label = NSAttributedString(string: item.0, attributes: [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: textSub
        ])
        let ls = label.size()
        label.draw(at: NSPoint(x: x + (size - ls.width) / 2, y: y - 14))
    }

    let strip = NSRect(x: 16, y: 16, width: w - 32, height: 30)
    let half = strip.width / 2
    beige.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.minX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 8, yRadius: 8).fill()
    darkBar.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.midX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 8, yRadius: 8).fill()
    for (i, state) in [CatState.sleep, .awake, .pressing].enumerated() {
        canvas(in: NSRect(x: strip.minX + 22 + CGFloat(i) * 40, y: strip.midY - 9, width: 18, height: 18)) {
            if spec.kind == "cat" { drawCatNoLine(spec.treat, state) }
            else { drawLeverNoLine(spec.treat, state) }
        }
        canvas(in: NSRect(x: strip.midX + 22 + CGFloat(i) * 40, y: strip.midY - 9, width: 18, height: 18)) {
            if spec.kind == "cat" { drawCatNoLine(spec.treat, state) }
            else { drawLeverNoLine(spec.treat, state) }
        }
    }

    NSAttributedString(string: "实际大小 18pt · 左浅 / 右深", attributes: [
        .font: NSFont.systemFont(ofSize: 8, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 16, y: 2))

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "/tmp/noline-\(spec.id).png"))
        print("wrote /tmp/noline-\(spec.id).png")
    }
}

for spec in specs { render(spec) }
