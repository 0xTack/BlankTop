//
//  modeicons.swift
//  留白 v1.1 新模式图标候选
//
//  生成一张对比图：无聊盒子 6 款、抓狂棋子 4 款，
//  每款都给出「关 / 开」两个状态、实际大小、浅色与深色菜单栏。
//  运行：
//    swiftc -O dev/modeicons.swift -framework AppKit -o /tmp/modeicons && /tmp/modeicons
//

import AppKit

// MARK: - 基础

let pageW: CGFloat = 840
let pageH: CGFloat = 1260
let pixelScale: CGFloat = 2

let paper = NSColor(srgbRed: 0.953, green: 0.941, blue: 0.914, alpha: 1)
let cardFill = NSColor(srgbRed: 1.0, green: 0.996, blue: 0.988, alpha: 0.72)
let cardStroke = NSColor(calibratedWhite: 0.0, alpha: 0.06)
let textMain = NSColor(calibratedWhite: 0.10, alpha: 1)
let textSub = NSColor(calibratedWhite: 0.42, alpha: 1)

let inkLight = NSColor(calibratedWhite: 0.05, alpha: 0.88)
let inkDark = NSColor(calibratedWhite: 0.97, alpha: 0.92)
let green = NSColor(srgbRed: 121 / 255, green: 188 / 255, blue: 81 / 255, alpha: 1)
let greenBright = NSColor(srgbRed: 143 / 255, green: 212 / 255, blue: 106 / 255, alpha: 1)

let barLight = NSColor(srgbRed: 0.973, green: 0.957, blue: 0.922, alpha: 1)
let barDark = NSColor(srgbRed: 0.118, green: 0.118, blue: 0.129, alpha: 1)

func path(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r)
}

func stroke(_ p: NSBezierPath, _ color: NSColor, _ width: CGFloat = 1.2) {
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
          _ color: NSColor, _ width: CGFloat = 1.0, dash: [CGFloat]? = nil) {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: x1, y: y1))
    p.line(to: NSPoint(x: x2, y: y2))
    p.lineCapStyle = .round
    p.lineWidth = width
    if let dash { p.setLineDash(dash, count: dash.count, phase: 0) }
    color.setStroke()
    p.stroke()
}

/// 把 20×20 的图标坐标映射到目标矩形。
func iconCanvas(in rect: NSRect, _ body: () -> Void) {
    let ctx = NSGraphicsContext.current!.cgContext
    let s = rect.width / 20
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.minY)
    ctx.scaleBy(x: s, y: s)
    body()
    ctx.restoreGState()
}

// MARK: - 猫爪

/// 猫爪：掌心 + 三个脚趾，脚趾朝下；armFrom 是手臂从箱子里伸出来的起点。
func drawPaw(at center: NSPoint, armFrom: NSPoint?, color: NSColor) {
    if let armFrom {
        let arm = NSBezierPath()
        arm.move(to: armFrom)
        let midY = (armFrom.y + center.y) / 2
        arm.curve(to: NSPoint(x: center.x, y: center.y + 1.2),
                  controlPoint1: NSPoint(x: armFrom.x, y: midY),
                  controlPoint2: NSPoint(x: center.x, y: midY))
        stroke(arm, color, 0.9)
    }
    fill(path(center.x - 1.5, center.y - 1.2, 3.0, 2.4, 1.2), color)
    for dx in [-0.95, 0.0, 0.95] {
        fill(NSBezierPath(ovalIn: NSRect(x: center.x + dx - 0.45, y: center.y - 2.0,
                                         width: 0.9, height: 0.85)), color)
    }
}

// MARK: - 盒子

/// A：纸箱 + 睡眼 + 正面开关
func boxA(open: Bool, paw: Bool, color: NSColor, accent: NSColor) {
    let body = path(3.2, 3.0, 13.6, 8.8, 1.2)
    stroke(body, color, 1.25)
    line(10, 3.2, 10, 11.7, color.withAlphaComponent(0.28), 0.9)

    if open {
        fill(path(3.8, 11.6, 12.4, 2.0, 0.8), color.withAlphaComponent(0.20))
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        ctx.translateBy(x: 2.4, y: 11.8)
        ctx.rotate(by: 32 * .pi / 180)
        fill(path(0, 0, 15.0, 2.0, 0.9), color)
        ctx.restoreGState()
    } else {
        fill(path(2.4, 11.8, 15.2, 2.0, 0.9), color)
    }

    // 正面小按钮
    let button = NSBezierPath(ovalIn: NSRect(x: 12.0, y: 4.0, width: 2.2, height: 2.2))
    if open {
        fill(button, accent)
    } else {
        stroke(button, color.withAlphaComponent(0.55), 1.0)
    }

    // 眼睛：关着是两条睡眼，打开是圆眼
    if open {
        fill(NSBezierPath(ovalIn: NSRect(x: 5.5, y: 8.9, width: 1.3, height: 1.3)), color)
        fill(NSBezierPath(ovalIn: NSRect(x: 9.1, y: 8.9, width: 1.3, height: 1.3)), color)
    } else {
        line(5.3, 9.4, 7.1, 9.4, color, 1.15)
        line(8.9, 9.4, 10.7, 9.4, color, 1.15)
    }
    line(6.6, 6.8, 8.2, 6.8, color.withAlphaComponent(0.65), 0.9)

    if paw {
        drawPaw(at: NSPoint(x: 13.0, y: 7.4), armFrom: NSPoint(x: 11.2, y: 12.2), color: color)
    }
}

/// B：极简纸箱 + 绿点
func boxB(open: Bool, paw: Bool, color: NSColor, accent: NSColor) {
    let body = path(3.4, 3.2, 13.2, 8.6, 1.0)
    stroke(body, color, 1.3)
    line(10, 3.4, 10, 11.6, color.withAlphaComponent(0.26), 0.9)

    if open {
        fill(path(3.9, 11.4, 12.2, 1.9, 0.7), color.withAlphaComponent(0.18))
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        ctx.translateBy(x: 2.6, y: 11.8)
        ctx.rotate(by: 32 * .pi / 180)
        fill(path(0, 0, 15.0, 1.4, 0.6), color)
        ctx.restoreGState()
    } else {
        stroke(path(2.6, 11.6, 14.8, 1.3, 0.5), color, 1.3)
        line(6.7, 11.6, 6.7, 10.5, color.withAlphaComponent(0.5), 1.0)
        line(13.3, 11.6, 13.3, 10.5, color.withAlphaComponent(0.5), 1.0)
    }

    let dot = NSBezierPath(ovalIn: NSRect(x: 13.5, y: 4.7, width: 2.1, height: 2.1))
    if open {
        fill(dot, accent)
    } else {
        stroke(dot, color.withAlphaComponent(0.5), 1.0)
    }

    if paw {
        drawPaw(at: NSPoint(x: 14.55, y: 7.4), armFrom: NSPoint(x: 10.2, y: 12.0), color: color)
    }
}

