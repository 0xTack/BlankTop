//
//  IconStyle.swift
//  BlankTop — 状态栏图标样式，以及菜单里用的同款预览
//
//  状态栏和「图标」子菜单共用 IconRenderer，菜单里看到的就是实际图标。
//

import AppKit

enum IconStyle: String, CaseIterable {
    case chevron        // ‹ › 粗
    case chevronThin    // ‹ › 细
    case triangle       // ◀ ▶
    case toLine         // ⇤ ⇥
    case symbol         // SF Symbol 箭头
    case eye            // 眼睛：展开时「眼睛关闭」= 点了会藏
    case dot            // ● / ○ 实心表示有东西收着
    case bar            // 一条竖线，没有方向感
    case sidebar        // SF Symbol 侧边栏
    case tray           // 收纳盘，收起时装满
    case archive        // 归档盒
    case moon           // 月亮
    case stack          // 一叠卡片
    case compress       // 压缩 / 展开矩形
    case doubleChevron  // 双箭头
    case halfCircle     // 半圆填充
    case menubar        // 菜单栏图标本身
    case toggle         // 自绘开关

    var label: String {
        switch self {
        case .chevron: return "粗箭头"
        case .chevronThin: return "细箭头"
        case .triangle: return "三角"
        case .toLine: return "到边箭头"
        case .symbol: return "SF Symbol 箭头"
        case .eye: return "眼睛"
        case .dot: return "圆点"
        case .bar: return "竖线"
        case .sidebar: return "侧边栏图标"
        case .tray: return "收纳盘"
        case .archive: return "归档盒"
        case .moon: return "月亮"
        case .stack: return "一叠卡片"
        case .compress: return "压缩 / 展开"
        case .doubleChevron: return "双箭头"
        case .halfCircle: return "半圆"
        case .menubar: return "菜单栏图标"
        case .toggle: return "开关"
        }
    }


    /// 有语义的图标在展开/折叠时换一个符号，其余不变。
    /// 除竖线和自绘开关外，所有样式都走 SF Symbols，保持同一套粗细和圆角。
    func symbolName(collapsed: Bool) -> String? {
        switch self {
        case .chevron, .chevronThin: return collapsed ? "chevron.right" : "chevron.left"
        case .symbol: return collapsed ? "chevron.compact.right" : "chevron.compact.left"
        case .triangle: return collapsed ? "arrowtriangle.right" : "arrowtriangle.left"
        case .toLine: return collapsed ? "arrow.right.to.line" : "arrow.left.to.line"
        case .dot: return collapsed ? "circle.fill" : "circle"
        case .eye: return collapsed ? "eye" : "eye.slash"
        case .sidebar: return collapsed ? "sidebar.right" : "sidebar.left"
        case .tray: return collapsed ? "tray.full.fill" : "tray"
        case .archive: return collapsed ? "archivebox.fill" : "archivebox"
        case .moon: return collapsed ? "moon.fill" : "moon"
        case .stack: return collapsed ? "square.stack.3d.up.fill" : "square.stack.3d.up"
        case .compress: return collapsed ? "rectangle.compress.vertical" : "rectangle.expand.vertical"
        case .doubleChevron: return collapsed ? "chevron.right.2" : "chevron.left.2"
        case .halfCircle: return collapsed ? "circle.righthalf.filled" : "circle.lefthalf.filled"
        case .menubar: return "menubar.rectangle"
        default: return nil
        }
    }

    /// 各样式在 SF Symbols 里的字号/字重，保证同一排看过去粗细一致。
    var symbolWeight: NSFont.Weight {
        switch self {
        case .chevron: return .heavy
        case .chevronThin: return .light
        default: return .semibold
        }
    }

    var symbolPointSize: CGFloat {
        switch self {
        case .dot: return 8
        case .chevronThin: return 11
        default: return 12
        }
    }
}

