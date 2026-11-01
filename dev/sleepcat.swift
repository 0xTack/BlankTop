//
//  sleepcat.swift
//  留白 v1.1 · 小猫盖被子
//
//  点击：被子卷起来（菜单栏展开）；10 秒后小猫伸手把被子拉回来（菜单栏合上）。
//  两种构图：横着睡 / 竖着坐起来。
//
//  运行：
//    swiftc -O dev/sleepcat.swift -framework AppKit -o /tmp/sleepcat && /tmp/sleepcat
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
let creamDeep = hex(0xEAD8BA)
let pillow = hex(0xF2E4C4)
let bed = hex(0xD9C39A)
let green = hex(0xA9CE8A)
let greenDeep = hex(0x6FA34C)
let orange = hex(0xE8A15C)
let pink = hex(0xE8A39E)
let beige = hex(0xE8D8B0)
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

func canvas(in rect: NSRect, _ body: () -> Void) {
    let ctx = NSGraphicsContext.current!.cgContext
    let s = rect.width / 22
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.minY)
    ctx.scaleBy(x: s, y: s)
    body()
    ctx.restoreGState()
}

// MARK: - 猫头

func catHead(centerX cx: CGFloat, baseY: CGFloat, width: CGFloat,
             awake: Bool, tilt: CGFloat = 0) {
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.saveGState()
    ctx.translateBy(x: cx, y: baseY)
    if tilt != 0 { ctx.rotate(by: tilt * .pi / 180) }
    ctx.translateBy(x: -cx, y: -baseY)

    let s = width / 6.4
    let head = rr(cx - width / 2, baseY, width, 5.0 * s, 2.3 * s)
    fill(head, cream)
    stroke(head, ink, 1.25 * s)

    // 耳朵
    let earL = poly([
        NSPoint(x: cx - width * 0.47, y: baseY + 4.1 * s),
        NSPoint(x: cx - width * 0.33, y: baseY + 7.2 * s),
        NSPoint(x: cx - width * 0.10, y: baseY + 4.7 * s)
    ])
    let earR = poly([
        NSPoint(x: cx + width * 0.10, y: baseY + 4.7 * s),
        NSPoint(x: cx + width * 0.33, y: baseY + 7.2 * s),
        NSPoint(x: cx + width * 0.47, y: baseY + 4.1 * s)
    ])
    fill(earL, cream); stroke(earL, ink, 1.2 * s)
    fill(earR, cream); stroke(earR, ink, 1.2 * s)
    fill(poly([
        NSPoint(x: cx - width * 0.38, y: baseY + 4.7 * s),
        NSPoint(x: cx - width * 0.31, y: baseY + 6.2 * s),
        NSPoint(x: cx - width * 0.19, y: baseY + 4.9 * s)
    ]), pink)
    fill(poly([
        NSPoint(x: cx + width * 0.19, y: baseY + 4.9 * s),
        NSPoint(x: cx + width * 0.31, y: baseY + 6.2 * s),
        NSPoint(x: cx + width * 0.38, y: baseY + 4.7 * s)
    ]), pink)

    // 眼睛
    if awake {
        fill(NSBezierPath(ovalIn: NSRect(x: cx - width * 0.23, y: baseY + 2.6 * s,
                                         width: 0.85 * s, height: 0.9 * s)), ink)
        fill(NSBezierPath(ovalIn: NSRect(x: cx + width * 0.11, y: baseY + 2.6 * s,
                                         width: 0.85 * s, height: 0.9 * s)), ink)
    } else {
        line(cx - width * 0.27, baseY + 3.0 * s, cx - width * 0.10, baseY + 3.0 * s, ink, 1.0 * s)
        line(cx + width * 0.10, baseY + 3.0 * s, cx + width * 0.27, baseY + 3.0 * s, ink, 1.0 * s)
    }

    // 鼻子 + 嘴
    let nose = NSBezierPath(ovalIn: NSRect(x: cx - 0.7 * s, y: baseY + 1.45 * s,
                                          width: 1.4 * s, height: 1.1 * s))
    fill(nose, cream)
    stroke(nose, ink, 0.8 * s)
    fill(NSBezierPath(ovalIn: NSRect(x: cx - 0.22 * s, y: baseY + 1.8 * s,
                                     width: 0.44 * s, height: 0.4 * s)), ink)
    line(cx, baseY + 1.45 * s, cx, baseY + 1.15 * s, ink, 0.8 * s)
    line(cx, baseY + 1.15 * s, cx - 0.45 * s, baseY + 0.95 * s, ink, 0.8 * s)
    line(cx, baseY + 1.15 * s, cx + 0.45 * s, baseY + 0.95 * s, ink, 0.8 * s)

    // 胡须
    for y in [baseY + 1.9 * s, baseY + 1.4 * s] {
        line(cx - width * 0.48, y, cx - width * 0.62, y + 0.15 * s, ink.withAlphaComponent(0.45), 0.55)
        line(cx + width * 0.48, y, cx + width * 0.62, y + 0.15 * s, ink.withAlphaComponent(0.45), 0.55)
    }

    ctx.restoreGState()
}