/// C：猫耳纸箱
func boxC(open: Bool, color: NSColor, accent: NSColor) {
    let head = NSBezierPath()
    head.move(to: NSPoint(x: 6.4, y: 11.2))
    head.curve(to: NSPoint(x: 6.9, y: 14.6),
               controlPoint1: NSPoint(x: 6.2, y: 12.4), controlPoint2: NSPoint(x: 6.5, y: 13.8))
    head.line(to: NSPoint(x: 7.5, y: 16.8))
    head.line(to: NSPoint(x: 9.1, y: 14.9))
    head.curve(to: NSPoint(x: 10.9, y: 14.9),
               controlPoint1: NSPoint(x: 9.8, y: 15.3), controlPoint2: NSPoint(x: 10.2, y: 15.3))
    head.line(to: NSPoint(x: 12.5, y: 16.8))
    head.line(to: NSPoint(x: 13.1, y: 14.6))
    head.curve(to: NSPoint(x: 13.6, y: 11.2),
               controlPoint1: NSPoint(x: 13.5, y: 13.8), controlPoint2: NSPoint(x: 13.8, y: 12.4))
    head.close()

    let eyes = NSBezierPath()
    eyes.appendOval(in: NSRect(x: 8.0, y: 12.5, width: 1.3, height: 1.1))
    eyes.appendOval(in: NSRect(x: 10.7, y: 12.5, width: 1.3, height: 1.1))
    head.append(eyes)
    head.windingRule = .evenOdd
    let body = path(3.2, 3.0, 13.6, 8.8, 1.0)
    if open {
        fill(path(3.8, 11.7, 12.4, 2.0, 0.8), color.withAlphaComponent(0.20))
        // 盖子先画，猫头盖在盖子前面
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        ctx.translateBy(x: 2.4, y: 11.9)
        ctx.rotate(by: 32 * .pi / 180)
        fill(path(0, 0, 15.0, 1.9, 0.85), color)
        ctx.restoreGState()
        fill(head, color)
        stroke(body, color, 1.25)
    } else {
        fill(head, color)
        fill(path(2.4, 11.8, 15.2, 2.0, 0.9), color)
        stroke(body, color, 1.25)
    }

    line(10, 3.2, 10, 11.6, color.withAlphaComponent(0.26), 0.9)

    if open {
        // 爪子搭在箱沿上
        fill(path(5.0, 10.4, 3.2, 1.7, 0.85), color)
        for dx in stride(from: 5.5, through: 7.7, by: 0.75) {
            fill(NSBezierPath(ovalIn: NSRect(x: dx - 0.32, y: 10.0, width: 0.65, height: 0.7)), color)
        }
        fill(path(11.8, 10.4, 3.2, 1.7, 0.85), color)
        for dx in stride(from: 12.3, through: 14.5, by: 0.75) {
            fill(NSBezierPath(ovalIn: NSRect(x: dx - 0.32, y: 10.0, width: 0.65, height: 0.7)), color)
        }
    }
}

/// D：睡箱 + zzz
func boxD(open: Bool, color: NSColor, accent: NSColor) {
    let body = path(3.2, 2.8, 13.6, 8.9, 1.1)
    stroke(body, color, 1.25)
    line(10, 3.0, 10, 11.6, color.withAlphaComponent(0.26), 0.9)

    if open {
        fill(path(3.8, 11.5, 12.4, 2.0, 0.8), color.withAlphaComponent(0.18))
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        ctx.translateBy(x: 2.4, y: 11.8)
        ctx.rotate(by: 32 * .pi / 180)
        fill(path(0, 0, 15.2, 1.9, 0.8), color)
        ctx.restoreGState()
        fill(NSBezierPath(ovalIn: NSRect(x: 6.1, y: 8.4, width: 1.3, height: 1.3)), color)
        fill(NSBezierPath(ovalIn: NSRect(x: 12.6, y: 8.4, width: 1.3, height: 1.3)), color)
        line(9.0, 6.4, 11.0, 6.4, color.withAlphaComponent(0.65), 0.9)
    } else {
        fill(path(2.4, 11.7, 15.2, 2.0, 0.9), color)
        line(6.0, 8.9, 7.8, 8.9, color, 1.15)
        line(12.2, 8.9, 14.0, 8.9, color, 1.15)
        line(9.0, 6.9, 11.0, 6.9, color.withAlphaComponent(0.65), 0.9)
        // z
        let z = NSBezierPath()
        z.move(to: NSPoint(x: 15.4, y: 17.4))
        z.line(to: NSPoint(x: 18.2, y: 17.4))
        z.line(to: NSPoint(x: 15.4, y: 14.7))
        z.line(to: NSPoint(x: 18.2, y: 14.7))
        stroke(z, color.withAlphaComponent(0.8), 0.95)
    }
}

/// E：SF Symbol 纸箱 + 绿点
func boxE(open: Bool, paw: Bool, color: NSColor, accent: NSColor) {
    let name = open ? "shippingbox.fill" : "shippingbox"
    let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
    if let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let box = NSRect(x: 2.2, y: 3.0, width: 15.6, height: 15.0)
        let s = min(box.width / image.size.width, box.height / image.size.height)
        let w = image.size.width * s, h = image.size.height * s
        image.draw(in: NSRect(x: box.midX - w / 2, y: box.midY - h / 2, width: w, height: h),
                   from: .zero, operation: .sourceOver, fraction: 1)
    }

    let dot = NSBezierPath(ovalIn: NSRect(x: 13.5, y: 4.2, width: 2.1, height: 2.1))
    if open { fill(dot, accent) } else { stroke(dot, color.withAlphaComponent(0.5), 1.0) }

    if paw {
        drawPaw(at: NSPoint(x: 14.55, y: 6.9), armFrom: NSPoint(x: 11.0, y: 11.6), color: color)
    }
}

