// 用和应用一致的绘制参数，把 18 种图标样式渲染成图库（展开 / 折叠两版）。
import AppKit

func textIcon(_ title: String, size: CGFloat, weight: NSFont.Weight) -> NSAttributedString {
    NSAttributedString(string: title, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: NSColor.black
    ])
}

func symbolIcon(_ name: String, pointSize: CGFloat = 12) -> NSImage? {
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
    let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(config)
    image?.isTemplate = true
    return image
}

func toggleIcon(on: Bool) -> NSImage {
    let logical = NSSize(width: 20, height: 12)
    let s: CGFloat = 4
    let w = logical.width * s, h = logical.height * s
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(w), pixelsHigh: Int(h),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let inset: CGFloat = 0.75 * s
    let radius = (h - inset * 2) / 2
    let track = NSBezierPath(roundedRect: NSRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2),
                             xRadius: radius, yRadius: radius)

    NSGraphicsContext.saveGraphicsState()
    track.addClip()
    let tint = on ? NSColor(srgbRed: 121 / 255, green: 188 / 255, blue: 81 / 255, alpha: 0.62)
                  : NSColor.black.withAlphaComponent(0.15)
    tint.setFill()
    NSRect(x: on ? inset : w / 2, y: inset, width: w / 2 - inset, height: h - inset * 2).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSColor.black.withAlphaComponent(0.78).setStroke()
    track.lineWidth = 1.2 * s
    track.stroke()

    let knob = 5.2 * s, margin = 2.4 * s
    let knobX = on ? w - margin - knob : margin
    NSColor.black.withAlphaComponent(0.85).setFill()
    NSBezierPath(ovalIn: NSRect(x: knobX, y: (h - knob) / 2, width: knob, height: knob)).fill()
    NSGraphicsContext.restoreGraphicsState()

    rep.size = logical
    let image = NSImage(size: logical)
    image.addRepresentation(rep)
    image.isTemplate = false
    return image
}

struct Style {
    let name: String
    let expanded: String
    let collapsed: String
    let isSymbol: Bool
}

let textStyles: [Style] = [
    Style(name: "开关", expanded: "toggle", collapsed: "toggle", isSymbol: false),
    Style(name: "压缩", expanded: "rectangle.expand.vertical", collapsed: "rectangle.compress.vertical", isSymbol: true),
    Style(name: "眼睛", expanded: "eye.slash", collapsed: "eye", isSymbol: true),
    Style(name: "收纳盘", expanded: "tray", collapsed: "tray.full.fill", isSymbol: true),
    Style(name: "月亮", expanded: "moon", collapsed: "moon.fill", isSymbol: true),
    Style(name: "归档盒", expanded: "archivebox", collapsed: "archivebox.fill", isSymbol: true),
    Style(name: "粗箭头", expanded: "‹", collapsed: "›", isSymbol: false),
    Style(name: "圆点", expanded: "○", collapsed: "●", isSymbol: false)
]

let textSizes: [String: (CGFloat, NSFont.Weight)] = [
    "粗箭头": (15, .semibold),
    "细箭头": (14, .regular),
    "三角": (9, .bold),
    "到边箭头": (13, .medium),
    "圆点": (10, .bold),
    "竖线": (13, .light)
]

func draw(style: Style, on: Bool, in rect: NSRect) {
    if style.name == "开关" {
        let image = toggleIcon(on: on)
        image.draw(in: NSRect(x: rect.midX - 20, y: rect.midY - 12, width: 40, height: 24))
        return
    }
    let value = on ? style.expanded : style.collapsed
    if style.isSymbol {
        guard let image = symbolIcon(value) else { return }
        image.draw(in: NSRect(x: rect.midX - image.size.width / 2,
                              y: rect.midY - image.size.height / 2,
                              width: image.size.width, height: image.size.height),
                   from: .zero, operation: .sourceOver, fraction: 1)
        return
    }
    let spec = textSizes[style.name] ?? (13, .regular)
    let string = textIcon(value, size: spec.0, weight: spec.1)
    let size = string.size()
    string.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2))
}

func render(on: Bool, path: String) {
    let cols = 4
    let rows = (textStyles.count + cols - 1) / cols
    let cardW: CGFloat = 250, cardH: CGFloat = 104, gap: CGFloat = 16, pad: CGFloat = 18
    let width = CGFloat(cols) * cardW + CGFloat(cols - 1) * gap + pad * 2
    let height = CGFloat(rows) * cardH + CGFloat(rows - 1) * gap + pad * 2

    let output = NSImage(size: NSSize(width: width, height: height))
    output.lockFocus()

    // 与官网底色一致，导出后直接嵌入页面
    NSColor(srgbRed: 0x0b / 255, green: 0x10 / 255, blue: 0x20 / 255, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    for (index, style) in textStyles.enumerated() {
        let col = index % cols
        let row = index / cols
        let x = pad + CGFloat(col) * (cardW + gap)
        let y = height - pad - CGFloat(row + 1) * cardH - CGFloat(row) * gap

        let card = NSRect(x: x, y: y, width: cardW, height: cardH)
        let cardPath = NSBezierPath(roundedRect: card, xRadius: 14, yRadius: 14)
        NSColor(calibratedWhite: 1, alpha: 0.045).setFill()
        cardPath.fill()
        NSColor(calibratedWhite: 1, alpha: 0.10).setStroke()
        cardPath.lineWidth = 1
        cardPath.stroke()

        NSAttributedString(string: style.name, attributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor(calibratedWhite: 0.72, alpha: 1)
        ]).draw(at: NSPoint(x: x + 14, y: y + cardH - 26))

        let stripW: CGFloat = 150, stripH: CGFloat = 38
        let strip = NSRect(x: x + (cardW - stripW) / 2, y: y + 16, width: stripW, height: stripH)
        let stripPath = NSBezierPath(roundedRect: strip, xRadius: 9, yRadius: 9)
        NSGradient(colors: [NSColor(srgbRed: 0.984, green: 0.972, blue: 0.937, alpha: 1),
                            NSColor(srgbRed: 0.937, green: 0.910, blue: 0.847, alpha: 1)])!
            .draw(in: stripPath, angle: -90)
        NSColor(calibratedWhite: 0, alpha: 0.06).setStroke()
        stripPath.lineWidth = 1
        stripPath.stroke()

        draw(style: style, on: on, in: strip)
    }

    output.unlockFocus()

    if let tiff = output.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: path))
        print("wrote \(path) \(Int(width))x\(Int(height))")
    }
}

render(on: true, path: "/tmp/icons-pick.png")