// MARK: - 被子

func blanketRoll(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, vertical: Bool) {
    let roll = rr(x, y, w, h, vertical ? w / 2 : h / 2)
    fill(roll, green)
    stroke(roll, ink, 1.2)
    // 卷边细节
    let c = NSPoint(x: vertical ? x + w / 2 : x + w - h / 2,
                    y: vertical ? y + h - w / 2 : y + h / 2)
    let r = (vertical ? w : h) * 0.22
    stroke(NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
           greenDeep, 0.8)
    line(c.x - r, c.y, c.x + r, c.y, greenDeep, 0.7)
}

// MARK: - N1 横着睡

enum CatState {
    case sleep
    case awake
    case pull
}

func drawN1(_ state: CatState) {
    // 床 + 枕头
    fill(rr(2.6, 3.0, 17.0, 2.4, 1.0), bed)
    stroke(rr(2.6, 3.0, 17.0, 2.4, 1.0), ink, 1.2)
    fill(rr(3.0, 4.8, 5.8, 3.0, 1.2), pillow)
    stroke(rr(3.0, 4.8, 5.8, 3.0, 1.2), ink, 1.1)

    // 被子
    if state == .sleep {
        let mound = rr(8.0, 3.8, 11.0, 7.2, 3.4)
        fill(mound, green)
        stroke(mound, ink, 1.3)
        line(8.6, 9.6, 18.2, 9.6, greenDeep, 0.7)
        line(9.2, 6.2, 17.6, 6.2, greenDeep.withAlphaComponent(0.5), 0.6)
        blanketRoll(x: 7.2, y: 4.0, w: 2.2, h: 6.8, vertical: true)
    } else {
        // 被子卷到左边，露出猫身体
        fill(rr(9.0, 3.8, 10.0, 2.2, 1.0), green)
        stroke(rr(9.0, 3.8, 10.0, 2.2, 1.0), ink, 1.0)
        // 身体 + 条纹
        let body = rr(9.4, 4.6, 9.4, 5.8, 2.6)
        fill(body, cream)
        stroke(body, ink, 1.2)
        for x in [11.2, 13.2, 15.2] {
            line(x, 8.8, x + 0.8, 5.4, orange.withAlphaComponent(0.85), 1.3)
        }
        // 尾巴
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: 18.4, y: 5.4))
        tail.curve(to: NSPoint(x: 19.4, y: 8.2),
                   controlPoint1: NSPoint(x: 19.6, y: 5.0), controlPoint2: NSPoint(x: 19.8, y: 7.2))
        stroke(tail, ink, 1.3)
        // 卷起来的被子
        blanketRoll(x: 7.2, y: 3.8, w: 2.6, h: 7.2, vertical: true)
    }

    // 猫头
    catHead(centerX: 6.3, baseY: 6.6, width: 5.9,
            awake: state != .sleep, tilt: state == .sleep ? -4 : 0)

    // 小手
    if state == .pull {
        drawPaw(at: NSPoint(x: 8.6, y: 9.0), scale: 0.95)
    }
}

