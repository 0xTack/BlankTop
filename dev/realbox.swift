//
//  realbox.swift
//  留白 v1.1 · “像真实小物品”的盒子图标候选
//
//  四款：纸箱、木盒、猫在纸箱里、铁皮盒。
//  每款都有关 / 开两个状态，输出大图 + 实际 18pt 菜单栏预览。
//
//  运行：
//    swiftc -O dev/realbox.swift -framework AppKit -o /tmp/realbox && /tmp/realbox
//

import AppKit

// MARK: - 颜色

func hex(_ v: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
            green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255,
            alpha: alpha)
}

let paper = hex(0xEFE9DD)
let cardFill = hex(0xFFFCF6, 0.82)
let textMain = hex(0x1B1B1B)
let textSub = hex(0x6E6A63)

let cardboardFrontTop = hex(0xDDB184)
let cardboardFrontBottom = hex(0xBE8A56)
let cardboardSideTop = hex(0xA17146)
let cardboardSideBottom = hex(0x855831)
let cardboardTopTop = hex(0xE9C69C)
let cardboardTopBottom = hex(0xD3A574)
let cardboardEdge = hex(0x7A5334)
let tapeColor = hex(0xF2E5C9, 0.92)
let labelColor = hex(0xFAF4E8)
let labelLine = hex(0xA99A85, 0.8)

let woodFrontTop = hex(0xB97C4C)
let woodFrontBottom = hex(0x8E592D)
let woodSideTop = hex(0x7E4F29)
let woodSideBottom = hex(0x62391C)
let woodTopTop = hex(0xCD925E)
let woodTopBottom = hex(0xA76C3B)
let woodEdge = hex(0x4F3018)
let woodGrain = hex(0x5F3A1C, 0.22)
let brassTop = hex(0xE1C078)
let brassBottom = hex(0xA9823F)

let tinFrontTop = hex(0xCCD5D8)
let tinFrontBottom = hex(0x99A5AA)
let tinSideTop = hex(0x818D93)
let tinSideBottom = hex(0x657176)
let tinTopTop = hex(0xE0E6E8)
let tinTopBottom = hex(0xB4BEC2)
let tinEdge = hex(0x59656A)
let tinRed = hex(0xC45148)
let tinCream = hex(0xF6EBD8)

let catFurTop = hex(0xF3B775)
let catFurBottom = hex(0xDB8F4A)
let catInnerEar = hex(0xD97C6A)
let catEye = hex(0x2F2118)
let catNose = hex(0xD97C6A)
let pawFurTop = hex(0xF8EAD8)
let pawFurBottom = hex(0xE6CDB0)
let pawPad = hex(0xE8A39E)
let pawEdge = hex(0x9C6B48, 0.55)

// MARK: - 基础绘制

func poly(_ pts: [NSPoint]) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: pts[0])
    for pt in pts.dropFirst() { p.line(to: pt) }
    p.close()
    return p
}

func grad(_ p: NSBezierPath, _ top: NSColor, _ bottom: NSColor, _ angle: CGFloat = -90) {
    NSGradient(colors: [top, bottom])?.draw(in: p, angle: angle)
}

func stroke(_ p: NSBezierPath, _ color: NSColor, _ width: CGFloat = 0.55) {
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
          _ color: NSColor, _ width: CGFloat = 0.5) {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: x1, y: y1))
    p.line(to: NSPoint(x: x2, y: y2))
    p.lineCapStyle = .round
    stroke(p, color, width)
}

func iconCanvas(in rect: NSRect, _ body: () -> Void) {
    let ctx = NSGraphicsContext.current!.cgContext
    let s = rect.width / 19.5
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.minY)
    ctx.scaleBy(x: s, y: s)
    body()
    ctx.restoreGState()
}

func groundShadow(width: CGFloat, center: NSPoint, alpha: CGFloat = 0.22) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(alpha + 0.10)
    shadow.shadowBlurRadius = 1.6
    shadow.shadowOffset = NSSize(width: 0, height: -0.7)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    fill(NSBezierPath(ovalIn: NSRect(x: center.x - width / 2, y: center.y - 1.2,
                                     width: width, height: 2.4)),
         NSColor.black.withAlphaComponent(alpha))
    NSGraphicsContext.restoreGraphicsState()
}

// MARK: - 纸箱

