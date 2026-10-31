// 生成官网用的图片：hero、折叠前后对比、社交分享图。
import AppKit

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

func cg(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    color(hex, alpha).cgColor
}

func makeContext(_ width: CGFloat, _ height: CGFloat, scale: CGFloat = 2) -> CGContext {
    let ctx = CGContext(data: nil, width: Int(width * scale), height: Int(height * scale),
                        bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: scale, y: scale)
    return ctx
}

func save(_ ctx: CGContext, _ path: String) {
    guard let image = ctx.makeImage() else { return }
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else { return }
    try? data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

// MARK: 画一个开关

func drawSwitch(_ ctx: CGContext, rect: CGRect, on: Bool) {
    let h = rect.height
    let radius = h / 2
    let track = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -h * 0.08), blur: h * 0.28, color: cg(0x0B1026, 0.22))
    ctx.addPath(track)
    ctx.setFillColor(on ? cg(0x45C34F) : cg(0x9BA0AE))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(track)
    ctx.clip()
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let colors = on
        ? [cg(0x6FD45F), cg(0x45C34F), cg(0x2EA845)]
        : [cg(0xB6BAC6), cg(0x9BA0AE), cg(0x82879A)]
    let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: nil)!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: rect.midX, y: rect.maxY),
                           end: CGPoint(x: rect.midX, y: rect.minY),
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()

    // 白点
    let d = h * 0.76
    let knob = CGRect(x: on ? rect.maxX - d - h * 0.12 : rect.minX + h * 0.12,
                      y: rect.midY - d / 2, width: d, height: d)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -h * 0.05), blur: h * 0.18, color: cg(0x0B1026, 0.20))
    ctx.addPath(CGPath(ellipseIn: knob, transform: nil))
    ctx.setFillColor(cg(0xFFFFFF))
    ctx.fillPath()
    ctx.restoreGState()
}

// MARK: 模拟的菜单栏

/// 一排抽象的状态栏图标（圆、方、三角…），避免出现真实 App 的图标。
func drawIcon(_ ctx: CGContext, rect: CGRect, kind: Int, alpha: CGFloat) {
    let s = rect.width
    ctx.setFillColor(cg(0x2A3350, alpha))
    switch kind % 6 {
    case 0:
        ctx.setStrokeColor(cg(0x2A3350, alpha))
        ctx.setLineWidth(s * 0.09)
        ctx.addPath(CGPath(ellipseIn: rect.insetBy(dx: s * 0.12, dy: s * 0.12), transform: nil))
        ctx.strokePath()
    case 1:
        ctx.addPath(CGPath(roundedRect: rect.insetBy(dx: s * 0.12, dy: s * 0.12),
                           cornerWidth: s * 0.16, cornerHeight: s * 0.16, transform: nil))
        ctx.fillPath()
    case 2:
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + s * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX - s * 0.16, y: rect.maxY - s * 0.18))
        path.addLine(to: CGPoint(x: rect.minX + s * 0.16, y: rect.maxY - s * 0.18))
        path.closeSubpath()
        ctx.addPath(path)
        ctx.fillPath()
    case 3:
        ctx.addPath(CGPath(roundedRect: rect.insetBy(dx: s * 0.24, dy: s * 0.14),
                           cornerWidth: s * 0.18, cornerHeight: s * 0.18, transform: nil))
        ctx.fillPath()
    case 4:
        let path = CGMutablePath()
        let r = s * 0.30
        for i in 0..<6 {
            let angle = CGFloat(i) / 6 * 2 * .pi + .pi / 6
            let point = CGPoint(x: rect.midX + r * cos(angle), y: rect.midY + r * sin(angle))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        ctx.addPath(path)
        ctx.fillPath()
    default:
        ctx.setStrokeColor(cg(0x2A3350, alpha))
        ctx.setLineWidth(s * 0.09)
        ctx.addPath(CGPath(ellipseIn: rect.insetBy(dx: s * 0.26, dy: s * 0.26), transform: nil))
        ctx.strokePath()
        ctx.setFillColor(cg(0x2A3350, alpha))
        ctx.addPath(CGPath(ellipseIn: rect.insetBy(dx: s * 0.40, dy: s * 0.40), transform: nil))
        ctx.fillPath()
    }
}