/// 状态栏和菜单共用：把某个样式画成图片。
enum IconRenderer {
    /// - Parameters:
    ///   - size: 逻辑边长。状态栏 20，菜单 18。
    ///   - collapsed: 是否处于折叠状态（决定方向/填充/睁眼）。
    static func image(style: IconStyle, collapsed: Bool, size: CGFloat, dark: Bool? = nil) -> NSImage {
        let logical = NSSize(width: size, height: size)
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

        let s = size / 20
        let box = NSRect(x: 0, y: 0, width: size, height: size)
        var isTemplate = true

        switch style {
        case .toggle:
            isTemplate = false
            let isDark = dark ?? (NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
            drawToggle(in: box, scale: s, on: !collapsed, dark: isDark)
        case .bar:
            drawBar(in: box, scale: s)
        default:
            if let name = style.symbolName(collapsed: collapsed) {
                drawSymbol(name, pointSize: style.symbolPointSize,
                           weight: style.symbolWeight, scale: s, in: box)
            }
        }

        NSGraphicsContext.restoreGraphicsState()

        rep.size = logical
        let image = NSImage(size: logical)
        image.addRepresentation(rep)
        image.isTemplate = isTemplate
        return image
    }

    /// 竖线：没有方向感，单独画，粗细和 SF Symbols 对齐。
    private static func drawBar(in box: NSRect, scale: CGFloat) {
        NSColor.black.setFill()
        let width = 1.5 * scale
        let height = 13 * scale
        NSBezierPath(roundedRect: NSRect(x: box.midX - width / 2,
                                         y: box.midY - height / 2,
                                         width: width, height: height),
                     xRadius: width / 2, yRadius: width / 2).fill()
    }

    private static func drawSymbol(_ name: String, pointSize: CGFloat,
                                   weight: NSFont.Weight, scale: CGFloat, in box: NSRect) {
        let configuration = NSImage.SymbolConfiguration(pointSize: pointSize * scale, weight: weight)
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration) else { return }
        let size = image.size
        image.draw(in: NSRect(x: box.midX - size.width / 2,
                              y: box.midY - size.height / 2,
                              width: size.width, height: size.height),
                   from: .zero, operation: .sourceOver, fraction: 1,
                   respectFlipped: false, hints: nil)
    }

    private static func drawToggle(in box: NSRect, scale: CGFloat, on: Bool, dark: Bool) {
        let width = box.width
        let height = box.height * 0.6
        let originY = box.midY - height / 2
        let inset = 0.75 * scale
        let radius = (height - inset * 2) / 2
        let track = NSBezierPath(roundedRect: NSRect(x: inset, y: originY + inset,
                                                     width: width - inset * 2,
                                                     height: height - inset * 2),
                                 xRadius: radius, yRadius: radius)

        // 浅色：原来的绿色；深色：保留绿色、轮廓和圆点改白
        let ink: NSColor = dark ? .white : .black
        let green = NSColor(srgbRed: 121 / 255, green: 188 / 255, blue: 81 / 255, alpha: 1)
        let tint: NSColor = dark
            ? (on ? green.withAlphaComponent(0.95)
                  : NSColor.white.withAlphaComponent(0.16))
            : (on ? green.withAlphaComponent(0.62)
                  : NSColor.black.withAlphaComponent(0.15))

        // 直接画「半截胶囊」，不用 clip —— clip 在部分上下文里会残留，导致只剩半边。
        let top = originY + inset + (height - inset * 2)
        let bottom = originY + inset
        let centerY = originY + height / 2
        let fill = NSBezierPath()
        if on {
            fill.move(to: NSPoint(x: width / 2, y: top))
            fill.line(to: NSPoint(x: inset + radius, y: top))
            fill.appendArc(withCenter: NSPoint(x: inset + radius, y: centerY),
                           radius: radius, startAngle: 90, endAngle: 270, clockwise: false)
            fill.line(to: NSPoint(x: width / 2, y: bottom))
        } else {
            let cx = width - inset - radius
            fill.move(to: NSPoint(x: width / 2, y: bottom))
            fill.line(to: NSPoint(x: cx, y: bottom))
            fill.appendArc(withCenter: NSPoint(x: cx, y: centerY),
                           radius: radius, startAngle: 270, endAngle: 90, clockwise: false)
            fill.line(to: NSPoint(x: width / 2, y: top))
        }
        fill.close()
        tint.setFill()
        fill.fill()

        ink.withAlphaComponent(0.78).setStroke()
        track.lineWidth = 1.2 * scale
        track.stroke()

        let knob = 5.2 * scale
        let margin = 2.4 * scale
        let knobX = on ? width - margin - knob : margin
        ink.withAlphaComponent(0.85).setFill()
        NSBezierPath(ovalIn: NSRect(x: knobX, y: originY + (height - knob) / 2,
                                    width: knob, height: knob)).fill()
    }
}