let FL: CGFloat = 3.8, FR: CGFloat = 12.8
let FB: CGFloat = 2.8, FT: CGFloat = 10.8
let DX: CGFloat = 3.4, DY: CGFloat = 2.2

func cardboardFaces() -> (front: NSBezierPath, side: NSBezierPath, top: NSBezierPath) {
    let front = NSBezierPath(rect: NSRect(x: FL, y: FB, width: FR - FL, height: FT - FB))
    let side = poly([
        NSPoint(x: FR, y: FB), NSPoint(x: FR + DX, y: FB + DY),
        NSPoint(x: FR + DX, y: FT + DY), NSPoint(x: FR, y: FT)
    ])
    let top = poly([
        NSPoint(x: FL, y: FT), NSPoint(x: FR, y: FT),
        NSPoint(x: FR + DX, y: FT + DY), NSPoint(x: FL + DX, y: FT + DY)
    ])
    return (front, side, top)
}

func drawTapeOnCardboard() {
    // 正面胶带
    let frontTape = NSBezierPath(rect: NSRect(x: 7.9, y: FB, width: 1.5, height: FT - FB))
    fill(frontTape, tapeColor)
    line(8.15, FB + 0.2, 8.15, FT - 0.2, NSColor.white.withAlphaComponent(0.35), 0.35)

    // 顶面胶带
    let topTape = poly([
        NSPoint(x: 8.2, y: FT), NSPoint(x: 9.5, y: FT),
        NSPoint(x: 13.1, y: FT + DY), NSPoint(x: 11.8, y: FT + DY)
    ])
    fill(topTape, tapeColor)
    line(9.1, FT + 0.1, 11.5, FT + DY - 0.1, NSColor.white.withAlphaComponent(0.30), 0.35)
}

func drawShippingLabel() {
    let label = NSBezierPath(roundedRect: NSRect(x: 4.7, y: 4.3, width: 3.9, height: 2.5),
                             xRadius: 0.25, yRadius: 0.25)
    fill(label, labelColor)
    stroke(label, hex(0xC8BAA5), 0.3)
    line(5.1, 6.15, 7.5, 6.15, labelLine, 0.35)
    line(5.1, 5.65, 7.9, 5.65, labelLine, 0.35)
    // 条形码
    for i in 0..<5 {
        let x = 5.2 + CGFloat(i) * 0.42
        line(x, 4.6, x, 5.2, hex(0x8C7E6C, 0.75), i % 2 == 0 ? 0.28 : 0.16)
    }
    // 红色易碎标
    let stamp = NSBezierPath(rect: NSRect(x: 10.6, y: 3.9, width: 1.5, height: 0.9))
    fill(stamp, hex(0xC45148, 0.85))
}

func drawCardboardBody(front: NSBezierPath, side: NSBezierPath, top: NSBezierPath?) {
    grad(side, cardboardSideTop, cardboardSideBottom)
    if let top { grad(top, cardboardTopTop, cardboardTopBottom) }
    grad(front, cardboardFrontTop, cardboardFrontBottom)
    stroke(front, cardboardEdge, 0.55)
    stroke(side, cardboardEdge, 0.55)
    if let top { stroke(top, cardboardEdge, 0.55) }
}

