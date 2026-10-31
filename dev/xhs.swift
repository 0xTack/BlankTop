// 生成小红书图文（3:4，1080×1440），8 张。
import AppKit

// MARK: - 基础

let W: CGFloat = 1080
let H: CGFloat = 1440

let navyTop = NSColor(srgbRed: 0.07, green: 0.10, blue: 0.20, alpha: 1)
let navyBottom = NSColor(srgbRed: 0.12, green: 0.16, blue: 0.32, alpha: 1)
let green = NSColor(srgbRed: 69 / 255, green: 195 / 255, blue: 79 / 255, alpha: 1)
let textColor = NSColor(srgbRed: 0.95, green: 0.96, blue: 1.0, alpha: 1)
let muted = NSColor(srgbRed: 0.62, green: 0.65, blue: 0.78, alpha: 1)
let beigeTop = NSColor(srgbRed: 0.984, green: 0.972, blue: 0.937, alpha: 1)
let beigeBottom = NSColor(srgbRed: 0.937, green: 0.910, blue: 0.847, alpha: 1)

func weight(_ size: CGFloat, _ w: NSFont.Weight) -> NSFont { NSFont.systemFont(ofSize: size, weight: w) }

/// 以「距离顶部」定位文字，返回文字块底部距顶部的距离。
@discardableResult
func drawText(_ string: String, x: CGFloat, top: CGFloat, width: CGFloat,
              size: CGFloat, fontW: NSFont.Weight = .regular,
              color: NSColor = textColor, lineSpacing: CGFloat = 10,
              align: NSTextAlignment = .left) -> CGFloat {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = lineSpacing
    paragraph.alignment = align
    let attributes: [NSAttributedString.Key: Any] = [
        .font: weight(size, fontW), .foregroundColor: color, .paragraphStyle: paragraph
    ]
    let attributed = NSAttributedString(string: string, attributes: attributes)
    let bounding = attributed.boundingRect(with: NSSize(width: width, height: 3000),
                                           options: [.usesLineFragmentOrigin, .usesFontLeading])
    let height = ceil(bounding.height)
    let rect = NSRect(x: x, y: H - top - height, width: width, height: height)
    attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
    return top + height
}

func background(_ ctx: CGContext) {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let gradient = CGGradient(colorsSpace: space,
                              colors: [navyBottom.cgColor, navyTop.cgColor] as CFArray,
                              locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: H), end: CGPoint(x: W, y: 0),
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    let glow = CGGradient(colorsSpace: space,
                          colors: [green.withAlphaComponent(0.20).cgColor,
                                   green.withAlphaComponent(0).cgColor] as CFArray,
                          locations: [0, 1])!
    ctx.drawRadialGradient(glow,
                           startCenter: CGPoint(x: W * 0.85, y: H * 0.85), startRadius: 0,
                           endCenter: CGPoint(x: W * 0.85, y: H * 0.85), endRadius: 760,
                           options: [])
}

@discardableResult
func chip(_ label: String, x: CGFloat, top: CGFloat) -> CGFloat {
    let font = weight(30, .semibold)
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: green]
    let size = (label as NSString).size(withAttributes: attributes)
    let rect = NSRect(x: x, y: H - top - 56, width: size.width + 44, height: 56)
    let path = NSBezierPath(roundedRect: rect, xRadius: 28, yRadius: 28)
    green.withAlphaComponent(0.10).setFill()
    path.fill()
    green.withAlphaComponent(0.38).setStroke()
    path.lineWidth = 1.5
    path.stroke()
    label.draw(at: NSPoint(x: x + 22, y: H - top - 44), withAttributes: attributes)
    return top + 56
}

func pageNumber(_ n: String) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: weight(28, .bold), .foregroundColor: muted
    ]
    let size = (n as NSString).size(withAttributes: attributes)
    n.draw(at: NSPoint(x: W - 90 - size.width, y: 78), withAttributes: attributes)
}