/// F：顶部拨杆纸箱（经典 useless machine）
func boxF(open: Bool, paw: Bool, color: NSColor, accent: NSColor) {
    let body = path(3.2, 2.6, 13.6, 9.2, 1.1)
    stroke(body, color, 1.25)
    line(10, 2.8, 10, 11.7, color.withAlphaComponent(0.26), 0.9)

    if open {
        fill(path(3.8, 11.5, 12.4, 2.0, 0.8), color.withAlphaComponent(0.18))
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        ctx.translateBy(x: 2.4, y: 11.8)
        ctx.rotate(by: 32 * .pi / 180)
        fill(path(0, 0, 15.2, 1.9, 0.8), color)
        ctx.restoreGState()
    } else {
        fill(path(2.4, 11.7, 15.2, 2.0, 0.9), color)
    }

    // 睡眼 + 平嘴
    if open {
        fill(NSBezierPath(ovalIn: NSRect(x: 6.1, y: 7.9, width: 1.3, height: 1.3)), color)
        fill(NSBezierPath(ovalIn: NSRect(x: 12.6, y: 7.9, width: 1.3, height: 1.3)), color)
    } else {
        line(6.0, 8.4, 7.8, 8.4, color, 1.15)
        line(12.2, 8.4, 14.0, 8.4, color, 1.15)
    }
    line(9.0, 6.3, 11.0, 6.3, color.withAlphaComponent(0.65), 0.9)

    // 拨杆底座
    fill(path(12.4, 11.9, 3.0, 0.9, 0.45), color.withAlphaComponent(0.8))
    let tip = open ? NSPoint(x: 15.5, y: 16.4) : NSPoint(x: 12.6, y: 16.2)
    line(13.8, 12.4, tip.x, tip.y, color.withAlphaComponent(0.85), 1.0)
    fill(NSBezierPath(ovalIn: NSRect(x: tip.x - 0.8, y: tip.y - 0.8, width: 1.6, height: 1.6)),
         open ? accent : color.withAlphaComponent(0.55))

    if paw {
        drawPaw(at: NSPoint(x: 13.5, y: 13.9), armFrom: NSPoint(x: 10.0, y: 12.2), color: color)
    }
}

// MARK: - 棋子

func glyph(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, in rect: NSRect) {
    let attr = NSAttributedString(string: text, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color
    ])
    let s = attr.size()
    attr.draw(at: NSPoint(x: rect.midX - s.width / 2, y: rect.midY - s.height / 2))
}

/// 手绘马
func customKnight(color: NSColor, in rect: NSRect) {
    let body = NSBezierPath()
    body.move(to: NSPoint(x: 7.2, y: 4.4))
    body.curve(to: NSPoint(x: 7.0, y: 7.6),
               controlPoint1: NSPoint(x: 7.5, y: 5.2), controlPoint2: NSPoint(x: 6.8, y: 6.4))
    body.curve(to: NSPoint(x: 8.1, y: 9.6),
               controlPoint1: NSPoint(x: 7.2, y: 8.4), controlPoint2: NSPoint(x: 7.9, y: 9.0))
    body.curve(to: NSPoint(x: 6.8, y: 12.4),
               controlPoint1: NSPoint(x: 8.2, y: 10.6), controlPoint2: NSPoint(x: 7.2, y: 11.4))
    body.curve(to: NSPoint(x: 5.7, y: 14.8),
               controlPoint1: NSPoint(x: 6.6, y: 13.4), controlPoint2: NSPoint(x: 5.6, y: 14.0))
    body.curve(to: NSPoint(x: 7.6, y: 16.2),
               controlPoint1: NSPoint(x: 5.9, y: 15.7), controlPoint2: NSPoint(x: 6.6, y: 16.1))
    body.curve(to: NSPoint(x: 9.2, y: 16.7),
               controlPoint1: NSPoint(x: 8.2, y: 16.6), controlPoint2: NSPoint(x: 8.7, y: 16.8))
    body.curve(to: NSPoint(x: 9.8, y: 18.3),
               controlPoint1: NSPoint(x: 9.4, y: 17.4), controlPoint2: NSPoint(x: 9.5, y: 18.0))
    body.curve(to: NSPoint(x: 11.2, y: 16.6),
               controlPoint1: NSPoint(x: 10.4, y: 17.2), controlPoint2: NSPoint(x: 10.8, y: 16.9))
    // 鬃毛锯齿
    body.line(to: NSPoint(x: 12.0, y: 15.5))
    body.line(to: NSPoint(x: 11.5, y: 14.8))
    body.line(to: NSPoint(x: 12.5, y: 14.1))
    body.line(to: NSPoint(x: 11.9, y: 13.1))
    body.line(to: NSPoint(x: 13.0, y: 12.0))
    body.curve(to: NSPoint(x: 12.2, y: 4.4),
               controlPoint1: NSPoint(x: 13.4, y: 9.8), controlPoint2: NSPoint(x: 13.2, y: 5.6))
    body.close()

    // 眼睛镂空
    let eye = NSBezierPath(ovalIn: NSRect(x: 8.1, y: 14.8, width: 0.9, height: 0.85))
    body.append(eye)
    body.windingRule = .evenOdd

    let base = path(5.2, 1.9, 9.6, 2.2, 1.0)

    let ctx = NSGraphicsContext.current!.cgContext
    let s = rect.width / 20
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.minY)
    ctx.scaleBy(x: s, y: s)
    fill(body, color)
    fill(base, color)
    ctx.restoreGState()
}

// MARK: - 卡片与页面

struct Candidate {
    let title: String
    let subtitle: String
    let wantPaw: Bool
    let draw: (Bool, NSColor, NSColor, NSRect) -> Void
    let horse: Bool
}