/// R1：纸箱 + 猫爪（关 = 封箱，开 = 开盖，猫爪扒着箱盖）
func drawCardboardPaw(open: Bool, in rect: NSRect) {
    iconCanvas(in: rect) {
        groundShadow(width: 13.8, center: NSPoint(x: 10.2, y: 2.6), alpha: 0.20)
        let (front, side, top) = cardboardFaces()

        if open {
            // 箱体
            grad(side, cardboardSideTop, cardboardSideBottom)
            grad(front, cardboardFrontTop, cardboardFrontBottom)
            stroke(front, cardboardEdge, 0.55)
            stroke(side, cardboardEdge, 0.55)
            drawShippingLabel()

            // 开口
            let opening = poly([
                NSPoint(x: FL, y: FT), NSPoint(x: FR, y: FT),
                NSPoint(x: FR + DX, y: FT + DY), NSPoint(x: FL + DX, y: FT + DY)
            ])
            grad(opening, hex(0x4C311D), hex(0x2B1A0E))
            stroke(opening, hex(0x5F3D24), 0.45)

            // 四片箱盖
            let backFlap = poly([
                NSPoint(x: FL + DX, y: FT + DY), NSPoint(x: FR + DX, y: FT + DY),
                NSPoint(x: FR + DX - 0.7, y: FT + DY + 1.7), NSPoint(x: FL + DX - 0.7, y: FT + DY + 1.7)
            ])
            grad(backFlap, hex(0xE5C198), hex(0xC99A6B))
            stroke(backFlap, cardboardEdge, 0.45)

            let leftFlap = poly([
                NSPoint(x: FL, y: FT), NSPoint(x: FL + DX, y: FT + DY),
                NSPoint(x: FL + DX - 1.5, y: FT + DY + 1.2), NSPoint(x: FL - 1.3, y: FT + 0.8)
            ])
            grad(leftFlap, hex(0xDDB184), hex(0xC18D5B))
            stroke(leftFlap, cardboardEdge, 0.45)

            let rightFlap = poly([
                NSPoint(x: FR, y: FT), NSPoint(x: FR + DX, y: FT + DY),
                NSPoint(x: FR + DX + 0.9, y: FT + DY - 0.4), NSPoint(x: FR + 0.9, y: FT - 0.5)
            ])
            grad(rightFlap, hex(0xD2A374), hex(0xB57F4D))
            stroke(rightFlap, cardboardEdge, 0.45)

            let frontFlap = poly([
                NSPoint(x: FL, y: FT), NSPoint(x: FR, y: FT),
                NSPoint(x: FR + 0.7, y: FT + 1.6), NSPoint(x: FL - 0.7, y: FT + 1.6)
            ])
            grad(frontFlap, hex(0xE3BC90), hex(0xC99765))
            stroke(frontFlap, cardboardEdge, 0.45)
            line(FL + 0.1, FT + 0.8, FR - 0.1, FT + 0.8, hex(0x8A5D36, 0.35), 0.35)

            // 猫爪扒着前盖
            let arm = NSBezierPath()
            arm.move(to: NSPoint(x: 9.8, y: 13.1))
            arm.curve(to: NSPoint(x: 9.4, y: 12.1),
                      controlPoint1: NSPoint(x: 9.4, y: 12.9),
                      controlPoint2: NSPoint(x: 9.3, y: 12.5))
            stroke(arm, pawEdge, 1.55)
            stroke(arm, pawFurTop, 1.15)
            drawPaw(at: NSPoint(x: 9.4, y: 12.2), size: 1.12, toesDown: true)
        } else {
            drawCardboardBody(front: front, side: side, top: top)
            drawTapeOnCardboard()
            drawShippingLabel()
        }
    }
}

// MARK: - 猫在纸箱里

func drawCatEars(baseY: CGFloat, small: Bool) {
    let s: CGFloat = small ? 0.85 : 1.0
    let offset: CGFloat = small ? 0.4 : 0.0
    for (x, flip) in [(8.4, 1.0), (12.4, -1.0)] {
        let ear = poly([
            NSPoint(x: x - 1.1 * s, y: baseY),
            NSPoint(x: x + 0.1 * flip * s, y: baseY + 2.9 * s + offset),
            NSPoint(x: x + 1.1 * s, y: baseY)
        ])
        grad(ear, catFurTop, catFurBottom)
        stroke(ear, hex(0x9C5F2E, 0.55), 0.3)
        let inner = poly([
            NSPoint(x: x - 0.55 * s, y: baseY + 0.25),
            NSPoint(x: x + 0.05 * flip * s, y: baseY + 2.05 * s + offset),
            NSPoint(x: x + 0.55 * s, y: baseY + 0.25)
        ])
        fill(inner, catInnerEar)
    }
}