// MARK: - N2 竖着坐

func drawN2(_ state: CatState) {
    // 床 + 枕头
    fill(rr(3.2, 2.8, 15.4, 3.2, 1.2), bed)
    stroke(rr(3.2, 2.8, 15.4, 3.2, 1.2), ink, 1.2)
    fill(rr(4.6, 4.0, 4.0, 3.0, 1.2), pillow)
    stroke(rr(4.6, 4.0, 4.0, 3.0, 1.2), ink, 1.0)

    let headBase: CGFloat = state == .sleep ? 11.0 : 11.6

    // 被子位置
    let rollY: CGFloat = state == .sleep ? 10.7 : (state == .pull ? 8.6 : 6.4)

    if state != .sleep {
        // 露出的胸口
        let chest = rr(6.0, rollY, 10.0, headBase - rollY + 0.6, 2.0)
        fill(chest, cream)
        stroke(chest, ink, 1.2)
        for x in [8.0, 10.0, 12.0, 14.0] {
            line(x, headBase - 0.6, x + 0.6, rollY + 0.5, orange.withAlphaComponent(0.8), 1.2)
        }
    }

    // 被子本体
    let bodyTop = state == .sleep ? rollY : rollY
    let blanket = rr(4.8, 3.2, 12.4, bodyTop - 3.2 + 1.9, 2.8)
    fill(blanket, green)
    stroke(blanket, ink, 1.3)
    line(5.6, bodyTop - 0.4, 16.4, bodyTop - 0.4, greenDeep.withAlphaComponent(0.55), 0.7)

    // 卷边
    blanketRoll(x: 4.4, y: bodyTop, w: 13.2, h: 2.0, vertical: false)

    // 猫头
    catHead(centerX: 11.0, baseY: headBase, width: 7.2,
            awake: state != .sleep, tilt: state == .sleep ? -3 : 0)

    // 爪子
    if state == .sleep {
        fill(rr(6.4, 10.8, 2.2, 1.4, 0.7), cream)
        stroke(rr(6.4, 10.8, 2.2, 1.4, 0.7), ink, 0.9)
        fill(rr(13.4, 10.8, 2.2, 1.4, 0.7), cream)
        stroke(rr(13.4, 10.8, 2.2, 1.4, 0.7), ink, 0.9)
    } else {
        // 一只爪搭在被子卷上
        drawPaw(at: NSPoint(x: 15.6, y: bodyTop + 1.4), scale: 0.85)
    }

    if state == .pull {
        // 拉被子的手
        drawPaw(at: NSPoint(x: 14.2, y: bodyTop + 1.5), scale: 0.95)
        // 手臂
        let arm = NSBezierPath()
        arm.move(to: NSPoint(x: 15.0, y: bodyTop + 2.6))
        arm.curve(to: NSPoint(x: 12.6, y: bodyTop + 2.0),
                  controlPoint1: NSPoint(x: 13.8, y: bodyTop + 3.4),
                  controlPoint2: NSPoint(x: 12.8, y: bodyTop + 2.8))
        stroke(arm, ink, 1.6)
        stroke(arm, cream, 1.1)
    }
}

func drawPaw(at p: NSPoint, scale s: CGFloat) {
    let paw = rr(p.x - 1.3 * s, p.y - 1.1 * s, 2.6 * s, 2.2 * s, 1.1 * s)
    fill(paw, cream)
    stroke(paw, ink, 0.9 * s)
    for dx in [-0.65, 0.0, 0.65] {
        fill(NSBezierPath(ovalIn: NSRect(x: p.x + (dx - 0.24) * s, y: p.y + 0.75 * s,
                                         width: 0.48 * s, height: 0.42 * s)), pink)
    }
    fill(NSBezierPath(ovalIn: NSRect(x: p.x - 0.4 * s, y: p.y - 0.3 * s,
                                     width: 0.8 * s, height: 0.65 * s)), pink.withAlphaComponent(0.9))
}