func footer(_ text: String) {
    drawText(text, x: 90, top: H - 150, width: 700, size: 28, color: muted)
}

// MARK: - 菜单栏示意

func drawMenuBar(rect: CGRect, collapsed: Bool) {
    let h = rect.height
    let path = NSBezierPath(roundedRect: rect, xRadius: 20, yRadius: 20)
    NSGradient(colors: [beigeTop, beigeBottom])!.draw(in: path, angle: -90)
    NSColor(calibratedWhite: 0, alpha: 0.06).setStroke()
    path.lineWidth = 1.2
    path.stroke()

    let icon = h * 0.36
    let iconY = rect.midY - icon / 2
    let gap = h * 0.26
    let dark = NSColor(srgbRed: 0.17, green: 0.20, blue: 0.31, alpha: 0.72)

    var x = rect.maxX - h * 0.45 - icon
    for i in 0..<3 {
        let r = CGRect(x: x, y: iconY, width: icon, height: icon)
        dark.setFill()
        if i % 2 == 0 {
            NSBezierPath(ovalIn: r.insetBy(dx: icon * 0.14, dy: icon * 0.14)).fill()
        } else {
            NSBezierPath(roundedRect: r.insetBy(dx: icon * 0.14, dy: icon * 0.14),
                         xRadius: icon * 0.16, yRadius: icon * 0.16).fill()
        }
        x -= icon + gap
    }

    let swW = h * 1.6, swH = h * 0.5
    let swRect = CGRect(x: x - swW + icon + gap * 0.2, y: rect.midY - swH / 2, width: swW, height: swH)
    drawSwitch(swRect, on: !collapsed)

    if !collapsed {
        var lx = swRect.minX - gap - icon
        for i in 0..<3 {
            let r = CGRect(x: lx, y: iconY, width: icon, height: icon)
            dark.setFill()
            if i % 2 == 0 {
                NSBezierPath(roundedRect: r.insetBy(dx: icon * 0.14, dy: icon * 0.14),
                             xRadius: icon * 0.16, yRadius: icon * 0.16).fill()
            } else {
                NSBezierPath(ovalIn: r.insetBy(dx: icon * 0.14, dy: icon * 0.14)).fill()
            }
            lx -= icon + gap
        }
    }
}

func drawSwitch(_ rect: CGRect, on: Bool) {
    let path = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)

    if on {
        NSColor(srgbRed: 121 / 255, green: 188 / 255, blue: 81 / 255, alpha: 0.92).setFill()
    } else {
        NSColor(calibratedWhite: 0.72, alpha: 1).setFill()
    }
    path.fill()

    NSColor.black.withAlphaComponent(0.55).setStroke()
    path.lineWidth = 1.6
    path.stroke()

    let knob = rect.height * 0.44
    let margin = rect.height * 0.19
    let knobX = on ? rect.maxX - margin - knob : rect.minX + margin
    NSColor.black.withAlphaComponent(0.82).setFill()
    NSBezierPath(ovalIn: NSRect(x: knobX, y: rect.midY - knob / 2, width: knob, height: knob)).fill()
}


func drawStrip(_ path: String, top: CGFloat, height: CGFloat, x: CGFloat = 90, width: CGFloat = 900) {
    guard let image = NSImage(contentsOfFile: path) else { return }
    let rect = NSRect(x: x, y: H - top - height, width: width, height: height)
    let clip = NSBezierPath(roundedRect: rect, xRadius: 18, yRadius: 18)
    NSGraphicsContext.saveGraphicsState()
    clip.addClip()
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    NSColor(calibratedWhite: 0, alpha: 0.10).setStroke()
    clip.lineWidth = 1.2
    clip.stroke()
}

// MARK: - 页面