func drawCatHead(baseY: CGFloat) {
    drawCatEars(baseY: baseY + 2.2, small: false)

    let head = NSBezierPath(roundedRect: NSRect(x: 7.2, y: baseY, width: 5.8, height: 5.0),
                            xRadius: 2.3, yRadius: 2.3)
    grad(head, catFurTop, catFurBottom)
    stroke(head, hex(0x9C5F2E, 0.55), 0.35)

    // 眼睛
    for x in [8.6, 11.4] {
        let eye = NSBezierPath(ovalIn: NSRect(x: x - 0.45, y: baseY + 2.55, width: 0.9, height: 1.05))
        fill(eye, catEye)
        fill(NSBezierPath(ovalIn: NSRect(x: x - 0.15, y: baseY + 3.15, width: 0.3, height: 0.3)),
             NSColor.white.withAlphaComponent(0.85))
    }
    // 鼻子 + 嘴
    let nose = poly([
        NSPoint(x: 9.75, y: baseY + 1.95),
        NSPoint(x: 10.25, y: baseY + 1.95),
        NSPoint(x: 10.0, y: baseY + 1.55)
    ])
    fill(nose, catNose)
    line(10.0, baseY + 1.55, 10.0, baseY + 1.15, hex(0x8C5A3A, 0.55), 0.3)
    line(10.0, baseY + 1.15, 9.55, baseY + 0.9, hex(0x8C5A3A, 0.55), 0.3)
    line(10.0, baseY + 1.15, 10.45, baseY + 0.9, hex(0x8C5A3A, 0.55), 0.3)

    // 胡须
    for y in [baseY + 1.7, baseY + 1.25] {
        line(7.45, y, 6.45, y + 0.15, hex(0x9C6B48, 0.40), 0.22)
        line(12.55, y, 13.55, y + 0.15, hex(0x9C6B48, 0.40), 0.22)
    }
}

func drawCardboardCat(open: Bool, in rect: NSRect) {
    iconCanvas(in: rect) {
        groundShadow(width: 13.8, center: NSPoint(x: 10.2, y: 2.6), alpha: 0.20)
        let (front, side, top) = cardboardFaces()

        if open {
            grad(side, cardboardSideTop, cardboardSideBottom)
            grad(front, cardboardFrontTop, cardboardFrontBottom)
            stroke(front, cardboardEdge, 0.55)
            stroke(side, cardboardEdge, 0.55)
            drawShippingLabel()

            let opening = poly([
                NSPoint(x: FL, y: FT), NSPoint(x: FR, y: FT),
                NSPoint(x: FR + DX, y: FT + DY), NSPoint(x: FL + DX, y: FT + DY)
            ])
            grad(opening, hex(0x4C311D), hex(0x2B1A0E))
            stroke(opening, hex(0x5F3D24), 0.45)

            // 后盖
            let backFlap = poly([
                NSPoint(x: FL + DX, y: FT + DY), NSPoint(x: FR + DX, y: FT + DY),
                NSPoint(x: FR + DX - 0.7, y: FT + DY + 1.7), NSPoint(x: FL + DX - 0.7, y: FT + DY + 1.7)
            ])
            grad(backFlap, hex(0xE5C198), hex(0xC99A6B))
            stroke(backFlap, cardboardEdge, 0.45)

            // 猫头
            drawCatHead(baseY: 12.9)

            // 前盖 + 侧盖，压在猫头下方
            let leftFlap = poly([
                NSPoint(x: FL, y: FT), NSPoint(x: FL + DX, y: FT + DY),
                NSPoint(x: FL + DX - 1.5, y: FT + DY + 1.2), NSPoint(x: FL - 1.3, y: FT + 0.8)
            ])
            grad(leftFlap, hex(0xDDB184), hex(0xC18D5B))
            stroke(leftFlap, cardboardEdge, 0.45)
            let rightFlap = poly([
                NSPoint(x: FR, y: FT), NSPoint(x: FR + DX, y: FT + DY),
                NSPoint(x: FR + DX + 0.9, y: FT + DY - 0.4), NSPoint(x: FR + 0.9, y: FT - 0.5)
            ])
            grad(rightFlap, hex(0xD2A374), hex(0xB57F4D))
            stroke(rightFlap, cardboardEdge, 0.45)
            let frontFlap = poly([
                NSPoint(x: FL, y: FT), NSPoint(x: FR, y: FT),
                NSPoint(x: FR + 0.7, y: FT + 1.6), NSPoint(x: FL - 0.7, y: FT + 1.6)
            ])
            grad(frontFlap, hex(0xE3BC90), hex(0xC99765))
            stroke(frontFlap, cardboardEdge, 0.45)

            // 前爪搭在箱沿
            drawPaw(at: NSPoint(x: 11.7, y: 11.9), size: 0.82, toesDown: true)
        } else {
            drawCardboardBody(front: front, side: side, top: top)
            drawTapeOnCardboard()
            drawShippingLabel()

            // 盖子微开一条缝 + 耳朵
            let slit = NSBezierPath(ovalIn: NSRect(x: 8.1, y: 12.75, width: 4.6, height: 1.0))
            fill(slit, hex(0x4C311D, 0.85))
            drawCatEars(baseY: 13.0, small: false)
        }
    }
}