let boxes: [Candidate] = [
    Candidate(title: "A · 纸箱 + 睡眼", subtitle: "正面小开关，最贴近 useless machine", wantPaw: true,
              draw: { open, color, accent, rect in iconCanvas(in: rect) { boxA(open: open, paw: false, color: color, accent: accent) } },
              horse: false),
    Candidate(title: "B · 极简纸箱", subtitle: "只有箱子和绿点，最像系统图标", wantPaw: true,
              draw: { open, color, accent, rect in iconCanvas(in: rect) { boxB(open: open, paw: false, color: color, accent: accent) } },
              horse: false),
    Candidate(title: "C · 猫耳纸箱", subtitle: "猫躲在箱子里，只露耳朵和眼睛", wantPaw: false,
              draw: { open, color, accent, rect in iconCanvas(in: rect) { boxC(open: open, color: color, accent: accent) } },
              horse: false),
    Candidate(title: "D · 睡箱 + zzz", subtitle: "一颗 z 表达“无聊”，点开就醒", wantPaw: false,
              draw: { open, color, accent, rect in iconCanvas(in: rect) { boxD(open: open, color: color, accent: accent) } },
              horse: false),
    Candidate(title: "E · SF 纸箱", subtitle: "系统 shippingbox，关线框 / 开实心", wantPaw: true,
              draw: { open, color, accent, rect in iconCanvas(in: rect) { boxE(open: open, paw: false, color: color, accent: accent) } },
              horse: false),
    Candidate(title: "F · 顶部拨杆纸箱", subtitle: "猫爪伸出来把拨杆按回去", wantPaw: true,
              draw: { open, color, accent, rect in iconCanvas(in: rect) { boxF(open: open, paw: false, color: color, accent: accent) } },
              horse: false)
]

/// 棋子的绘制单独处理：真马 / 空心马 / 手绘马
enum HorseStyle {
    case glyph16, glyph14Bold, outline, custom
}

let horses: [(String, String, HorseStyle)] = [
    ("H1 · ♞ 系统字体", "22pt regular，最稳", .glyph16),
    ("H2 · ♞ 加粗", "21pt semibold，更实", .glyph14Bold),
    ("H3 · ♘ 空心", "22pt regular，更轻", .outline),
    ("H4 · 手绘马", "自绘轮廓，辨识度最高也最冒险", .custom)
]

func drawHorse(_ style: HorseStyle, color: NSColor, in rect: NSRect) {
    switch style {
    case .glyph16:
        glyph("♞", size: 22, weight: .regular, color: color, in: rect)
    case .glyph14Bold:
        glyph("♞", size: 21, weight: .semibold, color: color, in: rect)
    case .outline:
        glyph("♘", size: 22, weight: .regular, color: color, in: rect)
    case .custom:
        customKnight(color: color, in: rect)
    }
}

func drawCardBackground(_ rect: NSRect) {
    let p = path(rect.minX, rect.minY, rect.width, rect.height, 15)
    fill(p, cardFill)
    stroke(p, cardStroke, 1)
}

func drawActualSizeStrip(_ rect: NSRect, candidate: Candidate) {
    let half = rect.width / 2
    let lightRect = NSRect(x: rect.minX, y: rect.minY, width: half, height: rect.height)
    let darkRect = NSRect(x: rect.minX + half, y: rect.minY, width: half, height: rect.height)

    barLight.setFill()
    NSBezierPath(roundedRect: lightRect, xRadius: 9, yRadius: 9).fill()
    barDark.setFill()
    NSBezierPath(roundedRect: darkRect, xRadius: 9, yRadius: 9).fill()
    // 中间接缝
    line(rect.midX, rect.minY + 2, rect.midX, rect.maxY - 2, NSColor(calibratedWhite: 0.5, alpha: 0.18), 0.8)

    let iconSize: CGFloat = 18
    for (index, open) in [false, true].enumerated() {
        let xLight = lightRect.minX + 16 + CGFloat(index) * 34
        let xDark = darkRect.minX + 16 + CGFloat(index) * 34
        let y = rect.midY - iconSize / 2
        candidate.draw(open, inkLight, green, NSRect(x: xLight, y: y, width: iconSize, height: iconSize))
        candidate.draw(open, inkDark, greenBright, NSRect(x: xDark, y: y, width: iconSize, height: iconSize))
    }
}

func drawHorseStrip(_ rect: NSRect, style: HorseStyle) {
    let half = rect.width / 2
    let lightRect = NSRect(x: rect.minX, y: rect.minY, width: half, height: rect.height)
    let darkRect = NSRect(x: rect.minX + half, y: rect.minY, width: half, height: rect.height)

    barLight.setFill()
    NSBezierPath(roundedRect: lightRect, xRadius: 9, yRadius: 9).fill()
    barDark.setFill()
    NSBezierPath(roundedRect: darkRect, xRadius: 9, yRadius: 9).fill()
    line(rect.midX, rect.minY + 2, rect.midX, rect.maxY - 2, NSColor(calibratedWhite: 0.5, alpha: 0.18), 0.8)

    let iconSize: CGFloat = 18
    drawHorse(style, color: inkLight, in: NSRect(x: lightRect.midX - iconSize / 2,
                                                y: rect.midY - iconSize / 2,
                                                width: iconSize, height: iconSize))
    drawHorse(style, color: inkDark, in: NSRect(x: darkRect.midX - iconSize / 2,
                                               y: rect.midY - iconSize / 2,
                                               width: iconSize, height: iconSize))
}