/// 一条菜单栏。`collapsed` 为真时不画开关左侧的图标。
func drawMenuBar(_ ctx: CGContext, rect: CGRect, collapsed: Bool, switchOn: Bool) {
    let h = rect.height
    let barPath = CGPath(roundedRect: rect, cornerWidth: min(h / 2, 18), cornerHeight: min(h / 2, 18), transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 26, color: cg(0x0B1026, 0.18))
    ctx.addPath(barPath)
    ctx.setFillColor(cg(0xF7F3E8))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(barPath)
    ctx.clip()

    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let gradient = CGGradient(colorsSpace: space,
                              colors: [cg(0xFBF8F0), cg(0xEFE8D6)] as CFArray, locations: nil)!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: rect.midX, y: rect.maxY),
                           end: CGPoint(x: rect.midX, y: rect.minY),
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

    // 左侧菜单文字示意
    var x = rect.minX + h * 0.45
    let widths: [CGFloat] = [h * 0.55, h * 0.9, h * 0.75, h * 0.62]
    for w in widths {
        let bar = CGRect(x: x, y: rect.midY - h * 0.06, width: w, height: h * 0.12)
        ctx.setFillColor(cg(0x2A3350, 0.55))
        ctx.addPath(CGPath(roundedRect: bar, cornerWidth: h * 0.06, cornerHeight: h * 0.06, transform: nil))
        ctx.fillPath()
        x += w + h * 0.28
    }

    let iconSize = h * 0.38
    let iconY = rect.midY - iconSize / 2
    let switchW = h * 1.55
    let switchH = h * 0.52

    // 右侧图标（始终可见）
    let rightArea = rect.maxX - h * 0.6
    let iconGap = h * 0.30
    var rightX = rightArea
    var rightPositions: [CGFloat] = []
    for _ in 0..<3 {
        rightX -= iconSize
        rightPositions.append(rightX)
        rightX -= iconGap
    }

    // 开关放在「右侧图标」左边
    let switchRight = (rightPositions.last ?? rightArea) - h * 0.40
    let switchRect = CGRect(x: switchRight - switchW,
                            y: rect.midY - switchH / 2,
                            width: switchW, height: switchH)

    // 开关左边（折叠时消失）
    var leftPositions: [CGFloat] = []
    var leftX = switchRect.minX - h * 0.45
    for _ in 0..<5 {
        leftX -= iconSize
        leftPositions.append(leftX)
        leftX -= iconGap
    }

    for (index, x) in rightPositions.enumerated() {
        drawIcon(ctx, rect: CGRect(x: x, y: iconY, width: iconSize, height: iconSize),
                 kind: index + 2, alpha: 0.72)
    }
    if !collapsed {
        for (index, x) in leftPositions.enumerated() {
            drawIcon(ctx, rect: CGRect(x: x, y: iconY, width: iconSize, height: iconSize),
                     kind: index, alpha: 0.72)
        }
    }

    drawSwitch(ctx, rect: switchRect, on: switchOn)

    ctx.restoreGState()
}

// MARK: 输出

let outDir = "website/assets"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// 1. hero
do {
    let w: CGFloat = 1600, h: CGFloat = 900
    let ctx = makeContext(w, h)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let bg = CGGradient(colorsSpace: space,
                        colors: [cg(0x121A38), cg(0x1E2A55), cg(0x27345F)] as CFArray,
                        locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: h), end: CGPoint(x: w, y: 0),
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

    // 柔光
    let glow = CGGradient(colorsSpace: space,
                          colors: [cg(0x45C34F, 0.30), cg(0x45C34F, 0.0)] as CFArray, locations: nil)!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: w * 0.72, y: h * 0.42), startRadius: 0,
                           endCenter: CGPoint(x: w * 0.72, y: h * 0.42), endRadius: w * 0.45, options: [])

    // 展开
    drawMenuBar(ctx, rect: CGRect(x: 130, y: h * 0.50, width: w - 260, height: 92), collapsed: false, switchOn: true)
    // 折叠
    drawMenuBar(ctx, rect: CGRect(x: 130, y: h * 0.50 - 150, width: w - 260, height: 92), collapsed: true, switchOn: false)

    save(ctx, "\(outDir)/hero.png")
}

// 2. 两种状态（透明背景，页面里自己上底色）
for (name, collapsed, on) in [("state-expanded", false, true), ("state-collapsed", true, false)] {
    let w: CGFloat = 1000, h: CGFloat = 150
    let ctx = makeContext(w, h)
    drawMenuBar(ctx, rect: CGRect(x: 0, y: 30, width: w, height: 90), collapsed: collapsed, switchOn: on)
    save(ctx, "\(outDir)/\(name).png")
}

// 3. 社交分享图
do {
    let w: CGFloat = 1200, h: CGFloat = 630
    let ctx = makeContext(w, h)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let bg = CGGradient(colorsSpace: space,
                        colors: [cg(0x121A38), cg(0x222E5A)] as CFArray, locations: nil)!
    ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: h), end: CGPoint(x: w, y: 0),
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

    // 图标
    if let icon = NSImage(contentsOfFile: "assets/icon_1024.png") {
        var rect = CGRect(x: 90, y: h / 2 - 110, width: 220, height: 220)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 40, color: cg(0x000000, 0.35))
        icon.draw(in: rect)
        ctx.restoreGState()
        rect = .zero
    }

    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = 6
    let title = NSAttributedString(string: "留白  BlankTop", attributes: [
        .font: NSFont.systemFont(ofSize: 64, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ])
    let subtitle = NSAttributedString(string: "更优雅的菜单栏开关 · macOS 27", attributes: [
        .font: NSFont.systemFont(ofSize: 28, weight: .regular),
        .foregroundColor: color(0xC9D2F0)
    ])
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    title.draw(at: NSPoint(x: 360, y: h / 2 + 10))
    subtitle.draw(at: NSPoint(x: 364, y: h / 2 - 40))
    NSGraphicsContext.restoreGraphicsState()

    save(ctx, "\(outDir)/og.png")
}