// MARK: - 木盒

func drawWoodGrain() {
    for y in [4.7, 6.4, 8.1] {
        let p = NSBezierPath()
        p.move(to: NSPoint(x: 4.2, y: y))
        p.curve(to: NSPoint(x: 12.4, y: y + 0.35),
                controlPoint1: NSPoint(x: 6.5, y: y + 0.55),
                controlPoint2: NSPoint(x: 10.0, y: y - 0.2))
        stroke(p, woodGrain, 0.45)
    }
    for y in [11.6, 12.5] {
        let p = NSBezierPath()
        p.move(to: NSPoint(x: 4.8, y: y))
        p.curve(to: NSPoint(x: 14.8, y: y + 0.5),
                controlPoint1: NSPoint(x: 7.5, y: y + 0.7),
                controlPoint2: NSPoint(x: 12.2, y: y - 0.1))
        stroke(p, woodGrain, 0.4)
    }
}

func brassScrew(_ x: CGFloat, _ y: CGFloat) {
    let c = NSBezierPath(ovalIn: NSRect(x: x - 0.28, y: y - 0.28, width: 0.56, height: 0.56))
    grad(c, brassTop, brassBottom)
    stroke(c, hex(0x6E4E20), 0.18)
}

func drawWoodBox(open: Bool, in rect: NSRect) {
    iconCanvas(in: rect) {
        groundShadow(width: 13.8, center: NSPoint(x: 10.2, y: 2.6), alpha: 0.24)
        let (front, side, top) = cardboardFaces()

        grad(side, woodSideTop, woodSideBottom)
        if !open { grad(top, woodTopTop, woodTopBottom) }
        grad(front, woodFrontTop, woodFrontBottom)
        stroke(front, woodEdge, 0.55)
        stroke(side, woodEdge, 0.55)
        if !open { stroke(top, woodEdge, 0.55) }
        drawWoodGrain()

        // 铜角
        for (x, y) in [(4.25, 3.25), (12.35, 3.25), (4.25, 10.35), (12.35, 10.35)] {
            let c = NSBezierPath(roundedRect: NSRect(x: x - 0.55, y: y - 0.55, width: 1.1, height: 1.1),
                                 xRadius: 0.2, yRadius: 0.2)
            grad(c, brassTop, brassBottom)
            stroke(c, hex(0x6E4E20), 0.2)
        }
        brassScrew(5.0, 4.0)
        brassScrew(11.6, 4.0)

        if open {
            // 内壁
            let opening = poly([
                NSPoint(x: FL, y: FT), NSPoint(x: FR, y: FT),
                NSPoint(x: FR + DX, y: FT + DY), NSPoint(x: FL + DX, y: FT + DY)
            ])
            grad(opening, hex(0x3B2411), hex(0x24150B))
            stroke(opening, woodEdge, 0.5)

            // 立起来的木盖
            let lid = poly([
                NSPoint(x: FL + DX, y: FT + DY), NSPoint(x: FR + DX, y: FT + DY),
                NSPoint(x: FR + DX - 0.4, y: FT + DY + 2.4), NSPoint(x: FL + DX - 0.4, y: FT + DY + 2.4)
            ])
            grad(lid, hex(0xC68A56), hex(0x9C6436), 90)
            stroke(lid, woodEdge, 0.5)
            line(FL + DX + 0.3, FT + DY + 1.2, FR + DX - 0.7, FT + DY + 1.2, woodGrain, 0.4)

            // 猫爪从箱子里伸出来
            let arm = NSBezierPath()
            arm.move(to: NSPoint(x: 9.6, y: 12.9))
            arm.curve(to: NSPoint(x: 9.5, y: 11.7),
                      controlPoint1: NSPoint(x: 9.3, y: 12.6),
                      controlPoint2: NSPoint(x: 9.2, y: 12.0))
            stroke(arm, pawEdge, 1.5)
            stroke(arm, pawFurTop, 1.1)
            drawPaw(at: NSPoint(x: 9.5, y: 11.8), size: 1.05, toesDown: true)
        } else {
            // 盖缝 + 铜搭扣
            line(FL, 9.55, FR, 9.55, hex(0x4A2A12, 0.55), 0.5)
            let latch = NSBezierPath(roundedRect: NSRect(x: 8.6, y: 9.0, width: 2.4, height: 1.5),
                                     xRadius: 0.3, yRadius: 0.3)
            grad(latch, brassTop, brassBottom)
            stroke(latch, hex(0x6E4E20), 0.25)
            fill(NSBezierPath(ovalIn: NSRect(x: 9.45, y: 9.45, width: 0.7, height: 0.7)),
                 hex(0x4A3418, 0.8))
        }
    }
}