func render() {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(pageW * pixelScale), pixelsHigh: Int(pageH * pixelScale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pageW, height: pageH)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x: pixelScale, y: pixelScale)

    // 背景
    paper.setFill()
    NSRect(x: 0, y: 0, width: pageW, height: pageH).fill()

    // 标题
    NSAttributedString(string: "留白 v1.1 · 新模式图标候选", attributes: [
        .font: NSFont.systemFont(ofSize: 24, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 28, y: pageH - 52))

    NSAttributedString(string: "回复字母即可：盒子 A–F，棋子 H1–H4。每组都给了关 / 开、实际大小、浅色与深色菜单栏。", attributes: [
        .font: NSFont.systemFont(ofSize: 11.5, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 28, y: pageH - 72))

    // 盒子区
    NSAttributedString(string: "无聊盒子", attributes: [
        .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 28, y: pageH - 108))

    let boxCardW: CGFloat = 248
    let boxCardH: CGFloat = 300
    let gap: CGFloat = 14
    let startX: CGFloat = 28
    let boxTop = pageH - 130

    for (index, candidate) in boxes.enumerated() {
        let col = index % 3
        let row = index / 3
        let x = startX + CGFloat(col) * (boxCardW + gap)
        let y = boxTop - CGFloat(row + 1) * boxCardH - CGFloat(row) * gap
        let card = NSRect(x: x, y: y, width: boxCardW, height: boxCardH)
        drawCardBackground(card)

        NSAttributedString(string: candidate.title, attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: x + 14, y: y + boxCardH - 27))

        NSAttributedString(string: candidate.subtitle, attributes: [
            .font: NSFont.systemFont(ofSize: 9.5, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: x + 14, y: y + boxCardH - 43))

        // 两个大预览：关 / 开
        let previewSize: CGFloat = 96
        for (state, open) in [("关", false), ("开", true)] {
            let px = x + 22 + (open ? 108 : 0)
            let py = y + boxCardH - 158
            let bg = path(px, py, previewSize, previewSize, 14)
            fill(bg, NSColor(calibratedWhite: 0.99, alpha: 0.85))
            stroke(bg, NSColor(calibratedWhite: 0, alpha: 0.035), 1)
            if open && candidate.wantPaw {
                // 开状态带猫爪：直接画在同一个 20×20 画布里
                iconCanvas(in: NSRect(x: px + 8, y: py + 8, width: previewSize - 16, height: previewSize - 16)) {
                    drawBoxWithPaw(candidate: candidate, color: inkLight, accent: green)
                }
            } else {
                candidate.draw(open, inkLight, green,
                               NSRect(x: px + 8, y: py + 8, width: previewSize - 16, height: previewSize - 16))
            }
            let label = NSAttributedString(string: state, attributes: [
                .font: NSFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: textSub
            ])
            let ls = label.size()
            label.draw(at: NSPoint(x: px + (previewSize - ls.width) / 2, y: py - 15))
        }

        // 实际大小
        drawActualSizeStrip(NSRect(x: x + 14, y: y + 32, width: boxCardW - 28, height: 40), candidate: candidate)

        NSAttributedString(string: "实际大小 18pt · 左浅色 / 右深色", attributes: [
            .font: NSFont.systemFont(ofSize: 8.5, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: x + 14, y: y + 16))
    }

    // 棋子区
    let horseTop = boxTop - 2 * (boxCardH + gap) - 26
    NSAttributedString(string: "抓狂棋子", attributes: [
        .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 28, y: horseTop))

    let horseCardW: CGFloat = 248
    let horseCardH: CGFloat = 188
    let horseStartY = horseTop - 20

    for (index, horse) in horses.enumerated() {
        let col = index % 3
        let row = index / 3
        let x = startX + CGFloat(col) * (horseCardW + gap)
        let y = horseStartY - CGFloat(row + 1) * horseCardH - CGFloat(row) * gap
        let card = NSRect(x: x, y: y, width: horseCardW, height: horseCardH)
        drawCardBackground(card)

        NSAttributedString(string: horse.0, attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: x + 14, y: y + horseCardH - 27))

        NSAttributedString(string: horse.1, attributes: [
            .font: NSFont.systemFont(ofSize: 9.5, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: x + 14, y: y + horseCardH - 43))

        let previewSize: CGFloat = 80
        let px = x + (horseCardW - previewSize) / 2
        let py = y + horseCardH - 128
        let bg = path(px, py, previewSize, previewSize, 14)
        fill(bg, NSColor(calibratedWhite: 0.99, alpha: 0.85))
        stroke(bg, NSColor(calibratedWhite: 0, alpha: 0.035), 1)
        drawHorse(horse.2, color: inkLight,
                  in: NSRect(x: px + 6, y: py + 6, width: previewSize - 12, height: previewSize - 12))

        drawHorseStrip(NSRect(x: x + 14, y: y + 22, width: horseCardW - 28, height: 40), style: horse.2)
    }

    // 底部备注
    NSAttributedString(string: "实际使用时图标是单色的：浅色菜单栏取黑，深色菜单栏取白；绿色只用于“开”的状态。", attributes: [
        .font: NSFont.systemFont(ofSize: 9.5, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 28, y: 20))

    NSGraphicsContext.restoreGraphicsState()

    let out = "/tmp/blanktop-mode-icons.png"
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: out))
        print("wrote \(out) \(rep.pixelsWide)x\(rep.pixelsHigh)")
    }
}

/// 紧凑图：给模型/聊天窗口看的小图，400×560。
func renderCompact() {
    let w: CGFloat = 400, h: CGFloat = 560
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(w * pixelScale), pixelsHigh: Int(h * pixelScale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.cgContext.scaleBy(x: pixelScale, y: pixelScale)

    paper.setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()

    NSAttributedString(string: "无聊盒子 · 6 选 1", attributes: [
        .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 14, y: h - 26))
    NSAttributedString(string: "左：关  中：开  右：实际大小（浅 / 深）", attributes: [
        .font: NSFont.systemFont(ofSize: 8.5, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 14, y: h - 40))

    let rowH: CGFloat = 82
    let top: CGFloat = h - 56

    for (index, candidate) in boxes.enumerated() {
        let y = top - CGFloat(index + 1) * rowH + 6
        NSAttributedString(string: String(candidate.title.prefix(1)) + "  " + String(candidate.title.dropFirst(4)),
                           attributes: [
            .font: NSFont.systemFont(ofSize: 10.5, weight: .medium),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: 14, y: y + 40))
        NSAttributedString(string: candidate.subtitle, attributes: [
            .font: NSFont.systemFont(ofSize: 7.5, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: 14, y: y + 28))

        let size: CGFloat = 50
        let closedRect = NSRect(x: 112, y: y + 6, width: size, height: size)
        let openRect = NSRect(x: 172, y: y + 6, width: size, height: size)

        fill(path(closedRect.minX, closedRect.minY, size, size, 10), NSColor(calibratedWhite: 0.99, alpha: 0.9))
        fill(path(openRect.minX, openRect.minY, size, size, 10), NSColor(calibratedWhite: 0.99, alpha: 0.9))

        candidate.draw(false, inkLight, green,
                       NSRect(x: closedRect.minX + 5, y: closedRect.minY + 5, width: size - 10, height: size - 10))
        if candidate.wantPaw {
            iconCanvas(in: NSRect(x: openRect.minX + 5, y: openRect.minY + 5, width: size - 10, height: size - 10)) {
                drawBoxWithPaw(candidate: candidate, color: inkLight, accent: green)
            }
        } else {
            candidate.draw(true, inkLight, green,
                           NSRect(x: openRect.minX + 5, y: openRect.minY + 5, width: size - 10, height: size - 10))
        }

        drawActualSizeStrip(NSRect(x: 238, y: y + 14, width: 148, height: 32), candidate: candidate)
    }

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "/tmp/blanktop-boxes-compact.png"))
        print("wrote /tmp/blanktop-boxes-compact.png")
    }
}

