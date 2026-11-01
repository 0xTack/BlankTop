//
//  leverbox.swift
//  留白 v1.1 · 正面拨杆盒子
//
//  正面一个拨杆：点一下拨过去，过一会儿一只小手伸出来拨回来。
//  三种外观：线稿纸箱 / 实心黑盒 / 绿盖盒子。
//
//  运行：
//    swiftc -O dev/leverbox.swift -framework AppKit -o /tmp/leverbox && /tmp/leverbox
//

import AppKit

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
            green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255,
            alpha: a)
}

let ink = hex(0x262626)
let cream = hex(0xF4E7CC)
let beige = hex(0xE8D8B0)
let beigeLight = hex(0xF6EBD5)
let metal = hex(0xC9BFAE)
let gray = hex(0x8A857C)
let green = hex(0xA9CE8A)
let greenDeep = hex(0x6FA34C)
let pink = hex(0xE8A39E)
let textMain = hex(0x1B1B1B)
let textSub = hex(0x6E6A63)
let darkBar = hex(0x1E1E20)

func rr(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r)
}

func stroke(_ p: NSBezierPath, _ color: NSColor, _ width: CGFloat = 1.3) {
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
          _ color: NSColor, _ width: CGFloat = 1.0) {
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

// MARK: - 拨杆盒子

enum BoxLook {
    case cardboard
    case solid
    case greenLid
}

enum LeverState {
    case off
    case on
    case pressing
}

func drawLeverBox(_ look: BoxLook, _ state: LeverState, hand: Bool = false) {
    let body = rr(3.0, 2.8, 14.0, 10.4, 1.3)
    let isOn = state != .off
    let solid = look == .solid
    let fg = solid ? cream : ink

    // 箱体
    switch look {
    case .cardboard:
        fill(body, beigeLight)
        stroke(body, ink, 1.45)
    case .solid:
        fill(body, ink)
    case .greenLid:
        fill(body, beigeLight)
        stroke(body, ink, 1.45)
    }

    // 盖子
    if look == .greenLid {
        let lid = rr(2.8, 11.3, 14.4, 2.1, 1.0)
        fill(lid, isOn ? green : beige)
        stroke(lid, ink, 1.3)
    } else if look == .solid {
        line(3.2, 11.9, 16.8, 11.9, cream, 1.0)
    } else {
        line(3.2, 11.9, 16.8, 11.9, ink, 1.2)
        // 顶部胶带
        fill(rr(9.2, 11.9, 1.6, 1.3, 0.2), beige)
        stroke(rr(9.2, 11.9, 1.6, 1.3, 0.2), ink, 0.7)
    }

    // 纸箱标签
    if look != .solid {
        let label = rr(4.2, 3.4, 3.2, 1.9, 0.3)
        fill(label, beige)
        stroke(label, ink, 0.7)
        line(4.6, 4.7, 6.9, 4.7, ink.withAlphaComponent(0.45), 0.5)
        line(4.6, 4.25, 7.1, 4.25, ink.withAlphaComponent(0.45), 0.5)
    }

    // 拨杆底座
    let base = rr(7.0, 4.3, 6.0, 2.2, 1.0)
    fill(base, solid ? cream : metal)
    stroke(base, ink, 1.0)
    fill(NSBezierPath(ovalIn: NSRect(x: 7.7, y: 4.9, width: 0.8, height: 0.8)),
         isOn ? green : (solid ? cream.withAlphaComponent(0.5) : gray))

    // 杆
    let pivot = NSPoint(x: 10.0, y: 5.7)
    let degrees: CGFloat = state == .off ? -42 : (state == .on ? 42 : 0)
    let radians = degrees * .pi / 180
    let length: CGFloat = 4.6
    let tip = NSPoint(x: pivot.x + sin(radians) * length,
                      y: pivot.y + cos(radians) * length)
    line(pivot.x, pivot.y, tip.x, tip.y, fg, 1.7)
    fill(NSBezierPath(ovalIn: NSRect(x: pivot.x - 0.55, y: pivot.y - 0.55, width: 1.1, height: 1.1)), fg)

    // 球头
    let ballColor = isOn ? green : (solid ? cream : gray)
    let ball = NSBezierPath(ovalIn: NSRect(x: tip.x - 1.35, y: tip.y - 1.35, width: 2.7, height: 2.7))
    fill(ball, ballColor)
    stroke(ball, ink, 0.95)

    // 小手
    if hand {
        drawHand(reachingTo: NSPoint(x: tip.x + 1.1, y: tip.y + 0.2))
    }
}

func drawHand(reachingTo target: NSPoint) {
    // 手臂从右上角伸出来
    let start = NSPoint(x: 15.8, y: 13.6)
    let arm = NSBezierPath()
    arm.move(to: start)
    arm.curve(to: NSPoint(x: target.x + 1.4, y: target.y + 1.3),
              controlPoint1: NSPoint(x: 15.6, y: 12.2),
              controlPoint2: NSPoint(x: target.x + 2.6, y: target.y + 3.0))
    stroke(arm, ink, 2.1)
    stroke(arm, cream, 1.4)

    // 掌心
    let paw = rr(target.x - 1.3, target.y - 1.1, 3.0, 2.4, 1.1)
    fill(paw, cream)
    stroke(paw, ink, 0.9)
    // 三个脚趾/指头
    for dx in [-0.75, 0.0, 0.75] {
        let toe = NSBezierPath(ovalIn: NSRect(x: target.x + dx - 0.28, y: target.y + 0.9,
                                              width: 0.56, height: 0.5))
        fill(toe, pink)
    }
    // 掌心肉垫
    fill(NSBezierPath(ovalIn: NSRect(x: target.x - 0.5, y: target.y - 0.35,
                                     width: 1.0, height: 0.8)), pink.withAlphaComponent(0.85))
}

// MARK: - 输出

struct LookSpec {
    let id: String
    let name: String
    let subtitle: String
    let look: BoxLook
}

let looks: [LookSpec] = [
    LookSpec(id: "P1", name: "线稿纸箱", subtitle: "米色箱体 + 黑描边，拨杆最清楚",
             look: .cardboard),
    LookSpec(id: "P2", name: "实心黑盒", subtitle: "黑盒子 + 米色拨杆，最醒目",
             look: .solid),
    LookSpec(id: "P3", name: "绿盖盒子", subtitle: "盖子变绿表示“开”，拨杆是黑的",
             look: .greenLid)
]

let scale: CGFloat = 2

func renderLook(_ spec: LookSpec) {
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

    let size: CGFloat = 100
    let states: [(String, LeverState, Bool)] = [
        ("关", .off, false),
        ("开", .on, false),
        ("小手", .pressing, true)
    ]
    for (i, item) in states.enumerated() {
        let x = 22 + CGFloat(i) * (size + 14)
        let y: CGFloat = 74
        let bg = rr(x, y, size, size, 14)
        beigeLight.setFill()
        bg.fill()
        stroke(bg, ink.withAlphaComponent(0.08), 0.6)
        canvas(in: NSRect(x: x + 10, y: y + 10, width: size - 20, height: size - 20)) {
            drawLeverBox(spec.look, item.1, hand: item.2)
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

    for (i, state) in [LeverState.off, .on, .pressing].enumerated() {
        canvas(in: NSRect(x: strip.minX + 22 + CGFloat(i) * 40, y: strip.midY - 9, width: 18, height: 18)) {
            drawLeverBox(spec.look, state, hand: state == .pressing)
        }
    }
    // 深色：把深色元素换白（线稿/纸箱）
    if spec.look != .solid {
        // 这里不反转颜色，深色下仍然能看清米色箱体和黑线；保持简单
    }

    NSAttributedString(string: "实际大小 18pt · 浅色菜单栏", attributes: [
        .font: NSFont.systemFont(ofSize: 8, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 18, y: 2))

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        let path = "/tmp/lever-\(spec.id).png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("wrote \(path)")
    }
}

/// 故事板：点一下 → 拨过去 → 10 秒后小手伸出来 → 拨回来
func renderStory(style: BoxLook) {
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

    NSAttributedString(string: "拨杆动画 · 6 帧", attributes: [
        .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 24, y: h - 38))

    let frames: [(String, LeverState, Bool)] = [
        ("关着", .off, false),
        ("点一下", .on, false),
        ("过 10 秒", .on, true),
        ("小手拨回", .pressing, true),
        ("拨回去了", .off, true),
        ("手缩回去", .off, false)
    ]

    let size: CGFloat = 140
    for (i, frame) in frames.enumerated() {
        let x = 24 + CGFloat(i) * (size + 20)
        let y: CGFloat = 80
        let bg = rr(x, y, size, size, 18)
        beigeLight.setFill()
        bg.fill()
        stroke(bg, ink.withAlphaComponent(0.08), 0.7)
        canvas(in: NSRect(x: x + 14, y: y + 14, width: size - 28, height: size - 28)) {
            drawLeverBox(style, frame.1, hand: frame.2)
        }
        NSAttributedString(string: frame.0, attributes: [
            .font: NSFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: x + 10, y: y - 18))
    }

    NSAttributedString(string: "实际动画会带一点回弹：拨过去时先过冲一点，再停住；小手伸出来时也是先探一下再按。", attributes: [
        .font: NSFont.systemFont(ofSize: 10, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 24, y: 30))

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "/tmp/lever-story.png"))
        print("wrote /tmp/lever-story.png")
    }
}

for spec in looks { renderLook(spec) }
renderStory(style: .cardboard)