// MARK: - 铁皮盒

func drawTinBox(open: Bool, in rect: NSRect) {
    iconCanvas(in: rect) {
        groundShadow(width: 13.0, center: NSPoint(x: 9.8, y: 2.8), alpha: 0.22)
        let front = NSBezierPath(roundedRect: NSRect(x: 4.0, y: 3.0, width: 9.0, height: 8.0),
                                 xRadius: 0.9, yRadius: 0.9)
        let side = poly([
            NSPoint(x: 13.0, y: 3.2), NSPoint(x: 16.0, y: 5.0),
            NSPoint(x: 16.0, y: 12.4), NSPoint(x: 13.0, y: 10.6)
        ])
        let top = poly([
            NSPoint(x: 4.2, y: 10.6), NSPoint(x: 13.0, y: 10.6),
            NSPoint(x: 16.0, y: 12.4), NSPoint(x: 7.2, y: 12.4)
        ])

        grad(side, tinSideTop, tinSideBottom)
        if !open { grad(top, tinTopTop, tinTopBottom) }
        grad(front, tinFrontTop, tinFrontBottom)
        stroke(front, tinEdge, 0.55)
        stroke(side, tinEdge, 0.55)
        if !open { stroke(top, tinEdge, 0.55) }

        // 红色标签
        let label = NSBezierPath(roundedRect: NSRect(x: 4.5, y: 5.0, width: 8.0, height: 2.9),
                                 xRadius: 0.35, yRadius: 0.35)
        fill(label, tinRed)
        line(5.0, 6.55, 11.9, 6.55, tinCream.withAlphaComponent(0.85), 0.45)
        line(5.0, 6.0, 9.8, 6.0, tinCream.withAlphaComponent(0.65), 0.35)
        // 小圆标
        let badge = NSBezierPath(ovalIn: NSRect(x: 10.0, y: 5.45, width: 1.7, height: 1.7))
        stroke(badge, tinCream.withAlphaComponent(0.8), 0.35)

        if open {
            // 开口
            let opening = poly([
                NSPoint(x: 4.2, y: 10.6), NSPoint(x: 13.0, y: 10.6),
                NSPoint(x: 16.0, y: 12.4), NSPoint(x: 7.2, y: 12.4)
            ])
            grad(opening, hex(0x333F43), hex(0x1C2427))
            stroke(opening, tinEdge, 0.45)

            // 掀开的盖子
            let lid = poly([
                NSPoint(x: 7.2, y: 12.4), NSPoint(x: 16.0, y: 12.4),
                NSPoint(x: 15.3, y: 14.5), NSPoint(x: 6.5, y: 14.5)
            ])
            grad(lid, hex(0xE6ECEE), hex(0xBAC4C8), 90)
            stroke(lid, tinEdge, 0.45)
            line(7.4, 13.9, 15.2, 13.9, NSColor.white.withAlphaComponent(0.35), 0.35)

            // 猫爪
            let arm = NSBezierPath()
            arm.move(to: NSPoint(x: 9.3, y: 13.0))
            arm.curve(to: NSPoint(x: 9.2, y: 12.1),
                      controlPoint1: NSPoint(x: 9.0, y: 13.0),
                      controlPoint2: NSPoint(x: 8.9, y: 12.5))
            stroke(arm, pawEdge, 1.45)
            stroke(arm, pawFurTop, 1.05)
            drawPaw(at: NSPoint(x: 9.2, y: 12.1), size: 1.0, toesDown: true)
        } else {
            // 盖缝 + 铜扣
            line(4.2, 10.55, 13.0, 10.55, hex(0x4B585C, 0.7), 0.5)
            let latch = NSBezierPath(roundedRect: NSRect(x: 7.9, y: 9.7, width: 2.0, height: 1.5),
                                     xRadius: 0.25, yRadius: 0.25)
            grad(latch, brassTop, brassBottom)
            stroke(latch, hex(0x6E4E20), 0.22)
            line(8.9, 10.0, 8.9, 10.8, hex(0x5A3E18, 0.8), 0.3)
        }
    }
}