/// 紧凑棋子图，400×260。
func renderCompactHorses() {
    let w: CGFloat = 400, h: CGFloat = 260
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(w * pixelScale), pixelsHigh: Int(h * pixelScale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.cgContext.scaleBy(x: pixelScale, y: pixelScale)

    paper.setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()

    NSAttributedString(string: "抓狂棋子 · 4 选 1", attributes: [
        .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 14, y: h - 26))
    NSAttributedString(string: "左：放大  右：实际大小（浅 / 深）", attributes: [
        .font: NSFont.systemFont(ofSize: 8.5, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 14, y: h - 40))

    let rowH: CGFloat = 50
    let top: CGFloat = h - 54

    for (index, horse) in horses.enumerated() {
        let y = top - CGFloat(index + 1) * rowH + 4
        NSAttributedString(string: horse.0, attributes: [
            .font: NSFont.systemFont(ofSize: 10.5, weight: .medium),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: 14, y: y + 22))
        NSAttributedString(string: horse.1, attributes: [
            .font: NSFont.systemFont(ofSize: 7.5, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: 14, y: y + 12))

        let size: CGFloat = 38
        fill(path(170, y + 2, size, size, 8), NSColor(calibratedWhite: 0.99, alpha: 0.9))
        drawHorse(horse.2, color: inkLight,
                  in: NSRect(x: 174, y: y + 6, width: size - 8, height: size - 8))
        drawHorseStrip(NSRect(x: 222, y: y + 7, width: 164, height: 28), style: horse.2)
    }

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "/tmp/blanktop-horses-compact.png"))
        print("wrote /tmp/blanktop-horses-compact.png")
    }
}

/// 开状态 + 猫爪：按候选分别画
func drawBoxWithPaw(candidate: Candidate, color: NSColor, accent: NSColor) {
    switch candidate.title.first {
    case "A": boxA(open: true, paw: true, color: color, accent: accent)
    case "B": boxB(open: true, paw: true, color: color, accent: accent)
    case "E": boxE(open: true, paw: true, color: color, accent: accent)
    case "F": boxF(open: true, paw: true, color: color, accent: accent)
    default: break
    }
}

/// 单张预览（360×220），方便逐张检查。
func renderTiles() {
    for candidate in boxes {
        let w: CGFloat = 360, h: CGFloat = 220
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(w * pixelScale), pixelsHigh: Int(h * pixelScale),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = NSSize(width: w, height: h)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current!.cgContext.scaleBy(x: pixelScale, y: pixelScale)

        paper.setFill()
        NSRect(x: 0, y: 0, width: w, height: h).fill()

        NSAttributedString(string: candidate.title, attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: 14, y: h - 26))
        NSAttributedString(string: candidate.subtitle, attributes: [
            .font: NSFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: 14, y: h - 40))

        let size: CGFloat = 76
        for (index, open) in [false, true].enumerated() {
            let x = 16 + CGFloat(index) * 92
            let rect = NSRect(x: x, y: 72, width: size, height: size)
            fill(path(rect.minX, rect.minY, size, size, 12), NSColor(calibratedWhite: 0.99, alpha: 0.9))
            if open && candidate.wantPaw {
                iconCanvas(in: NSRect(x: x + 6, y: 78, width: size - 12, height: size - 12)) {
                    drawBoxWithPaw(candidate: candidate, color: inkLight, accent: green)
                }
            } else {
                candidate.draw(open, inkLight, green,
                               NSRect(x: x + 6, y: 78, width: size - 12, height: size - 12))
            }
            let label = NSAttributedString(string: open ? "开" : "关", attributes: [
                .font: NSFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: textSub
            ])
            let ls = label.size()
            label.draw(at: NSPoint(x: x + (size - ls.width) / 2, y: 56))
        }

        drawActualSizeStrip(NSRect(x: 208, y: 96, width: 132, height: 32), candidate: candidate)
        NSAttributedString(string: "实际大小", attributes: [
            .font: NSFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: 208, y: 80))

        NSGraphicsContext.restoreGraphicsState()
        let letter = String(candidate.title.prefix(1))
        if let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: "/tmp/blanktop-tile-\(letter).png"))
            print("wrote /tmp/blanktop-tile-\(letter).png")
        }
    }

    for (index, horse) in horses.enumerated() {
        let w: CGFloat = 360, h: CGFloat = 170
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(w * pixelScale), pixelsHigh: Int(h * pixelScale),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = NSSize(width: w, height: h)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current!.cgContext.scaleBy(x: pixelScale, y: pixelScale)

        paper.setFill()
        NSRect(x: 0, y: 0, width: w, height: h).fill()

        NSAttributedString(string: horse.0, attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: 14, y: h - 26))
        NSAttributedString(string: horse.1, attributes: [
            .font: NSFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: 14, y: h - 40))

        let size: CGFloat = 64
        fill(path(20, 44, size, size, 12), NSColor(calibratedWhite: 0.99, alpha: 0.9))
        drawHorse(horse.2, color: inkLight, in: NSRect(x: 26, y: 50, width: size - 12, height: size - 12))
        drawHorseStrip(NSRect(x: 110, y: 60, width: 180, height: 34), style: horse.2)

        NSGraphicsContext.restoreGraphicsState()
        if let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: "/tmp/blanktop-horse-\(index + 1).png"))
            print("wrote /tmp/blanktop-horse-\(index + 1).png")
        }
    }
}