let cards: [() -> Void] = [
    // 1 封面
    {
        chip("macOS 27 · 菜单栏", x: 90, top: 110)
        drawText("菜单栏终于\n清爽了", x: 86, top: 210, width: 900, size: 124, fontW: .bold, lineSpacing: 14)
        drawText("一个开关，把不常用的图标收起来。\n需要的时候再放出来。", x: 90, top: 580, width: 820,
                 size: 40, color: muted, lineSpacing: 14)
        drawMenuBar(rect: CGRect(x: 90, y: H - 1000, width: 900, height: 130), collapsed: false)
        footer("留白 BlankTop")
        pageNumber("01")
    },
    // 2 痛点
    {
        chip("先说实话", x: 90, top: 110)
        drawText("Hidden Bar\n在 macOS 27 上\n不好用了", x: 86, top: 200, width: 900,
                 size: 88, fontW: .bold, lineSpacing: 18)
        drawText("不是你的操作问题，\n是它和系统的新菜单栏机制不兼容。", x: 90, top: 590, width: 860,
                 size: 38, color: muted, lineSpacing: 14)
        drawText("·  该保留的图标也被一起藏了\n·  图标藏了收不回来\n·  分隔符一拖就消失", x: 96, top: 760, width: 860,
                 size: 40, fontW: .medium, lineSpacing: 30)
        pageNumber("02")
    },
    // 3 痛点 2
    {
        chip("于是发生这种事", x: 90, top: 110)
        drawText("图标被藏了\n找不回来", x: 86, top: 200, width: 900,
                 size: 104, fontW: .bold, lineSpacing: 16)
        drawText("菜单栏只剩几个孤零零的图标，\n重启、重装都不一定回来。", x: 90, top: 520, width: 860,
                 size: 38, color: muted, lineSpacing: 14)
        drawMenuBar(rect: CGRect(x: 90, y: H - 900, width: 900, height: 130), collapsed: true)
        drawText("不是你想要的效果", x: 90, top: 960, width: 700, size: 30, color: muted)
        pageNumber("03")
    },
    // 4 转折
    {
        chip("所以我做了个小的", x: 90, top: 110)
        drawText("一个小小的\n菜单栏开关", x: 86, top: 200, width: 900,
                 size: 100, fontW: .bold, lineSpacing: 16)
        drawText("不管系统怎么改，它只做一件事：\n把开关左边的图标收起来。", x: 90, top: 520, width: 860,
                 size: 38, color: muted, lineSpacing: 14)
        drawSwitch(CGRect(x: 330, y: H - 900, width: 420, height: 230), on: true)
        drawText("圆点在右 = 全部显示", x: 90, top: 950, width: 900, size: 32, color: muted, align: .center)
        pageNumber("04")
    },
    // 5 卖点
    {
        chip("四个词", x: 90, top: 110)
        drawText("不用学，也不占地方", x: 86, top: 200, width: 900, size: 74, fontW: .bold)

        let items: [(String, String, String)] = [
            ("1", "个开关", "没有面板、没有规则"),
            ("340", "KB", "没有后台进程"),
            ("MIT", "开源", "代码随便看"),
            ("18", "种图标", "还能换音效")
        ]
        for (index, item) in items.enumerated() {
            let col = index % 2
            let row = index / 2
            let x = 90 + CGFloat(col) * 470
            let topY = 400 + CGFloat(row) * 360
            let box = NSRect(x: x, y: H - topY - 300, width: 420, height: 300)
            let path = NSBezierPath(roundedRect: box, xRadius: 28, yRadius: 28)
            NSColor(calibratedWhite: 1, alpha: 0.05).setFill()
            path.fill()
            NSColor(calibratedWhite: 1, alpha: 0.09).setStroke()
            path.lineWidth = 1.4
            path.stroke()

            let number = NSMutableAttributedString(string: item.0, attributes: [
                .font: weight(80, .bold), .foregroundColor: textColor
            ])
            number.append(NSAttributedString(string: " " + item.1, attributes: [
                .font: weight(30, .semibold), .foregroundColor: muted
            ]))
            number.draw(at: NSPoint(x: x + 36, y: H - topY - 150))
            drawText(item.2, x: x + 36, top: topY + 180, width: 350, size: 28, color: muted)
        }
        pageNumber("05")
    },
    // 6 对比
    {
        chip("两种状态", x: 90, top: 110)
        drawText("开关在右，图标都在", x: 86, top: 200, width: 900, size: 80, fontW: .bold)
        drawMenuBar(rect: CGRect(x: 90, y: H - 460, width: 900, height: 140), collapsed: false)
        drawText("开关在左，左边收起来", x: 86, top: 640, width: 900, size: 80, fontW: .bold)
        drawMenuBar(rect: CGRect(x: 90, y: H - 900, width: 900, height: 140), collapsed: true)
        drawText("右边那些一直可见，不会跟着消失", x: 90, top: 990, width: 900, size: 32, color: muted)
        pageNumber("06")
    },
    // 7 真实截图
    {
        chip("真实截图", x: 90, top: 110)
        drawText("我自己的\n菜单栏", x: 86, top: 200, width: 900, size: 88, fontW: .bold, lineSpacing: 14)
        drawText("开 · 全部可见", x: 90, top: 470, width: 700, size: 30, fontW: .semibold, color: green)
        drawStrip("/tmp/real_on_raw.png", top: 520, height: 120)

        drawText("关 · 左边收起", x: 90, top: 700, width: 700, size: 30, fontW: .semibold, color: green)
        drawStrip("/tmp/real_off_raw.png", top: 750, height: 120)

        drawText("截图来自我这台 Mac，原样未做处理", x: 90, top: 930, width: 880,
                 size: 28, color: muted)
        pageNumber("07")
    },
    // 8 使用
    {
        chip("怎么用", x: 90, top: 110)
        drawText("按住 ⌘ 拖几下\n就配置完了", x: 86, top: 200, width: 900, size: 82, fontW: .bold, lineSpacing: 14)

        let steps: [(String, String)] = [
            ("01", "按住 ⌘，把想收起的图标拖到开关左边"),
            ("02", "点一下开关，左边整体收起来"),
            ("03", "再点一下，全部回来")
        ]
        for (index, step) in steps.enumerated() {
            let topY = 520 + CGFloat(index) * 180
            drawText(step.0, x: 96, top: topY, width: 120, size: 40, fontW: .bold, color: green)
            drawText(step.1, x: 240, top: topY + 6, width: 740, size: 36, lineSpacing: 10)
        }
        drawText("只有开关左边的会被收起，\n右边的永远留在菜单栏。", x: 96, top: 1030, width: 860,
                 size: 30, color: muted, lineSpacing: 12)
        pageNumber("08")
    },
    // 9 结尾
    {
        chip("最后", x: 90, top: 110)
        drawText("代码是公开的\n随便看", x: 86, top: 200, width: 900, size: 92, fontW: .bold, lineSpacing: 16)
        drawText("这类工具要拿到辅助功能权限，\n所以我把它做成了开源项目。\n它只做三件事：读图标位置、给出名单、撤销名单。",
                 x: 90, top: 520, width: 880, size: 34, color: muted, lineSpacing: 18)
        drawText("搜  BlankTop", x: 90, top: 800, width: 700, size: 54, fontW: .bold, color: green)
        drawText("记得放到「应用程序」文件夹里", x: 90, top: 890, width: 860, size: 30, color: muted)
        pageNumber("09")
    }
]

let outDir = "/tmp/xhs"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let names = ["cover", "pain", "pain2", "solution", "pillars", "compare", "real", "usage", "end"]

for (index, card) in cards.enumerated() {
    let image = NSImage(size: NSSize(width: W, height: H))
    image.lockFocus()
    background(NSGraphicsContext.current!.cgContext)
    card()
    image.unlockFocus()

    if let tiff = image.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let name = String(format: "%02d-%@.png", index + 1, names[index])
        try? png.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    }
}
print("done")