// MARK: - 猫爪

func drawPaw(at center: NSPoint, size: CGFloat, toesDown: Bool) {
    let s = size
    let padRect = NSRect(x: center.x - 1.75 * s, y: center.y - 1.35 * s,
                         width: 3.5 * s, height: 2.7 * s)
    let pad = NSBezierPath(roundedRect: padRect, xRadius: 1.3 * s, yRadius: 1.3 * s)
    grad(pad, pawFurTop, pawFurBottom)
    stroke(pad, pawEdge, 0.32 * s)

    let toeY = toesDown ? center.y - 2.15 * s : center.y + 1.5 * s
    for dx in [-1.05, 0.0, 1.05] {
        let toe = NSBezierPath(ovalIn: NSRect(x: center.x + (dx - 0.58) * s, y: toeY,
                                              width: 1.16 * s, height: 1.08 * s))
        grad(toe, pawFurTop, pawFurBottom)
        stroke(toe, pawEdge, 0.28 * s)
        fill(NSBezierPath(ovalIn: NSRect(x: center.x + (dx - 0.26) * s, y: toeY + 0.32 * s,
                                         width: 0.52 * s, height: 0.42 * s)), pawPad)
    }
    // 掌心肉垫
    fill(NSBezierPath(ovalIn: NSRect(x: center.x - 0.62 * s, y: center.y - 0.5 * s,
                                     width: 1.24 * s, height: 0.95 * s)), pawPad)
}

// MARK: - 候选

struct RealCandidate {
    let id: String
    let name: String
    let subtitle: String
    let draw: (Bool, NSRect) -> Void
}

let candidates: [RealCandidate] = [
    RealCandidate(id: "R1", name: "真实纸箱", subtitle: "胶带、面单、易碎标；开盖时猫爪扒着箱盖",
                  draw: { open, rect in drawCardboardPaw(open: open, in: rect) }),
    RealCandidate(id: "R2", name: "木盒", subtitle: "木纹、铜角、铜搭扣；开盖时猫爪伸出来",
                  draw: { open, rect in drawWoodBox(open: open, in: rect) }),
    RealCandidate(id: "R3", name: "猫在纸箱里", subtitle: "关着只露耳朵，打开是猫头和一只爪",
                  draw: { open, rect in drawCardboardCat(open: open, in: rect) }),
    RealCandidate(id: "R4", name: "铁皮盒", subtitle: "铁皮、红标、铜扣；掀盖时猫爪压着盒沿",
                  draw: { open, rect in drawTinBox(open: open, in: rect) })
]

// MARK: - 输出

let scale: CGFloat = 2

func renderTile(_ candidate: RealCandidate) {
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

    paper.setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()

    let title = NSAttributedString(string: "\(candidate.id) · \(candidate.name)", attributes: [
        .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
        .foregroundColor: textMain
    ])
    title.draw(at: NSPoint(x: 18, y: h - 30))

    NSAttributedString(string: candidate.subtitle, attributes: [
        .font: NSFont.systemFont(ofSize: 9, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 18, y: h - 46))

    let size: CGFloat = 118
    for (index, open) in [false, true].enumerated() {
        let x = 54 + CGFloat(index) * (size + 18)
        let y: CGFloat = 66
        let bg = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: size, height: size),
                              xRadius: 16, yRadius: 16)
        fill(bg, hex(0xFFFDF9, 0.9))
        stroke(bg, NSColor.black.withAlphaComponent(0.04), 0.8)
        candidate.draw(open, NSRect(x: x + 10, y: y + 10, width: size - 20, height: size - 20))

        let label = NSAttributedString(string: open ? "开" : "关", attributes: [
            .font: NSFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: textSub
        ])
        let ls = label.size()
        label.draw(at: NSPoint(x: x + (size - ls.width) / 2, y: y - 16))
    }

    // 实际大小：左浅右深
    let strip = NSRect(x: 18, y: 14, width: w - 36, height: 34)
    let half = strip.width / 2
    hex(0xF7F0E4).setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.minX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 9, yRadius: 9).fill()
    hex(0x1E1E20).setFill()
    NSBezierPath(roundedRect: NSRect(x: strip.midX, y: strip.minY, width: half, height: strip.height),
                 xRadius: 9, yRadius: 9).fill()
    line(strip.midX, strip.minY + 2, strip.midX, strip.maxY - 2, NSColor(calibratedWhite: 0.5, alpha: 0.18), 0.8)

    for open in [false, true] {
        let i = open ? 1 : 0
        candidate.draw(open, NSRect(x: strip.minX + 22 + CGFloat(i) * 40,
                                    y: strip.midY - 9, width: 18, height: 18))
        candidate.draw(open, NSRect(x: strip.midX + 22 + CGFloat(i) * 40,
                                    y: strip.midY - 9, width: 18, height: 18))
    }

    NSAttributedString(string: "实际大小 18pt · 左浅色 / 右深色", attributes: [
        .font: NSFont.systemFont(ofSize: 8, weight: .regular),
        .foregroundColor: textSub
    ]).draw(at: NSPoint(x: 18, y: 2))

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        let path = "/tmp/realbox-\(candidate.id).png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("wrote \(path)")
    }
}