/// 纯图标 QA 图：只有图标，没有标题，避免查看器裁掉顶部。
func renderQA() {
    for candidate in boxes {
        let w: CGFloat = 220, h: CGFloat = 110
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(w * pixelScale), pixelsHigh: Int(h * pixelScale),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = NSSize(width: w, height: h)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current!.cgContext.scaleBy(x: pixelScale, y: pixelScale)

        paper.setFill()
        NSRect(x: 0, y: 0, width: w, height: h).fill()
        fill(path(8, 8, 96, 96, 12), NSColor(calibratedWhite: 0.99, alpha: 0.9))
        fill(path(116, 8, 96, 96, 12), NSColor(calibratedWhite: 0.99, alpha: 0.9))

        candidate.draw(false, inkLight, green,
                       NSRect(x: 16, y: 16, width: 80, height: 80))
        if candidate.wantPaw {
            iconCanvas(in: NSRect(x: 124, y: 16, width: 80, height: 80)) {
                drawBoxWithPaw(candidate: candidate, color: inkLight, accent: green)
            }
        } else {
            candidate.draw(true, inkLight, green,
                           NSRect(x: 124, y: 16, width: 80, height: 80))
        }

        NSGraphicsContext.restoreGraphicsState()
        let letter = String(candidate.title.prefix(1))
        if let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: "/tmp/qa-box-\(letter).png"))
            print("wrote /tmp/qa-box-\(letter).png")
        }
    }

    for (index, horse) in horses.enumerated() {
        let w: CGFloat = 220, h: CGFloat = 110
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(w * pixelScale), pixelsHigh: Int(h * pixelScale),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = NSSize(width: w, height: h)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current!.cgContext.scaleBy(x: pixelScale, y: pixelScale)

        paper.setFill()
        NSRect(x: 0, y: 0, width: w, height: h).fill()
        fill(path(8, 8, 96, 96, 12), NSColor(calibratedWhite: 0.99, alpha: 0.9))
        drawHorse(horse.2, color: inkLight, in: NSRect(x: 16, y: 16, width: 80, height: 80))

        barLight.setFill()
        NSBezierPath(roundedRect: NSRect(x: 116, y: 40, width: 48, height: 32), xRadius: 8, yRadius: 8).fill()
        barDark.setFill()
        NSBezierPath(roundedRect: NSRect(x: 164, y: 40, width: 48, height: 32), xRadius: 8, yRadius: 8).fill()
        drawHorse(horse.2, color: inkLight, in: NSRect(x: 127, y: 47, width: 18, height: 18))
        drawHorse(horse.2, color: inkDark, in: NSRect(x: 175, y: 47, width: 18, height: 18))

        NSGraphicsContext.restoreGraphicsState()
        if let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: "/tmp/qa-horse-\(index + 1).png"))
            print("wrote /tmp/qa-horse-\(index + 1).png")
        }
    }
}

/// 一条横排，方便一次看完 6 个盒子（无文字、矮图）。
func renderStrip() {
    for open in [false, true] {
        let w: CGFloat = 246, h: CGFloat = 48
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(w * pixelScale), pixelsHigh: Int(h * pixelScale),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = NSSize(width: w, height: h)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current!.cgContext.scaleBy(x: pixelScale, y: pixelScale)

        paper.setFill()
        NSRect(x: 0, y: 0, width: w, height: h).fill()

        for (index, candidate) in boxes.enumerated() {
            let x = 4 + CGFloat(index) * 40
            fill(path(x, 4, 38, 40, 8), NSColor(calibratedWhite: 0.99, alpha: 0.9))
            if open && candidate.wantPaw {
                iconCanvas(in: NSRect(x: x + 4, y: 8, width: 30, height: 30)) {
                    drawBoxWithPaw(candidate: candidate, color: inkLight, accent: green)
                }
            } else {
                candidate.draw(open, inkLight, green,
                               NSRect(x: x + 4, y: 8, width: 30, height: 30))
            }
        }

        NSGraphicsContext.restoreGraphicsState()
        if let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: open ? "/tmp/strip-open.png" : "/tmp/strip-closed.png"))
            print("wrote strip \(open)")
        }
    }
}

/// 拆分图：每张只放 3 个盒子或 4 个棋子，避免预览被裁掉。
func renderSplitSheets() {
    renderBoxSplit(title: "无聊盒子 A–C", list: Array(boxes[0...2]),
                   output: "/tmp/blanktop-boxes-abc.png")
    renderBoxSplit(title: "无聊盒子 D–F", list: Array(boxes[3...5]),
                   output: "/tmp/blanktop-boxes-def.png")
    renderHorseSplit(output: "/tmp/blanktop-horses-all.png")
}

func renderBoxSplit(title: String, list: [Candidate], output: String) {
    let w: CGFloat = 840, h: CGFloat = 300
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(w * pixelScale), pixelsHigh: Int(h * pixelScale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.cgContext.scaleBy(x: pixelScale, y: pixelScale)

    paper.setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()

    NSAttributedString(string: title, attributes: [
        .font: NSFont.systemFont(ofSize: 17, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 20, y: h - 32))
    NSAttributedString(string: "左：关  中：开  右：实际大小（浅 / 深）", attributes: [
        .font: NSFont.systemFont(ofSize: 9, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 20, y: h - 46))

    for (index, candidate) in list.enumerated() {
        let card = NSRect(x: 20 + CGFloat(index) * 270, y: 14, width: 260, height: 232)
        drawCardBackground(card)

        NSAttributedString(string: candidate.title, attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: card.minX + 14, y: card.maxY - 26))

        NSAttributedString(string: candidate.subtitle, attributes: [
            .font: NSFont.systemFont(ofSize: 8.5, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: card.minX + 14, y: card.maxY - 42))

        let size: CGFloat = 84
        for (stateIndex, open) in [false, true].enumerated() {
            let x = card.minX + 18 + CGFloat(stateIndex) * 100
            let y = card.minY + 64
            fill(path(x, y, size, size, 12), NSColor(calibratedWhite: 0.99, alpha: 0.9))
            if open && candidate.wantPaw {
                iconCanvas(in: NSRect(x: x + 6, y: y + 6, width: size - 12, height: size - 12)) {
                    drawBoxWithPaw(candidate: candidate, color: inkLight, accent: green)
                }
            } else {
                candidate.draw(open, inkLight, green,
                               NSRect(x: x + 6, y: y + 6, width: size - 12, height: size - 12))
            }
            let label = NSAttributedString(string: open ? "开" : "关", attributes: [
                .font: NSFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: textSub
            ])
            let ls = label.size()
            label.draw(at: NSPoint(x: x + (size - ls.width) / 2, y: y - 15))
        }

        drawActualSizeStrip(NSRect(x: card.minX + 18, y: card.minY + 14, width: 224, height: 32),
                            candidate: candidate)
    }

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: output))
        print("wrote \(output)")
    }
}