// MARK: - 输出

let scale: CGFloat = 2

func renderTile(name: String, path: String, draw: @escaping (CatState) -> Void) {
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

    NSAttributedString(string: name, attributes: [
        .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 18, y: h - 30))

    let size: CGFloat = 96
    let states: [(String, CatState)] = [("睡觉", .sleep), ("掀被子", .awake), ("拉回来", .pull)]
    for (i, item) in states.enumerated() {
        let x = 22 + CGFloat(i) * (size + 18)
        let y: CGFloat = 76
        let bg = rr(x, y, size, size, 14)
        fill(bg, pillow.withAlphaComponent(0.9))
        stroke(bg, ink.withAlphaComponent(0.08), 0.6)
        canvas(in: NSRect(x: x + 8, y: y + 8, width: size - 16, height: size - 16)) {
            draw(item.1)
        }
        let label = NSAttributedString(string: item.0, attributes: [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: textSub
        ])
        let ls = label.size()
        label.draw(at: NSPoint(x: x + (size - ls.width) / 2, y: y - 14))
    }

    // 实际大小
    let strip = NSRect(x: 18, y: 14, width: w - 36, height: 32)
    let half = strip.width / 2
    beige.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.minX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 8, yRadius: 8).fill()
    darkBar.setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.midX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 8, yRadius: 8).fill()
    for (i, state) in [CatState.sleep, .awake, .pull].enumerated() {
        canvas(in: NSRect(x: strip.minX + 22 + CGFloat(i) * 40, y: strip.midY - 9, width: 18, height: 18)) {
            draw(state)
        }
        canvas(in: NSRect(x: strip.midX + 22 + CGFloat(i) * 40, y: strip.midY - 9, width: 18, height: 18)) {
            draw(state)
        }
    }

    NSAttributedString(string: "实际大小 18pt · 左浅 / 右深", attributes: [
        .font: NSFont.systemFont(ofSize: 8, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 18, y: 2))

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: path))
        print("wrote \(path)")
    }
}

func renderStory() {
    let w: CGFloat = 1200, h: CGFloat = 330
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

    NSAttributedString(string: "小猫被子 · 6 帧", attributes: [
        .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 24, y: h - 38))

    let frames: [(String, CatState)] = [
        ("睡觉", .sleep),
        ("点一下", .awake),
        ("10 秒", .awake),
        ("伸手", .pull),
        ("拉回来", .pull),
        ("又睡了", .sleep)
    ]

    let size: CGFloat = 140
    for (i, frame) in frames.enumerated() {
        let x = 24 + CGFloat(i) * (size + 20)
        let y: CGFloat = 80
        let bg = rr(x, y, size, size, 18)
        fill(bg, pillow.withAlphaComponent(0.9))
        stroke(bg, ink.withAlphaComponent(0.08), 0.7)
        canvas(in: NSRect(x: x + 14, y: y + 14, width: size - 28, height: size - 28)) {
            drawN2(frame.1)
        }
        NSAttributedString(string: frame.0, attributes: [
            .font: NSFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: x + 10, y: y - 18))
    }

    NSAttributedString(string: "掀被子时被子卷到腰上，小猫坐起来；10 秒后小猫自己把被子拉回下巴，眼睛闭上，图标回到竖着的睡姿。", attributes: [
        .font: NSFont.systemFont(ofSize: 10, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 24, y: 30))

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "/tmp/sleepcat-story.png"))
        print("wrote /tmp/sleepcat-story.png")
    }
}

renderTile(name: "N1 · 横着睡", path: "/tmp/sleepcat-N1.png", draw: { drawN1($0) })
renderTile(name: "N2 · 竖着坐", path: "/tmp/sleepcat-N2.png", draw: { drawN2($0) })
renderStory()