func renderAll() {
    let cols = 2
    let tileW: CGFloat = 400, tileH: CGFloat = 270, gap: CGFloat = 16, pad: CGFloat = 24
    let w = CGFloat(cols) * tileW + gap + pad * 2
    let rows = 2
    let h = CGFloat(rows) * tileH + gap + pad * 2 + 40

    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(w * scale), pixelsHigh: Int(h * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.cgContext.scaleBy(x: scale, y: scale)

    paper.setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()

    NSAttributedString(string: "留白 v1.1 · 真实小物品候选", attributes: [
        .font: NSFont.systemFont(ofSize: 24, weight: .semibold),
        .foregroundColor: textMain
    ]).draw(at: NSPoint(x: pad, y: h - 34))

    for (index, candidate) in candidates.enumerated() {
        let col = index % cols
        let row = index / cols
        let x = pad + CGFloat(col) * (tileW + gap)
        let y = h - 50 - CGFloat(row + 1) * tileH - CGFloat(row) * gap
        let card = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: tileW, height: tileH),
                                xRadius: 18, yRadius: 18)
        fill(card, cardFill)
        stroke(card, NSColor.black.withAlphaComponent(0.05), 0.8)

        NSAttributedString(string: "\(candidate.id) · \(candidate.name)", attributes: [
            .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: textMain
        ]).draw(at: NSPoint(x: x + 16, y: y + tileH - 26))

        NSAttributedString(string: candidate.subtitle, attributes: [
            .font: NSFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: textSub
        ]).draw(at: NSPoint(x: x + 16, y: y + tileH - 41))

        let size: CGFloat = 110
        for (i, open) in [false, true].enumerated() {
            let px = x + 18 + CGFloat(i) * (size + 10)
            let py = y + 55
            let bg = NSBezierPath(roundedRect: NSRect(x: px, y: py, width: size, height: size),
                                  xRadius: 14, yRadius: 14)
            fill(bg, hex(0xFFFDF9, 0.9))
            candidate.draw(open, NSRect(x: px + 8, y: py + 8, width: size - 16, height: size - 16))
        }

        let strip = NSRect(x: x + 18, y: y + 14, width: tileW - 36, height: 30)
        let half = strip.width / 2
        hex(0xF7F0E4).setFill()
        NSBezierPath(roundedRect: NSRect(x: strip.minX, y: strip.minY, width: half, height: strip.height),
                     xRadius: 8, yRadius: 8).fill()
        hex(0x1E1E20).setFill()
        NSBezierPath(roundedRect: NSRect(x: strip.midX, y: strip.minY, width: half, height: strip.height),
                     xRadius: 8, yRadius: 8).fill()
        for open in [false, true] {
            let i = open ? 1 : 0
            candidate.draw(open, NSRect(x: strip.minX + 20 + CGFloat(i) * 34,
                                        y: strip.midY - 9, width: 18, height: 18))
            candidate.draw(open, NSRect(x: strip.midX + 20 + CGFloat(i) * 34,
                                        y: strip.midY - 9, width: 18, height: 18))
        }
    }

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        let path = "/tmp/realbox-all.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("wrote \(path) \(rep.pixelsWide)x\(rep.pixelsHigh)")
    }
}

for candidate in candidates { renderTile(candidate) }
renderAll()