func renderHorseSplit(output: String) {
    let w: CGFloat = 840, h: CGFloat = 280
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(w * pixelScale), pixelsHigh: Int(h * pixelScale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.cgContext.scaleBy(x: pixelScale, y: pixelScale)

    paper.setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()

    NSAttributedString(string: "抓狂棋子 H1–H4", attributes: [
        .font: NSFont.systemFont(ofSize: 17, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 20, y: h - 32))
    NSAttributedString(string: "左：放大  右：实际大小（浅 / 深）", attributes: [
        .font: NSFont.systemFont(ofSize: 9, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 20, y: h - 46))

    for (index, horse) in horses.enumerated() {
        let card = NSRect(x: 16 + CGFloat(index) * 206, y: 14, width: 196, height: 208)
        drawCardBackground(card)

        NSAttributedString(string: horse.0, attributes: [
            .font: NSFont.systemFont(ofSize: 12.5, weight: .semibold),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: card.minX + 12, y: card.maxY - 26))

        NSAttributedString(string: horse.1, attributes: [
            .font: NSFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: card.minX + 12, y: card.maxY - 41))

        let size: CGFloat = 70
        let px = card.midX - size / 2
        let py = card.minY + 66
        fill(path(px, py, size, size, 12), NSColor(calibratedWhite: 0.99, alpha: 0.9))
        drawHorse(horse.2, color: inkLight,
                  in: NSRect(x: px + 6, y: py + 6, width: size - 12, height: size - 12))

        drawHorseStrip(NSRect(x: card.minX + 12, y: card.minY + 16, width: 172, height: 32),
                       style: horse.2)
    }

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: output))
        print("wrote \(output)")
    }
}

/// 一张横向总览，适合直接在“预览”里看，不用滚。
func renderSelectionSheet() {
    let w: CGFloat = 1200, h: CGFloat = 900
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(w * pixelScale), pixelsHigh: Int(h * pixelScale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.cgContext.scaleBy(x: pixelScale, y: pixelScale)

    paper.setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()

    NSAttributedString(string: "留白 v1.1 · 选图标", attributes: [
        .font: NSFont.systemFont(ofSize: 26, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 30, y: h - 54))
    NSAttributedString(string: "回复组合，例如 F + H1。每组：左关 / 中开 / 右实际大小。", attributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 30, y: h - 76))

    let cardW: CGFloat = 360, cardH: CGFloat = 230
    for (index, candidate) in boxes.enumerated() {
        let col = index % 3
        let row = index / 3
        let x = 30 + CGFloat(col) * (cardW + 20)
        let y = 580 - CGFloat(row) * (cardH + 15)
        let card = NSRect(x: x, y: y, width: cardW, height: cardH)
        drawCardBackground(card)

        NSAttributedString(string: candidate.title, attributes: [
            .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: x + 16, y: y + cardH - 30))

        NSAttributedString(string: candidate.subtitle, attributes: [
            .font: NSFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: x + 16, y: y + cardH - 47))

        let size: CGFloat = 88
        for (stateIndex, open) in [false, true].enumerated() {
            let px = x + 26 + CGFloat(stateIndex) * 96
            let py = y + 62
            fill(path(px, py, size, size, 12), NSColor(calibratedWhite: 0.99, alpha: 0.9))
            if open && candidate.wantPaw {
                iconCanvas(in: NSRect(x: px + 7, y: py + 7, width: size - 14, height: size - 14)) {
                    drawBoxWithPaw(candidate: candidate, color: inkLight, accent: green)
                }
            } else {
                candidate.draw(open, inkLight, green,
                               NSRect(x: px + 7, y: py + 7, width: size - 14, height: size - 14))
            }
            let label = NSAttributedString(string: open ? "开" : "关", attributes: [
                .font: NSFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: textSub
            ])
            let ls = label.size()
            label.draw(at: NSPoint(x: px + (size - ls.width) / 2, y: py - 16))
        }

        drawActualSizeStrip(NSRect(x: x + 30, y: y + 16, width: 300, height: 34), candidate: candidate)
    }

    // 棋子
    NSAttributedString(string: "抓狂棋子", attributes: [
        .font: NSFont.systemFont(ofSize: 17, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: 30, y: 310))

    let horseW: CGFloat = 270, horseH: CGFloat = 200
    for (index, horse) in horses.enumerated() {
        let x = 30 + CGFloat(index) * (horseW + 15)
        let y: CGFloat = 95
        let card = NSRect(x: x, y: y, width: horseW, height: horseH)
        drawCardBackground(card)

        NSAttributedString(string: horse.0, attributes: [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: x + 14, y: y + horseH - 28))

        NSAttributedString(string: horse.1, attributes: [
            .font: NSFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: x + 14, y: y + horseH - 44))

        let size: CGFloat = 84
        let px = x + 20
        let py = y + 52
        fill(path(px, py, size, size, 12), NSColor(calibratedWhite: 0.99, alpha: 0.9))
        drawHorse(horse.2, color: inkLight,
                  in: NSRect(x: px + 7, y: py + 7, width: size - 14, height: size - 14))

        drawHorseStrip(NSRect(x: x + 122, y: y + 78, width: 128, height: 34), style: horse.2)
        NSAttributedString(string: "实际大小", attributes: [
            .font: NSFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: x + 122, y: y + 62))
    }

    NSAttributedString(string: "绿色只出现在“开”的状态；实际图标会随浅色 / 深色菜单栏自动反色。", attributes: [
        .font: NSFont.systemFont(ofSize: 10, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 30, y: 26))

    NSGraphicsContext.restoreGraphicsState()
    let out = "/tmp/blanktop-select.png"
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: out))
        print("wrote \(out) \(rep.pixelsWide)x\(rep.pixelsHigh)")
    }
}

render()
renderCompact()
renderCompactHorses()
renderTiles()
renderQA()
renderStrip()
renderSplitSheets()
renderSelectionSheet()






