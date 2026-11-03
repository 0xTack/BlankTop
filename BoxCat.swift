//
//  BoxCat.swift
//  BlankTop — 无聊盒子模式的状态栏图标
//
//  打开（展开）：猫从盒子里探出来（耳朵 + 眼睛）
//  关闭（收起）：盒子完全合上，猫全部收进去，只剩箱子和爪印
//

import AppKit

enum BoxCat {
    static let lidColor = NSColor(srgbRed: 234 / 255, green: 99 / 255, blue: 18 / 255, alpha: 1)
    static let bodyColor = NSColor(srgbRed: 239 / 255, green: 123 / 255, blue: 30 / 255, alpha: 1)
    static let seamColor = NSColor(srgbRed: 168 / 255, green: 67 / 255, blue: 10 / 255, alpha: 1)
    static let ink = NSColor(srgbRed: 8 / 255, green: 4 / 255, blue: 4 / 255, alpha: 1)
    static let cream = NSColor(srgbRed: 243 / 255, green: 243 / 255, blue: 184 / 255, alpha: 1)
    static let green = NSColor(srgbRed: 60 / 255, green: 139 / 255, blue: 65 / 255, alpha: 1)
    static let toe = NSColor(srgbRed: 248 / 255, green: 195 / 255, blue: 151 / 255, alpha: 1)

    /// 20pt 逻辑尺寸的状态栏图标。
    static func image(open: Bool) -> NSImage {
        let logical = NSSize(width: 20, height: 20)
        let scale: CGFloat = 2
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(logical.width * scale),
                                   pixelsHigh: Int(logical.height * scale),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.current = context
        context.cgContext.scaleBy(x: scale, y: scale)

        draw(open: open, in: NSRect(x: 0, y: 0, width: 20, height: 20))

        NSGraphicsContext.restoreGraphicsState()
        rep.size = logical
        let image = NSImage(size: logical)
        image.addRepresentation(rep)
        image.isTemplate = false
        return image
    }

    private static func draw(open: Bool, in rect: NSRect) {
        let ctx = NSGraphicsContext.current!.cgContext
        let s = min(rect.width / 20, rect.height / 20)
        ctx.saveGState()
        // 整体缩一点，给菜单栏上下留出余量。
        // 两种状态的内容高度不同，分别按各自中心对齐，再整体上移 0.4。
        let contentCenterY: CGFloat = open ? 9.9 : 11.3
        ctx.translateBy(x: rect.midX, y: rect.midY)
        ctx.scaleBy(x: s * 0.92, y: -s * 0.92)
        ctx.translateBy(x: -10, y: -(contentCenterY - 0.4))

        if open {
            // 耳朵
            ink.setFill()
            for cx in [CGFloat(6.1), 13.9] {
                NSBezierPath(ovalIn: NSRect(x: cx - 2.2, y: 0.4, width: 4.4, height: 4.6)).fill()
            }

            // 盖子
            lidColor.setFill()
            NSBezierPath(roundedRect: NSRect(x: 0.2, y: 3.7, width: 19.6, height: 3.1),
                         xRadius: 0.5, yRadius: 0.5).fill()

            // 猫头黑带
            ink.setFill()
            NSBezierPath(roundedRect: NSRect(x: 1.1, y: 6.7, width: 17.8, height: 3.4),
                         xRadius: 1.7, yRadius: 1.7).fill()

            // 眼睛
            for cx in [CGFloat(7.0), 13.0] {
                cream.setFill()
                NSBezierPath(ovalIn: NSRect(x: cx - 2.0, y: 7.0, width: 4.0, height: 2.8)).fill()
                green.setFill()
                NSBezierPath(ovalIn: NSRect(x: cx - 1.6, y: 7.25, width: 3.2, height: 2.3)).fill()
                ink.setFill()
                NSBezierPath(ovalIn: NSRect(x: cx - 0.35, y: 7.45, width: 0.7, height: 1.9)).fill()
            }

            // 箱体
            bodyColor.setFill()
            NSBezierPath(roundedRect: NSRect(x: 0.3, y: 10.0, width: 19.4, height: 9.4),
                         xRadius: 0.6, yRadius: 0.6).fill()
        } else {
            // 完全合上的箱子
            bodyColor.setFill()
            NSBezierPath(roundedRect: NSRect(x: 0.6, y: 6.8, width: 18.8, height: 12.6),
                         xRadius: 0.7, yRadius: 0.7).fill()

            seamColor.setFill()
            NSRect(x: 0.6, y: 6.5, width: 18.8, height: 0.35).fill()

            lidColor.setFill()
            NSBezierPath(roundedRect: NSRect(x: 0.2, y: 3.2, width: 19.6, height: 3.4),
                         xRadius: 0.6, yRadius: 0.6).fill()
        }

        // 爪印（水平居中，避免视觉上偏向一边）
        toe.setFill()
        for (dx, dy) in [(-1.7, 11.6), (0.0, 11.1), (1.7, 11.6)] {
            NSBezierPath(ovalIn: NSRect(x: 10.0 + dx - 0.55, y: dy, width: 1.1, height: 1.5)).fill()
        }
        NSColor.white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 8.6, y: 13.1, width: 2.8, height: 2.1)).fill()

        ctx.restoreGState()
    }
}
